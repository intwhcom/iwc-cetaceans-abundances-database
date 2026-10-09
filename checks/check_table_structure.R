#### Check main table column names and types ####

# Expected structure of the consolidated main abundance table.
# Keep this in sync with the schema used in tables/scripts/build_main_table.R.

expected_main_columns <- c(
  "id", "year", "startyear", "endyear", "estimate", "cv", "se", "cvav",
  "lci", "uci", "notes", "pl", "pu", "season", "gnull", "areacoverage",
  "sd", "cvcalc", "dateadded", "datemodified", "regions_code",
  "references_ref", "species_code", "category_code", "evaluation_extent",
  "subareas_subarea", "timeseries_code", "trials_usage", "method_code",
  "correction_code", "survey_programme"
)

expected_main_types <- list(
  id = "character",
  year = "numeric",
  startyear = "numeric",
  endyear = "numeric",
  estimate = "numeric",
  cv = "numeric",
  se = "numeric",
  cvav = "numeric",
  lci = "numeric",
  uci = "numeric",
  notes = "character",
  pl = "numeric",
  pu = "numeric",
  season = "character",
  gnull = "numeric",
  areacoverage = "character",
  sd = "numeric",
  cvcalc = "numeric",
  dateadded = "date",
  datemodified = "date",
  regions_code = "character",
  references_ref = "character",
  species_code = "character",
  category_code = "character",
  evaluation_extent = "character",
  subareas_subarea = "character",
  timeseries_code = "character",
  trials_usage = "character",
  method_code = "character",
  correction_code = "character",
  survey_programme = "character"
)

matches_expected_type <- function(x, expected_type) {
  if (expected_type == "character") return(is.character(x))
  if (expected_type == "numeric") return(is.numeric(x))
  if (expected_type == "date") return(inherits(x, "Date"))
  FALSE
}

check_table_structure <- function(data,
                                  required_columns = expected_main_columns,
                                  col_types = expected_main_types) {

  missing_columns <- setdiff(required_columns, names(data))
  extra_columns <- setdiff(names(data), required_columns)

  column_order_matches <- identical(names(data), required_columns)

  common_columns <- intersect(required_columns, names(data))

  type_issues <- lapply(common_columns, function(column) {
    expected <- col_types[[column]]

    if (is.null(expected)) {
      return(data.frame(
        column = column,
        expected_type = NA_character_,
        actual_type = paste(class(data[[column]]), collapse = "/"),
        issue = "No expected type defined",
        stringsAsFactors = FALSE
      ))
    }

    if (!matches_expected_type(data[[column]], expected)) {
      return(data.frame(
        column = column,
        expected_type = expected,
        actual_type = paste(class(data[[column]]), collapse = "/"),
        issue = "Type mismatch",
        stringsAsFactors = FALSE
      ))
    }

    NULL
  })

  type_issues <- Filter(Negate(is.null), type_issues)

  if (length(type_issues) == 0) {
    type_issues <- data.frame(
      column = character(),
      expected_type = character(),
      actual_type = character(),
      issue = character()
    )
  } else {
    type_issues <- do.call(rbind, type_issues)
  }

  list(
    passed = (
      length(missing_columns) == 0 &&
      length(extra_columns) == 0 &&
      column_order_matches &&
      nrow(type_issues) == 0
    ),
    missing_columns = missing_columns,
    extra_columns = extra_columns,
    column_order_matches = column_order_matches,
    type_issues = type_issues
  )
}
