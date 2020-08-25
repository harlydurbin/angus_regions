read_snp_sol_ww <-
  function(r1, r2 = NULL, analysis) {
    run <- analysis
    
    dir <- glue::glue("data/derived_data/snp_effects_ww/{run}")
    
    msg <-
      if (is.null(r2)) {
        glue::glue("Reading results for region {r1} and {r2} from {dir}")
      } else{
        glue::glue("Reading results for region {r1} from {dir}")
      }
    
    msg
    
    # P-values
    read_table2(
      here::here(glue::glue("{dir}/chrsnp_pval")),
      col_names = c("region", "effect", "pval", "snp", "chr", "pos")
    )  %>%
      # SNP effects & weights
      left_join(read_table2(here::here(glue::glue("{dir}/snp_sol"))) %>%
                  rename(region = trait)) %>%
      rename(neglog10p = pval) %>%
      # Label regions and effects
      mutate(
        region = as.integer(region),
        region = if_else(region == 1, r1, r2),
        effect = if_else(effect == 2, "direct", "maternal"),
        # Change -log(10) values back
        pval = 10 ^ (-(neglog10p)),
        analysis = as.character(run)
      ) %>%
      # Keep only autosomes
      filter(29 >= chr) %>%
      # Remove SNPs with no pvalue
      filter(!is.nan(pval)) %>%
      left_join(read_table2(
        here::here(glue::glue("{dir}/freqdata.count.after.clean")),
        col_names = c("snp", "af", "snp_comment")
      )) #%>%
      #filter(between(af, left = 0.0099, right = 0.99))
  }


read_windows_var <-
  function(r1, r2 = NULL, analysis) {
    run <- analysis
    
    dir <- glue::glue("data/derived_data/snp_effects_ww/{run}")
    
    read_table2(
      here::here(glue::glue("{dir}/windows_variance")),
      col_names = c(
        "region",
        "effect",
        "start_snp",
        "end_snp",
        "n_snps",
        "start_win",
        "end_win",
        "window_id",
        "var_exp"
      )
    ) %>%
      mutate(
        region = as.integer(region),
        region = if_else(region == 1, r1, r2),
        effect = if_else(effect == 2, "direct", "maternal"),
        analysis = as.character(run),
        chr = str_extract(start_win, "^[[:digit:]]{1,2}(?=_)")
      ) %>%
      mutate_at(vars(contains("_win")), ~ str_remove_all(., "^[[:digit:]]{1,2}_")) %>%
      mutate_at(vars(c(contains("_win"), "chr")), ~ as.numeric(.)) %>%
      select(region, effect, analysis, chr, everything(),-window_id)
  }