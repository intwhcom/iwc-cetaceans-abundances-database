#### Run checks on the intermediate tabular database objects ####

source("checks/check_table_structure.R")
source("checks/check_values_against_reference_tables.R")
source("checks/check_literature_references.R")
source("checks/check_subareas.R")
source("checks/check_main_table_values.R")
source("checks/check_timeseries_tables.R")

run_table_checks <- function(main_abundances_table,
                             literature_references,
                             reference_tables,
                             timeseries_tables,
                             shapefile_path) {

  structure_check <- check_table_structure(main_abundances_table)

  main_table_value_checks <- check_main_table_values(
    data = main_abundances_table
  )

  timeseries_checks <- check_timeseries_tables(
    main_abundances_table = main_abundances_table,
    timeseries_tables = timeseries_tables
  )

  reference_value_checks <- check_reference_columns(
    main_abundances_table = main_abundances_table,
    reference_tables = reference_tables
  )

  missing_reference_ids <- check_reference_ids(
    main_abundances_table = main_abundances_table,
    literature_references = literature_references
  )

  reference_combination_issues <- check_reference_combinations(
    main_abundances_table = main_abundances_table,
    literature_references = literature_references
  )

  missing_subareanames <- checksubareanames(
    originaldata = main_abundances_table,
    shapefile_path = shapefile_path,
    writecsv = FALSE
  )

  list(
    main_table_structure = structure_check,
    main_table_values = main_table_value_checks,
    timeseries = timeseries_checks,
    reference_values = reference_value_checks,
    missing_reference_ids = missing_reference_ids,
    reference_combination_issues = reference_combination_issues,
    missing_subareanames = missing_subareanames
  )
}
