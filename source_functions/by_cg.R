# Given a `df`, `trait_var`, and `effect_var`, summarise the mean `value` by contemporary group

by_cg <- 
  function(df, trait_var, effect_var){
    
    df %>% 
      filter(trait == trait_var, var == effect_var) %>% 
      group_by(cg_new) %>% 
      mutate(value = mean(value)) %>% 
      ungroup() %>% 
      select(-id_new, -full_reg) %>% 
      distinct()
  }