# Load required packages
library(RPostgres)  # PostgreSQL connection
library(DBI)        # Database interface
library(readxl)     # Reading Excel files
library(sf)         # Spatial data handling
library(tidyverse)
sf::sf_use_s2(FALSE)
#source functions:
source("read_excel_tables.R")
source("junction tables.R")

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

# Create database (if not exists)
dbExecute(conn_admin, paste0("DROP DATABASE IF EXISTS ", db_name))
dbExecute(conn_admin, paste0("CREATE DATABASE ", db_name))
dbDisconnect(conn_admin)  # Disconnect admin connection

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

# Read and execute SQL file
sql_file <- "iwc_abundances_table_create.sql"
sql_text <- readLines(sql_file, warn = FALSE)

# Remove full-line and inline SQL comments
sql_text <- gsub("--.*", "", sql_text)  # Remove inline comments
sql_text <- paste(sql_text, collapse = "\n")  # Preserve multi-line queries

# Split SQL statements correctly by semicolon but keep multi-line statements intact
sql_statements <- unlist(strsplit(sql_text, ";[[:space:]]*\n", perl = TRUE))
for (stmt in sql_statements) {
  stmt <- trimws(stmt)
  if (nchar(stmt) > 0) {  # Execute only non-empty statements
    dbExecute(conn, stmt)
  }
}

#### Load and write data - Excel and shapefiles ####

#the reference tables - load in R and write in db
reftabs <- readreftabsdb()
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
for (j in reference_tables) dbWriteTable(conn, j, reftabs[[j]], row.names = FALSE, append = TRUE)

#add the subareas reference table which has a geometry and data come from shapefiles
shapefiles <- c("NA-subareas.shp","SH-subareas.shp","NP-subareas.shp")

spatial_data <- list()
for (shp_file in shapefiles) spatial_data[[shp_file]] <- st_read(shp_file) %>%
  st_transform(4326) %>%
  group_by(subareas, accuracy, source, species, large_area, survey) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")

insubareas <- do.call(rbind, spatial_data) %>% 
  mutate(id = row_number()) %>% select(id, subareas, accuracy ,source ,geometry , species, large_area, survey) %>% 
  rename_with(~ c("id", 'subarea', 'accuracy', 'source', 'geometry', 'species_code', 'regions_code', "survey_programme")) # change select the columns and change names (to delete this: need to change the original names when the subareas are made!!!!!)

st_write(insubareas, conn, "subareas", append = TRUE) 

#load the main abundances tables in R and write in db
abundances <- readexceldb()

duplicate_abundance_ids <- abundances %>%
  count(id) %>%
  filter(n > 1)

if (nrow(duplicate_abundance_ids) > 0) {
  print(duplicate_abundance_ids)
  stop(
    "ERROR: Duplicate abundance record IDs found. Database import stopped."
  )
}

abundancesj <- abundances %>% mutate(survey_programme = ifelse(is.na(survey_programme), "NA_placeholder", survey_programme))
insubareasj <- insubareas %>% mutate(survey_programme = ifelse(is.na(survey_programme), "NA_placeholder", survey_programme))

abundancesin <- abundancesj %>%
  left_join(insubareasj, by = c("subareas_subarea" = "subarea", "survey_programme" = "survey_programme", "species_code" = "species_code", "regions_code" = "regions_code")) %>%
  rename(id = "id.x", subareas_id = "id.y") %>% 
  select(id,year,startyear,endyear,estimate,cv,se,cvav,lci,uci,notes,pl,pu,season,gnull,areacoverage,sd,cvcalc,dateadded,datemodified,regions_code,species_code,category_code,evaluation_extent,subareas_id,timeseries_code) %>%
  mutate(across(c(year, startyear, endyear, estimate, pl,pu,evaluation_extent), as.integer))

# validation before writing to db
unmatched_subareas <- abundancesj %>%
  anti_join(
    insubareasj,
    by = c(
      "subareas_subarea" = "subarea",
      "survey_programme" = "survey_programme",
      "species_code" = "species_code",
      "regions_code" = "regions_code"
    )
  )

if (nrow(unmatched_subareas) > 0) {
  print(unmatched_subareas)
  stop("Some abundance records do not match a subarea.")
}

# now write the table to the dataset
dbWriteTable(conn, "iwc_abundances_table", abundancesin, row.names = FALSE, append = TRUE)

#the references (source papers) tables
sourcerefs <- readsourcerefsdb()
# the reference table
insourceref <- sourcerefs %>% select(refid, ref, fullref, iwcref)

#if workbooks with the same refid, insertion fails. test it:
duplicate_refs <- sourcerefs %>%
  count(refid) %>%
  filter(n > 1)

print(duplicate_refs)

#check whether duplicates genuinely contain identical bibliographic data before doing something like:

insourceref <- sourcerefs %>%
  select(refid, ref, fullref, iwcref) %>%
  distinct()

if (nrow(duplicate_refs) > 0) {
  print(duplicate_refs)
  stop("ERROR: Duplicate refid values found in the references table. Database import stopped.")
}

#if no errors, write the table
dbWriteTable(conn, "references", insourceref, row.names = FALSE, append = TRUE)

#the junction table for the references (source papers) tables
insref <- refs_f(mainref = abundances,reftab = sourcerefs)
dbWriteTable(conn, "references1", insref, row.names = FALSE, append = TRUE)

#regions and species junction tables
regions1 <- sourcerefs %>% select(regions_code, refid) %>% 
  mutate(rgc = strsplit(regions_code, "\\+")) %>% unnest(rgc) %>% mutate(rgc = trimws(rgc)) %>% select(rgc, refid) %>% distinct() %>% rename(references_refid = refid, regions_code = rgc) %>% mutate(id = row_number())
dbWriteTable(conn, "regions1", regions1, row.names = FALSE, append = TRUE)

species2 <- sourcerefs %>% select(species_code, refid) %>% mutate(rgc = strsplit(species_code, "\\+")) %>% unnest(rgc) %>% mutate(rgc = trimws(rgc)) %>% select(rgc, refid) %>% distinct() %>% rename(references_refid = refid, species_code = rgc) %>% mutate(id = row_number())
dbWriteTable(conn, "species2", species2, row.names = FALSE, append = TRUE)

#the correction, method, survey and trials junction tables
for (i in c('correction', 'method', 'survey', 'trials')) {
  jreftabs <- inter_f(mainref=abundances,refcode=paste0(i,"_",colnames(reftabs[[i]][1])))
  dbWriteTable(conn, paste0(i,"1"), jreftabs, row.names = FALSE, append = TRUE)
  }

#the time series tables
source("timeseries_tables.R")
tstabs <- tstables(abundances)
dbWriteTable(conn, "timeseries", tstabs$timeseries, row.names = FALSE, append = TRUE)
dbWriteTable(conn, "timeseries1", tstabs$junction_table, row.names = FALSE, append = TRUE)
# Close the database connection
dbDisconnect(conn)

# Print success message
cat("Database setup and data import completed successfully!\n")
