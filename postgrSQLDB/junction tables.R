# functions that make the junction tables of the database #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# make references1 table in the postGIS database
refs_f <- function(mainref,reftab){
  library(tidyr)
# references from main table
A <- mainref %>% select(id, regions_code, species_code, references_ref) %>% 
  mutate(ref = strsplit(references_ref, ";")) %>%
  unnest(ref)

#references from references table
B <- reftab %>% select(refid, regions_code, species_code, ref) %>% 
  mutate(rgc = strsplit(regions_code, "\\+")) %>% unnest(rgc) %>% 
  mutate(spc = strsplit(species_code, "\\+")) %>%
  unnest(spc)

#join the 2 table and keep the relevant columns
refstable <- inner_join(A, B, by = c("regions_code" = "rgc", "species_code" = "spc", 'ref' = 'ref'), relationship = "many-to-many") %>% select(id, refid)  %>% rename(iwc_abundances_table_id = id, references_refid = refid) %>% mutate(id = row_number())

return(refstable)
}

# make the rest of the junction tables
inter_f <- function(mainref,refcode){
  # references from main table
  mainref <- as.data.frame(mainref)
  mainref$refcode0 <- mainref[,refcode]
  A <- mainref %>% select(id,refcode0) %>% filter(!is.na(refcode0)) %>% 
    mutate(ref = strsplit(as.character(refcode0), "\\+")) %>%
    unnest(ref) %>% rename(iwc_abundances_table_id = id) %>%
    mutate(id = row_number()) %>% select(ref,iwc_abundances_table_id,id)
  A[,refcode] <- A$ref
  A <- A %>% select(-ref)
  return(A)
}

#the timeseries junction table is made in script timeseries_tables.R