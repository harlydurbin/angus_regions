aireml_long <-
  
  function(df) {
    
    
    df %>%
      mutate(val1 = colnames(.)) %>%
      reshape2::melt(value.name = "var_cov", id = c("val1")) %>%
      mutate(val2 = as.character(variable)) %>%
      select(-variable)
    
  }

# Converts all matrices in `aireml.log` to dataframe of variances and covariances
# First, read in entire file and convert to df where each row is a line of `aireml.log`
# Parse dataframe into its component matrices corresponding to effects, convert matrices to 2-column "long" format
# Bind "long" matrices, resulting in df of variances and covariances with columns `val1`, `val2`, and `var_cov`

melt_aireml <-

  
  function(path, effect1 = NULL, effect2 = NULL, effect3 = NULL, effect4 = NULL, effect5 = NULL, resids) {
    
    # Convert entire file
    raw <- 
      # Read in as one string
      readr::read_file(here::here(path)) %>% 
      # Split string into strings by newline
      stringr::str_split("\n") %>% 
      # Remove extraneous space from strings
      purrr::map(~ str_squish(.x)) %>% 
      # Convert list of strings to nested data frame
      tibble::tibble() %>% 
      # Rename column
      rename(c1 = 1) %>% 
      # Results in one line per row in df
      unnest(c1)
    
    # Row numbers of where to find variance/covariance matrices
    rownum1 <- which(str_detect(raw$c1, "Genetic variance\\(s\\) for effect 1"))
    
    rownum2 <- which(str_detect(raw$c1, "Genetic variance\\(s\\) for effect 2"))
    
    rownum3 <- which(str_detect(raw$c1, "Genetic variance\\(s\\) for effect 3"))
    
    rownum4 <- which(str_detect(raw$c1, "Genetic variance\\(s\\) for effect 4"))
    
    rownum5 <- which(str_detect(raw$c1, "Genetic variance\\(s\\) for effect 5"))
    
    rownum_res <- which(str_detect(raw$c1, "Residual variance\\(s\\)"))
    
    
    mat1 <-
      if(!is.null(effect1)) {
        
        raw %>% 
          slice(
            (rownum1 + 1):(rownum1 + as.integer(length(effect1)))
          ) %>% 
          separate(c1, sep = " ", into = effect1) %>% 
          aireml_long()
        
      
      } 
    
  
    
    mat2 <- 
      if(!is.null(effect2)){
        raw %>% 
          slice(
            (rownum2 + 1):(rownum2 + as.integer(length(effect2)))
          ) %>% 
          separate(c1, sep = " ", into = effect2) %>% 
          aireml_long()
      }


    mat3 <-
      if(!is.null(effect3)){
        raw %>%
          slice(
            (rownum3 + 1):(rownum3 + as.integer(length(effect3)))
          ) %>%
          separate(c1, sep = " ", into = effect3) %>%
          aireml_long()
      }


    mat4 <-
      if(!is.null(effect4)){
        raw %>%
          slice(
            (rownum4 + 1):(rownum4 + as.integer(length(effect4)))
          ) %>%
          separate(c1, sep = " ", into = effect4) %>%
          aireml_long()
      }

    mat5 <-
      if(!is.null(effect5)){
        raw %>%
          slice(
            (rownum5 + 1):(rownum5 + as.integer(length(effect5)))
          ) %>%
          separate(c1, sep = " ", into = effect5) %>%
          aireml_long()
      }
    
    
    resmat <-
      raw %>% 
      slice(
        (rownum_res + 1):(rownum_res + as.integer(length(resids)))
      ) %>% 
      separate(c1, sep = " ", into = resids) %>% 
      aireml_long()
    
    
    bind_rows(mat1, mat2, mat3, mat4, mat5, resmat) %>% 
      select(val1, val2, var_cov) %>% 
      mutate(var_cov = as.numeric(var_cov))
    
     }
