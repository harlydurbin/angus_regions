# DEFUNCT

library(magrittr)
library(dplyr)
library(glue)
library(readr)

trait <- as.character(commandArgs(trailingOnly = TRUE)[1])

solution <- 
  readr::read_table2(here::here(glue::glue("data/raw_data/{trait}_solutions.txt")),
                     skip = 1,
                     col_names = c("trait", "effect", "cg_new", "solution"))

solution %>%
  filter(solution != 0) %>% 
  group_by(effect) %>% 
  summarise(mean_sol = mean(solution, na.rm = TRUE), 
            sd_sol = sd(solution, na.rm = TRUE),
            min_sol = min(solution, na.rm = TRUE),
            max_sol = max(solution, na.rm = TRUE),
            n = n()) %>% 
  write_csv(here::here(glue::glue("data/derived_data/{trait}_summary.no_zero.csv")))