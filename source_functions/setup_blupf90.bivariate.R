#' ---
#' title: "Untitled"
#' author: "Harly Durbin"
#' date: "10/26/2020"
#' output: html_document
#' ---
#'
## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(tidyr)
library(glue)
library(stringr)
library(magrittr)
library(tibble)
library(purrr)
library(ggplot2)
library(rlang)
library(tidylog)

source(here::here("source_functions/three_gen.R"))


#'
## ------------------------------------------------------------------------
dataset <- as.character(commandArgs(trailingOnly = TRUE)[1])

#'
#' # Setup
#'
## ------------------------------------------------------------------------
ped <- read_rds(here::here("data/derived_data/import_regions/ped.rds")) %>%
  # Add registration number formatted in same way as genotyped file
  mutate(format_reg = as.character(glue("{reg_type}~~~{registration_number}")))

#'
## ------------------------------------------------------------------------
# ww_data only contains weaning weights (no other values) for zip codes with >= 10 years of data
ww_data <-
  read_rds(here::here("data/derived_data/varcomp_ww/ww_data.rds")) %>%
  # Add registration number formatted in same way as genotyped file
  left_join(ped %>%
              select(full_reg, format_reg))

#'
## ------------------------------------------------------------------------
genotyped <-
  read_table2(here::here("data/raw_data/genotyped_animals.txt"),
              col_names = "format_reg")

#'
#' # Import data across iterations: use all phenotypes from region 3 and the comparison region across all iterations
#'
## ------------------------------------------------------------------------
alliter <-
  c(1:5) %>%
  purrr::map_dfr(~ read_table2(here::here(glue::glue("data/derived_data/varcomp_ww/iter{.x}/{dataset}/gibbs/data.txt")),
                               col_names = c("format_reg", "cg_num", "ww_3", "ww_other"))) %>%
  distinct()

#'
#' # Export data
#'
## ------------------------------------------------------------------------
alliter %>%
  write_delim(here::here(glue("data/derived_data/gwas_ww.gibbs/{dataset}/data.txt")),
              delim = " ",
              col_names = FALSE)

#'
#' # Three-generation pedigree
#'
## ------------------------------------------------------------------------
dataset_ped <-
  alliter %>%
  select(format_reg) %>%
  left_join(ww_data %>%
              select(format_reg, id_new, sire_id, dam_id)) %>%
  three_gen(full_ped = ped,
            extra_cols = "format_reg") %>%
  # Reformat sire_reg and dam_reg to same format as snp_file
  left_join(ped %>%
              select(sire_reg = format_reg, sire_id = id_new)) %>%
  left_join(ped %>%
              select(dam_reg = format_reg, dam_id = id_new)) %>%
  select(format_reg, sire_reg, dam_reg) %>%
  distinct() %>%
  # Replace all missing dam and sire reg with 0
  mutate_all(~replace_na(., "0"))


#'
## ------------------------------------------------------------------------
dataset_ped %>%
  write_delim(here::here(glue("data/derived_data/gwas_ww.gibbs/{dataset}/ped.txt")),
              delim = " ",
              col_names = FALSE)

#'
#' # Genotyped pull list
#'
## ------------------------------------------------------------------------
alliter %>%
  select(format_reg) %>%
  distinct() %>%
  left_join(genotyped %>%
              mutate(genotyped = TRUE)) %>%
  filter(genotyped == TRUE) %>%
  select(format_reg) %>%
  write_delim(here::here(glue("data/derived_data/gwas_ww.gibbs/{dataset}/pull_list.txt")),
              delim = " ",
              col_names = FALSE)

#'
