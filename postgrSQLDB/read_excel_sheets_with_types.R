library(readxl)
library(dplyr)

# Function to read all sheets from an Excel file and enforce column types
read_excel_sheets_with_types <- function(file_path, required_columns, col_types, required_sheets) {
  print("start reading the spreadsheets")
  # Get sheet names
  sheet_names <- intersect(required_sheets,excel_sheets(file_path))
  print("required sheets:")
  print(sheet_names)
  # Initialize an empty list to store data
  data_list <- list()
  
  for (sheet in sheet_names) {
    # Read the sheet
    df <- read_excel(file_path, sheet = sheet)
    print(head(df))
    # Check if all required columns are present
    missing_cols <- setdiff(required_columns, names(df))
    
    if (length(missing_cols) > 0) {
      warning(paste("Skipping sheet:", sheet, "Missing columns:", paste(missing_cols, collapse = ", ")))
      next
    }
    
    # Select and reorder columns
    df <- df %>% select(all_of(required_columns))
    print("df with selected columns:")
    print(head(df))
    # Convert columns to specified types
    for (col in names(df)) {
      if (col_types[[col]] == "character") {
        df[[col]] <- as.character(df[[col]])
      } else if (col_types[[col]] == "numeric") {
        df[[col]] <- as.numeric(df[[col]])
      } else if (col_types[[col]] == "date") {
        df[[col]] <- as.Date(df[[col]], format = "%d-%m-%Y")  # Excel date handling
      }
    }
    print("df with specified types:")
    print(head(df))
    # Store the cleaned dataframe in the list
    data_list[[sheet]] <- df
  }
  finaldata <- do.call(rbind.data.frame,data_list)
  return(finaldata)
}

# Example usage:
#file_path <- "C:\\Users\\IsidoraKatara\\OneDrive - International Whaling Commission\\Abundance-Tabs&Refs\\Abund-Masters/NA/abundances-NA.xlsx"
#required_sheets <- c("Mi", "Fin", "Hbk", "Sei","Spr", "NArht", "Bow", "Blu", "Other", "Gray", "Brd", "AMi", "blue" , "Srht", "Abund-Small")
# Define required columns and their types
#required_columns <- c("id","large_area","sub_area","species","category","evaluation_extent","year","start_year","end_year","season", "estimate","cv","se","sd","cv_calc","uci","lci","cv_av","pl","pu", "trials_usage","survey_programme","method","correction","area_coverage", "gnull","ref","notes","date_added","date_modified","web","web_estimate","web_cis","internal_notes","time_series")
#col_types <- list("id" = "character", "large_area" = "character", "sub_area" = "character", "species" = "character", "category" = "character", "evaluation_extent" = "character", "year" = "numeric", "start_year" = "numeric", "end_year" = "numeric", "season" = "character", "estimate" = "numeric", "cv" = "numeric", "se" = "numeric", "sd" = "numeric","cv_calc" = "numeric","uci" = "numeric","lci" = "numeric","cv_av" = "numeric","pl" = "numeric","pu" = "numeric", "trials_usage" = "character","survey_programme" = "character","method" = "character","correction" = "character","area_coverage" = "character", "gnull" = "numeric","ref" = "character","notes" = "character","date_added" = "date","date_modified" = "date", "web" = "character","web_estimate" = "numeric","web_cis" = "character","internal_notes" = "character","time_series" = "character")

# Read and process sheets
#abundance_data <- read_excel_sheets_with_types(file_path, required_columns, col_types,required_sheets)
