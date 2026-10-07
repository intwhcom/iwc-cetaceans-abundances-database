# Tables scripts

This folder contains the R scripts used to assemble the tabular components of the IWC cetacean abundance database.

The objects produced by these scripts are **intermediate outputs**. They have not yet passed the full database validation and quality-assurance workflow and should not be treated as final publication-ready tables.

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

## Scripts

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

### `read_literature_refs.R`

Reads the `references` sheet from each of the three regional legacy abundance workbooks and combines the selected reference fields.

**Inputs:** the three regional legacy abundance workbooks.

**Output:** R object `literature_references`.

### `read_reference_tables.R`

Reads every worksheet from the current reference-table workbook and returns them as a named list, retaining the worksheet names.

**Input:** `tables/reference tables.xlsx`.

**Output:** R object `reference_tables`, containing the individual reference tables as named list elements.

### `timeseries_tables.R`

Builds the time-series table and the junction table linking abundance records to time series.

It reads the `timeseries` sheet from each regional legacy abundance workbook, combines the records, identifies the time-series codes associated with records in `main_abundances_table`, checks that the referenced codes exist and creates the many-to-many link between abundance records and time series.

**Inputs:**

- the three regional legacy abundance workbooks;
- the previously created `main_abundances_table`.

**Output:** R object `timeseries_tables`, a list containing:

- `timeseries` — the combined time-series records;
- `junction_table` — links between abundance-table records and time-series records.

## Suggested run order

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

These objects should subsequently be passed through the full validation and quality-assurance workflow before files are produced for release or publication.

## Note on intermediate outputs

These scripts assemble and standardise the source tables but do not constitute the complete quality-assurance workflow. The resulting objects should therefore be regarded as intermediate database tables until the subsequent validation and consistency checks have been completed.

The scripts currently create R objects in memory rather than writing final publication files to disk. Export of release-ready tables should take place only after the full checks have been completed.
