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


## ----import--------------------------------------------------------------

cg_regions <- readr::read_rds(here::here("data/derived_data/cg_regions.rds"))
animal_regions <- readr::read_rds(here::here("data/derived_data/animal_regions.rds"))
ped <- read_rds(here::here("data/derived_data/ped.rds"))
growth_pheno <- read_rds(here::here("data/derived_data/growth_pheno.rds"))



## ----hp zips-------------------------------------------------------------
# Choose HP zipcodes 
zips_keep <-
  cg_regions %>%
  filter(region %in% c(3) & trait == "ww") %>%
  filter(n_animals >= 5) %>%
  group_by(zip) %>%
  filter(n_distinct(year) >= 10) %>%
  summarise(n_years = n_distinct(year),
            n_records = sum(n_animals)) %>%
  arrange(desc(n_years)) %>%
  ungroup() %>%
  # Sample zip codes up to ~ 100,000 animals
  sample_until(limit = 100000)
  
  
zips_keep %>% 
  summarise(sum(n_records), 
            n_distinct(zip))


## ----subset data---------------------------------------------------------
# Use the same SE animals that I used for the last run
se_hp <-
  read_table2(
  here::here("data/f90/190723_2v9/SE/data.SE.txt"),
  col_names = c("id_new", "cg_new", "weight")
) %>%
  left_join(
    animal_regions %>%
      filter(trait == "ww" & var == "weight") %>%
      select(-value,-var)) %>%
  mutate(key = "SE") %>% 
  bind_rows(
    zips_keep %>%
      left_join(
        cg_regions %>%
          filter(trait == "ww" & n_animals >= 5)) %>%
      mutate(key = "HP") %>% 
      select(
             cg_new,
             key
             ) %>%
      left_join(
        animal_regions %>%
          filter(trait == "ww" & var == "weight")) %>% 
      select(-var) %>% 
      rename(weight = value)
  )

  


## ----univariate data-----------------------------------------------------

se_hp %>% 
  select(key, id_new, cg_new, weight) %>% 
  group_by(key) %>% 
  group_walk(~ write_delim(.x,
                           path = here::here(
                             glue::glue("data/f90/190725_2v3/{.y}/data.{.y}.txt")
                             ),
                           delim = " ",
                           col_names = FALSE))



## ----univariate pedigrees------------------------------------------------

se_hp %>%
  select(key, id_new) %>%
  left_join(ped %>%
              select(1:3)) %>% 
  group_by(key) %>%
  group_map( ~ three_gen(df = .x, full_ped = ped), keep = TRUE) %>%
  set_names(c("HP", "SE")) %>% 
  iwalk(~ write_delim(
    .x,
    path = here::here(glue::glue(
      "data/f90/190725_2v3/{.y}/ped.{.y}.txt"
    )),
    delim = " ",
    col_names = FALSE
  ))



## ----bivariate data------------------------------------------------------
c("data/f90/190725_2v3/SE/data.SE.txt", "data/f90/190725_2v3/HP/data.HP.txt") %>% 
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
  write_delim(here::here("data/f90/190725_2v3/data.SE_HP.txt"),
              delim = " ",
              col_names = FALSE)


## ----bivariate pedigrees-------------------------------------------------
c("data/f90/190725_2v3/SE/ped.SE.txt", "data/f90/190725_2v3/HP/ped.HP.txt") %>%
  purrr::map_dfr( ~ read_table2(here::here(.x),
                                col_names = c("id_new", "sire_id", "dam_id"))) %>% 
  distinct() %>% 
  write_delim(
    here::here("data/f90/190725_2v3/ped.SE_HP.txt"),
    delim = " ",
    col_names = FALSE
  )



## ----hi v lo-------------------------------------------------------------

hi_lo <-
  cg_regions %>%
  # working with WW
  filter(trait == "ww" & var == "cg_sol") %>%
  filter(n_animals > 4) %>%
  group_by(region) %>%
  # Bin into thirds by region
  # Pull year
  mutate(rank = ntile(x = value, n = 3)) %>%
  ungroup() %>%
  right_join(
    c(
      "data/f90/190725_2v3/SE/data.SE.txt",
      "data/f90/190725_2v3/HP/data.HP.txt"
    ) %>%
      purrr::map_dfr( ~ read_table2(
        here::here(.x),
        col_names = c("id_new", "cg_new", "weight")
      ))
  ) %>% 
  # group_by(region, rank) %>% 
  # summarise(mean(value),
  #           mean(weight))
  # Rank is backwards than what I thought oops
  # I.e., 3 is best
  mutate(keep = 
           case_when(
             region == 3 & rank == 3 ~ "keep",
             region == 2 & rank == 1 ~ "keep"
           )) %>% 
  filter(keep == "keep") 

hi_lo %>% 
  mutate(region = glue::glue("region_{region}")) %>% 
  tidyr::spread(region, weight) %>% 
  mutate_at(vars(contains("region_")), funs(replace_na(., "0"))) %>%
  select(id_new, cg_new, region_2, region_3) %>%
  write_delim(here::here("data/f90/190725_2v3/hi_lo/data.hi_lo.txt"),
              delim = " ",
              col_names = FALSE) 

hi_lo %>% 
  select(id_new) %>% 
  left_join(ped) %>% 
  three_gen(full_ped = ped) %>% 
  distinct() %>% 
  write_delim(
    here::here("data/f90/190725_2v3/hi_lo/ped.hi_lo.txt"),
    delim = " ",
    col_names = FALSE
  )

read_table2(here::here("data/f90/190725_2v3/hi_lo/data.hi_lo.txt"), col_names = FALSE)


