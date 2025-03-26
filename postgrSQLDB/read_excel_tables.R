# read the data from the excel files #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


# read the excel files holding the abundance estimates main tables and, chose only those columns that are needed for the database #

readexceldb <- function(){
  library(readxl)
  library(dplyr)

source("read_excel_sheets_with_types.R")

# general vectors for all tables ####
required_sheets <- c("Mi", "Fin", "Hbk", "Sei","Spr", "NArht", "Bow", "Blu", "Other", "Gray", "Brd", "AMi", "blue" , "Srht", "Abund-Small")
# Define required columns and their types
required_columns <- c('id',	'year',	'startyear',	'endyear','estimate',	'cv',	'se',	'cvav',	'lci',	'uci',	'notes', 'pl',	'pu',	'season',	'gnull', 'areacoverage', 'sd',	'cvcalc',	'dateadded',	'datemodified',	'regions_code', 'references_ref', 'species_code',	'category_code', 'evaluation_extent', 'subareas_subarea',	'timeseries_code', 'trials_usage',	'method_code',	'correction_code', 'survey_programme'
)
col_types <- list("id" = "character", "regions_code" = "character", "subareas_subarea" = "character", "species_code" = "character", "category_code" = "character", "evaluation_extent" = "character", "year" = "numeric", "startyear" = "numeric", "endyear" = "numeric", "season" = "character", "estimate" = "numeric", "cv" = "numeric", "se" = "numeric", "sd" = "numeric","cvcalc" = "numeric","uci" = "numeric","lci" = "numeric","cvav" = "numeric","pl" = "numeric","pu" = "numeric", "trials_usage" = "character","survey_programme" = "character","method_code" = "character","correction_code" = "character","areacoverage" = "character", "gnull" = "numeric","references_ref" = "character","notes" = "character","dateadded" = "date","datemodified" = "date", "timeseries_code" = "character")

# read in the data for all tables ####
alldatalist <- list()
for (i in c('SH','NP','NA')){
  file_path <- paste0("abundances-",i,".xlsx")
  alldatalist[[i]] <- read_excel_sheets_with_types(file_path, required_columns, col_types,required_sheets)
}

#final output data frame
output <- do.call(rbind.data.frame, alldatalist)
return(output)
}

# read the references (sources) from the excel files, chose only those columns that are needed for the database #

readsourcerefsdb <- function(){
  library(readxl)
  library(dplyr)
  
  # read in the data for all tables ####
  alldatalist <- list()
  for (i in c('SH','NP','NA')){
    file_path <- paste0("abundances-",i,".xlsx")
    alldatalist[[i]] <- read_excel(file_path, sheet = "references") %>% select(refid, regions_code, species_code, ref, fullref,	iwcref)}
    #final output data frame
    output <- do.call(rbind.data.frame, alldatalist)
    return(output)      
  }

# read the reference tables from the excel files, chose only those columns that are needed for the database #
readreftabsdb <- function(){
  library(readxl)
  
  # Function to read all sheets from an Excel file
  read_all_sheets <- function(file_path) {
    sheets <- excel_sheets(file_path)
    sheet_data <- lapply(sheets, function(sheet) read_excel(file_path, sheet = sheet))
    names(sheet_data) <- sheets  # Assign sheet names to the list
    return(sheet_data)
  }
  
  # Example usage
  file_path <- "reference tables.xlsx"  # Change to your file path
  data_list <- read_all_sheets(file_path)
  
  #final output data frame
  return(data_list)  
  }
