#' ---
#' title: "Prepare BLUPF90 output for SNP1101 GWAS"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#'
## ----setup, include=FALSE-----------------------------------------------------------------------------
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)

source(here::here("source_functions/calculate_acc.R"))

options(scipen=999)

#'
## -----------------------------------------------------------------------------------------------------
iter <- as.character(commandArgs(trailingOnly = TRUE)[1])

dataset <- as.character(commandArgs(trailingOnly = TRUE)[2])

#'
## -----------------------------------------------------------------------------------------------------
blup_dir <- glue("data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}")

postmean <- glue("data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/postmean")

region_num <- as.numeric(str_extract(dataset, "(?<=3v)[1-9]"))

#'
#' # Import solutions
#'
## -----------------------------------------------------------------------------------------------------
solutions <-
  read_table2(here::here(glue("{blup_dir}/solutions")),
              skip = 1,
              col_names = c("region",
                            "effect",
                            "id_renamed",
                            "solution",
                            "se")) %>%
  mutate(effect = case_when(effect == 1 ~ "cg_sol",
                            effect == 2 ~ "bv_sol",
                            effect == 3 ~ "mat_sol",
                            effect == 4 ~ "mpe"),
         region = if_else(region == 1, 3, region_num)) %>%
  left_join(read_table2(here::here(glue("{blup_dir}/renadd02.ped")),
                        col_names = FALSE) %>%
              select(id_renamed = X1,
                     format_reg = X10))


#'
#' # Import genetic (co)variances
#'
## -----------------------------------------------------------------------------------------------------
g_cov <-
  read_table2(here::here(postmean),
              skip = 1,
              n_max = 4,
              col_names = FALSE) %>%
  janitor::remove_empty(which = c("rows", "cols")) %>%
  purrr::set_names("d_3", "d_other", "m_3", "m_other") %>%
  mutate(val1 = colnames(.)) %>%
  tidyr::pivot_longer(cols = -val1,
                      names_to = "val2")

#'
#' # Import residual variances
#'
## -----------------------------------------------------------------------------------------------------
r_cov <-
  read_table2(here::here(postmean),
              skip = 9,
              n_max = 2,
              col_names = FALSE) %>%
  janitor::remove_empty(which = c("rows", "cols")) %>%
  purrr::set_names("r_3", "r_other") %>%
  mutate(val1 = colnames(.)) %>%
  tidyr::pivot_longer(cols = -val1,
                      names_to = "val2")

#'
#' # Pull maternal and direct (co)variances
#'
#' ## Direct-direct
#'
## -----------------------------------------------------------------------------------------------------
var_d <-
  g_cov %>%
  filter(val1 == "d_other" & val2 == "d_other") %>%
  pull(value)

#'
#' ## Maternal-maternal
#'
## -----------------------------------------------------------------------------------------------------
var_m <-
  g_cov %>%
  filter(val1 == "m_other" & val2 == "m_other") %>%
  pull(value)

#'
#' ## Direct-maternal covariance
#'
## -----------------------------------------------------------------------------------------------------
cov_md <-
  g_cov %>%
  filter(val1 == "m_other" & val2 == "d_other") %>%
  pull(value)

#'
#' ## Residual variance
#'
## -----------------------------------------------------------------------------------------------------
var_e <-
  r_cov %>%
  filter(val1 == "r_other" & val2 == "r_other") %>%
  pull(value)

#'
#' # Calculate reliability
#'
#' ## Direct effect
#'
## -----------------------------------------------------------------------------------------------------
solutions %>%
  filter(region == region_num & effect == "bv_sol") %>%
  mutate(acc = purrr::map_dbl(.x = se,
                              ~ calculate_acc(e = var_e,
                                              u = var_d,
                                              se = .x,
                                              option = "reliability")),
         Group = 1,
         acc = round(acc*100, digits = 0),
         solution = round(solution, digits = 3)) %>%
  select(ID = format_reg, Group, Obs = solution, Rel = acc) %>%
  arrange(Rel) %>%
  write_tsv(here::here(glue::glue("{blup_dir}/trait_direct.txt")))

#'
#' ## Maternal effect
#'
## -----------------------------------------------------------------------------------------------------
solutions %>%
  filter(region == region_num & effect == "mat_sol") %>%
  mutate(acc = purrr::map_dbl(.x = se,
                              ~ calculate_acc(e = var_e,
                                              u = var_m,
                                              se = .x,
                                              option = "reliability")),
         Group = 1,
         acc = round(acc*100, digits = 0),
         solution = round(solution, digits = 3)) %>%
  select(ID = format_reg, Group, Obs = solution, Rel = acc) %>%
  arrange(Rel) %>%
  write_tsv(here::here(glue::glue("{blup_dir}/trait_maternal.txt")))

#'
