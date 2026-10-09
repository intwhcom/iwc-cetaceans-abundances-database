#### Run checks on the intermediate tabular database objects ####

source("checks/check_table_structure.R")
source("checks/check_values_against_reference_tables.R")
source("checks/check_literature_references.R")
source("checks/check_subareas.R")

run_table_checks <- function(main_abundances_table,
                             literature_references,
                             reference_tables,
                             shapefile_path) {

  structure_check <- check_table_structure(main_abundances_table)

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
    writecsv = FALSE)

  list(
    main_table_structure = structure_check,
    reference_values = reference_value_checks,
    missing_reference_ids = missing_reference_ids,
    reference_combination_issues = reference_combination_issues,
    missing_subareanames = missing_subareanames
  )
}


# Example usage, after the intermediate tables have been created:
#
# source("tables/scripts/build_main_table.R")
# source("tables/scripts/read_literature_refs.R")
# source("tables/scripts/read_reference_tables.R")
#
# check_results <- run_table_checks(
#   main_abundances_table = main_abundances_table,
#   literature_references = literature_references,
#   reference_tables = reference_tables
# )
#
# check_results$main_table_structure
# check_results$reference_values
# View(check_results$missing_reference_ids)
# View(check_results$reference_combination_issues)
# View(check_results$missing_subareanames)
