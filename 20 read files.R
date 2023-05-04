library(data.table)

if(!"tidytable" %in% installed.packages()){install.packages("tidytable")}
if(!dir.exists(here::here("data", "R_data_files"))) {dir.create(here::here("data", "R_data_files"))}

library(tidytable)


state_eff_csv_files <- list.files(here::here("data", "csv_files", "effl_data"),
                                  full.names =  TRUE)

state_eff_csv_files <- stringr::str_subset(state_eff_csv_files, ".csv$")

fread_effl_csv <- function(effl_csv_file) {
  fread(effl_csv_file, select = c("NPDES_ID", "VIOLATION_CODE", "MONITORING_PERIOD_END_DATE")) %>%
    mutate.(n = 1) %>%
    pivot_wider.(names_from = VIOLATION_CODE, values_from = n, values_fn = sum)
   
}


#test <- fread_effl_csv(state_eff_csv_files[1])

npdes_eff_viols <- purrr::map_dfr(state_eff_csv_files, .f = ~ fread_effl_csv(.x))

npdes_formal_enforcement <- fread(here::here("data", "csv_files", "NPDES_FORMAL_ENFORCEMENT_ACTIONS.csv"))

npdes_formal_enforcement <- npdes_formal_enforcement %>%
  select.(NPDES_ID, AGENCY, SETTLEMENT_ENTERED_DATE, FED_PENALTY_ASSESSED_AMT, STATE_LOCAL_PENALTY_AMT)


save(npdes_eff_viols, file = here::here("data", "R_data_files", "npdes_eff_viols.Rdata"), compress = TRUE)

save(npdes_formal_enforcement, file = here::here("data", "R_data_files", "npdes_formal_enforce.Rdata"), compress = TRUE)
