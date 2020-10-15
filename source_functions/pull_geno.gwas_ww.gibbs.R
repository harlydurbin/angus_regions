library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(magrittr)
library(glue)

genotyped <-
  read_table2(here::here("data/raw_data/genotyped_animals.txt"),
              col_names = "full_reg")

iter <- as.character(commandArgs(trailingOnly = TRUE)[1])

fp <- glue("data/derived_data/varcomp_ww/iter{iter}/3v1/gibbs/ped.txt")

all_animals <-
  read_table2(here::here(fp),
              col_names = c("full_reg", "sire_reg", "dam_reg")) %>%
  select(full_reg) %>%
  bind_rows(read_table2(here::here(fp),
                        col_names = c("full_reg", "sire_reg", "dam_reg")) %>%
              select(full_reg = sire_reg)) %>%
  bind_rows(read_table2(here::here(fp),
                        col_names = c("full_reg", "sire_reg", "dam_reg")) %>%
              select(full_reg = dam_reg)) %>%
  distinct() %>%
  left_join(genotyped %>%
              mutate(genotyped = TRUE)) %>%
  filter(genotyped == TRUE)

all_animals %>%
  select(full_reg) %>%
  write_delim(here::here(glue("data/derived_data/gwas_ww.gibbs/iter{iter}/pull_list.txt")),
              delim = " ",
              col_names = FALSE)
