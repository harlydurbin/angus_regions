#' ---
#' title: "Write ssGWAS param files using estimated variance components"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)
library(purrr)

#' 
## ------------------------------------------------------------------------
dataset <- as.character(commandArgs(trailingOnly = TRUE)[1])

#' 
## ------------------------------------------------------------------------
par_out <- glue("data/derived_data/gwas_ww.gibbs/{dataset}/blupf90.par")

#' 
## ------------------------------------------------------------------------
par_in <- "source_functions/par/blupf90.bivariate.par"

#' 
## ------------------------------------------------------------------------
g_cov <-
  map_dfr(.x = c(1:5),
          ~ read_table2(here::here(glue("data/derived_data/varcomp_ww/iter{.x}/{dataset}/gibbs/postmean")),
                        skip = 1,
                        n_max = 4,
                        col_names = FALSE) %>% 
          janitor::remove_empty(which = c("rows", "cols")) %>% 
          purrr::set_names("d_3", "d_other", "m_3", "m_other") %>% 
          mutate(val2 = colnames(.),
                 dataset = dataset,
                 iter = .x) %>%
          tidyr::pivot_longer(cols = c("d_3", "d_other", "m_3", "m_other"),
                              names_to = "val1",
                              values_to = "varcov")) %>% 
  group_by(val1, val2) %>% 
  summarise(varcov = mean(varcov)) %>% 
  tidyr::pivot_wider(names_from = val2, values_from = varcov) %>% 
  arrange(val1) %>% 
  mutate(string = glue("{d_3} {d_other} {m_3} {m_other}")) %>%
  select(string, everything())

#' 
## ------------------------------------------------------------------------
r_cov <-
  map_dfr(.x = c(1:5),
          ~ read_table2(here::here(glue("data/derived_data/varcomp_ww/iter{.x}/{dataset}/gibbs/postmean")),
                        skip = 9,
                        n_max = 2,
                        col_names = FALSE) %>% 
            janitor::remove_empty(which = c("rows", "cols")) %>% 
            purrr::set_names("r_3", "r_other") %>% 
            mutate(val2 = colnames(.),
                   dataset = dataset,
                   iter = .x) %>% 
            tidyr::pivot_longer(cols = c("r_3", "r_other"),
                                names_to = "val1",
                                values_to = "varcov")) %>% 
  group_by(val1, val2) %>% 
  summarise(varcov = mean(varcov)) %>% 
  tidyr::pivot_wider(names_from = val2, values_from = varcov) %>% 
  arrange(val1) %>% 
  mutate(string = glue("{r_3} {r_other}")) %>% 
  select(string, everything())

#' 
## ------------------------------------------------------------------------
mpe_cov <-
  map_dfr(.x = c(1:5),
          ~ read_table2(here::here(glue("data/derived_data/varcomp_ww/iter{.x}/{dataset}/gibbs/postmean")),
                        skip = 6,
                        n_max = 2,
                        col_names = FALSE) %>% 
            janitor::remove_empty(which = c("rows", "cols")) %>% 
            purrr::set_names("mpe_3", "mpe_other") %>% 
            mutate(val2 = colnames(.),
                   dataset = dataset,
                   iter = .x) %>% 
            tidyr::pivot_longer(cols = c("mpe_3", "mpe_other"),
                                names_to = "val1",
                                values_to = "varcov")) %>% 
  group_by(val1, val2) %>% 
  summarise(varcov = mean(varcov)) %>% 
  tidyr::pivot_wider(names_from = val2, values_from = varcov) %>% 
  arrange(val1) %>% 
  mutate(string = glue("{mpe_3} {mpe_other}")) %>% 
  select(string, everything())

#' 
## ------------------------------------------------------------------------
read_lines(here::here(par_in),
           n_max = 9) %>% 
  write_lines(here::here(par_out))

#' 
#' 
## ------------------------------------------------------------------------
r_cov[[1]] %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ------------------------------------------------------------------------
read_lines(here::here(par_in),
           skip = 11,
           n_max = 19) %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ------------------------------------------------------------------------
g_cov[[1]] %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ------------------------------------------------------------------------
"(CO)VARIANCES_MPE" %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ------------------------------------------------------------------------
mpe_cov[[1]] %>% 
  write_lines(here::here(par_out),
              append = TRUE)

#' 
## ------------------------------------------------------------------------
read_lines(here::here(par_in),
           skip = 37) %>% 
  write_lines(here::here(par_out),
              append = TRUE)

