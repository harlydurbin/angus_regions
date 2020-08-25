sample_group <-
  
  function(df, var, k) {
    
    var <- rlang::enquo(var)
    
    # Starting df of distict 
    # values to assign groups by
    start <-
      df %>% 
      dplyr::select(!!var) %>% 
      dplyr::distinct()
    
    # Create indexes for each row in start
    # https://gist.github.com/dsparks/3695362
    folds <-
      split(
        sample(nrow(start),
               nrow(start),
               replace = FALSE),
        as.factor(1:k))
    
    # Split start df into sub-dfs
    purrr::map(.x = folds, ~ start[.x,]) %>% 
      # Create a column for group assignment
      purrr::imap(~ dplyr::mutate(.x,
                                  k = .y)) %>% 
      # Reduce back to one df
      purrr::reduce(bind_rows) %>% 
      # attach to original df
      dplyr::right_join(df)
    
  }


# Probably should eventually adapt this to work with more than 2 k

sample_group_until <-
  
  function(df, var, per_k) {
    
    var <- rlang::enquo(var)
    
    
    
    groupsum_1 <-
      df %>% 
      group_by(!!var) %>% 
      summarise(n = n()) %>% 
      ungroup()
    
    fold_1 <- 
      tibble::tribble(~col1, ~n) %>% 
      rename(!!var := col1)
    
    # Run until enough animals 
    while(per_k >= sum(fold_1$n)) {
      
      chosen_1 <-
        # Exclude from sampling if zip is already in keep
        groupsum_1[!groupsum_1[[1]] %in% fold_1[[1]],] %>% 
        sample_n(1)
      
      x1 <- pull(chosen_1, !!var)
      
      y1 <- pull(chosen_1, n)
      
      fold_1 %<>%
        add_row(
          !!var := x1,
          n = y1
        )
      
    }
    
    groupsum_2 <-
      # starting zips for second fold exclude
      # zips in final fold 1
      groupsum_1[!groupsum_1[[1]] %in% fold_1[[1]],]
    
    fold_2 <- 
      tibble::tribble(~col1, ~n) %>% 
      rename(!!var := col1)
    
    # Run until enough animals 
    while(per_k >= sum(fold_2$n)) {
      
      chosen_2 <-
        # Exclude from sampling if zip is already in keep
        groupsum_2[!groupsum_2[[1]] %in% fold_2[[1]],] %>% 
        sample_n(1)
      
      x2 <- pull(chosen_2, !!var)
      
      y2 <- pull(chosen_2, n)
      
      fold_2 %<>%
        add_row(
          !!var := x2,
          n = y2
        )
      
    }

    fold_1 %>% 
      mutate(k = 1) %>% 
      bind_rows(fold_2 %>% 
                  mutate(k = 2)) %>% 
      select(-n) %>% 
      left_join(df)
      
  }