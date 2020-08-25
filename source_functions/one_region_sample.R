library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(rlang)
library(glue)
library(magrittr)
library(purrr)
library(lubridate)
library(tidylog)


source(here::here("source_functions/ped.R"))
source(here::here("source_functions/sample_until.R"))
source(here::here("source_functions/three_gen.R"))

#### Setup ####

sample_limit <- as.numeric(commandArgs(trailingOnly = TRUE)[1])

other_region <- as.character(commandArgs(trailingOnly = TRUE)[2])

#other_region <- 8

glue("Sample limit is {sample_limit}")

glue("Comparison region is {other_region}")

#sample_limit <- 6000

set.seed(69)

# hp_zips <-
#   read_csv(here::here("data/derived_data/snp_effects_ww/hp_zips.csv"), col_types = list(col_character(), col_integer(), col_integer()))

# Full pedigree
ped <-
  pull_ped(refresh = FALSE) %>%
  mutate(format_reg = as.character(glue("{reg_type}~~~{registration_number}")))

# Read in filtered animal_regions
start <-
  read_rds(here::here("data/derived_data/bootstrap_ww_start2.rds")) %>%
  # Keep only CGs with at least 15 animals
  filter(n_animals >= 15) %>%
  # Only after 1990
  filter(year >= 1990) %>%
  # Spring born
  # filter(lubridate::month(weigh_date) %in% c(7:12)) %>%
  # Keep HP and comparison region
  filter(region %in% c(other_region)) %>% 
  left_join(ped %>%
              select(id_new, sire_id, dam_id)) 

# Read in list of genotyped animals
genotyped_all <-
  read_table2(here::here("data/raw_data/genotyped_animals.txt"), col_names = "format_reg") 

genotyped_filter <-
  genotyped_all %>%
  left_join(start %>%
              # TEST
              select(region, format_reg, zip, weigh_date) %>%
              distinct()) %>%
  filter(region %in% c(other_region)) %>% 
  # filter(lubridate::month(weigh_date) %in% c(7:12)) %>%
  group_by(zip) %>%
  mutate(n_records = n()) %>%
  ungroup()


total_geno <-
  genotyped_filter %>%
  filter(n_records >= 5) %>%
  filter(region == other_region) %>%
  # filter(lubridate::month(weigh_date) %in% c(7:12)) %>%
  tally() %>%
  pull(n)



#### Choose zipcodes ####

ww_zips <-

  if (total_geno >= sample_limit) {
    genotyped_filter %>%
      filter(region == other_region) %>%
      # At least 5 genotyped animals per zip
      filter(n_records >= 5) %>%
      select(-n_records) %>%
      sample_until(
        # limit = number of genotyped animals
        # in next most populous region
        limit = sample_limit,
        tolerance = 100,
        var = zip,
        id_var = other_region
      ) %>%
      select(zip, n_records, region = id)
  } else {
    genotyped_filter %>%
      filter(region == other_region) %>%
      filter(n_records >= 5) %>%
      distinct(zip, n_records, region)

  }

ww_zips %<>%
  mutate(
    zip = as.character(zip),
    n_records = as.integer(n_records),
    region = as.integer(region)
  )


# ww_zips <-
#   genotyped %>%
#   # TEST
#   # filter(n_records >= 15) %>%
#   filter(region %in% c(3, other_region)) %>%
#   # TEST
#   filter(lubridate::month(weigh_date) %in% c(7:12)) %>%
#   # In order to easier calculate maternal effects
#   group_by(region) %>%
#   group_map(~ sample_until(
#     .x,
#     limit = 2720,
#     tolerance = 100,
#     var = zip,
#     id_var = unique(.$region)),
#     keep = TRUE) %>%
#   reduce(bind_rows)

start %>% 
  filter(zip %in% ww_zips$zip) %>% 
  group_by(region) %>%
  tally()

#### Write out data ####

start %>%
  filter(zip %in% ww_zips$zip) %>%
  select(region, format_reg, cg_new, value) %>%
  spread(region, value) %>%
  mutate_all(~ replace_na(., "0")) %>%
  #arrange(`3`) %>%
  select(format_reg, cg_new, everything()) %>%
  write_delim(here::here(
    glue(
      "data/derived_data/snp_effects_ww/{other_region}_all/data.txt"
    )
  ),
  delim = " ",
  col_names = FALSE)

#### Write out pedigree ####

# Pull out animals in start from ww_zip
start_ped <-
  start %>%
  filter(zip %in% ww_zips$zip) %>%
  select(id_new, sire_id, dam_id) %>%
  # Three generation pedigree using old IDs
  # keep column of reg numbers formatted in the same way as snp_file
  three_gen(full_ped = ped, extra_cols = c("format_reg")) %>%
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

write_delim(start_ped, here::here(
  glue(
    "data/derived_data/snp_effects_ww/{other_region}_all/ped.txt"
  )
),
delim = " ",
col_names = FALSE)

#### List of genotyped animals to pull from master genotype file ####

genotyped_all %>%
  # left_join(
  #   start %>%
  #     filter(zip %in% ww_zips$zip) %>%
  #     filter(region %in% c(3, other_region)) %>%
  #     filter(lubridate::month(weigh_date) %in% c(7:12)) %>%
  #     select(format_reg, full_reg)
  # ) %>%
  # filter(!is.na(full_reg)) %>%
  # TEST
  filter(format_reg %in% start_ped$format_reg) %>%
  select(format_reg) %>%
  write_delim(here::here(
    glue(
      "data/derived_data/snp_effects_ww/{other_region}_all/pull_genotypes.txt"
    )
  ),
  delim = " ",
  col_names = FALSE)

glue("{length(unique(start_ped$format_reg))} animals in pedigree")
glue("{genotyped_all %>% filter(format_reg %in% start_ped$format_reg) %>% tally() %>% pull(n)} animals in pedigree with genotypes")


start %>%
  filter(zip %in% ww_zips$zip) %>%
  left_join(genotyped_filter %>%
              mutate(genid = row_number()) %>%
              select(format_reg, genid)) %>%
  group_by(region) %>%
  summarise(
    n = n(),
    n_gen = n_distinct(genid),
    n_zip = n_distinct(zip),
    n_cg = n_distinct(cg_new)
  ) %>%
  write_delim(here::here(
    glue(
      "data/derived_data/snp_effects_ww/{other_region}_all/sample_stats.txt"
    )
  ),
  delim = " ")
