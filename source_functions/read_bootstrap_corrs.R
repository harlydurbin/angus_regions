# Read in all iterations in all regions of `aireml.log` files (if they exist)
# Pull out genetic correlations

read_bootstrap_corrs <- function(iteration, r1, r2) {
  
  iter <- iteration
  
  region_key <-
    tribble(~num, ~abbrv, ~desc,
            2, "SE", "Southeast",
            8, "FB", "Fescue Belt",
            3, "HP", "High Plains", 
            5, "AP", "Arid Prairie",
            7, "FM", "Forested Mountains", 
            1, "D", "Desert",
            9, "UMWNE", "Upper Midwest & Northeast")
  
  r1_abbrv <-
    region_key %>%
    filter(num == r1) %>%
    pull(abbrv)
  
  
  r2_abbrv <-
    region_key %>%
    filter(num == r2) %>%
    pull(abbrv)
  
  r1_desc <-
    region_key %>%
    filter(num == r1) %>%
    pull(desc)
  
  
  r2_desc <-
    region_key %>%
    filter(num == r2) %>%
    pull(desc)
  
  fp <-
    glue::glue("data/derived_data/bootstrap_ww/{r1}v{r2}/iter{iter}/airemlf90.iter{iter}_{r1}v{r2}.log")
  
  if (file.exists(here::here(fp))) {
    
    corrmat <-
      read_table2(
        here::here(fp),
        skip = 9,
        n_max = 4,
        col_names = c(
          glue("{r1_abbrv} (direct)"),
          glue("{r2_abbrv} (direct)"),
          glue("{r1_abbrv} (milk)"),
          glue("{r2_abbrv} (milk)")
        )
      ) %>% 
      as.matrix()
    
    # Only take the upper diagonal to get rid of duplicates
    corrmat[lower.tri(corrmat, diag = TRUE)] <- na_dbl
    
    corrmat %>%
      as.tibble() %>% 
      mutate(effect_1 = colnames(.)) %>%
      tidyr::pivot_longer(-effect_1,
                          names_to = "effect_2",
                          values_to = "corr") %>% 
      filter(!is.na(corr))
    
  }
}

# Read in all iterations in all regions of `aireml.log` files (if they exist)
# Use `melt_aireml` to convert to "long" variance/covariance matrices
# Calculate heritabilities using `biv_heritability`

read_bootstrap_covs <- function(iteration, r1, r2) {
  
  iter <- iteration
  
  run <- as.character(glue("iter{iter}_{r1}v{r2}"))
  
  region_key <-
    tribble(~num, ~abbrv, ~desc,
            2, "SE", "Southeast",
            8, "FB", "Fescue Belt",
            3, "HP", "High Plains", 
            5, "AP", "Arid Prairie",
            7, "FM", "Forested Mountains", 
            1, "D", "Desert",
            9, "UMWNE", "Upper Midwest & Northeast")
  
  r1_abbrv <-
    region_key %>%
    filter(num == r1) %>%
    pull(abbrv)
  
  
  r2_abbrv <-
    region_key %>%
    filter(num == r2) %>%
    pull(abbrv)
  
  r1_desc <-
    region_key %>%
    filter(num == r1) %>%
    pull(desc)
  
  
  r2_desc <-
    region_key %>%
    filter(num == r2) %>%
    pull(desc)
  
  fp <-
    glue::glue("data/derived_data/bootstrap_ww/{r1}v{r2}/iter{iter}/airemlf90.{run}.log")
  
  if (file.exists(here::here(fp))) {
    melt_aireml(
      path = fp,
      effect2 = c(
        glue("{r1_abbrv}_dir"),
        glue("{r2_abbrv}_dir"),
        glue("{r1_abbrv}_mat"),
        glue("{r2_abbrv}_mat")
      ),
      effect4 = c(glue("{r1_abbrv}_mpe"), glue("{r2_abbrv}_mpe")),
      resids = c(glue("{r1_abbrv}_res"), glue("{r2_abbrv}_res"))
    ) %>% 
      biv_heritability(
        abbrvs = c(r1_abbrv, r2_abbrv),
        descs = c(r1_desc, r2_desc),
        mat = TRUE,
        mpe = TRUE
      ) %>% 
      mutate(run = run)
      
  }
}


