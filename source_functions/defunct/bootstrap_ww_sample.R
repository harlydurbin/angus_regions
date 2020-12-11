## ----setup, include=FALSE------------------------------------------------
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

region_key <-
  tribble(~num, ~abbrv, ~desc,
          2, "SE", "Southeast",
          8, "FB", "Fescue Belt",
          3, "HP", "High Plains",
          5, "AP", "Arid Prairie",
          7, "FM", "Forested Mountains",
          1, "D", "Desert",
          9, "UMWNE", "Upper Midwest & Northeast")


## ------------------------------------------------------------------------
iter <- as.character(commandArgs(trailingOnly = TRUE)[1])

other_region <- as.character(commandArgs(trailingOnly = TRUE)[2])

## ------------------------------------------------------------------------
#start <- read_rds(here::here("data/derived_data/bootstrap_ww_start2.rds"))

start <- read_rds(here::here("data/derived_data/varcomp_ww/ww_data.rds"))


## ------------------------------------------------------------------------
#ped <- read_rds(here::here("data/derived_data/ped.rds"))

ped <-
  pull_ped(refresh = FALSE)

## ------------------------------------------------------------------------
ww_zips <-
  start %>%
  filter(region %in% c(3, other_region)) %>%
  # In order to easier calculate maternal effects
  group_by(zip) %>%
  filter(n_distinct(year) >= 10) %>%
  ungroup() %>%
  group_by(region) %>%
  group_map(~ sample_until(
    .x,
    limit = 100000,
    tolerance = 1000,
    var = zip,
    id_var = unique(.$region)),
    keep = TRUE) %>%
  reduce(bind_rows)


## ------------------------------------------------------------------------
write_biv <-
  function(region2) {

    abbrv <-
      region_key %>%
      filter(num == region2) %>%
      pull(abbrv)

    start %>%
      filter(zip %in% ww_zips$zip) %>%
      filter(region %in% c(3, region2)) %>%
      select(region, id_new, cg_new, value) %>%
      spread(region, value) %>%
      mutate_all( ~ replace_na(., "0")) %>%
      arrange(`3`) %>%
      select(id_new, cg_new, `3`, everything()) %>%
      write_delim(
        here::here(glue("data/derived_data/bootstrap_ww/3v{region2}/iter{iter}/data.txt")),
        delim = " ",
        col_names = FALSE
      )
  }


## ------------------------------------------------------------------------
# list("1", "2", "5", "7", "8", "9") %>%
# walk(~ write_biv(region2 = .x))

write_biv(region2 = other_region)

## ------------------------------------------------------------------------
write_biv_ped <-
  function(region2) {

    abbrv <-
      region_key %>%
      filter(num == region2) %>%
      pull(abbrv)

    start %>%
      filter(zip %in% ww_zips$zip) %>%
      filter(region %in% c(3, region2)) %>%
      select(id_new, sire_id, dam_id) %>%
      three_gen(full_ped = ped) %>%
      distinct() %>%
      write_delim(
        here::here(glue("data/derived_data/bootstrap_ww/3v{region2}/iter{iter}/ped.txt")),
      delim = " ",
      col_names = FALSE)

  }

write_biv_ped(region2 = other_region)

## ------------------------------------------------------------------------
# list("1", "2", "5", "7", "8", "9") %>%
# walk(~ write_biv_ped(region2 = .x))
