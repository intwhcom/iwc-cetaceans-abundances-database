# Tables scripts

This folder contains the R scripts used to assemble, validate and export the tabular components of the IWC cetacean abundance database.

The objects produced by the table-building scripts are initially **intermediate outputs**. They should not be treated as final publication-ready tables until the full database validation and quality-assurance workflow has been completed successfully.

## Working directory and inputs

Run the scripts from the root of the repository:

`iwc-cetaceans-abundances-database/`

### Legacy inputs

The main abundance data are read from the three regional legacy workbooks:

- `legacy/data/abundances-NA.xlsx` — North Atlantic abundance tables
- `legacy/data/abundances-NP.xlsx` — North Pacific abundance tables
- `legacy/data/abundances-SH.xlsx` — Southern Hemisphere abundance tables

These workbooks contain species-specific abundance sheets as well as `references` and `timeseries` sheets.

### Current reference tables

The database reference/lookup tables are stored separately from the legacy workbooks:

- `tables/reference tables.xlsx`

These tables are part of the current database structure rather than the legacy abundance-table format.

## Table-building scripts

### `read_main_data_legacy_workbook.R`

Helper script used by `build_main_table.R`.

It reads the species sheets from a single legacy abundance workbook, excluding `references` and `timeseries`. It checks that the required columns are present, selects and orders those columns, applies the specified data types and combines the species sheets into one data frame.

**Input:** one regional legacy abundance workbook, plus the required column names, column types and excluded sheet names.

**Output:** one data frame containing the abundance records from that regional workbook.

This script normally does not need to be run directly.

### `build_main_table.R`

Builds the consolidated abundance table from the three regional legacy workbooks.

It sources `read_main_data_legacy_workbook.R`, reads the Southern Hemisphere, North Pacific and North Atlantic workbooks, standardises the selected columns and combines all abundance records into one table.

**Inputs:**

- `legacy/data/abundances-SH.xlsx`
- `legacy/data/abundances-NP.xlsx`
- `legacy/data/abundances-NA.xlsx`

**Output:** R object `main_abundances_table`.

The abundance-record IDs are permanent identifiers stored in the source data and should not be regenerated from row order.

### `read_literature_refs.R`

Reads the `references` sheet from each of the three regional legacy abundance workbooks and combines the selected reference fields.

**Inputs:** the three regional legacy abundance workbooks.

**Output:** R object `literature_references`.

### `read_reference_tables.R`

Reads every worksheet from the current reference-table workbook and returns them as a named list, retaining the worksheet names.

**Input:** `tables/reference tables.xlsx`.

**Output:** R object `reference_tables`, containing the individual reference tables as named list elements.

### `timeseries_tables.R`

Builds the time-series table and the junction table linking abundance records to time-series records.

It reads the `timeseries` sheet from each regional legacy abundance workbook, combines the records, identifies the time-series codes associated with records in `main_abundances_table`, checks that the referenced codes exist and creates the many-to-many link between abundance records and time-series records.

Time-series record IDs are permanent identifiers stored in the source workbooks and use the form:

```text
TS-<code>-000000
```

These IDs are preserved when the three regional time-series sheets are combined and should not be regenerated from row order. Numbering may reflect the regional legacy workbooks and is not required to be globally consecutive.

**Inputs:**

- the three regional legacy abundance workbooks;
- the previously created `main_abundances_table`.

**Output:** R object `timeseries_tables`, a list containing:

- `timeseries` — the combined time-series records;
- `junction_table` — links between abundance-table records and time-series records.

The junction-table row `id` is generated during table construction. The permanent foreign keys are the abundance-record ID and the time-series-record ID.

## Building the intermediate tables

From the repository root:

```r
source("tables/scripts/build_main_table.R")
source("tables/scripts/read_literature_refs.R")
source("tables/scripts/read_reference_tables.R")
source("tables/scripts/timeseries_tables.R")
```

This creates the main intermediate R objects:

- `main_abundances_table`
- `literature_references`
- `reference_tables`
- `timeseries_tables`

These objects must then be passed through the full validation and quality-assurance workflow before release files are written.

## Validation and quality assurance

The validation scripts are stored in `checks/`. The individual checks are coordinated by `checks/run_table_checks.R`.

### `check_table_structure.R`

Checks the structure of `main_abundances_table` against the expected database schema, including:

- required columns;
- unexpected columns;
- column order;
- expected R data types.

### `check_main_table_values.R`

Checks record-level values and logical consistency in `main_abundances_table`, including:

- missing or duplicate abundance-record IDs;
- abundance-record ID format and agreement with region and species codes;
- valid abundance estimates, including the permitted sentinel value `-1` and non-negative estimates;
- numeric validity of uncertainty and interval fields when present;
- valid year fields within the configured year range;
- presence of either `year`, or both `startyear` and `endyear`;
- `startyear <= endyear`;
- `lci <= estimate <= uci` when confidence limits are available and the estimate is a genuine estimate rather than the `-1` sentinel;
- `pl <= pu` when both limits are present;
- `cv` between 0 and 1 when present;
- date fields stored using the expected R date type.

