# IWC Cetacean Abundance Estimates Viewer

This folder contains the source code for the R Shiny application used to explore the **IWC Cetacean Abundance Estimates Geodataset**.

The application allows users to filter abundance estimates by species, large area, subarea and year, and to explore the associated tabular data, spatial subareas and literature references.

## Data used by the app

**The data files are not included in this application folder.** This avoids maintaining duplicate copies of the geodataset within the repository.

The app uses the consolidated, quality-controlled outputs held elsewhere in this repository:

- [`tables/outputs/main_abundances_table.csv`](https://github.com/intwhcom/iwc-cetaceans-abundances-database/tree/main/tables/outputs/main_abundances_table.csv) — consolidated abundance estimates and associated metadata.
- [`tables/outputs/literature_references.csv`](https://github.com/intwhcom/iwc-cetaceans-abundances-database/tree/main/tables/outputs/literature_references.csv) — literature references linked to the abundance records.
- `subareas.shp` (10.5281/zenodo.24002558) — spatial subareas used by the viewer. The associated shapefile components (`.dbf`, `.shx`, `.prj`, and `.cpg` where present) are held in the same zip file.

The full set of release tables, reference tables and time-series outputs is available under [`tables/outputs/`](https://github.com/intwhcom/iwc-cetaceans-abundances-database/tree/main/tables/outputs/).

> **Important:** `app.R` currently reads `main_abundances_table.csv`, `literature_references.csv` and `subareas.shp` from the application's working directory. For deployment, copies of these files and the required shapefile components must therefore be placed alongside `app.R`, or the file paths in the application must be changed accordingly. These deployment copies are not intended to be maintained as a second authoritative version of the data.

## Authoritative data release

The official, versioned release of the geodataset is available through Zenodo:

**DOI:** https://doi.org/10.5281/zenodo.24002558

Zenodo should be checked for the most recent release, as the deployed Shiny application may not be updated as frequently. The current deployed app contains data dated **6 November 2026**.

## Running the app

The application requires R and the following packages:

- `shiny`
- `shinyWidgets`
- `leaflet`
- `leaflet.extras`
- `sf`
- `DT`
- `dplyr`
- `tidyr`
- `stringr`

With the required data files available in the application's working directory, run:

```r
shiny::runApp()
```

## Availability

The public viewer is hosted using a free Shiny hosting service on https://isidorakatara.shinyapps.io/whales-abundances-view/. Availability is not guaranteed at all times. The Zenodo release remains the authoritative source for the data.

## Contact

Please report issues with the data or the application to:

**statistics@iwc.int**
