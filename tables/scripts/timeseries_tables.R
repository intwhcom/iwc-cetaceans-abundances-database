# make the time series table and its junction table

tstables <- function(abundances){
#load the data R function
read_time_sheets <- function(file_path = "legacy/data/abundances-NP.xlsx") {
  print("start reading the spreadsheet")
    df <- read_excel(file_path, sheet = 'timeseries') %>%
      select(id, code, estimate, cv, se, sd, year, lci, uci, notes) %>% 
      mutate(
        id = as.integer(id),
        estimate = as.integer(estimate),
        year = as.integer(year),
        lci = as.integer(lci),
        uci = as.integer(uci),
        code = as.character(code),
        notes = as.character(notes),
        cv = as.numeric(cv),
        se = as.numeric(se),
        sd = as.numeric(sd)
      )
}
#load the data:
dt <- list(); for (i in c("legacy/data/abundances-NP.xlsx","legacy/data/abundances-NA.xlsx","legacy/data/abundances-SH.xlsx")) dt[[i]] <- read_time_sheets(file_path = i)
ddf <- as.data.frame(do.call(rbind,dt)) %>% mutate(id = row_number())

#the junction table has the iwc_abundances_table_id and the timeseries_id
# clean codes
abu <- abundances %>%
  select(id, timeseries_code) %>%
  filter(!is.na(timeseries_code), timeseries_code != "") %>%
  mutate(rgc = strsplit(timeseries_code, "\\+")) %>%
  tidyr::unnest(rgc) %>%
  mutate(rgc = trimws(rgc)) %>%
  select(id, rgc) %>%
  rename(
    iwc_abundances_table_id = id,
    timeseries_code = rgc
  )

tst <- ddf %>%
  select(id, code) %>%
  mutate(code = trimws(code)) %>%
  rename(timeseries_id = id)

# check for missing codes
missing_ts_codes <- setdiff(
  unique(abu$timeseries_code),
  unique(tst$code)
)

if (length(missing_ts_codes) > 0) {
  print(missing_ts_codes)
  stop(
    paste(
      "ERROR: Timeseries codes not found:",
      paste(missing_ts_codes, collapse = ", "),
      "- database import stopped."
    )
  )
}

jt <- inner_join(abu, tst, by = c("timeseries_code" = "code"), relationship = "many-to-many") %>% distinct() %>% mutate(id = row_number()) %>% select(iwc_abundances_table_id,id, timeseries_id)

#return the 2 tables:
return(list(junction_table = jt, timeseries = ddf))
}

timeseries_tables <- tstables(abundances = main_abundances_table)
