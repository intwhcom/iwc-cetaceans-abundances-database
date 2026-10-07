# read the reference tables from the excel files, chose only those columns that are needed for the database #

read_reference_tables <- function(){
  library(readxl)
  
  # Function to read all sheets from an Excel file
  read_all_sheets <- function(file_path) {
    sheets <- excel_sheets(file_path)
    sheet_data <- lapply(sheets, function(sheet) read_excel(file_path, sheet = sheet))
    names(sheet_data) <- sheets  # Assign sheet names to the list
    return(sheet_data)
  }
  
  # Example usage
  file_path <- "tables/reference tables.xlsx"  # Change to your file path
  data_list <- read_all_sheets(file_path)
  
  #final output data frame
  return(data_list)  
}

reference_tables <- read_reference_tables()
