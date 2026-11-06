#### Save final release tables ####

# ---------------------------------------------------------------------------
# 1. Confirm that all checks passed
# ---------------------------------------------------------------------------

reference_values_ok <- all(
  vapply(
    check_results$reference_values,
    function(x) nrow(x) == 0,
    logical(1)
  )
)

all_checks_passed <- all(
  isTRUE(check_results$main_table_structure$passed),
  isTRUE(check_results$main_table_values$passed),
  isTRUE(check_results$timeseries$passed),
  reference_values_ok,
  nrow(check_results$missing_reference_ids) == 0,
  nrow(check_results$reference_combination_issues) == 0,
  nrow(check_results$missing_subareanames) == 0
)

if (!all_checks_passed) {
  stop("One or more database checks failed. Final tables were not written.")
}


# ---------------------------------------------------------------------------
# 2. Create output directory
# ---------------------------------------------------------------------------

output_dir <- "tables/outputs"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)


# ---------------------------------------------------------------------------
# 3. Save main tables
# ---------------------------------------------------------------------------

write.csv(
  main_abundances_table,
  file.path(output_dir, "main_abundances_table.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  literature_references,
  file.path(output_dir, "literature_references.csv"),
  row.names = FALSE,
  na = ""
)


# ---------------------------------------------------------------------------
# 4. Save time-series tables
# ---------------------------------------------------------------------------

write.csv(
  timeseries_tables$timeseries,
  file.path(output_dir, "timeseries.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  timeseries_tables$junction_table,
  file.path(output_dir, "timeseries1.csv"),
  row.names = FALSE,
  na = ""
)


# ---------------------------------------------------------------------------
# 5. Save reference tables
# ---------------------------------------------------------------------------

reference_dir <- file.path(output_dir, "reference_tables")

dir.create(
  reference_dir,
  showWarnings = FALSE
)

for (nm in names(reference_tables)) {
  
  write.csv(
    reference_tables[[nm]],
    file.path(reference_dir, paste0(nm, ".csv")),
    row.names = FALSE,
    na = ""
  )
}


# ---------------------------------------------------------------------------
# 6. Confirmation
# ---------------------------------------------------------------------------

message("All checks passed. Final release tables written to: ", output_dir)
