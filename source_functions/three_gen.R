
# Pull out 3 generation pedigree

three_gen <-
  function(df, full_ped, extra_cols = NULL) {

    df <- 
      df %>% 
      left_join(full_ped %>% 
                  select(id_new, !!!extra_cols))
    
    sires_list <-
      df %>%
      select(id_new = sire_id) %>%
      distinct() %>%
      pull(id_new)

    sires <-
      full_ped[full_ped$id_new %in% sires_list, ]

    dams_list <-
      df %>%
      select(id_new = dam_id) %>%
      distinct() %>%
      pull(id_new)

    dams <-
      full_ped[full_ped$id_new %in% dams_list, ]


    bind_rows(df, sires, dams) %>%
      select(id_new, sire_id, dam_id, !!!extra_cols) %>%
      distinct() %>%
      mutate_at(vars(contains("id")), ~ replace_na(., 0))
  }

three_gen2 <-
  function(df, full_ped, region_id) {

    sires_list <-
      df %>%
      select(id_new = sire_id) %>%
      distinct() %>%
      pull(id_new)

    sires <-
      full_ped[full_ped$id_new %in% sires_list, ]

    dams_list <-
      df %>%
      select(id_new = dam_id) %>%
      distinct() %>%
      pull(id_new)

    dams <-
      full_ped[full_ped$id_new %in% dams_list, ]


    bind_rows(df, sires, dams) %>%
      select(id_new, sire_id, dam_id, birth_year) %>%
      distinct() %>%
      mutate(region = region_id)
  }
