# R function that reads an Excel file, selects specific columns for each sheet, and writes a new Excel file while preserving special characters (Scandinavian & English). ####

library(readxl)
library(writexl)
library(dplyr)

#Define the Function

filter_excel_sheets <- function(input_file = "C:\\Users\\IsidoraKatara\\OneDrive - International Whaling Commission\\Abundance-Tabs&Refs\\Abund-Masters/NA/abundances-NA.xlsx", output_file = "C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/Abundance-Tabs&Refs/abundances tables db/db/abundances-NA.xlsx", output_csv = "C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/Abundance-Tabs&Refs/Extras/abundances-viewer/view-abundances-whales/NAcombined.csv", output_refs = "C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/Abundance-Tabs&Refs/Extras/abundances-viewer/view-abundances-whales/NAreferences.csv") {
  
  # define the vectors of sheets and columns
  maincolumns = c('id',	'regions_code', 'species_code',	'subareas_subarea',	'category_code',	'evaluation_extent',	'trials_usage',	'year',	'startyear',	'endyear',	'method_code',	'correction_code',	'estimate',	'cv',	'se',	'cvav',	'lci',	'uci',	'references_ref',	'notes',	'survey_programme', 'pl',	'pu',	'season',	'gnull',	'areacoverage',	'sd',	'cvcalc',	'dateadded',	'datemodified',	'timeseries_code')
  mainsheets = c("Mi", "Fin", "Hbk", "Sei","Spr", "NArht", "Bow", "Blu", "Other", "Gray", "Brd", "AMi", "blue" , "Srht")
  allsheets = c(mainsheets,"timeseries","references")
  timecolumns = c('id','year','estimate','cv','se','sd','lci','uci','code','notes')
  refcolumns = c('refid', 'regions_code', 'species_code', 'ref', 'fullref', 'iwcref')
  species_keys <- c("Mi", "Fin", "Hbk", "Sei", "Spr", "NArht", "Bow", "Blu", 
                    "Other", "Gray", "Brd", "AMi", "blue", "Srht")
  # Define sheet-column mappings
  # Create a list where each species key maps to the same column names
  selected_columns <- setNames(
    rep(list(maincolumns), length(species_keys)), 
    species_keys
  )
  
  # Add other list elements
  selected_columns$timeseries <- c('id', 'year', 'estimate', 'cv', 'se', 'sd', 'lci', 'uci', 'code', 'notes')
  selected_columns$references <- c('refid', 'regions_code', 'species_code', 'ref', 'fullref', 'iwcref')
  
  # Read all sheet names and choose the ones we need from allsheets
  sheets <- intersect(excel_sheets(input_file),allsheets)
  
  # Create an empty list to store filtered data
  filtered_data <- list()
  
  # Loop through each sheet and apply column selection
  for (sheet in sheets) {
    # Read the full sheet
    df <- read_excel(input_file, sheet = sheet)
    
    # Determine which columns to select
    cols_to_select <- NULL
    for (key in names(selected_columns)) {
      if (sheet %in% unlist(strsplit(key, ","))) {
        cols_to_select <- selected_columns[[key]]
        break
      }
    }
    
    # If the sheet has specific column selections, apply them
    if (!is.null(cols_to_select)) {
      df <- df %>% select(any_of(cols_to_select))  # Select only available columns
    }
    
    # define the column types
    col_types <- list("id" = "character", "regions_code" = "character", "subareas_subarea" = "character", "species_code" = "character", "category_code" = "character", "evaluation_extent" = "character", "year" = "numeric", "startyear" = "numeric", "endyear" = "numeric", "season" = "character", "estimate" = "numeric", "cv" = "numeric", "se" = "numeric", "sd" = "numeric","cvcalc" = "numeric","uci" = "numeric","lci" = "numeric","cvav" = "numeric","pl" = "numeric","pu" = "numeric", "trials_usage" = "character","survey_programme" = "character","method_code" = "character","correction_code" = "character","areacoverage" = "character", "gnull" = "numeric","references_ref" = "character","notes" = "character","dateadded" = "date","datemodified" = "date", "web" = "character","webestimate" = "numeric","webcis" = "character","internal_notes" = "character","timeseries_code" = "character",'code' = "character",'refid' = "character", 'ref' = "character", 'fullref' = "character", 'iwcref' = "character")
    for (col in names(df)) {
      if (col_types[[col]] == "character") {
        df[[col]] <- as.character(df[[col]])
      } else if (col_types[[col]] == "numeric") {
        df[[col]] <- as.numeric(df[[col]])
      } else if (col_types[[col]] == "date") {
        df[[col]] <- as.Date(df[[col]], format = "%d-%m-%Y")  # Excel date handling
      }
    }
    
    # Store the filtered data
    filtered_data[[sheet]] <- df
  }
  
  #select the data sheets and turn them into a CSV file
  csv1 <- as.data.frame(do.call(rbind,filtered_data[intersect(names(filtered_data),species_keys)]))
  write.csv(csv1, file = output_csv)
  
  #select the reference sheet and write to a cvs file
  csv2 <- as.data.frame(filtered_data["references"])
  write.csv(csv2, file = output_refs)
  
  # Write the selected columns to a new Excel file
  write_xlsx(filtered_data, output_file)
  
  cat("Filtered Excel file saved as:", output_file, "\n")
}

#### run for all the files ####
for (i in c('SH','NP','NA')){
  filter_excel_sheets(input_file = paste0("C:\\Users\\IsidoraKatara\\OneDrive - International Whaling Commission\\Abundance-Tabs&Refs\\Abund-Masters/",i,"/abundances-",i,".xlsx"), output_file = paste0("C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/Abundance-Tabs&Refs/abundances tables db/db/abundances-",i,".xlsx"), output_csv = paste0("C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/Abundance-Tabs&Refs/Extras/abundances-viewer/view-abundances-whales/",i,"combined.csv"), output_refs = paste0("C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/Abundance-Tabs&Refs/Extras/abundances-viewer/view-abundances-whales/",i,"references.csv"))
}

