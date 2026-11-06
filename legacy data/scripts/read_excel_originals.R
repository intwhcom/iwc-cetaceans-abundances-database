# function that reads the original excel file to 1 data frame #

readexceloriginals <- function(){
  library(readxl)
  library(dplyr)
  
  source("scripts/read_excel_sheets_with_types.R")

  # general vectors for all tables ####
  required_sheets <- c("Mi", "Fin", "Hbk", "Sei","Spr", "NArht", "Bow", "Blu", "Other", "SM","Gray", "Brd", "AMi" , "Srht","Bdu","Fpn")#, "Abund-Small"
  # Define required columns and their types
  required_columns <- c('id',	'year',	'startyear',	'endyear','estimate',	'cv',	'se',	'cvav',	'lci',	'uci',	'notes', 'pl',	'pu',	'season',	'gnull', 'areacoverage', 'sd',	'cvcalc',	'dateadded',	'datemodified',	'regions_code', 'references_ref', 'species_code',	'category_code', 'evaluation_extent', 'subareas_subarea',	'timeseries_code', 'trials_usage',	'method_code',	'correction_code', 'survey_programme'
  )
  col_types <- list("id" = "character", "regions_code" = "character", "subareas_subarea" = "character", "species_code" = "character", "category_code" = "character", "evaluation_extent" = "character", "year" = "character", "startyear" = "numeric", "endyear" = "numeric", "season" = "character", "estimate" = "numeric", "cv" = "numeric", "se" = "numeric", "sd" = "numeric","cvcalc" = "numeric","uci" = "numeric","lci" = "numeric","cvav" = "numeric","pl" = "numeric","pu" = "numeric", "trials_usage" = "character","survey_programme" = "character","method_code" = "character","correction_code" = "character","areacoverage" = "character", "gnull" = "numeric","references_ref" = "character","notes" = "character","dateadded" = "date","datemodified" = "date", "timeseries_code" = "character")
  
  # read in the data for all tables ####
  alldatalist <- list()
  for (i in c('SH','NP','NA')){
    file_path <- paste0("data/abundances-",i,".xlsx")
    alldatalist[[i]] <- read_excel_sheets_with_types(file_path, required_columns, col_types,required_sheets)
  }
  
  #final output data frame
  output <- do.call(rbind.data.frame, alldatalist)
  return(output)
}

abundances <- readexceloriginals()
