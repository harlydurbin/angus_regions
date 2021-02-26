#' ---
#' title: "Setup BLUPF90 breeding value calculation using Gibbs sampling results"
#' author: "Harly Durbin"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE---------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(tidyr)
library(glue)
library(magrittr)
library(tibble)
library(purrr)
library(stringr)
library(tidylog)

source(here::here("source_functions/three_gen.R"))
source(here::here("source_functions/ped.R"))

#' 
#' # Setup
#' 
## ---------------------------------------------------------------------------
dataset <- as.character(commandArgs(trailingOnly = TRUE)[1])

#' 
## ---------------------------------------------------------------------------
ped <-
  pull_ped(refresh = FALSE)

#' 
## ---------------------------------------------------------------------------
base_par <- "source_functions/par/calculate_blups.par"

#' 
## ---------------------------------------------------------------------------
blup_par <- glue("data/derived_data/calculate_blups/{dataset}/calculate_blups.par")

#' 
#' # Import data from all iterations
#' 
## ---------------------------------------------------------------------------
region_data <-
  c(1:5) %>% 
  purrr::map_dfr(~ read_table2(here::here(glue("data/derived_data/gibbs_varcomp/iter{.x}/{dataset}/data.txt")),
                               col_names = c("full_reg", "cg_num", "3", "other"))) %>% 
  distinct()

#' 
#' # Export data
#' 
## ---------------------------------------------------------------------------
region_data %>% 
  write_delim(path = here::here(glue("data/derived_data/calculate_blups/{dataset}/data.txt")),
              col_names = FALSE,
              delim = " ")

#' 
#' # Export pedigree
#' 
## ---------------------------------------------------------------------------
region_data %>% 
  distinct(full_reg) %>% 
  left_join(ped %>% 
              select(full_reg, sire_reg, dam_reg)) %>% 
  three_gen(full_ped = ped) %>% 
  write_delim(path = here::here(glue("data/derived_data/calculate_blups/{dataset}/ped.txt")),
              col_names = FALSE,
              delim = " ")

#' 
#' # # Import post-Gibbs variance components and average across all iterations
#' 
#' ## Direct & maternal effects
#' 
## ---------------------------------------------------------------------------
g_cov <-
  map_dfr(.x = c(1:5),
          ~ read_table2(here::here(glue("data/derived_data/gibbs_varcomp/iter{.x}/{dataset}/postmean")),
                        skip = 1,
                        n_max = 4,
                        col_names = FALSE) %>% 
          janitor::remove_empty(which = c("rows", "cols")) %>% 
          purrr::set_names("d_3", "d_other", "m_3", "m_other") %>% 
          mutate(val2 = colnames(.),
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
#' ## Residuals 
#' 
## ---------------------------------------------------------------------------
r_cov <-
  map_dfr(.x = c(1:5),
          ~ read_table2(here::here(glue("data/derived_data/gibbs_varcomp/iter{.x}/{dataset}/postmean")),
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
#' ## Maternal permanent environment
#' 
## ---------------------------------------------------------------------------
mpe_cov <-
  map_dfr(.x = c(1:5),
          ~ read_table2(here::here(glue("data/derived_data/gibbs_varcomp/iter{.x}/{dataset}/postmean")),
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
#' # Export averaged parameter file
#' 
## ---------------------------------------------------------------------------
read_lines(here::here(base_par),
           n_max = 9) %>% 
  write_lines(here::here(blup_par))

#' 
## ---------------------------------------------------------------------------
r_cov[[1]] %>% 
  write_lines(here::here(blup_par),
              append = TRUE)

#' 
## ---------------------------------------------------------------------------
read_lines(here::here(base_par),
           skip = 10,
           n_max = 17) %>% 
  write_lines(here::here(blup_par),
              append = TRUE)

#' 
## ---------------------------------------------------------------------------
g_cov[[1]] %>% 
  write_lines(here::here(blup_par),
              append = TRUE)

#' 
## ---------------------------------------------------------------------------
"(CO)VARIANCES_MPE" %>% 
  write_lines(here::here(blup_par),
              append = TRUE)

#' 
## ---------------------------------------------------------------------------
mpe_cov[[1]] %>% 
  write_lines(here::here(blup_par),
              append = TRUE)

#' 
## ---------------------------------------------------------------------------
read_lines(here::here(base_par),
           skip = 30) %>% 
  write_lines(here::here(blup_par),
              append = TRUE)

