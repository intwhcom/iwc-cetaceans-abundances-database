# Database checks

This folder contains the R scripts used to validate the intermediate tabular and spatial components of the IWC cetacean abundance database.

The checks are run **after the intermediate tables have been assembled**. They identify structural inconsistencies, invalid coded values, unresolved literature references and abundance records without a matching spatial subarea record. These checks form part of the quality-assurance workflow; the intermediate objects should not be treated as final release-ready data until the checks and any subsequent QA steps have been completed.

## Required objects

Run the scripts from the repository root:

`iwc-cetaceans-abundances-database/`

The following R objects should already exist:

- `main_abundances_table` — consolidated abundance table;
- `literature_references` — consolidated literature/reference table;
- `reference_tables` — named list containing the database reference tables.

These are created by the scripts in `tables/scripts/`.

The spatial check also requires a **single consolidated shapefile** containing the subareas used by the abundance records across all regions.

For example:

```r
shapefile_path <- "subareas/subareas.shp"
```

Adjust the path to match the repository structure.

## Scripts

### `check_table_structure.R`

Checks `main_abundances_table` against the expected schema.

It reports:

- missing required columns;
- unexpected additional columns;
- differences in column order;
- columns with unexpected data types.

**Input:** `main_abundances_table`

**Output:** a list containing the overall pass/fail result and details of any structural issues.

### `check_values_against_reference_tables.R`

Checks coded fields in `main_abundances_table` against the corresponding lookup tables in `reference_tables`.

The standard checks cover:

- region;
- species;
- abundance category;
- evaluation extent;
- trials usage;
- method;
- correction;
- survey programme.

Values separated by `+` are expanded before comparison.

**Inputs:** `main_abundances_table`, `reference_tables`

**Output:** a named list of unmatched values. An empty result for a field means that no unmatched values were found.

### `check_literature_references.R`

Performs two literature-reference checks:

- `check_reference_ids()` verifies that every reference used in the main abundance table exists in `literature_references`;
- `check_reference_combinations()` verifies the region + species + reference combinations.

Multiple references in the abundance table are assumed to be separated by `;`. Multiple regions or species in the literature-reference table may be separated by `+`.

**Inputs:** `main_abundances_table`, `literature_references`

**Outputs:** data frames of unresolved references or unresolved combinations. Zero rows means that no problem was found.

### `check_subareas.R`

Checks that every unique combination of:

- subarea;
- survey programme;
- species

used by an abundance record is present in the consolidated spatial subareas shapefile.

The spatial layer is expected to contain the fields:

- `subareas`;
- `survey`;
- `species`.

**Inputs:** `main_abundances_table`, `shapefile_path`

**Output:** a data frame of combinations without a matching spatial record. Zero rows means that all checked combinations matched.

By default, the check does not write a CSV. If the function is run with `writecsv = TRUE`, the unmatched combinations can be written to file.

### `run_table_checks.R`

Sources the individual checking functions and runs all checks together.

This is the main script to use once the intermediate tables have been created.

## Running the checks

First create the intermediate tables:

```r
source("tables/scripts/build_main_table.R")
source("tables/scripts/read_literature_refs.R")
source("tables/scripts/read_reference_tables.R")
source("tables/scripts/timeseries_tables.R")
```

Define the spatial input:

```r
shapefile_path <- "spatial/subareas.shp"
```

Then run:

```r
source("checks/run_table_checks.R")

check_results <- run_table_checks(
  main_abundances_table = main_abundances_table,
  literature_references = literature_references,
  reference_tables = reference_tables,
  timeseries_tables = timeseries_tables,
  shapefile_path = "subareas/subareas.shp"
)
```

## Inspecting the results

The returned `check_results` object contains:

```r
check_results$main_table_structure
check_results$reference_values
check_results$missing_reference_ids
check_results$reference_combination_issues
check_results$missing_subareanames
check_results$timeseries
```

For checks that return data frames, **zero rows means that no unmatched records were found**.

For the coded reference checks, individual results can be inspected, for example:

```r
check_results$reference_values$species
check_results$reference_values$method
check_results$reference_values$survey
```

## Notes

The checks report inconsistencies; they do not modify the underlying data.

Paths should remain relative to the repository root so that the workflow is portable across computers.

Use the exact filename `check_subareas.R` in both the repository and the `source()` statement, because file names are case-sensitive on some operating systems.
