# Since BLUPF90 re-uses CG numbers across traits, match records up to the correct CG number based on order in which traits occur in the `renf90.tables`

slice_cg_new <-
 
   function(df, trait_var, trait_order) {
    
    single <-
      df %>% 
      filter(trait == trait_var) %>% 
      left_join(renf90) %>%
      group_by(cg_old) %>% 
      filter(n() == 1) %>% 
      ungroup()
    
    multi <-
      df %>% 
      filter(trait == trait_var) %>% 
      left_join(renf90) %>%
      group_by(cg_old) %>% 
      filter(n() > 1) %>% 
      slice(trait_order) %>% 
      ungroup()
    
    bind_rows(single, multi)
    
  }