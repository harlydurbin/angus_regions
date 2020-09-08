write_tworegion_data <-
  function(iter, comparison_region, df) {
    
    abbrv <-
      region_key %>%
      dplyr::filter(num == comparison_region) %>%
      dplyr::pull(abbrv)
    
    df %>%
      dplyr::filter(region %in% c(3, comparison_region)) %>%
      dplyr::select(region, format_reg, cg_new, value) %>%
      tidyr::pivot_wider(
        id_cols = c("format_reg", "cg_new"),
        names_from = "region",
        values_from = "value"
      ) %>%
      dplyr::mutate_all( ~ tidyr::replace_na(., "0"))%>%
      dplyr::arrange(`3`) %>%
      dplyr::select(format_reg, cg_new, `3`, everything()) %>%
      readr::write_delim(
        here::here(glue("data/derived_data/varcomp_ww/iter{iter}/3v{comparison_region}/data.txt")),
        delim = " ",
        col_names = FALSE
      )
  }