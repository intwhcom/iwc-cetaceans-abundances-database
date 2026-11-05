# Load required packages
library(RPostgres)  # PostgreSQL connection
library(DBI)        # Database interface
library(sf)         # Spatial data handling
library(tidyverse)

sf::sf_use_s2(FALSE)

# source functions
source("postgrSQLDB/junction tables.R")

# Database connection details
db_name <- "iwcabundances"
db_user <- "postgres"
db_password <- "postgres"
db_host <- "localhost"
db_port <- 5432

# Connect to PostgreSQL as an admin user to create the database
conn_admin <- dbConnect(
  Postgres(),
  dbname = "postgres",
  user = db_user,
  password = db_password,
  host = db_host,
  port = db_port
)

# Recreate database
dbExecute(conn_admin, paste0("DROP DATABASE IF EXISTS ", db_name))
dbExecute(conn_admin, paste0("CREATE DATABASE ", db_name))
dbDisconnect(conn_admin)

# Connect to the newly created database
conn <- dbConnect(
  Postgres(),
  dbname = db_name,
  user = db_user,
  password = db_password,
  host = db_host,
  port = db_port
)

# Enable PostGIS extension
dbExecute(conn, "CREATE EXTENSION IF NOT EXISTS postgis")

# Read and execute SQL schema
sql_file <- "postgrSQLDB/iwc_abundances_table_create.sql"
sql_text <- readLines(sql_file, warn = FALSE)

# Remove full-line and inline SQL comments
sql_text <- gsub("--.*", "", sql_text)
sql_text <- paste(sql_text, collapse = "\n")

# Split SQL statements by semicolon while retaining multi-line statements
sql_statements <- unlist(strsplit(sql_text, ";[[:space:]]*\n", perl = TRUE))

for (stmt in sql_statements) {
  stmt <- trimws(stmt)
  if (nchar(stmt) > 0) {
    dbExecute(conn, stmt)
  }
}


# ---------------------------------------------------------------------------
# Reference tables
# ---------------------------------------------------------------------------

reference_tables <- c(
  "category",
  "correction",
  "evaluation",
  "method",
  "regions",
  "species",
  "survey",
  "trials"
)

reftabs <- list()

for (j in reference_tables) {

  intable <- read.csv(
    file = paste0("tables/outputs/reference_tables/", j, ".csv"),
    stringsAsFactors = FALSE,
    na.strings = ""
  )

  # retain in R for creation/validation of junction tables
  reftabs[[j]] <- intable

  DBI::dbWriteTable(
    conn,
    j,
    intable,
    row.names = FALSE,
    append = TRUE
  )
}


# ---------------------------------------------------------------------------
# Spatial subareas
# ---------------------------------------------------------------------------

subareas <- sf::st_read(
  "subareas/subareas.shp",
  quiet = TRUE
)

if (sf::st_crs(subareas)$epsg != 4326) {
  subareas <- sf::st_transform(subareas, 4326)
}

# Standardise names while retaining every original polygon feature.
# Separate polygon features are deliberately retained, including features on
# opposite sides of longitude 180.
subareas_source <- subareas %>%
  select(
    subareas,
    accuracy,
    source,
    geometry,
    species,
    large_area,
    survey
  ) %>%
  rename(
    subarea = subareas,
    species_code = species,
    regions_code = large_area,
    survey_programme = survey
  )

# Create one logical subarea record for each unique combination used to match
# abundance records to their spatial definition. The combined survey string is
# retained only in this R lookup object; survey relationships are normalised in
# the PostgreSQL subareas_survey junction table.
subareas_lookup <- subareas_source %>%
  sf::st_drop_geometry() %>%
  select(
    subarea,
    species_code,
    regions_code,
    survey_programme
  ) %>%
  distinct() %>%
  mutate(id = row_number()) %>%
  select(
    id,
    subarea,
    species_code,
    regions_code,
    survey_programme
  )

# PostgreSQL subareas table: one row per logical subarea.
# survey_programme is not stored here because the survey relationship is held
# in subareas_survey.
insubareas <- subareas_lookup %>%
  select(
    id,
    subarea,
    species_code,
    regions_code
  )

DBI::dbWriteTable(
  conn,
  "subareas",
  insubareas,
  row.names = FALSE,
  append = TRUE
)

# Build and write subarea-related relational tables.
subareas_survey <- subareas_survey_f(
  subareas_lookup = subareas_lookup,
  survey_ref = reftabs$survey
)

DBI::dbWriteTable(
  conn,
  "subareas_survey",
  subareas_survey,
  row.names = FALSE,
  append = TRUE
)

subareas_geometry <- subareas_geometry_f(
  subareas_source = subareas_source,
  subareas_lookup = subareas_lookup
)

sf::st_write(
  subareas_geometry,
  conn,
  "subareas_geometry",
  append = TRUE
)


# ---------------------------------------------------------------------------
# Main abundance table
# ---------------------------------------------------------------------------

abundances <- read.csv(
  "tables/outputs/main_abundances_table.csv",
  stringsAsFactors = FALSE,
  na.strings = ""
)

duplicate_abundance_ids <- abundances %>%
  count(id) %>%
  filter(n > 1)

