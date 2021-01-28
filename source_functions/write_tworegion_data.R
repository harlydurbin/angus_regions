write_tworegion_data <-
  function(iter, comparison_region, df) {

    df %>%
      dplyr::filter(region %in% c(3, comparison_region)) %>%
      dplyr::select(region, full_reg, cg_new, weight) %>%
      tidyr::pivot_wider(id_cols = c("full_reg", "cg_new"),
                         names_from = "region",
                         values_from = "weight") %>%
      dplyr::mutate_all( ~ tidyr::replace_na(., "0"))%>%
      dplyr::arrange(`3`) %>%
      dplyr::select(full_reg, cg_new, `3`, everything()) %>%
      readr::write_delim(here::here(glue("data/derived_data/gibbs_varcomp/iter{iter}/3v{comparison_region}/data.txt")),
                         delim = " ",
                         col_names = FALSE)
  }