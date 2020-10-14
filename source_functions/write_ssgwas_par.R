#' ---
#' title: "Write ssGWAS param files using estimated variance components"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)

#' 
## ----------------------------------------------------------------------------
iteration <- 5

dataset <- 2

#' 
## ----------------------------------------------------------------------------
fp <- glue("data/derived_data/varcomp_ww/iter{iteration}/3v{dataset}/gibbs/postmean")

#' 
## ----------------------------------------------------------------------------
#par_out <- glue("data/derived_data/ssgwas_ww/iter{iteration}/3v{dataset}/univariate_ssgwas.par")

par_out <- "test2.par"

#' 
#' 
#' 
## ----------------------------------------------------------------------------
g_cov <-
  read_table2(here::here(fp),
              skip = 1,
              n_max = 4,
              col_names = FALSE) %>% 
  janitor::remove_empty(which = c("rows", "cols")) %>% 
  purrr::set_names("d_3", "d_other", "m_3", "m_other") %>% 
  mutate(rowname = colnames(.)) %>% 
  filter(str_detect(rowname, "other")) %>% 
  select(contains("other"))

#' 
## ----------------------------------------------------------------------------
r_cov <-
  read_table2(here::here(fp),
              skip = 9,
              n_max = 2,
              col_names = FALSE) %>% 
  janitor::remove_empty(which = c("rows", "cols")) %>% 
  purrr::set_names("r_3", "r_other") %>% 
  mutate(rowname = colnames(.)) %>% 
  filter(str_detect(rowname, "other")) %>% 
  select(contains("other"))

#' 
## ----------------------------------------------------------------------------
mpe_cov <-
  read_table2(here::here(fp),
              skip = 6,
              n_max = 2,
              col_names = FALSE) %>% 
  janitor::remove_empty(which = c("rows", "cols")) %>% 
  purrr::set_names("mpe_3", "mpe_other") %>% 
  mutate(rowname = colnames(.)) %>% 
  filter(str_detect(rowname, "other")) %>% 
  select(contains("other"))  

#' 
## ----------------------------------------------------------------------------
read_lines(here::here("source_functions/par/ssgwas.par"),
           n_max = 9) %>% 
  write_lines(here::here(par_out))

#' 
## ----------------------------------------------------------------------------
r_cov %>% 
  pull(r_other) %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ----------------------------------------------------------------------------
read_lines(here::here("source_functions/par/ssgwas.par"),
           skip = 10,
           n_max = 19) %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ----------------------------------------------------------------------------

#' 
## ----------------------------------------------------------------------------
list(glue("{g_cov[[1]][1]} {g_cov[[1]][2]}"), glue("{g_cov[[2]][1]} {g_cov[[2]][2]}"), "(CO)VARIANCES_MPE", glue("{mpe_cov[[1]][1]}")) %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ----------------------------------------------------------------------------
read_lines(here::here("source_functions/par/ssgwas.par"),
           skip = 33,
           n_max = 11) %>% 
  write_lines(here::here(par_out),
              append = TRUE)

