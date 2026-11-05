#### Check time-series table and junction table ####

library(dplyr)
library(tidyr)


check_timeseries_tables <- function(main_abundances_table,
                                    timeseries_tables,
                                    min_year = 1500,
                                    max_year = 3000) {
  
  # ---------------------------------------------------------------------------
  # 1. Extract tables
  # ---------------------------------------------------------------------------
  
  ts <- timeseries_tables$timeseries
  jt <- timeseries_tables$junction_table
  
  
  # ---------------------------------------------------------------------------
  # 2. Check required columns
  # ---------------------------------------------------------------------------
  
  required_ts <- c(
    "id", "code", "estimate", "cv", "se", "sd",
    "year", "lci", "uci", "notes"
  )
  
  required_jt <- c(
    "iwc_abundances_table_id",
    "id",
    "timeseries_id"
  )
  
  missing_ts_columns <- setdiff(required_ts, names(ts))
  missing_jt_columns <- setdiff(required_jt, names(jt))
  
  if (length(missing_ts_columns) > 0) {
    stop(
      "Missing required columns in timeseries table: ",
      paste(missing_ts_columns, collapse = ", ")
    )
  }
  
  if (length(missing_jt_columns) > 0) {
    stop(
      "Missing required columns in junction table: ",
      paste(missing_jt_columns, collapse = ", ")
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # 3. Helper functions
  # ---------------------------------------------------------------------------
  
  is_missing <- function(x) {
    is.na(x) | trimws(as.character(x)) == ""
  }
  
  num <- function(x) {
    suppressWarnings(as.numeric(as.character(x)))
  }
  
  
  # ---------------------------------------------------------------------------
  # 4. Time-series ID checks
  # ---------------------------------------------------------------------------
  
  ts_id <- as.character(ts$id)
  ts_code <- trimws(as.character(ts$code))
  
  
  # Missing IDs
  missing_timeseries_ids <- ts %>%
    mutate(row = row_number()) %>%
    filter(is_missing(id)) %>%
    transmute(
      row,
      id = as.character(id),
      issue = "Missing time-series id"
    )
  
  
  # Duplicate IDs
  duplicate_timeseries_ids <- ts %>%
    mutate(
      row = row_number(),
      id_chr = as.character(id)
    ) %>%
    filter(
      !is_missing(id),
      duplicated(id_chr) | duplicated(id_chr, fromLast = TRUE)
    ) %>%
    transmute(
      row,
      id = id_chr,
      issue = "Duplicate time-series id"
    )
  
  
  # Missing codes
  missing_timeseries_codes <- ts %>%
    mutate(row = row_number()) %>%
    filter(is_missing(code)) %>%
    transmute(
      row,
      id = as.character(id),
      code = as.character(code),
      issue = "Missing time-series code"
    )
  
  
  # ID format:
  # TS-<code>-000000
  id_pattern <- "^TS-.+-[0-9]{6}$"
  
  invalid_id_pattern <- ts %>%
    mutate(row = row_number()) %>%
    filter(
      !is_missing(id),
      !grepl(id_pattern, as.character(id))
    ) %>%
    transmute(
      row,
      id = as.character(id),
      code = as.character(code),
      issue = "Invalid time-series ID format"
    )
  
  
  # Check that code embedded in ID matches the code column
  invalid_id_code <- ts %>%
    mutate(
      row = row_number(),
      expected_prefix = paste0(
        "TS-",
        trimws(as.character(code)),
        "-"
      )
    ) %>%
    filter(
      !is_missing(id),
      !is_missing(code),
      !startsWith(as.character(id), expected_prefix)
    ) %>%
    transmute(
      row,
      id = as.character(id),
      code = as.character(code),
      issue = "Time-series ID does not agree with code"
    )
  
  
  # ---------------------------------------------------------------------------
  # 5. Estimate
  # ---------------------------------------------------------------------------
  
  estimate_num <- num(ts$estimate)
  
  estimate_bad <- is_missing(ts$estimate) |
    is.na(estimate_num) |
    !(estimate_num == -1 | estimate_num >= 0)
  
  estimate_rows <- which(estimate_bad %in% TRUE)
  
  estimate_issues <- data.frame(
    row = estimate_rows,
    id = as.character(ts$id[estimate_rows]),
    value = as.character(ts$estimate[estimate_rows]),
    issue = rep(
      "Estimate must be present and be -1 or a positive number",
      length(estimate_rows)
    ),
    stringsAsFactors = FALSE
  )
  
  
  # ---------------------------------------------------------------------------
  # 6. Positive numeric values
  #
  # se, sd, lci and uci may be missing.
  # If present, they must be > 0.
  # ---------------------------------------------------------------------------
  
  positive_value_issues <- bind_rows(
    lapply(
      c("se", "sd", "lci", "uci"),
      function(v) {
        
        x <- num(ts[[v]])
        
        bad <- !is_missing(ts[[v]]) &
          (is.na(x) | x < 0)
        
        bad_rows <- which(bad %in% TRUE)
        
        data.frame(
          row = bad_rows,
          id = as.character(ts$id[bad_rows]),
          column = rep(v, length(bad_rows)),
          value = as.character(ts[[v]][bad_rows]),
          issue = rep(
            "Value must be positive when present",
            length(bad_rows)
          ),
          stringsAsFactors = FALSE
        )
      }
    )
  )
  
  
  # ---------------------------------------------------------------------------
  # 7. Year
  #
  # Time-series records should have a year.
  # ---------------------------------------------------------------------------
  
  year_num <- num(ts$year)
  
  year_bad <- is_missing(ts$year) |
    is.na(year_num) |
    year_num != floor(year_num) |
    year_num < min_year |
    year_num > max_year
  
  year_rows <- which(year_bad %in% TRUE)
  
  year_issues <- data.frame(
    row = year_rows,
    id = as.character(ts$id[year_rows]),
    value = as.character(ts$year[year_rows]),
    issue = rep(
      paste0(
        "Year must be present and be an integer from ",
        min_year,
        " to ",
        max_year
      ),
      length(year_rows)
    ),
    stringsAsFactors = FALSE
  )
  
  
  # ---------------------------------------------------------------------------
  # 8. CV
  #
  # CV may be missing.
  # If present, it must be between 0 and 1 inclusive.
  # ---------------------------------------------------------------------------
  
  cv_num <- num(ts$cv)
  
  cv_bad <- !is_missing(ts$cv) &
    (
      is.na(cv_num) |
        cv_num < 0 |
        cv_num > 5
    )
  
  cv_rows <- which(cv_bad %in% TRUE)
  
  cv_issues <- data.frame(
    row = cv_rows,
    id = as.character(ts$id[cv_rows]),
    value = as.character(ts$cv[cv_rows]),
    issue = rep(
      "CV must be between 0 and 1 but can be higher",
      length(cv_rows)
    ),
    stringsAsFactors = FALSE
  )
  
  
  # ---------------------------------------------------------------------------
  # 9. Confidence intervals
  #
  # When both limits are present:
  # lci <= estimate <= uci
  #
  # Records with estimate == -1 are excluded from this logical check.
  # ---------------------------------------------------------------------------
  
  lci_num <- num(ts$lci)
  uci_num <- num(ts$uci)
  
  ci_bad <- !is_missing(ts$lci) &
    !is_missing(ts$uci) &
    !is.na(lci_num) &
    !is.na(estimate_num) &
    !is.na(uci_num) &
    estimate_num != -1 &
    (
      lci_num > estimate_num |
        estimate_num > uci_num
    )
  
  ci_rows <- which(ci_bad %in% TRUE)
  
  confidence_interval_issues <- data.frame(
    row = ci_rows,
    id = as.character(ts$id[ci_rows]),
    lci = as.character(ts$lci[ci_rows]),
    estimate = as.character(ts$estimate[ci_rows]),
    uci = as.character(ts$uci[ci_rows]),
    issue = rep(
      "Expected lci <= estimate <= uci",
      length(ci_rows)
    ),
    stringsAsFactors = FALSE
  )
  
  
  # ---------------------------------------------------------------------------
  # 10. Extract time-series codes used by the main abundance table
  # ---------------------------------------------------------------------------
  
  main_codes <- main_abundances_table %>%
    select(id, timeseries_code) %>%
    filter(
      !is.na(timeseries_code),
      trimws(timeseries_code) != ""
    ) %>%
    separate_rows(
      timeseries_code,
      sep = "\\+"
    ) %>%
    transmute(
      iwc_abundances_table_id = id,
      timeseries_code = trimws(as.character(timeseries_code))
    ) %>%
    filter(timeseries_code != "")
  
  
  # ---------------------------------------------------------------------------
  # 11. Check that all codes used in the abundance table exist
  #     in the time-series table
  # ---------------------------------------------------------------------------
  
  missing_codes_from_timeseries <- main_codes %>%
    filter(
      !timeseries_code %in% ts_code
    ) %>%
    distinct()
  
  
  # ---------------------------------------------------------------------------
  # 12. Check for time-series codes that are never used
  #     by an abundance record
  # ---------------------------------------------------------------------------
  
  orphan_timeseries_codes <- data.frame(
    timeseries_code = unique(
      ts_code[
        !is.na(ts_code) &
          ts_code != ""
      ]
    ),
    stringsAsFactors = FALSE
  ) %>%
    filter(
      !timeseries_code %in%
        unique(main_codes$timeseries_code)
    )
  
  
  # ---------------------------------------------------------------------------
  # 13. Junction-table ID checks
  # ---------------------------------------------------------------------------
  
  missing_junction_ids <- jt %>%
    mutate(row = row_number()) %>%
    filter(is_missing(id)) %>%
    transmute(
      row,
      id = as.character(id),
      issue = "Missing junction-table id"
    )
  
  
  duplicate_junction_ids <- jt %>%
    mutate(
      row = row_number(),
      id_chr = as.character(id)
    ) %>%
    filter(
      !is_missing(id),
      duplicated(id_chr) |
        duplicated(id_chr, fromLast = TRUE)
    ) %>%
    transmute(
      row,
      id = id_chr,
      issue = "Duplicate junction-table id"
    )
  
  
  # ---------------------------------------------------------------------------
  # 14. Junction-table foreign-key checks
  # ---------------------------------------------------------------------------
  
  invalid_abundance_ids <- jt %>%
    filter(
      !iwc_abundances_table_id %in%
        main_abundances_table$id
    ) %>%
    distinct(iwc_abundances_table_id)
  
  
  invalid_timeseries_ids <- jt %>%
    filter(
      !timeseries_id %in% ts$id
    ) %>%
    distinct(timeseries_id)
  
  
  # ---------------------------------------------------------------------------
  # 15. Duplicate abundance/time-series links
  # ---------------------------------------------------------------------------
  
  duplicate_links <- jt %>%
    count(
      iwc_abundances_table_id,
      timeseries_id,
      name = "n"
    ) %>%
    filter(n > 1)
  
  
  # ---------------------------------------------------------------------------
  # 16. Construct the links that SHOULD exist
  # ---------------------------------------------------------------------------
  
  ts_code_lookup <- ts %>%
    transmute(
      timeseries_id = id,
      timeseries_code = trimws(as.character(code))
    )
  
  
  expected_links <- main_codes %>%
    inner_join(
      ts_code_lookup,
      by = "timeseries_code",
      relationship = "many-to-many"
    ) %>%
    select(
      iwc_abundances_table_id,
      timeseries_id
    ) %>%
    distinct()
  
  
  actual_links <- jt %>%
    select(
      iwc_abundances_table_id,
      timeseries_id
    ) %>%
    distinct()
  
  
  # ---------------------------------------------------------------------------
  # 17. Missing expected links
  # ---------------------------------------------------------------------------
  
  missing_junction_links <- anti_join(
    expected_links,
    actual_links,
    by = c(
      "iwc_abundances_table_id",
      "timeseries_id"
    )
  )
  
  
  # ---------------------------------------------------------------------------
  # 18. Unexpected links
  # ---------------------------------------------------------------------------
  
  unexpected_junction_links <- anti_join(
    actual_links,
    expected_links,
    by = c(
      "iwc_abundances_table_id",
      "timeseries_id"
    )
  )
  
  
  # ---------------------------------------------------------------------------
  # 19. Time-series rows not linked to any abundance record
  # ---------------------------------------------------------------------------
  
  unlinked_timeseries_rows <- ts %>%
    filter(
      !id %in% jt$timeseries_id
    ) %>%
    select(
      id,
      code,
      year,
      estimate
    )
  
  
  # ---------------------------------------------------------------------------
  # 20. Overall result
  # ---------------------------------------------------------------------------
  
  passed <- all(
    nrow(missing_timeseries_ids) == 0,
    nrow(duplicate_timeseries_ids) == 0,
    nrow(missing_timeseries_codes) == 0,
    nrow(invalid_id_pattern) == 0,
    nrow(invalid_id_code) == 0,
    nrow(estimate_issues) == 0,
    nrow(positive_value_issues) == 0,
    nrow(year_issues) == 0,
    nrow(cv_issues) == 0,
    nrow(confidence_interval_issues) == 0,
    nrow(missing_codes_from_timeseries) == 0,
    nrow(orphan_timeseries_codes) == 0,
    nrow(missing_junction_ids) == 0,
    nrow(duplicate_junction_ids) == 0,
    nrow(invalid_abundance_ids) == 0,
    nrow(invalid_timeseries_ids) == 0,
    nrow(duplicate_links) == 0,
    nrow(missing_junction_links) == 0,
    nrow(unexpected_junction_links) == 0,
    nrow(unlinked_timeseries_rows) == 0
  )
  
  
  # ---------------------------------------------------------------------------
  # 21. Return results
  # ---------------------------------------------------------------------------
  
  list(
    passed = passed,
    
    missing_timeseries_ids = missing_timeseries_ids,
    duplicate_timeseries_ids = duplicate_timeseries_ids,
    missing_timeseries_codes = missing_timeseries_codes,
    
    invalid_id_pattern = invalid_id_pattern,
    invalid_id_code = invalid_id_code,
    
    estimate_issues = estimate_issues,
    positive_value_issues = positive_value_issues,
    year_issues = year_issues,
    cv_issues = cv_issues,
    confidence_interval_issues = confidence_interval_issues,
    
    missing_codes_from_timeseries = missing_codes_from_timeseries,
    orphan_timeseries_codes = orphan_timeseries_codes,
    
    missing_junction_ids = missing_junction_ids,
    duplicate_junction_ids = duplicate_junction_ids,
    invalid_abundance_ids = invalid_abundance_ids,
    invalid_timeseries_ids = invalid_timeseries_ids,
    duplicate_links = duplicate_links,
    
    missing_junction_links = missing_junction_links,
    unexpected_junction_links = unexpected_junction_links,
    
    unlinked_timeseries_rows = unlinked_timeseries_rows
  )
}