if (nrow(duplicate_abundance_ids) > 0) {
  print(duplicate_abundance_ids)
  stop(
    "ERROR: Duplicate abundance record IDs found. Database import stopped."
  )
}

# Use a temporary matching key for missing survey values. The placeholder is
# used only in R and is never written to the database.
abundancesj <- abundances %>%
  mutate(
    survey_match = ifelse(
      is.na(survey_programme),
      "NA_placeholder",
      survey_programme
    )
  )

subareas_lookup_j <- subareas_lookup %>%
  mutate(
    survey_match = ifelse(
      is.na(survey_programme),
      "NA_placeholder",
      survey_programme
    )
  )

# Validate that every abundance record has a logical subarea match.
unmatched_subareas <- abundancesj %>%
  anti_join(
    subareas_lookup_j,
    by = c(
      "subareas_subarea" = "subarea",
      "survey_match" = "survey_match",
      "species_code" = "species_code",
      "regions_code" = "regions_code"
    )
  )

if (nrow(unmatched_subareas) > 0) {
  print(unmatched_subareas)
  stop("ERROR: Some abundance records do not match a logical subarea.")
}

# Join the stable logical subarea ID to each abundance record.
abundancesin <- abundancesj %>%
  left_join(
    subareas_lookup_j %>%
      select(
        subareas_id = id,
        subarea,
        species_code,
        regions_code,
        survey_match
      ),
    by = c(
      "subareas_subarea" = "subarea",
      "survey_match" = "survey_match",
      "species_code" = "species_code",
      "regions_code" = "regions_code"
    ),
    relationship = "many-to-one"
  )

# Defensive check: spatial lookup must not duplicate abundance records.
duplicate_joined_ids <- abundancesin %>%
  count(id) %>%
  filter(n > 1)

if (nrow(duplicate_joined_ids) > 0) {
  print(duplicate_joined_ids)
  stop(
    "ERROR: Spatial matching created duplicate abundance records. Database import stopped."
  )
}

abundancesin <- abundancesin %>%
  select(
    id,
    year,
    startyear,
    endyear,
    estimate,
    cv,
    se,
    cvav,
    lci,
    uci,
    notes,
    pl,
    pu,
    season,
    gnull,
    areacoverage,
    sd,
    cvcalc,
    dateadded,
    datemodified,
    regions_code,
    species_code,
    category_code,
    evaluation_extent,
    subareas_id,
    timeseries_code
  ) %>%
  mutate(
    across(
      c(
        year,
        startyear,
        endyear,
        pl,
        pu,
        evaluation_extent
      ),
      as.integer
    )
  )

DBI::dbWriteTable(
  conn,
  "iwc_abundances_table",
  abundancesin,
  row.names = FALSE,
  append = TRUE
)


# ---------------------------------------------------------------------------
# Literature references and their junction tables
# ---------------------------------------------------------------------------

sourcerefs <- read.csv(
  "tables/outputs/literature_references.csv",
  stringsAsFactors = FALSE,
  na.strings = ""
)

duplicate_refs <- sourcerefs %>%
  count(refid) %>%
  filter(n > 1)

if (nrow(duplicate_refs) > 0) {
  print(duplicate_refs)
  stop(
    "ERROR: Duplicate refid values found in the references table. Database import stopped."
  )
}

insourceref <- sourcerefs %>%
  select(refid, ref, fullref, iwcref) %>%
  distinct()

DBI::dbWriteTable(
  conn,
  "references",
  insourceref,
  row.names = FALSE,
  append = TRUE
)

# references1
insref <- refs_f(
  mainref = abundances,
  reftab = sourcerefs
)

DBI::dbWriteTable(
  conn,
  "references1",
  insref,
  row.names = FALSE,
  append = TRUE
)

# regions1
regions1 <- regions1_f(sourcerefs)

DBI::dbWriteTable(
  conn,
  "regions1",
  regions1,
  row.names = FALSE,
  append = TRUE
)

# species2
species2 <- species2_f(sourcerefs)

DBI::dbWriteTable(
  conn,
  "species2",
  species2,
  row.names = FALSE,
  append = TRUE
)

# correction1, method1, survey1 and trials1
for (i in c("correction", "method", "survey", "trials")) {

  jreftabs <- inter_f(
    mainref = abundances,
    refcode = paste0(i, "_", colnames(reftabs[[i]])[1])
  )

  DBI::dbWriteTable(
    conn,
    paste0(i, "1"),
    jreftabs,
    row.names = FALSE,
    append = TRUE
  )
}


# ---------------------------------------------------------------------------
# Time-series tables
# ---------------------------------------------------------------------------

timeseries <- read.csv(
  "tables/outputs/timeseries.csv",
  stringsAsFactors = FALSE,
  na.strings = ""
)

timeseries1 <- read.csv(
  "tables/outputs/timeseries1.csv",
  stringsAsFactors = FALSE,
  na.strings = ""
)

DBI::dbWriteTable(
  conn,
  "timeseries",
  timeseries,
  row.names = FALSE,
  append = TRUE
)

DBI::dbWriteTable(
  conn,
  "timeseries1",
  timeseries1,
  row.names = FALSE,
  append = TRUE
)

# Close the database connection
dbDisconnect(conn)

cat("Database setup and data import completed successfully!\n")
