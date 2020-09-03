## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(tidylog)

source(here::here("source_functions/sample_until.R"))
source(here::here("source_functions/three_gen.R"))


## ---- eval = TRUE--------------------------------------------------------
cg_regions <- readr::read_rds(here::here("data/derived_data/cg_regions.rds"))
animal_regions <- readr::read_rds(here::here("data/derived_data/animal_regions.rds"))
ped <- read_rds(here::here("data/derived_data/ped.rds"))
growth_pheno <- read_rds(here::here("data/derived_data/growth_pheno.rds"))



## ----choose zips, eval = TRUE--------------------------------------------
  
zips_keep <-
  cg_regions %>%
  filter(region %in% c(2) & trait == "ww") %>%
  filter(n_animals >= 5) %>%
  group_by(zip) %>%
  filter(n_distinct(year) >= 10) %>%
  summarise(n_years = n_distinct(year),
            n_records = sum(n_animals)) %>%
  arrange(desc(n_years)) %>%
  ungroup() %>%
  # Sample zip codes up to ~ 100,000 animals
  sample_until(limit = 100000) %>%
  mutate(key = "SE")
  bind_rows(
    cg_regions %>%
      filter(region %in% c(9) & trait == "ww") %>%
      filter(n_animals >= 5) %>%
      group_by(zip) %>%
      filter(n_distinct(year) >= 10) %>%
      summarise(n_years = n_distinct(year),
                n_records = sum(n_animals)) %>%
      arrange(desc(n_years)) %>%
      ungroup() %>%
      # Sample zip codes up to ~ 100,000 animals
      sample_until(limit = 100000) %>% 
      mutate(key = "UMWNE")
  ) 
 


## ----subset data, eval = TRUE--------------------------------------------

se_umwne <-
  zips_keep %>% 
  left_join(
    cg_regions %>% 
      filter(trait == "ww" & n_animals >= 5) 
  ) %>% 
  select(
    cg_sol = value,
    cg_new,
    key
  ) %>% 
  left_join(
    animal_regions %>% 
      filter(trait == "ww" & var == "weight")
  )



## ----univariate data, eval = TRUE----------------------------------------

se_umwne %>% 
  select(key, id_new, cg_new, value) %>% 
  group_by(key) %>% 
  group_walk(~ write_delim(.x,
                           path = here::here(
                             glue::glue("data/f90/190718_2v9/{.y}/data.{.y}.txt")
                             ),
                           delim = " ",
                           col_names = FALSE))




## ----univariate pedigree, eval = TRUE------------------------------------

se_umwne %>% 
  select(key, id_new) %>% 
  left_join(
    ped %>% 
      select(1:3)
    ) %>% 
  group_by(key) %>% 
  group_map(~ three_gen(df = .x, full_ped = ped)) %>% 
  walk(~ write_delim(.x,
                           path = here::here(
                             glue::glue("data/f90/190718_2v9/{.x}/ped.{.x}.txt")
                             ),
                           delim = " ",
                           col_names = FALSE))



## ----bivariate data, eval = TRUE-----------------------------------------

c("data/f90/190718_2v9/SE/data.SE.txt", "data/f90/190718_2v9/UMWNE/data.UMWNE.txt") %>% 
  purrr::map_dfr(~read_table2(here::here(.x), 
                              col_names = c("id_new", "cg_new", "weight"))) %>% 
  left_join(
    cg_regions %>% 
      filter(trait == "ww") %>% 
      select(cg_new, region)
  ) %>% 
  mutate(region = glue::glue("region_{region}")) %>% 
  tidyr::spread(region, weight) %>% 
  mutate_all(funs(replace_na(., "0"))) %>% 
  write_delim(here::here("data/f90/190718_2v9/data.SE_UMWNE.txt"),
              delim = " ",
              col_names = FALSE)



## ----bivariate pedigree, eval = TRUE-------------------------------------

c("data/f90/190718_2v9/SE/data.SE.txt", "data/f90/190718_2v9/UMWNE/data.UMWNE.txt") %>%
  purrr::map_dfr( ~ read_table2(here::here(.x),
                                col_names = c("id_new", "cg_new", "weight"))) %>%
  left_join(cg_regions %>%
              filter(trait == "ww") %>%
              select(cg_new, region)) %>% 
  left_join(ped) %>% 
  select(id_new, sire_id, dam_id) %>% 
  write_delim(
    here::here("data/f90/190718_2v9/ped.SE_UMWNE.txt"),
    delim = " ",
    col_names = FALSE
  )

