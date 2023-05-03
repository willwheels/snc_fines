library(tidyverse)

top200_files_jan_2020 <- list.files(here::here("..", "SNC Tracking", "Jan 2020"), full.names = TRUE)

top200_files_jan_2020

top200_files_jan_2020 <- str_subset(top200_files_jan_2020, ".xlsx")



read_snc_file <- function(excel_filename) {
  
  one_file <- readxl::read_xlsx(excel_filename, skip = 1, sheet = 2)
  
  one_file <- one_file %>%
    select(source_id, cwp_name, cwp_major_minor_status_flag, over80_count_us, cwp_indian_cntry_flg, 
           cwp_state,
           issuing_agency, cwp_qtrs_with_snc, days_eff_exceedances, pct_limits_in_violation, e90_count,
           dmr_lol_pounds) %>%
    mutate(row_id=row_number())
  
  
  }

all_snc_files_jan_2020 <- purrr::map_dfr(top200_files_jan_2020, .f = read_snc_file)

all_snc_files_jan_2020 <- all_snc_files_jan_2020 %>%
  rename(NPDES_ID = source_id)

summary(all_snc_files_jan_2020)

if(!file.exists(here::here("snc_enf_actions.Rda"))) {
  
  temp_download <- tempfile()
  download.file(url = "https://echo.epa.gov/files/echodownloads/npdes_downloads.zip",
                destfile = temp_download)
  unzip(temp_download, files = "NPDES_FORMAL_ENFORCEMENT_ACTIONS.csv",
        exdir = here::here())
  unlink(temp_download)
  
  npdes_formal_enforce <- read.csv(here::here("NPDES_FORMAL_ENFORCEMENT_ACTIONS.csv"))
           
  npdes_formal_enforce <- npdes_formal_enforce %>%
    select(NPDES_ID, AGENCY, SETTLEMENT_ENTERED_DATE, FED_PENALTY_ASSESSED_AMT, STATE_LOCAL_PENALTY_AMT) %>%
    mutate(settlement_date = lubridate::mdy(SETTLEMENT_ENTERED_DATE)) %>%
    filter(settlement_date >= lubridate::mdy("1-1-2018"), settlement_date <= lubridate::mdy("12-31-2020"))
    
  snc_enf_actions <- all_snc_files_jan_2020 %>%
    left_join(npdes_formal_enforce) 
  

  save(snc_enf_actions, file = here::here("snc_enf_actions.Rda"))
  
}

load(here::here("snc_enf_actions.Rda"))

snc_enf_actions <- snc_enf_actions %>%
  replace_na(list(FED_PENALTY_ASSESSED_AMT = 0, STATE_LOCAL_PENALTY_AMT = 0)) %>%
  mutate(penalty = case_when(STATE_LOCAL_PENALTY_AMT > 0 ~ STATE_LOCAL_PENALTY_AMT,
                             FED_PENALTY_ASSESSED_AMT > 0 ~FED_PENALTY_ASSESSED_AMT,
                             TRUE ~ 0
                             ),
         agency = case_when(STATE_LOCAL_PENALTY_AMT > 0 ~ "State",
                             FED_PENALTY_ASSESSED_AMT > 0 ~ "EPA",
                             TRUE ~ "no penalty"
         )
         )
    

snc_enf_actions_graph <- snc_enf_actions %>%
  group_by(NPDES_ID, row_id, days_eff_exceedances, cwp_qtrs_with_snc, agency) %>%
  summarize(total_penalty = sum(penalty)) %>%
  ungroup() %>%
  group_by(NPDES_ID) %>%
  mutate(n = n())


ggplot(snc_enf_actions_graph, aes(x = row_id, y = total_penalty, color = agency)) +
  geom_point() +
  ggthemes::scale_color_colorblind() +
  theme_minimal()



ggplot(snc_enf_actions %>% filter(!is.na(agency)), 
       aes(x =  days_eff_exceedances, y = penalty, color = agency)) +
  geom_point() +
  ggthemes::scale_color_colorblind() +
  theme_minimal()



ggplot(snc_enf_actions %>% filter(!is.na(agency)), 
       aes(x =  cwp_qtrs_with_snc ,y = penalty, color = agency)) +
  geom_point() +
  ggthemes::scale_color_colorblind() +
  theme_minimal()


summary(snc_enf_actions)
sum(snc_enf_actions$penalty==0)
sum(snc_enf_actions$penalty>0)
