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
  pull_ped(refresh = FALSE) %>%
  # Add registration number formatted in same way as genotyped file
  mutate(format_reg = as.character(glue("{reg_type}~~~{registration_number}")))


## -----------------------------------------------------------------------------
# ww_data only contains weaning weights (no other values) for zip codes with >= 10 years of data
ww_data <-
  read_rds(here::here("data/derived_data/varcomp_ww/ww_data.rds")) %>%
  # Add registration number formatted in same way as genotyped file
  left_join(ped %>%
              select(full_reg, format_reg))


## -----------------------------------------------------------------------------
iter <- as.character(commandArgs(trailingOnly = TRUE)[1])


## -----------------------------------------------------------------------------
genotyped <-
  read_table2(here::here("data/raw_data/genotyped_animals.txt"),
              col_names = "format_reg")


## -----------------------------------------------------------------------------
dir.create(here::here(glue::glue("data/derived_data/varcomp_ww/iter{iter}")))


## -----------------------------------------------------------------------------
c("all", "3v1", "3v2", "3v5", "3v7", "3v8", "3v9") %>% 
  purrr::map(~ dir.create(here::here(glue::glue("data/derived_data/varcomp_ww/iter{iter}/{.x}"))))


## -----------------------------------------------------------------------------
keep_zips <-
  ww_data %>%
  group_by(region) %>%
  group_map(~ sample_until(.x,
                           # Changed to 50,000 on 9/25/20
                           limit = 50000,
                           tolerance = 500,
                           var = zip,
                           id_var = unique(.$region)) %>%
              ungroup(),
            keep = TRUE) %>%
  reduce(bind_rows) 


## -----------------------------------------------------------------------------
iter_data <-
  ww_data %>% 
  filter(zip %in% keep_zips$zip)


## -----------------------------------------------------------------------------
c(1, 2, 5, 7, 8, 9) %>%
  purrr::map(~ write_tworegion_data(iter = iter,
                                    comparison_region = .x,
                                    df = iter_data))


## -----------------------------------------------------------------------------
# Changed from 7-region analysis to treating all records as the same trait on 9/25/20
iter_data %>%
  dplyr::select(format_reg, cg_new, value) %>%
  dplyr::mutate_all(~ tidyr::replace_na(., "0")) %>%
  write_delim(here::here(glue("data/derived_data/varcomp_ww/iter{iter}/all/data.txt")),
              delim = " ",
              col_names = FALSE)


## -----------------------------------------------------------------------------
iter_ped <-
  iter_data %>% 
  select(id_new, sire_id, dam_id) %>% 
  three_gen(full_ped = ped,
            extra_cols = c("format_reg")) %>% 
  distinct() %>%
  # Reformat sire_reg and dam_reg to same format as snp_file
  left_join(ped %>%
              select(sire_reg = format_reg, sire_id = id_new)) %>%
  left_join(ped %>%
              select(dam_reg = format_reg, dam_id = id_new)) %>%
  select(format_reg, sire_reg, dam_reg) %>%
  distinct() %>%
  # Replace all missing dam and sire reg with 0
  mutate_all(~replace_na(., "0"))


## -----------------------------------------------------------------------------
c("all", "3v1", "3v2", "3v5", "3v7", "3v8", "3v9") %>%
  purrr::map( ~ write_delim(iter_ped, here::here(
    glue("data/derived_data/varcomp_ww/iter{iter}/{.x}/ped.txt")
  ),
  delim = " ",
  col_names = FALSE))


## -----------------------------------------------------------------------------
# Unsure how many genotyped samples I can use, so test for now
# May need to change zip sampling to keep genotyped animals within limit

iter_genotyped <-
  genotyped %>% 
  left_join(iter_data %>% 
               select(format_reg, region, zip)) %>% 
  filter(!is.na(region))


## -----------------------------------------------------------------------------
iter_genotyped %>%
    select(format_reg) %>%
    write_delim(here::here(glue("data/derived_data/varcomp_ww/iter{iter}/pull_list.txt")),
                delim = " ",
                col_names = FALSE)


## -----------------------------------------------------------------------------
iter_data %>%
  group_by(region, zip) %>%
  summarise(n_records = n(),
            mean_weight = mean(value)) %>%
  ungroup() %>% 
  left_join(iter_genotyped %>%
              group_by(zip) %>%
              summarise(n_genotyped = n())) %>% 
  mutate(n_genotyped = replace_na(n_genotyped, 0)) %>% 
  write_csv(here::here(glue::glue("data/derived_data/varcomp_ww/iter{iter}/varcomp_ww.data_summary.iter{iter}.csv")))

