
# Pull out 3 generation pedigree

three_gen <-
  function(df, full_ped, extra_cols = NULL) {

    df <- 
      if(!is.null(extra_cols)) {
        df %>% 
          left_join(full_ped %>% 
                  select(full_reg, !!!extra_cols)) 
        } else df
    
    # List of unique sires in sample
    sires_list <-
      df %>%
      distinct(sire_reg) %>%
      pull(sire_reg)

    # Pull out parentage info for list of uniqe sires in sample
    # i.e., rows where sire is the individual
    sires <-
      full_ped[full_ped$full_reg %in% sires_list, ]
    
    # Repeat for dams
    dams_list <-
      df %>%
      distinct(dam_reg) %>%
      pull(dam_reg)

    dams <-
      full_ped[full_ped$full_reg %in% dams_list, ]

    bind_rows(df, sires, dams) %>%
      select(full_reg, sire_reg, dam_reg, !!!extra_cols) %>%
      distinct() %>%
      mutate_at(vars(contains("reg")), ~ replace_na(., 0))
  }
