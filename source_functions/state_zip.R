require(readxl)
require(dplyr)
require(janitor)
require(maps)

## DEFUNCT

zcta <-
  read_excel(here::here("data/raw_data/state-geocodes-v2016.xls"),
             skip = 5) %>%
  janitor::clean_names() %>%
  rename(fips = state_fips,
         state_name = name) %>%
  filter(fips != "00") %>%
  left_join(
    read_excel(here::here(
      "data/raw_data/state-geocodes-v2016.xls"
    ),
    skip = 5) %>%
      janitor::clean_names() %>%
      filter(state_fips == "00") %>%
      rename(div_name = name) %>%
      select(-state_fips),
    by = c("region", "division")
  ) %>%
  left_join(
    maps::state.fips %>%
      select(fips, abb) %>%
      mutate(
        fips = as.character(fips),
        fips = str_pad(
          fips,
          width = 2,
          side = "left",
          pad = "0"
        )
      ) %>%
      distinct()
  ) %>%
  # Didn't have Alaska and Hawaii for some reason??
  mutate(abb =
           case_when(fips == "02" ~ "AK",
                     fips == "15" ~ "HI",
                     TRUE ~ abb)) %>%
  select(fips:abb) %>%
  right_join(
    # https://gis.stackexchange.com/questions/53918/determining-which-us-zipcodes-map-to-more-than-one-state-or-more-than-one-city
    # http://www2.census.gov/geo/docs/maps-data/data/rel/zcta_place_rel_10.txt
    read_csv(
      here::here("data/raw_data/zcta_place_rel_10.csv")
    ) %>%
      janitor::clean_names() %>%
      rename(fips = state) %>% 
      mutate(
        fips = as.character(fips),
        fips = str_pad(
          fips,
          width = 2,
          side = "left",
          pad = "0"
        )
      ) %>%
      select(zcta5, fips) %>%
      rename(zip = zcta5) %>%
      distinct()
  ) %>%
  # remove PR
  filter(!is.na(abb))


