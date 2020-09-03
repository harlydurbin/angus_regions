library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(rlang)
library(glue)
library(magrittr)
library(purrr)
library(tidylog)

##### Select HP sample set #####

source(here::here("source_functions/sample_until.R"))

sample_limit <- as.numeric(commandArgs(trailingOnly = TRUE)[1])

#sample_limit <- 6000

glue("Sample limit is {sample_limit}")

# Read in filtered animal_regions
start <-
  read_rds(here::here("data/derived_data/bootstrap_ww_start2.rds")) %>%
  # Keep only CGs with at least 15 animals
  filter(n_animals >= 15) %>%
  filter(year >= 1990)


genotyped <-
  read_table2(here::here("data/raw_data/genotyped_animals.txt"), col_names = "format_reg") %>%
  left_join(start %>%
              # TEST
              select(region, format_reg, zip, weigh_date) %>%
              distinct()) %>%
  group_by(zip) %>%
  mutate(n_records = n()) %>%
  ungroup()


hp_zips <-
  # Downsample High Plains animals to compare against
  # region of interest
  genotyped %>%
  filter(region == 3) %>%
  filter(n_records >= 5) %>%
  select(-n_records) %>%
  sample_until(
    limit = sample_limit,
    tolerance = 100,
    var = zip,
    id_var = 3
  ) %>%
  select(zip, n_records, region = id)


hp_zips %>%
  write_csv(here::here("data/derived_data/snp_effects_ww/hp_zips.csv"))
