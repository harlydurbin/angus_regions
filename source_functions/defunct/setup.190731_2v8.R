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
  filter(region %in% c(2, 8)) %>%
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
  ungroup() %>% 
  filter(herd_state != "CA")


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
  mutate(total = n_2 + n_8) %>% 
  # At least 100 calves in each region
  filter(n_2 >=100) %>% 
  filter(n_8 >= 100) %>% 
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
  sample_until(limit = 100000)


se_keep %>% 
  summarise(sum(n_records), 
            n_distinct(zip))


## ------------------------------------------------------------------------

fb_keep <-
  cg_regions %>% 
  filter(trait == "ww") %>% 
  filter(cg_new %in% start$cg_new) %>% 
  filter(zip %in% prol_zips$zip & region == 8) %>% 
  group_by(zip) %>%
  summarise(n_years = n_distinct(year),
            n_records = sum(n_animals)) %>% 
  ungroup() %>% 
  # summarise(sum(n_records))
  sample_until(limit = 100000)


fb_keep %>% 
  summarise(sum(n_records), 
            n_distinct(zip))


## ------------------------------------------------------------------------
se_fb <- 
  bind_rows(se_keep, fb_keep) %>% 
  distinct()


## ----univariate data-----------------------------------------------------

start %>% 
  filter(zip %in% se_fb$zip) %>% 
  mutate(key = 
           case_when(
             region == 2 ~ "SE",
             region == 8 ~ "FB"
           )) %>% 
  select(key, id_new, cg_new, value) %>% 
  group_by(key) %>% 
  group_walk(~ write_delim(.x,
                           path = here::here(
                             glue::glue("data/f90/190731_2v8/{.y}/data.{.y}.txt")
                             ),
                           delim = " ",
                           col_names = FALSE))



## ----univariate pedigrees------------------------------------------------
start %>% 
  filter(zip %in% se_fb$zip) %>% 
  mutate(key = 
           case_when(
             region == 2 ~ "SE",
             region == 8 ~ "FB"
           )) %>% 
  select(key, id_new) %>% 
  left_join(ped %>%
              select(1:3)) %>% 
  group_by(key) %>%
  group_map( ~ three_gen(df = .x, full_ped = ped), keep = TRUE) %>%
  set_names(c("FB", "SE")) %>% 
  iwalk(~ write_delim(
    .x,
    path = here::here(glue::glue(
      "data/f90/190731_2v8/{.y}/ped.{.y}.txt"
    )),
    delim = " ",
    col_names = FALSE
  ))



## ----bivariate data------------------------------------------------------
c("data/f90/190731_2v8/SE/data.SE.txt", "data/f90/190731_2v8/FB/data.FB.txt") %>% 
  purrr::map_dfr(~read_table2(here::here(.x), 
                              col_names = c("id_new", "cg_new", "weight"))) %>% 
  left_join(
    cg_regions %>% 
      filter(trait == "ww") %>% 
      select(cg_new, region)
  ) %>% 
  mutate(region = glue::glue("region_{region}")) %>% 
  tidyr::spread(region, weight) %>% 
  mutate_all(~ replace_na(., "0")) %>% 
  arrange(region_2) %>% 
  write_delim(here::here("data/f90/190731_2v8/data.SE_FB.txt"),
              delim = " ",
              col_names = FALSE)


## ----bivariate ped-------------------------------------------------------

c("data/f90/190731_2v8/SE/data.SE.txt", "data/f90/190731_2v8/FB/data.FB.txt") %>%
  purrr::map_dfr( ~ read_table2(here::here(.x),
                                col_names = c("id_new", "cg_new", "weight"))) %>% 
  select(id_new) %>% 
  left_join(ped %>% 
              select(1:3)) %>% 
  three_gen(full_ped = ped) %>% 
  distinct() %>% 
  write_delim(
    here::here("data/f90/190731_2v8/ped.SE_FB.txt"),
    delim = " ",
    col_names = FALSE
  )


