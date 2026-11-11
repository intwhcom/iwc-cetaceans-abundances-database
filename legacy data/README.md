# Legacy abundance data

This folder contains the **legacy Excel-based source files** from which the IWC cetacean abundance estimates dataset was historically maintained.
														 

These files are retained for **provenance, historical reference and reproducibility**. They are not the authoritative current release of the data and should not be used in place of the final quality-controlled outputs produced by the repository workflow.


## Legacy files

The legacy abundance data are organised in three regional Excel workbooks:

| File | Region |
|------|--------|
| `NA-abundances.xlsx` | North Atlantic |
| `NP-abundances.xlsx` | North Pacific |
| `SH-abundances.xlsx` | Southern Hemisphere |

## Workbook structure

The structure of the workbooks reflects the historical organisation of the abundance database.

### Species worksheets

- Most worksheets contain abundance information for individual species.
- Species with relatively few records may be grouped in an `Other` worksheet.
- Some small-cetacean records originating from earlier legacy material may appear in `SM` worksheets or in species-specific worksheets.

### Supporting worksheets

Depending on the workbook, additional worksheets may contain:

- full time series associated with particular abundance records;
- literature references and source documentation; and
- combined abundance calculations or other working material used in response to Scientific Committee requirements.

The exact structure varies among workbooks and reflects the historical development of the database.


## Relationship to the current dataset

The legacy workbooks are used as source material in the repository's data-preparation workflow. Records are standardised, checked and consolidated before being written to the final output tables.

The current quality-controlled outputs are stored under:

```text
tables/outputs/
```

These include, among others:

```text
main_abundances_table.csv
literature_references.csv
timeseries.csv
timeseries1.csv
reference_tables/
```

Users interested in the current dataset should use these final outputs or the corresponding versioned Zenodo release rather than the legacy Excel files.

## Important note

The presence of a value or record in a legacy workbook does not necessarily mean that it appears unchanged in the current release. During restructuring and quality control, records may have been standardised, linked to controlled reference tables, assigned permanent identifiers, corrected where necessary, or otherwise updated while preserving their provenance.

The legacy files should therefore be treated as **historical source material**, not as the current authoritative dataset.
