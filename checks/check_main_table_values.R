#### Check IDs and record-level numeric/date values ####

library(dplyr)

# Check record IDs and selected value ranges in the consolidated abundance table.
#
# Rules:
#   id:
#     - cannot be missing
#     - must be unique
#     - must follow: large area-species-4 digit number
#       e.g. NA-Fin-0001
#     - large-area and species components must agree with regions_code
#       and species_code in the same record
#
#   estimate:
#     - cannot be missing
#     - must be -1 or a positive number
#
#   se, lci, uci, pl, pu:
#     - may be missing
#     - when present, must be positive numbers
#
#   year, startyear, endyear:
#     - when present, must be integer years from min_year to the current year
#     - each record must contain either year, or both startyear and endyear
#     - when both startyear and endyear are present, startyear <= endyear
#
#   confidence / percentile limits:
#     - when lci and uci are both present: lci <= estimate <= uci
#     - when pl and pu are both present: pl <= pu
#
#   cv:
#     - may be missing
#     - when present, must be between 0 and 1 inclusive
#
#   dateadded, datemodified:
#     - must be stored as Date columns
#
# The check does NOT require sequential ID numbers. Gaps are allowed because
# an ID should never be reassigned after a record is removed or retired.

check_main_table_values <- function(data,
                                    min_year = 1960,
                                    max_year = as.integer(format(Sys.Date(), "%Y")),
                                    id_pattern = "^(NP|NA|SO|SA|IO|SEP|SP|SH)-[A-Za-z0-9]+-[0-9]{4}$") {
  required_columns <- c(
    "id", "regions_code", "species_code",
    "year", "startyear", "endyear",
    "estimate", "cv", "se", "lci", "uci", "pl", "pu",
    "dateadded", "datemodified"
  )

  missing_columns <- setdiff(required_columns, names(data))

  if (length(missing_columns) > 0) {
    stop(
      "Required columns not found in main table: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  row_id <- seq_len(nrow(data))
  id_value <- trimws(as.character(data$id))

  # ---------------------------------------------------------------------------
  # 1. ID checks
  # ---------------------------------------------------------------------------

  missing_ids <- data.frame(
    row = row_id,
    id = id_value,
    stringsAsFactors = FALSE
  ) %>%
    filter(is.na(id) | id == "") %>%
    mutate(issue = "Missing id")

  duplicate_ids <- data.frame(
    row = row_id,
    id = id_value,
    stringsAsFactors = FALSE
  ) %>%
    filter(
      !is.na(id),
      id != "",
      duplicated(id) | duplicated(id, fromLast = TRUE)
    ) %>%
    arrange(id, row) %>%
    mutate(issue = "Duplicate id")

  invalid_id_pattern <- data.frame(
    row = row_id,
    id = id_value,
    stringsAsFactors = FALSE
  ) %>%
    filter(
      !is.na(id),
      id != "",
      !grepl(id_pattern, id)
    ) %>%
    mutate(
      issue = "ID must follow large area-species-4 digit number (e.g. NA-Fin-0001)"
    )

  region_value <- trimws(as.character(data$regions_code))
  species_value <- trimws(as.character(data$species_code))

  expected_prefix <- ifelse(
    is.na(region_value) | region_value == "" |
      is.na(species_value) | species_value == "",
    NA_character_,
    paste0(region_value, "-", species_value, "-")
  )

  id_component_mismatches <- data.frame(
    row = row_id,
    id = id_value,
    regions_code = region_value,
    species_code = species_value,
    expected_prefix = expected_prefix,
    stringsAsFactors = FALSE
  ) %>%
    filter(
      !is.na(id),
      id != "",
      grepl(id_pattern, id),
      !is.na(expected_prefix),
      !startsWith(id, expected_prefix)
    ) %>%
    mutate(
      issue = "ID large-area/species components do not match regions_code/species_code"
    )

  # ---------------------------------------------------------------------------
  # Helper for numeric checks
  # ---------------------------------------------------------------------------

  numeric_values <- function(x) {
    if (is.numeric(x)) {
      return(as.numeric(x))
    }

    suppressWarnings(as.numeric(as.character(x)))
  }

  original_missing <- function(x) {
    is.na(x) | trimws(as.character(x)) == ""
  }

  make_value_issues <- function(column, invalid, issue_text) {

    invalid_rows <- which(invalid %in% TRUE)

    if (length(invalid_rows) == 0) {
      return(data.frame(
        row = integer(),
        id = character(),
        column = character(),
        value = character(),
        issue = character(),
        stringsAsFactors = FALSE
      ))
    }

    data.frame(
      row = row_id[invalid_rows],
      id = id_value[invalid_rows],
      column = rep(column, length(invalid_rows)),
      value = as.character(data[[column]][invalid_rows]),
      issue = rep(issue_text, length(invalid_rows)),
      stringsAsFactors = FALSE
    )
  }

  # ---------------------------------------------------------------------------
  # 2. Estimate: required; -1 or >= 0
  # ---------------------------------------------------------------------------

  estimate_num <- numeric_values(data$estimate)
  estimate_missing <- original_missing(data$estimate)

  invalid_estimate <- estimate_missing |
    is.na(estimate_num) |
    !is.finite(estimate_num) |
    !(estimate_num == -1 | estimate_num >= 0)

  estimate_issues <- make_value_issues(
    "estimate",
    invalid_estimate,
    "Estimate must be present and must be -1 or a positive number"
  )

  # ---------------------------------------------------------------------------
  # 3. Positive numeric fields: optional, but >= 0 when present
  # ---------------------------------------------------------------------------

  positive_columns <- c("se", "lci", "uci", "pl", "pu")

  positive_value_issues <- lapply(positive_columns, function(column) {

    x <- data[[column]]
    x_num <- numeric_values(x)
    missing <- original_missing(x)

    invalid <- !missing & (
      is.na(x_num) |
        !is.finite(x_num) |
        x_num < 0
    )

    make_value_issues(
      column,
      invalid,
      "Value must be a positive number when present"
    )
  })

  positive_value_issues <- bind_rows(positive_value_issues)

  # ---------------------------------------------------------------------------
  # 4. Years: optional integer values from min_year to max_year
  # ---------------------------------------------------------------------------

  year_columns <- c("year", "startyear", "endyear")

  year_issues <- lapply(year_columns, function(column) {

    x <- data[[column]]
    x_num <- numeric_values(x)
    missing <- original_missing(x)

    invalid <- !missing & (
      is.na(x_num) |
        !is.finite(x_num) |
        x_num != floor(x_num) |
        x_num < min_year |
        x_num > max_year
    )

    make_value_issues(
      column,
      invalid,
      paste0(
        "Year must be an integer from ",
        min_year,
        " to ",
        max_year,
        " when present"
      )
    )
  })

  year_issues <- bind_rows(year_issues)

  # ---------------------------------------------------------------------------
  # 5. Logical consistency checks
  # ---------------------------------------------------------------------------

  # Each record must contain either a reference year, or both start/end years.
  year_num <- numeric_values(data$year)
  startyear_num <- numeric_values(data$startyear)
  endyear_num <- numeric_values(data$endyear)

  year_missing <- original_missing(data$year)
  startyear_missing <- original_missing(data$startyear)
  endyear_missing <- original_missing(data$endyear)

  invalid_year_presence <- year_missing & (startyear_missing | endyear_missing)

  invalid_year_presence_rows <- which(invalid_year_presence %in% TRUE)

  year_presence_issues <- data.frame(
    row = row_id[invalid_year_presence_rows],
    id = id_value[invalid_year_presence_rows],
    year = as.character(data$year[invalid_year_presence_rows]),
    startyear = as.character(data$startyear[invalid_year_presence_rows]),
    endyear = as.character(data$endyear[invalid_year_presence_rows]),
    issue = rep(
      "Record must contain either year, or both startyear and endyear",
      length(invalid_year_presence_rows)
    ),
    stringsAsFactors = FALSE
  )

  # When both startyear and endyear are present, startyear must not exceed endyear.
  invalid_year_order <- !startyear_missing & !endyear_missing & (
    !is.na(startyear_num) &
      !is.na(endyear_num) &
      startyear_num > endyear_num
  )

  invalid_year_order_rows <- which(invalid_year_order %in% TRUE)

  year_order_issues <- data.frame(
    row = row_id[invalid_year_order_rows],
    id = id_value[invalid_year_order_rows],
    startyear = as.character(data$startyear[invalid_year_order_rows]),
    endyear = as.character(data$endyear[invalid_year_order_rows]),
    issue = rep(
      "startyear must be less than or equal to endyear",
      length(invalid_year_order_rows)
    ),
    stringsAsFactors = FALSE
  )

  # Confidence interval consistency: check only when both limits are present.
  lci_num <- numeric_values(data$lci)
  uci_num <- numeric_values(data$uci)

  lci_missing <- original_missing(data$lci)
  uci_missing <- original_missing(data$uci)

  invalid_ci_order <- !lci_missing & !uci_missing & (
    !is.na(lci_num) &
      !is.na(uci_num) &
      !is.na(estimate_num) &
      (lci_num > estimate_num | estimate_num > uci_num)
  )

  invalid_ci_order_rows <- which(invalid_ci_order %in% TRUE)

  confidence_interval_issues <- data.frame(
    row = row_id[invalid_ci_order_rows],
    id = id_value[invalid_ci_order_rows],
    lci = as.character(data$lci[invalid_ci_order_rows]),
    estimate = as.character(data$estimate[invalid_ci_order_rows]),
    uci = as.character(data$uci[invalid_ci_order_rows]),
    issue = rep(
      "Expected lci <= estimate <= uci",
      length(invalid_ci_order_rows)
    ),
    stringsAsFactors = FALSE
  )

  # Percentile/range consistency: check only when both limits are present.
  pl_num <- numeric_values(data$pl)
  pu_num <- numeric_values(data$pu)

  pl_missing <- original_missing(data$pl)
  pu_missing <- original_missing(data$pu)

  invalid_pl_pu_order <- !pl_missing & !pu_missing & (
    !is.na(pl_num) &
      !is.na(pu_num) &
      pl_num > pu_num
  )

  invalid_pl_pu_order_rows <- which(invalid_pl_pu_order %in% TRUE)

  percentile_limit_issues <- data.frame(
    row = row_id[invalid_pl_pu_order_rows],
    id = id_value[invalid_pl_pu_order_rows],
    pl = as.character(data$pl[invalid_pl_pu_order_rows]),
    pu = as.character(data$pu[invalid_pl_pu_order_rows]),
    issue = rep(
      "Expected pl <= pu",
      length(invalid_pl_pu_order_rows)
    ),
    stringsAsFactors = FALSE
  )

  # ---------------------------------------------------------------------------
  # 6. CV: optional numeric value from 0 to 1 inclusive
  # higher values are allowed but it is preferable to double check
  # ---------------------------------------------------------------------------

  cv_num <- numeric_values(data$cv)
  cv_missing <- original_missing(data$cv)

  invalid_cv <- !cv_missing & (
    is.na(cv_num) |
      !is.finite(cv_num) |
      cv_num < 0 |
      cv_num > 2
  )

  cv_issues <- make_value_issues(
    "cv",
    invalid_cv,
    "CV must be between 0 and 1 inclusive when present"
  )

  # ---------------------------------------------------------------------------
  # 7. Date columns must have Date class
  # ---------------------------------------------------------------------------

  date_columns <- c("dateadded", "datemodified")

  date_type_issues <- lapply(date_columns, function(column) {

    if (inherits(data[[column]], "Date")) {
      return(NULL)
    }

    data.frame(
      column = column,
      expected_type = "Date",
      actual_type = paste(class(data[[column]]), collapse = "/"),
      issue = "Column is not stored in Date format",
      stringsAsFactors = FALSE
    )
  })

  date_type_issues <- Filter(Negate(is.null), date_type_issues)

  if (length(date_type_issues) == 0) {
    date_type_issues <- data.frame(
      column = character(),
      expected_type = character(),
      actual_type = character(),
      issue = character(),
      stringsAsFactors = FALSE
    )
  } else {
    date_type_issues <- bind_rows(date_type_issues)
  }

  # ---------------------------------------------------------------------------
  # Return all results
  # ---------------------------------------------------------------------------

  passed <- (
    nrow(missing_ids) == 0 &&
      nrow(duplicate_ids) == 0 &&
      nrow(invalid_id_pattern) == 0 &&
      nrow(id_component_mismatches) == 0 &&
      nrow(estimate_issues) == 0 &&
      nrow(positive_value_issues) == 0 &&
      nrow(year_issues) == 0 &&
      nrow(year_presence_issues) == 0 &&
      nrow(year_order_issues) == 0 &&
      nrow(confidence_interval_issues) == 0 &&
      nrow(percentile_limit_issues) == 0 &&
      nrow(cv_issues) == 0 &&
      nrow(date_type_issues) == 0
  )

  list(
    passed = passed,
    missing_ids = missing_ids,
    duplicate_ids = duplicate_ids,
    invalid_id_pattern = invalid_id_pattern,
    id_component_mismatches = id_component_mismatches,
    estimate_issues = estimate_issues,
    positive_value_issues = positive_value_issues,
    year_issues = year_issues,
    year_presence_issues = year_presence_issues,
    year_order_issues = year_order_issues,
    confidence_interval_issues = confidence_interval_issues,
    percentile_limit_issues = percentile_limit_issues,
    cv_issues = cv_issues,
    date_type_issues = date_type_issues
  )
}
