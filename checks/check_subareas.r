#### Function checking that each subarea has a polygon ####

library(sf)       # For reading shapefiles
library(readxl)   # For reading Excel files
library(dplyr)    # For data wrangling

checksubareanames <- function(originaldata, shapefile_path, writecsv = FALSE){
# --- 1. Load the shapefile ---
shape_data <- st_read(shapefile_path) %>% mutate(sub_area = subareas, survey_programme = survey) %>% 
  select(sub_area, survey_programme, species) %>%
  st_drop_geometry()  # Drop spatial data, keep attributes

# --- 2. Load the abundance data ---
excel_data <- originaldata %>%
  select(subareas_subarea, survey_programme, species_code) %>%
  rename(sub_area = subareas_subarea, species = "species_code")
  

# --- 3. Get unique combinations from both datasets ---
shape_combinations <- shape_data %>% distinct()
excel_combinations <- excel_data %>% distinct()

# --- 4. Find missing combinations ---
missing_combinations <- anti_join(excel_combinations, shape_combinations, by = c("sub_area", "survey_programme", "species"))

# --- 5. Output results ---
if (nrow(missing_combinations) == 0) {
  print("✅ All combinations from the Excel file are present in the shapefile!")
} else {
  print("⚠️ The following combinations are missing in the shapefile:")
  print(missing_combinations)
}

# --- 6. Save missing combinations (optional) ---
if(writecsv) write.csv(missing_combinations, "missing_combinations.csv", row.names = FALSE)
# --- 7. return object of missing combinations (optional) ---
return(missing_combinations)
}