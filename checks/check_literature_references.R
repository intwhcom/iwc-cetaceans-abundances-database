#### Literature reference checks ####

library(dplyr)
library(tidyr)

# Check that every literature reference used in the main abundance table
# exists in the consolidated literature_references table.
check_reference_ids <- function(main_abundances_table, literature_references) {

  used_refs <- main_abundances_table %>%
    select(id, references_ref) %>%
    separate_rows(references_ref, sep = ";") %>%
    transmute(
      id = id,
      reference = trimws(as.character(references_ref))
    ) %>%
    filter(!is.na(reference), reference != "") %>%
    distinct()

  available_refs <- literature_references %>%
    transmute(reference = trimws(as.character(ref))) %>%
    filter(!is.na(reference), reference != "") %>%
    distinct()

  anti_join(used_refs, available_refs, by = "reference")
}


# Check that each region + species + literature-reference combination used
# in the main abundance table is represented in literature_references.
#
# In the main table, multiple references may be separated by ";".
# In the literature reference table, a reference may apply to multiple
# regions or species separated by "+".
check_reference_combinations <- function(main_abundances_table,
                                         literature_references) {

  used_combinations <- main_abundances_table %>%
    select(id, regions_code, species_code, references_ref) %>%
    separate_rows(references_ref, sep = ";") %>%
    transmute(
      id = id,
      regions_code = trimws(as.character(regions_code)),
      species_code = trimws(as.character(species_code)),
      reference = trimws(as.character(references_ref))
    ) %>%
    filter(
      !is.na(reference), reference != "",
      !is.na(regions_code), regions_code != "",
      !is.na(species_code), species_code != ""
    ) %>%
    distinct()

  valid_combinations <- literature_references %>%
    select(regions_code, species_code, ref) %>%
    separate_rows(regions_code, sep = "\\+") %>%
    separate_rows(species_code, sep = "\\+") %>%
    transmute(
      regions_code = trimws(as.character(regions_code)),
      species_code = trimws(as.character(species_code)),
      reference = trimws(as.character(ref))
    ) %>%
    filter(
      !is.na(reference), reference != "",
      !is.na(regions_code), regions_code != "",
      !is.na(species_code), species_code != ""
    ) %>%
    distinct()

  anti_join(
    used_combinations,
    valid_combinations,
    by = c("regions_code", "species_code", "reference")
  )
}

