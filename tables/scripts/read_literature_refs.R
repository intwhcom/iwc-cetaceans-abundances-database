# read the references (sources) from the excel files, chose only those columns that are needed for the database #

read_literature_refs <- function(){
  library(readxl)
  library(dplyr)
  
  # read in the data for all tables ####
  alldatalist <- list()
  for (i in c('SH','NP','NA')){
    file_path <- paste0("legacy/data/abundances-",i,".xlsx")
    alldatalist[[i]] <- read_excel(file_path, sheet = "references") %>% select(refid, regions_code, species_code, ref, fullref,	iwcref)}
  #final output data frame
  output <- do.call(rbind.data.frame, alldatalist)
  return(output)      
}

literature_references <- read_literature_refs()

