#' ---
#' title: "Write AIREML parameter files using Gibbs sampling results"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE-----------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)
library(purrr)

#' 
#' # Setup
#' 
## -----------------------------------------------------------------
iter <- as.character(commandArgs(trailingOnly = TRUE)[1])

dataset <- as.character(commandArgs(trailingOnly = TRUE)[2])

#' 
## -----------------------------------------------------------------
gibbs_path <- glue("data/derived_data/gibbs_varcomp/iter{iter}/{dataset}")

#aireml_par <- glue("data/derived_data/aireml_varcomp/iter{iter}/{dataset}/aireml_varcomp.par")

aireml_par <- "test.par"

base_par <- "source_functions/par/aireml_varcomp.par"

#' 
#' # Import post-Gibbs variance components
#' 
#' ## Direct & maternal effects
#' 
## -----------------------------------------------------------------
g_cov <-
  read_table2(here::here(glue("{gibbs_path}/postmean")),
              skip = 1,
              n_max = 4,
              col_names = FALSE) %>% 
  janitor::remove_empty(which = c("rows", "cols")) %>% 
  purrr::set_names("d_3", "d_other", "m_3", "m_other") %>% 
  mutate(string = glue("{d_3} {d_other} {m_3} {m_other}")) %>% 
  select(string, everything())

#' 
#' ## Residuals
#' 
## -----------------------------------------------------------------
r_cov <-
  read_table2(here::here(glue("{gibbs_path}/postmean")),
              skip = 9,
              n_max = 2,
              col_names = FALSE) %>% 
  janitor::remove_empty(which = c("rows", "cols")) %>% 
  purrr::set_names("r_3", "r_other") %>% 
  mutate(string = glue("{r_3} {r_other}")) %>% 
  select(string, everything())

#' 
#' ## Maternal permanent environment
#' 
## -----------------------------------------------------------------
mpe_cov <-
  read_table2(here::here(glue("{gibbs_path}/postmean")),
              skip = 6,
              n_max = 2,
              col_names = FALSE) %>% 
  janitor::remove_empty(which = c("rows", "cols")) %>% 
  purrr::set_names("mpe_3", "mpe_other") %>% 
  mutate(string = glue("{mpe_3} {mpe_other}")) %>% 
  select(string, everything())

#' 
#' # Export parameter file
#' 
## -----------------------------------------------------------------
read_lines(here::here(base_par),
           n_max = 9) %>% 
  write_lines(here::here(aireml_par))

#' 
## -----------------------------------------------------------------
r_cov[[1]] %>% 
  write_lines(here::here(aireml_par),
              append = TRUE)

#' 
## -----------------------------------------------------------------
read_lines(here::here(base_par),
           skip = 10,
           n_max = 17) %>% 
  write_lines(here::here(aireml_par),
              append = TRUE)

#' 
## -----------------------------------------------------------------
g_cov[[1]] %>% 
  write_lines(here::here(aireml_par),
              append = TRUE)

#' 
## -----------------------------------------------------------------
"(CO)VARIANCES_MPE" %>% 
  write_lines(here::here(aireml_par),
              append = TRUE)

#' 
## -----------------------------------------------------------------
mpe_cov[[1]] %>% 
  write_lines(here::here(aireml_par),
              append = TRUE)

#' 
## -----------------------------------------------------------------
read_lines(here::here(base_par),
           skip = 30) %>% 
  write_lines(here::here(aireml_par),
              append = TRUE)

