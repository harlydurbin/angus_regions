
require(magrittr)
require(dplyr)

# Used to sample zip codes, contemporary groups, etc up to a certain limit
# Given a certain `limit` and `tolerance`, samples by `var` until the number of rows is `limit` +/- `tolerance`
# Iteratively populates a df called `keep` with `var`, without replacement until threshold is reached
# Tosses a random row of `var` and tries again if `limit` + `tolerance` is exceeded 

sample_until <-
  
  function(df, limit, var, tolerance, id_var) {
    var <- rlang::enquo(var)
    
    up_limit <- limit + tolerance
    down_limit <- limit - tolerance
    
    groupsum <-
      df %>%
      group_by(!!var) %>%
      summarise(n_records = n()) %>%
      ungroup()
    
    keep <-
      tibble::tribble(~ col1, ~ n_records) %>%
      rename(!!var := col1)
    
    
    # While total samples less than limit + tolerance, and greater than or equal to limit
    #while (sum(keep$n_records) <= down_limit) {
    
    repeat{
      
      chosen <-
        # Choose a random row, exclude from sampling if already in keep
        groupsum[!groupsum[[1]] %in% keep[[1]],] %>%
        sample_n(1)
      
      # Pull out zip code, CG number, whatever
      x <- pull(chosen, !!var)
      
      # Pull out corresponding n
      y <- pull(chosen, n_records)
      
      # Add to keep table
      keep %<>%
        add_row(!!var := x,
                n_records = y
        )
      
      # If total within acceptable range, quit
      if (sum(keep$n_records) <= up_limit && sum(keep$n_records) >= down_limit) {
        
        print("AHHHHH")
        
        break
        
      }
      
      # If total went beyond acceptale range, toss smallest zip and try again
      if (sum(keep$n_records) > up_limit) {
        
        print("TOO FAR")
        
        toss <-
          keep %>%
          sample_n(3)
        
        # keep %<>%
        #   arrange(desc(n_records)) %>% 
        #   head(., -1) %>%
        #   as_tibble()
        
        keep %<>%
          anti_join(toss)
        # 
      }
      
    }
    
    keep %>% 
      mutate(id = id_var)
  }