### `check_values_against_reference_tables.R`

Checks coded fields in `main_abundances_table` against the current lookup/reference tables.

The standard checks cover:

- region;
- species;
- abundance category;
- evaluation extent;
- trials usage;
- method;
- correction;
- survey programme.

Values containing multiple codes are expanded before comparison.

### `check_literature_references.R`

Checks literature/reference relationships, including:

- every reference used in the abundance table exists in `literature_references`;
- region + species + reference combinations used by abundance records can be resolved against the literature-reference table.

### `check_subareas.R`

Checks that each unique abundance-record combination of:

- subarea;
- survey programme;
- species

is present in the consolidated spatial subareas shapefile.

The spatial layer is expected to contain the corresponding `subareas`, `survey` and `species` fields.

### `check_timeseries_tables.R`

Checks both the combined time-series table and the abundance/time-series junction table.

Time-series record checks include:

- required columns are present;
- time-series IDs are present and unique;
- time-series IDs follow the `TS-<code>-000000` format;
- the code embedded in each time-series ID agrees with the `code` field;
- time-series codes are present;
- estimates are present and are either `-1` or non-negative;
- `se`, `sd`, `lci` and `uci`, when present, contain valid non-negative numeric values;
- years are present, integer-valued and within the configured year range;
- `cv`, when present, lies between 0 and 1;
- `lci <= estimate <= uci` when both confidence limits are present and the estimate is not the `-1` sentinel.

Cross-table and junction-table checks include:

- every `timeseries_code` used in the main abundance table exists in the time-series table;
- time-series codes are not left completely unreferenced by abundance records;
- junction-table IDs are present and unique;
- abundance IDs in the junction table exist in `main_abundances_table`;
- time-series IDs in the junction table exist in the time-series table;
- duplicate abundance/time-series links are not present;
- all expected abundance/time-series links are present;
- unexpected abundance/time-series links are not present;
- time-series records are not left unlinked from the abundance table.

### `run_table_checks.R`

Sources the individual checking functions and runs the complete QA workflow.

After the intermediate tables have been created, run:

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

The returned `check_results` object contains the main groups of validation results, including:

```r
check_results$main_table_structure
check_results$main_table_values
check_results$timeseries
check_results$reference_values
check_results$missing_reference_ids
check_results$reference_combination_issues
check_results$missing_subareanames
```

The overall record-level checks can be inspected with:

```r
check_results$main_table_values$passed
check_results$timeseries$passed
```

For checks that return issue data frames, zero rows indicate that no problems were found.

The checks report inconsistencies but do not modify the underlying data.

## Final release tables

Final files should be written only after the complete QA workflow passes.

The final export script is:

```text
tables/scripts/save_final_tables.R
```

This script acts as a final QA gate. It should stop without writing release files if any of the following fail:

- main-table structure checks;
- main-table value and logical-consistency checks;
- time-series and junction-table checks;
- coded reference-table checks;
- literature-reference checks;
- region + species + reference combination checks;
- spatial subarea checks.

If all checks pass, the final CSV tables are written to:

```text
tables/final/
```

with the following structure:

```text
tables/
└── final/
    ├── main_abundances_table.csv
    ├── literature_references.csv
    ├── timeseries.csv
    ├── timeseries1.csv
    └── reference_tables/
        ├── regions.csv
        ├── species.csv
        ├── category.csv
        ├── evaluation.csv
        ├── trials.csv
        ├── method.csv
        ├── correction.csv
        └── survey.csv
```

`timeseries1.csv` is the junction table linking abundance records to time-series records. The name `timeseries1` is retained intentionally because this table is also used as an input to the PostgreSQL database workflow.

The reference-table filenames correspond to the worksheet names in `tables/reference tables.xlsx`; the exact set of files therefore follows the reference tables present in that workbook.

## Complete run order

A complete table build, validation and export workflow is:

```r
# 1. Build intermediate tables
source("tables/scripts/build_main_table.R")
source("tables/scripts/read_literature_refs.R")
source("tables/scripts/read_reference_tables.R")
source("tables/scripts/timeseries_tables.R")

# 2. Run all checks
source("checks/run_table_checks.R")

check_results <- run_table_checks(
  main_abundances_table = main_abundances_table,
  literature_references = literature_references,
  reference_tables = reference_tables,
  timeseries_tables = timeseries_tables,
  shapefile_path = "subareas/subareas.shp"
)

# 3. Write final release tables only if all checks pass
source("tables/scripts/save_final_tables.R")
```

## Intermediate versus final outputs

The table-building scripts create standardised R objects in memory. These remain intermediate database objects until all validation and consistency checks have passed.

The files in `tables/final/` are the release-ready tabular outputs produced after successful QA. They can then be used for publication, archival release and downstream database import, including the PostgreSQL workflow.

Paths should remain relative to the repository root so that the workflow is portable across computers.
