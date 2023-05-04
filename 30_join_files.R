library(tidytable)
library(lubridate)

load(here::here("data", "R_data_files", "npdes_eff_viols.Rdata"))

npdes_eff_viols <- npdes_eff_viols %>%
  mutate.(monitoring_period = mdy(MONITORING_PERIOD_END_DATE)) %>%
  select.(-MONITORING_PERIOD_END_DATE) %>%
  filter.(monitoring_period > ymd("2014-01-01"), monitoring_period < ymd("2022-01-01")) %>%
  mutate.(monitoring_period = ceiling_date(monitoring_period, "month") - days(1))

all_viol_dates <- seq(as.Date("2014-02-01"), length=96, by="1 month") - 1

sort(unique(npdes_eff_viols$monitoring_period))

all_viol_npdes <- unique(npdes_eff_viols$NPDES_ID)



npdes_complete <- crossing.(all_viol_npdes, all_viol_dates) %>%
  rename.(NPDES_ID = all_viol_npdes, monitoring_period = all_viol_dates) %>%
  left_join.(npdes_eff_viols) %>%
  mutate_across.(.cols = c(D80, D90, E90), replace_na., replace = 0) %>%
  mutate.(D80_24 = data.table::frollsum(D80, 24),
          D90_24 = data.table::frollsum(D90, 24),
          E90_24 = data.table::frollsum(E90, 24)) %>%
  filter.(!is.na(E90_24)) %>%
  select.(-E90, -D80, -D90)


load(here::here("data", "R_data_files", "npdes_formal_enforce.Rdata"))

npdes_formal_enforcement <- npdes_formal_enforcement %>%
  mutate.(monitoring_period = ceiling_date(mdy(SETTLEMENT_ENTERED_DATE), "month") - days(1))

npdes_formal_enforcement <- npdes_formal_enforcement %>%
  filter.(monitoring_period > ymd("2016-01-01")) %>%
  mutate.(FED_PENALTY_ASSESSED_AMT = replace_na.(FED_PENALTY_ASSESSED_AMT, 0),
          STATE_LOCAL_PENALTY_AMT = replace_na.(STATE_LOCAL_PENALTY_AMT, 0))

npdes_joined <- npdes_formal_enforcement %>%
  left_join.(npdes_complete) %>%
  filter.(!is.na(D80_24) & !is.na(D90_24) & !is.na(E90_24)) 

library(ggplot2)

ggplot(npdes_joined %>% filter.(E90_24 > 0), aes(x = E90_24, y = FED_PENALTY_ASSESSED_AMT)) +
  geom_point() +
  theme_minimal()

ggplot(npdes_joined %>% filter.(E90_24 > 0), aes(x = E90_24, y = STATE_LOCAL_PENALTY_AMT)) +
  geom_point() +
  theme_minimal()


ggplot(npdes_joined %>% filter.(D90_24 > 0), aes(x = D90_24, y = FED_PENALTY_ASSESSED_AMT)) +
  geom_point() +
  theme_minimal()

ggplot(npdes_joined %>% filter.(D90_24 > 0), aes(x = D90_24, y = STATE_LOCAL_PENALTY_AMT)) +
  geom_point() +
  theme_minimal()



ggplot(npdes_joined %>% filter.(D90_24 > 0), aes(x = D80_24, y = FED_PENALTY_ASSESSED_AMT)) +
  geom_point() +
  theme_minimal()

ggplot(npdes_joined %>% filter.(D90_24 > 0), aes(x = D80_24, y = STATE_LOCAL_PENALTY_AMT)) +
  geom_point() +
  theme_minimal()
