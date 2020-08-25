# DEFUNCT

library(here)
library(readr)
library(purrr)
library(dplyr)
library(stringr)


growth_summary <-
  
  function(pattern) {
    list.files(here::here("data/derived_data/"),
               #pattern = "bw_summary|ww_summary|pwg_summary",
               pattern = pattern,
               full.names = TRUE) %>%
      # Name the elements of the list based on a stripped down version of the filepath
      set_names(nm = (basename(.) %>%
                        tools::file_path_sans_ext())) %>%
      purrr::map_dfr(read_csv, .id = "trait") %>%
      mutate(
        trait = stringr::str_extract(trait, "bw|pwg|ww"),
        effect_key = case_when(
          effect == 1 ~ "cg",
          effect == 2 ~ "bv",
          effect == 3 ~ "maternal",
          effect == 4 ~ "pe"
        )
      ) %>%
      select(trait, effect, effect_key, dplyr::everything())
    #  write_csv(here::here("data/derived_data/growth_summary.no_zero.csv"), na = "")
    
  }