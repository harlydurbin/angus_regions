library(tidyverse)
library(prism)

options(prism.path = "~/regions/data/raw_data/prism")

growth_regions <- readr::read_rds(here::here("data/derived_data/growth_regions.rds"))

yrs <- 1972:2017

get_prism_annual(type = "tmean", years = yrs, keepZip = FALSE)
get_prism_annual(type = "ppt", years = yrs, keepZip = FALSE)

zips <- 
  growth_regions %>% 
  #filter(region %in% c(1, 2, 5)) %>% 
  distinct(zip, lat, lng) %>% 
  mutate(lat = round(lat, digits = 1),
         lng = round(lng, digits = 1))


reduce_prism <-
  function(file, yr, var, zips_df) {
    
    var <- rlang::enquo(var)
    
    data <-
      prism::prism_stack(file) %>%
      raster::rasterToPoints() %>%
      as_tibble() %>%
      rename(!! var := 3,
             lat = y,
             lng = x) %>%
      mutate(
        lat = round(lat, digits = 1),
        lng = round(lng, digits = 1),
        !! var := round(!! var, digits = 0)
      ) %>% 
      distinct()
    
    
    zips_df %>% 
      left_join(data) %>% 
      group_by(zip) %>% 
      mutate(!! var := mean(!! var)) %>% 
      distinct() %>% 
      mutate(year = yr)
    
  }

prism_tmean <-
  purrr::map2_df(
    .x = purrr::map_chr(.x = yrs, ~ glue::glue("PRISM_tmean_stable_4kmM2_{.x}_bil")),
    .y = yrs,
    ~ reduce_prism(
      file = .x,
      yr = .y,
      var = tmean,
      zips_df = zips
    )
  )

# annoying
ppt_paths <-
  list.dirs(path = here::here("data/raw_data/prism")) %>% 
  str_subset("ppt") %>% 
  str_remove("C:/Users/agiintern/Documents/regions/data/raw_data/prism/")


prism_ppt <-
  purrr::map2_df(
    .x = ppt_paths,
    .y = yrs,
    ~ reduce_prism(
      file = .x,
      yr = .y,
      var = ppt,
      zips_df = zips
    )
  )

prism_ppt %>% 
  group_by(year, zip) %>% 
  filter(n() > 1)

prism_zip <- full_join(prism_tmean, prism_ppt)

readr::write_rds(prism_zip, here::here("data/derived_data/prism_zip.rds"))
