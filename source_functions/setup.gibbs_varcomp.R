## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(magrittr)
library(glue)

source(here::here("source_functions/sample_until.R"))
source(here::here("source_functions/three_gen.R"))
source(here::here("source_functions/ped.R"))
source(here::here("source_functions/write_tworegion_data.R"))
source(here::here("source_functions/region_key.R"))


## -----------------------------------------------------------------------------
ped <-
  pull_ped(refresh = FALSE)

## -----------------------------------------------------------------------------
animal_regions <-
  read_rds(here::here("data/derived_data/import_regions/animal_regions.rds"))


## -----------------------------------------------------------------------------
iter <- as.character(commandArgs(trailingOnly = TRUE)[1])

sample_limit <- as.numeric(commandArgs(trailingOnly = TRUE)[2])


## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
dir.create(here::here(glue::glue("data/derived_data/gibbs_varcomp/iter{iter}")))


## -----------------------------------------------------------------------------
c("3v1", "3v2", "3v5", "3v7", "3v8", "3v9") %>% 
  purrr::map(~ dir.create(here::here(glue::glue("data/derived_data/gibbs_varcomp/iter{iter}/{.x}"))))


## -----------------------------------------------------------------------------
keep_zips <-
  animal_regions %>%
  group_by(region) %>%
  group_map(~ sample_until(.x,
                           # Changed to 50,000 on 9/25/20
                           limit = sample_limit,
                           tolerance = 500,
                           var = zip,
                           id_var = unique(.$region)) %>%
              ungroup(),
            keep = TRUE) %>%
  reduce(bind_rows) %>% 
  rename(region = id)

## -----------------------------------------------------------------------------
iter_data <-
  animal_regions %>% 
  filter(zip %in% keep_zips$zip)

## -----------------------------------------------------------------------------
c(1, 2, 5, 7, 8, 9) %>%
  purrr::map(~ write_tworegion_data(iter = iter,
                                    comparison_region = .x,
                                    df = iter_data))


## -----------------------------------------------------------------------------
c(1, 2, 5, 7, 8, 9) %>%
  purrr::map(~ iter_data %>%
               filter(region %in% c(3, .x)) %>% 
               select(full_reg, sire_reg, dam_reg) %>% 
               three_gen(full_ped = ped) %>% 
               write_delim(here::here(glue("data/derived_data/gibbs_varcomp/iter{iter}/3v{.x}/ped.txt")),
                           delim = " ",
                           col_names = FALSE))
  
## -----------------------------------------------------------------------------
iter_data %>%
  group_by(region, zip) %>%
  summarise(n_records = n(),
            mean_weight = mean(weight)) %>%
  ungroup() %>% 
  View()
  write_csv(here::here(glue::glue("data/derived_data/gibbs_varcomp/iter{iter}/gibbs_varcomp.data_summary.iter{iter}.csv")))

