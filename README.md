# IWC Cetacean Abundance Estimates Database

This repository contains the code, data-processing workflow, validation checks, spatial data, database schema and data-viewer application used to develop and maintain the **International Whaling Commission (IWC) cetacean abundance estimates database**.

The database brings together abundance estimates discussed and reviewed by the IWC Scientific Committee, together with associated information on species, regions, survey programmes, analytical methods, corrections, references, time series and spatial subareas.

Historically, these data have been maintained in Excel workbooks, CSV files and other flat-file formats. This repository supports their consolidation into a structured **PostgreSQL/PostGIS database**, while retaining the source material and the processing steps needed for provenance, validation and reproducibility.

## Purpose

The repository supports a transparent workflow for:

- collating and standardising abundance-estimate records;
- maintaining stable identifiers for abundance estimates and time-series records;
- validating table structure, values and relationships;
- linking estimates to literature references, reference tables and spatial subareas;
- producing final quality-controlled tables;
- building the relational PostgreSQL/PostGIS database; and
- viewing and exploring the abundance data through an interactive application.

The database preserves the abundance estimates and associated metadata as recorded and reviewed by the IWC. It is not intended to recalculate or reinterpret the underlying abundance estimates.

## Repository structure

The repository contains six main folders:

```text
.
├── checks/
├── legacy/
├── postgrSQLDB/
├── subareas/
├── tables/
└── view-abundances-whales/
```

### `checks/`

Contains the validation scripts used to check the final database tables before release and before construction of the PostgreSQL/PostGIS database.

Checks include table structure, reference-table values, literature references, spatial subareas, abundance values, identifiers and time-series relationships.

### `legacy/`

Contains legacy source material retained for provenance and reproducibility.

These files are used during data preparation and historical reconstruction, but they are **not** the authoritative inputs to the final PostgreSQL/PostGIS build.

### `postgrSQLDB/`

Contains the files used to create the PostgreSQL/PostGIS database from the final quality-controlled outputs.

This includes:

- the SQL schema;
- the main R database-build script;
- functions for creating junction and relational tables;
- the entity-relationship diagram; and
- detailed database-model documentation.

See [`postgrSQLDB/README.md`](postgrSQLDB/README.md) for the database structure and build instructions.

### `subareas/`

Contains the final spatial subarea layer used by the database.

The PostgreSQL/PostGIS model separates logical subarea identities from their individual polygon geometries. This allows one logical subarea to be represented by several separate polygons where necessary.

### `tables/`

Contains the scripts used to prepare the database tables and the final quality-controlled tabular outputs.

The final outputs used by the PostgreSQL/PostGIS build are stored under:

```text
tables/outputs/
```

and include:

```text
main_abundances_table.csv
literature_references.csv
timeseries.csv
timeseries1.csv
reference_tables/
```

### `view-abundances-whales/`

Contains the application used to **display and explore the abundance-estimate data**.

The app provides an interactive interface to the database outputs so that users can view and explore the information without working directly with the underlying tables or PostgreSQL database.

## Repository workflow

The workflow separates data preparation and validation from database construction and data presentation.

```text
Legacy source data
      |
      v
Data preparation and standardisation
      |
      v
Validation checks
      |
      v
Final quality-controlled tables
tables/outputs/
      |
      +----------------------------+
      |                            |
      v                            v
PostgreSQL/PostGIS database     Data-viewer app
postgrSQLDB/                  view-abundances-whales/
      |
      v
Structured relational and
spatial database
```

The PostgreSQL/PostGIS database is therefore built from the **final quality-controlled outputs**, rather than directly from the legacy Excel workbooks.

## Final tabular outputs

The principal final tabular outputs are stored in `tables/outputs/`.

### Main abundance table

`main_abundances_table.csv`

Contains the consolidated abundance-estimate records and associated metadata.

Each abundance record has a stable identifier, for example:

```text
NA-Fin-0001
NP-Gray-0034
```

These identifiers are intended to remain stable across releases.

### Literature references

`literature_references.csv`

Contains the bibliographic references associated with abundance estimates, including the identifiers used to construct relationships between abundance records, species and regions.

### Time-series tables

`timeseries.csv`

Contains individual estimates belonging to documented time series.

Time-series records use permanent character identifiers, for example:

```text
TS-NPHBK01-000023
```

`timeseries1.csv`

Links abundance records in the main table to individual records in `timeseries.csv`.

### Reference tables

`tables/outputs/reference_tables/`

Contains the controlled lookup tables used by the relational database:

- `category`
- `correction`
- `evaluation`
- `method`
- `regions`
- `species`
- `survey`
- `trials`

## Quality-control checks

The `checks/` directory contains the scripts used to validate the final outputs.

The checks cover, among other things:

