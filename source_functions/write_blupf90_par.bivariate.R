#' ---
#' title: "Write ssGWAS param files using estimated variance components"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#'
## ----setup, include=FALSE--------------------------------------------------
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)

#'
## --------------------------------------------------------------------------
iteration <- as.character(commandArgs(trailingOnly = TRUE)[1])

dataset <- as.character(commandArgs(trailingOnly = TRUE)[2])

par_in <- "source_functions/par/blupf90.bivariate.par"

#'
## ----------------------------------------------------------------------------
fp <- glue("data/derived_data/varcomp_ww/iter{iteration}/{dataset}/gibbs/postmean")

#'
## ----------------------------------------------------------------------------
par_out <- glue("data/derived_data/gwas_ww.gibbs/iter{iteration}/{dataset}/blupf90.par")

#'
#'
#'
## --------------------------------------------------------------------------
g_cov <-
  read_table2(here::here(fp),
              skip = 1,
              n_max = 4,
              col_names = FALSE) %>%
  janitor::remove_empty(which = c("rows", "cols")) %>%
  purrr::set_names("d_3", "d_other", "m_3", "m_other") %>%
  mutate(string = glue("{d_3} {d_other} {m_3} {m_other}"))

#'
## --------------------------------------------------------------------------
r_cov <-
  read_table2(here::here(fp),
              skip = 9,
              n_max = 2,
              col_names = FALSE) %>%
  janitor::remove_empty(which = c("rows", "cols")) %>%
  purrr::set_names("r_3", "r_other") %>%
  mutate(string = glue("{r_3} {r_other}"))

#'
## --------------------------------------------------------------------------
mpe_cov <-
  read_table2(here::here(fp),
              skip = 6,
              n_max = 2,
              col_names = FALSE) %>%
  janitor::remove_empty(which = c("rows", "cols")) %>%
  purrr::set_names("mpe_3", "mpe_other") %>%
  mutate(string = glue("{mpe_3} {mpe_other}"))


#'
## --------------------------------------------------------------------------
read_lines(here::here(par_in),
           n_max = 9) %>%
  write_lines(here::here(par_out))

#'
#'
## --------------------------------------------------------------------------
r_cov[[3]] %>%
  write_lines(here::here(par_out),
              append = TRUE)

#'
## --------------------------------------------------------------------------
read_lines(here::here(par_in),
           skip = 11,
           n_max = 19) %>%
  write_lines(here::here(par_out),
              append = TRUE)

#'
## --------------------------------------------------------------------------
g_cov[[5]] %>%
  write_lines(here::here(par_out),
              append = TRUE)

#'
## --------------------------------------------------------------------------
"(CO)VARIANCES_MPE" %>%
  write_lines(here::here(par_out),
              append = TRUE)

#'
#'
## --------------------------------------------------------------------------
mpe_cov[[3]] %>%
  write_lines(here::here(par_out),
              append = TRUE)

#'
## --------------------------------------------------------------------------
read_lines(here::here(par_in),
           skip = 37) %>%
  write_lines(here::here(par_out),
              append = TRUE)
