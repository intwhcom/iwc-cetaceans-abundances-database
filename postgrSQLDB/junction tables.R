# functions that make the junction tables of the database #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# make references1 table in the PostGIS database
refs_f <- function(mainref, reftab) {
  library(tidyr)

  # references from main table
  A <- mainref %>%
    select(id, regions_code, species_code, references_ref) %>%
    filter(!is.na(references_ref), references_ref != "") %>%
    mutate(ref = strsplit(references_ref, ";")) %>%
    unnest(ref) %>%
    mutate(
      ref = trimws(ref),
      regions_code = trimws(regions_code),
      species_code = trimws(species_code)
    )

  # references from references table
  B <- reftab %>%
    select(refid, regions_code, species_code, ref) %>%
    mutate(rgc = strsplit(regions_code, "\\+")) %>%
    unnest(rgc) %>%
    mutate(spc = strsplit(species_code, "\\+")) %>%
    unnest(spc) %>%
    mutate(
      rgc = trimws(rgc),
      spc = trimws(spc),
      ref = trimws(ref)
    )

  # CHECK: every reference in the abundance tables must
  # be identifiable in the reference table
  unmatched_refs <- anti_join(
    A,
    B,
    by = c(
      "regions_code" = "rgc",
      "species_code" = "spc",
      "ref" = "ref"
    )
  )

  if (nrow(unmatched_refs) > 0) {
    print(unmatched_refs)
    stop(
      paste0(
        "ERROR: ",
        nrow(unmatched_refs),
        " abundance-reference relationship(s) could not be matched. ",
        "Database import stopped."
      )
    )
  }

  # make junction table
  refstable <- inner_join(
    A,
    B,
    by = c(
      "regions_code" = "rgc",
      "species_code" = "spc",
      "ref" = "ref"
    ),
    relationship = "many-to-many"
  ) %>%
    select(id, refid) %>%
    rename(
      iwc_abundances_table_id = id,
      references_refid = refid
    ) %>%
    distinct(iwc_abundances_table_id, references_refid) %>%
    mutate(id = row_number())

  return(refstable)
}


# make correction1, method1, survey1 and trials1
inter_f <- function(mainref, refcode) {
  mainref <- as.data.frame(mainref)
  mainref$refcode0 <- mainref[[refcode]]

  A <- mainref %>%
    select(id, refcode0) %>%
    filter(!is.na(refcode0), refcode0 != "") %>%
    mutate(ref = strsplit(as.character(refcode0), "\\+")) %>%
    unnest(ref) %>%
    mutate(ref = trimws(ref)) %>%
    rename(iwc_abundances_table_id = id) %>%
    select(ref, iwc_abundances_table_id) %>%
    distinct()

  A[[refcode]] <- A$ref

  A <- A %>%
    select(-ref) %>%
    mutate(id = row_number())

  return(A)
}


# make regions1: junction table between literature references and regions
regions1_f <- function(reftab) {
  reftab %>%
    select(regions_code, refid) %>%
    filter(!is.na(regions_code), regions_code != "") %>%
    mutate(regions_code = strsplit(as.character(regions_code), "\\+")) %>%
    unnest(regions_code) %>%
    mutate(regions_code = trimws(regions_code)) %>%
    select(regions_code, refid) %>%
    distinct() %>%
    rename(references_refid = refid) %>%
    mutate(id = row_number()) %>%
    select(regions_code, references_refid, id)
}


# make species2: junction table between literature references and species
species2_f <- function(reftab) {
  reftab %>%
    select(species_code, refid) %>%
    filter(!is.na(species_code), species_code != "") %>%
    mutate(species_code = strsplit(as.character(species_code), "\\+")) %>%
    unnest(species_code) %>%
    mutate(species_code = trimws(species_code)) %>%
    select(species_code, refid) %>%
    distinct() %>%
    rename(references_refid = refid) %>%
    mutate(id = row_number()) %>%
    select(references_refid, species_code, id)
}


# make subareas_survey junction table
# subareas_lookup contains one row per logical subarea and retains the original
# combined survey string only for construction/matching in R.
subareas_survey_f <- function(subareas_lookup, survey_ref) {

  subareas_survey <- subareas_lookup %>%
    select(
      subareas_id = id,
      survey_programme
    ) %>%
    filter(
      !is.na(survey_programme),
      trimws(survey_programme) != ""
    ) %>%
    tidyr::separate_rows(
      survey_programme,
      sep = "\\+"
    ) %>%
    mutate(
      survey_programme = trimws(survey_programme)
    ) %>%
    distinct(
      subareas_id,
      survey_programme
    )

  # check that every survey exists in the survey reference table
  missing_surveys <- subareas_survey %>%
    anti_join(
      survey_ref,
      by = c("survey_programme" = "programme")
    )

  if (nrow(missing_surveys) > 0) {
    print(missing_surveys)
    stop(
      "ERROR: Survey programme(s) used by subareas are missing from the survey reference table."
    )
  }

  subareas_survey <- subareas_survey %>%
    mutate(id = row_number()) %>%
    select(
      subareas_id,
      survey_programme,
      id
    )

  return(subareas_survey)
}


# make subareas_geometry table
# Each original spatial feature is retained as a separate geometry and linked
# to one logical subarea. This avoids creating MULTIPOLYGON geometries, including
# for subareas represented by separate polygons on either side of longitude 180.
subareas_geometry_f <- function(subareas_source, subareas_lookup) {

  lookup_for_join <- subareas_lookup %>%
    mutate(
      survey_match = ifelse(
        is.na(survey_programme),
        "NA_placeholder",
        survey_programme
      )
    ) %>%
    select(
      subareas_id = id,
      subarea,
      species_code,
      regions_code,
      survey_match
    )

  geometry_source <- subareas_source %>%
    mutate(
      survey_match = ifelse(
        is.na(survey_programme),
        "NA_placeholder",
        survey_programme
      )
    )

  subareas_geometry <- geometry_source %>%
    left_join(
      lookup_for_join,
      by = c(
        "subarea" = "subarea",
        "species_code" = "species_code",
        "regions_code" = "regions_code",
        "survey_match" = "survey_match"
      ),
      relationship = "many-to-one"
    )

  unmatched_geometry <- subareas_geometry %>%
    sf::st_drop_geometry() %>%
    filter(is.na(subareas_id))

  if (nrow(unmatched_geometry) > 0) {
    print(unmatched_geometry)
    stop(
      "ERROR: One or more spatial features could not be linked to a logical subarea."
    )
  }

  subareas_geometry <- subareas_geometry %>%
    mutate(id = row_number()) %>%
    select(
      id,
      subareas_id,
      accuracy,
      source,
      geometry
    )

  return(subareas_geometry)
}
