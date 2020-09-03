## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(magrittr)
library(tidylog)

source(here::here("source_functions/sample_until.R"))
source(here::here("source_functions/three_gen.R"))


## ------------------------------------------------------------------------

cg_regions <- readr::read_rds(here::here("data/derived_data/cg_regions.rds"))
animal_regions <- readr::read_rds(here::here("data/derived_data/animal_regions.rds"))
ped <- read_rds(here::here("data/derived_data/ped.rds"))
growth_pheno <- read_rds(here::here("data/derived_data/growth_pheno.rds"))



## ------------------------------------------------------------------------

start <-
  animal_regions %>%
  # Only weaning weights
  filter(trait == "ww") %>%
  filter(var == "weight") %>%
  # Only region 2 or 3
  filter(region %in% c(2, 3)) %>%
  left_join(ped) %>%
  # Keep only contemporary groups with 15 or more animals
  filter(n_animals >= 15) %>%
  group_by(cg_new) %>%
  # Remove single sire single dam contemporary groups
  filter(n_distinct(sire_id) > 1) %>%
  filter(n_distinct(dam_id) > 1) %>%
  ungroup() %>%
  group_by(zip) %>%
  # At least 10 years of data
  filter(n_distinct(year) >= 10) %>%
  ungroup()




## ------------------------------------------------------------------------
start %>% 
  select(reg_type, reg) %>% 
  distinct() %>% 
  write_csv(here::here("data/derived_data/reg_2v3.csv"),
            col_names = FALSE)


## ------------------------------------------------------------------------

# Find multi-region sires as a starting point
prolific <-
  start %>% 
  # How many calves per region does each sire have?
  group_by(sire_id, region) %>%
  tally() %>%
  ungroup() %>%
  group_by(sire_id) %>%
  filter(n_distinct(region) == 2) %>% 
  ungroup() %>% 
  tidyr::pivot_wider(
    id_cols = c("sire_id"),
    names_from = region,
    values_from = n,
    names_prefix = "n_"
  ) %>% 
  mutate(total = n_2 + n_3) %>% 
  # At least 100 calves in each region
  filter(n_2 >=100) %>% 
  filter(n_3 >= 100) %>% 
  arrange(desc(total))
  


## ------------------------------------------------------------------------
prol_zips <-
  prolific %>% 
  left_join(start) %>% 
  select(region, zip) %>% 
  distinct()


## ------------------------------------------------------------------------
se_keep <-
  cg_regions %>% 
  filter(trait == "ww") %>% 
  filter(cg_new %in% start$cg_new) %>% 
  filter(zip %in% prol_zips$zip & region == 2) %>% 
  group_by(zip) %>%
  summarise(n_years = n_distinct(year),
            n_records = sum(n_animals)) %>% 
  ungroup() %>% 
  # summarise(sum(n_records))
  sample_until(limit = 150000)


se_keep %>% 
  summarise(sum(n_records), 
            n_distinct(zip))


## ------------------------------------------------------------------------
hp_keep <-
  cg_regions %>% 
  filter(trait == "ww") %>% 
  filter(cg_new %in% start$cg_new) %>% 
  filter(zip %in% prol_zips$zip & region == 3) %>% 
  group_by(zip) %>%
  summarise(n_years = n_distinct(year),
            n_records = sum(n_animals)) %>% 
  ungroup() %>% 
  # summarise(sum(n_records))
  sample_until(limit = 150000)


hp_keep %>% 
  summarise(sum(n_records), 
            n_distinct(zip))


## ------------------------------------------------------------------------
se_hp <- 
  bind_rows(se_keep, hp_keep) %>% 
  distinct()


## ----univariate data-----------------------------------------------------

start %>% 
  filter(zip %in% se_hp$zip) %>% 
  mutate(key = 
           case_when(
             region == 2 ~ "SE",
             region == 3 ~ "HP"
           )) %>% 
  select(key, id_new, cg_new, value) %>% 
  group_by(key) %>% 
  group_walk(~ write_delim(.x,
                           path = here::here(
                             glue::glue("data/f90/190729_2v3/{.y}/data.{.y}.txt")
                             ),
                           delim = " ",
                           col_names = FALSE))



## ----univariate pedigrees------------------------------------------------
start %>% 
  filter(zip %in% se_hp$zip) %>% 
  mutate(key = 
           case_when(
             region == 2 ~ "SE",
             region == 3 ~ "HP"
           )) %>% 
  select(key, id_new) %>% 
  left_join(ped %>%
              select(1:3)) %>% 
  group_by(key) %>%
  group_map( ~ three_gen(df = .x, full_ped = ped), keep = TRUE) %>%
  set_names(c("HP", "SE")) %>% 
  iwalk(~ write_delim(
    .x,
    path = here::here(glue::glue(
      "data/f90/190729_2v3/{.y}/ped.{.y}.txt"
    )),
    delim = " ",
    col_names = FALSE
  ))



## ----bivariate data------------------------------------------------------
c("data/f90/190729_2v3/SE/data.SE.txt", "data/f90/190729_2v3/HP/data.HP.txt") %>% 
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
  write_delim(here::here("data/f90/190729_2v3/data.SE_HP.txt"),
              delim = " ",
              col_names = FALSE)


## ------------------------------------------------------------------------

c("data/f90/190729_2v3/SE/ped.SE.txt", "data/f90/190729_2v3/HP/ped.HP.txt") %>%
  purrr::map_dfr( ~ read_table2(here::here(.x),
                                col_names = c("id_new", "sire_id", "dam_id"))) %>% 
  distinct() %>% 
  write_delim(
    here::here("data/f90/190729_2v3/ped.SE_HP.txt"),
    delim = " ",
    col_names = FALSE
  )


