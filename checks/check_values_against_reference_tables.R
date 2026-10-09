#### Check coded values against reference tables ####

library(dplyr)
library(tidyr)

# Check one coded field in the main abundance table against one reference table.
#
# data          Main data frame to check.
# ref_table     Data frame containing valid reference values.
# column_main   Column in data to validate.
# column_ref    Column in ref_table containing valid codes.
# separator     Separator used when a main-table cell contains >1 code.
ref_values_check <- function(data,
                             ref_table,
                             column_main,
                             column_ref,
                             separator = "\\+") {

  if (!column_main %in% names(data)) {
    stop(paste("Column not found in main table:", column_main))
  }

  if (!column_ref %in% names(ref_table)) {
    stop(paste("Column not found in reference table:", column_ref))
  }

  main_values <- data %>%
    select(id, all_of(column_main)) %>%
    separate_rows(all_of(column_main), sep = separator) %>%
    transmute(
      id = id,
      value = trimws(as.character(.data[[column_main]]))
    ) %>%
    filter(!is.na(value), value != "")

  valid_values <- ref_table %>%
    transmute(value = trimws(as.character(.data[[column_ref]]))) %>%
    filter(!is.na(value), value != "") %>%
    distinct()

  anti_join(main_values, valid_values, by = "value") %>%
    distinct()
}


# Run all standard coded-column checks against the named list produced by
# tables/scripts/read_reference_tables.R.
check_reference_columns <- function(main_abundances_table, reference_tables) {

  mapping <- data.frame(
    check_name = c(
      "regions", "species", "category", "evaluation",
      "trials", "method", "correction", "survey"
    ),
    ref_table = c(
      "regions", "species", "category", "evaluation",
      "trials", "method", "correction", "survey"
    ),
    main_column = c(
      "regions_code", "species_code", "category_code", "evaluation_extent",
      "trials_usage", "method_code", "correction_code", "survey_programme"
    ),
    ref_column = c(
      "code", "code", "code", "extent",
      "usage", "code", "code", "programme"
    ),
    stringsAsFactors = FALSE
  )

  results <- vector("list", nrow(mapping))
  names(results) <- mapping$check_name

  for (i in seq_len(nrow(mapping))) {

    ref_name <- mapping$ref_table[i]

    if (!ref_name %in% names(reference_tables)) {
      stop(paste("Reference table not found in reference_tables:", ref_name))
    }

    results[[mapping$check_name[i]]] <- ref_values_check(
      data = main_abundances_table,
      ref_table = reference_tables[[ref_name]],
      column_main = mapping$main_column[i],
      column_ref = mapping$ref_column[i]
    )
  }

  results
}