- expected table structure and column names;
- values against reference tables;
- literature-reference consistency;
- spatial subarea consistency;
- uniqueness and format of permanent identifiers;
- valid abundance values and uncertainty fields;
- valid year and date fields;
- logical relationships among estimates and confidence intervals; and
- consistency of time-series records and their links to the main abundance table.

The final tables should only be saved and used for the PostgreSQL/PostGIS build after the required checks pass.

## Spatial subareas

Spatial definitions associated with abundance estimates are stored in `subareas/`.

The spatial subareas are constructed and maintained in a separate GitHub repository:

- **Subareas repository:** https://github.com/intwhcom/iwc-cetaceans-abundances-subareas

That repository contains the code and source spatial data used to create the final subarea layer used here.

The database separates a **logical subarea** from its individual polygon geometries:

```text
iwc_abundances_table
        |
        | subareas_id
        v
     subareas
       /   \
      /     \
subareas_survey   subareas_geometry
      |                  |
    survey         individual polygons
```

This allows one logical subarea to have more than one polygon feature without forcing separate features into a single `MULTIPOLYGON`.

Separate polygons are deliberately retained where appropriate, including spatial definitions represented on opposite sides of the 180-degree meridian.

## PostgreSQL/PostGIS database

The `postgrSQLDB/` folder contains the final database-construction stage.

The central PostgreSQL table is `iwc_abundances_table`.

It links directly to single-value lookup tables such as:

- `regions`
- `species`
- `category`
- `evaluation`
- `subareas`

Relationships that may contain multiple values are normalised through junction tables, including:

- `correction1`
- `method1`
- `references1`
- `survey1`
- `trials1`
- `timeseries1`

Additional relational tables link literature references to regions and species, and logical subareas to survey programmes and polygon geometries.

For the full schema, field definitions and database-build instructions, see:

[`postgrSQLDB/README.md`](postgrSQLDB/README.md)

## Interactive data viewer

The `view-abundances-whales/` folder contains the application used to display the abundance data interactively.

The app is part of the dissemination layer of the project: it provides a user-facing way to inspect and explore the compiled abundance estimates while the underlying tables and PostgreSQL/PostGIS database provide the structured data model.

The application will be deployed as an **R Shiny web application**.

- **Web application:** _[R Shiny deployment URL to be added]_

Technical instructions for running or deploying the application should be documented within the `view-abundances-whales/` folder.

## Contributors and scientific use

The database has developed over many years through both the ongoing compilation of abundance estimates and subsequent restructuring, validation and database development.

- **Cherry Allison** compiled and maintained the original abundance-estimate database.
- **Isidora Katara (IWC Secretariat)**, her successor, has maintained and updated the database over the past five years and led its restructuring, validation, spatial development and migration to GitHub/PostgreSQL.

The abundance estimates themselves are discussed through the IWC Scientific Committee process. The **SAS (formerly ASI) Sub-Committee** reviews and discusses abundance estimates, and the resulting abundance tables are used by Scientific Committee sub-committees in their assessment and management work.

This repository supports the ongoing maintenance, organisation, validation, documentation and dissemination of the abundance information used in the IWC Scientific Committee process; it does not replace the scientific review of the estimates by the relevant Scientific Committee bodies.

## Data provenance

The repository distinguishes between:

- **legacy source material**, retained under `legacy/`;
- **processing and validation code**, under `tables/` and `checks/`;
- **final quality-controlled tables**, under `tables/outputs/`;
- **spatial data**, under `subareas/`;
- **database construction and documentation**, under `postgrSQLDB/`; and
- **data visualisation and exploration**, under `view-abundances-whales/`.

This separation helps preserve provenance and reduces the risk that database construction or visualisation changes the scientific content of the underlying abundance records.

## GitHub and archived releases

This GitHub repository is the **development and reproducibility repository**. It contains the scripts, validation checks, documentation, spatial workflow and application needed to understand and reproduce the database.

Versioned archival releases of the database should be deposited in **Zenodo** and used as the citable, persistent data releases.

- **Zenodo release:** _[Zenodo DOI / release URL to be added]_

The two platforms therefore serve different purposes:

- **GitHub** — development, code, validation, documentation and application;
- **Zenodo** — archived, versioned and citable database releases.

## Documentation

For the PostgreSQL/PostGIS database structure and build process, see:

- [`postgrSQLDB/README.md`](postgrSQLDB/README.md)
- `postgrSQLDB/iwc_abundances_table-data_model.docx`
- `postgrSQLDB/iwc_abundances_table_create.sql`
- `postgrSQLDB/iwc_abundances_table.png`

For the final tabular data, see `tables/outputs/`.

For the interactive data viewer, see `view-abundances-whales/`.

External resources:

- **Subareas construction repository:** https://github.com/intwhcom/iwc-cetaceans-abundances-subareas
- **Zenodo release:** _[Zenodo DOI / release URL to be added]_
- **R Shiny web application:** _[R Shiny deployment URL to be added]_
