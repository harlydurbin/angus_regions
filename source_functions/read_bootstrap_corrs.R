# Read in all iterations in all regions of `aireml.log` files (if they exist)
# Pull out genetic correlations

read_bootstrap_corrs <- function(iteration, r1, r2) {
  
  iter <- iteration
  
  region_key <-
    tibble::tribble(~num, ~abbrv, ~desc,
                    2, "SE", "Southeast",
                    8, "FB", "Fescue Belt",
                    3, "HP", "High Plains", 
                    5, "AP", "Arid Prairie",
                    7, "FM", "Forested Mountains", 
                    1, "D", "Desert",
                    9, "UMWNE", "Upper Midwest & Northeast")
  
  r1_abbrv <-
    region_key %>%
    dplyr::filter(num == r1) %>%
    dplyr::pull(abbrv)
  
  r2_abbrv <-
    region_key %>%
    dplyr::filter(num == r2) %>%
    dplyr::pull(abbrv)
  
  r1_desc <-
    region_key %>%
    dplyr::filter(num == r1) %>%
    dplyr::pull(desc)
  
  r2_desc <-
    region_key %>%
    dplyr::filter(num == r2) %>%
    dplyr::pull(desc)
  
  fp <-
    glue::glue("data/derived_data/bootstrap_ww/{r1}v{r2}/iter{iter}/airemlf90.iter{iter}_{r1}v{r2}.log")
  
  if (file.exists(here::here(fp))) {
    
    gmat <-
      readr::read_table2(here::here(fp),
                         skip = 9,
                         n_max = 4,
                         col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      purrr::set_names(glue::glue("{r1_abbrv} (direct)"),
                       glue::glue("{r2_abbrv} (direct)"),
                       glue::glue("{r1_abbrv} (milk)"),
                       glue::glue("{r2_abbrv} (milk)")) %>% 
      mutate(val2 = colnames(.)) %>%
      tidyr::pivot_longer(cols = -val2,
                          names_to = "val1",
                          values_to = "corr") %>% 
      mutate(iter = glue("{iter}")) 
    
    mpemat <-
      readr::read_table2(here::here(fp),
                         skip = 24,
                         n_max = 2,
                         col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>%
      purrr::set_names(glue::glue("{r1_abbrv} (MPE)"),
                       glue::glue("{r2_abbrv} (MPE)")) %>% 
      mutate(val2 = colnames(.)) %>%
      tidyr::pivot_longer(cols = -val2,
                          names_to = "val1",
                          values_to = "corr") %>% 
      mutate(iter = glue("{iter}"))      
    
    bothmat <-
      bind_rows(gmat, mpemat)
    
    return(bothmat)
    
  }
}

# Read in all iterations in all regions of `aireml.log` files (if they exist)
# Use `melt_aireml` to convert to "long" variance/covariance matrices
# Calculate heritabilities using `biv_heritability`

read_bootstrap_h2 <- function(iteration, r1, r2) {
  
  iter <- iteration
  
  run <- as.character(glue::glue("iter{iter}_{r1}v{r2}"))
  
  region_key <-
    tibble::tribble(~num, ~abbrv, ~desc,
            2, "SE", "Southeast",
            8, "FB", "Fescue Belt",
            3, "HP", "High Plains", 
            5, "AP", "Arid Prairie",
            7, "FM", "Forested Mountains", 
            1, "D", "Desert",
            9, "UMWNE", "Upper Midwest & Northeast")
  
  r1_abbrv <-
    region_key %>%
    dplyr::filter(num == r1) %>%
    dplyr::pull(abbrv)
  
  
  r2_abbrv <-
    region_key %>%
    dplyr::filter(num == r2) %>%
    dplyr::pull(abbrv)
  
  r1_desc <-
    region_key %>%
    dplyr::filter(num == r1) %>%
    dplyr::pull(desc)
  
  
  r2_desc <-
    region_key %>%
    dplyr::filter(num == r2) %>%
    dplyr::pull(desc)
  
  fp <-
    glue::glue("data/derived_data/bootstrap_ww/{r1}v{r2}/iter{iter}/airemlf90.{run}.log")
  
  if (file.exists(here::here(fp))) {
    melt_aireml(
      path = fp,
      effect2 = c(glue::glue("{r1_abbrv}_dir"),
                  glue::glue("{r2_abbrv}_dir"),
                  glue::glue("{r1_abbrv}_mat"),
                  glue::glue("{r2_abbrv}_mat")),
      effect4 = c(glue::glue("{r1_abbrv}_mpe"),
                  glue::glue("{r2_abbrv}_mpe")),
      resids = c(glue::glue("{r1_abbrv}_res"),
                 glue::glue("{r2_abbrv}_res"))) %>% 
      biv_heritability(
        abbrvs = c(r1_abbrv, r2_abbrv),
        descs = c(r1_desc, r2_desc),
        mat = TRUE,
        mpe = TRUE
      ) %>% 
      dplyr::mutate(run = run)
      
  }
}

read_bootstrap_covs <- function(iteration, r1, r2) {
  
  iter <- iteration
  
  run <- as.character(glue::glue("iter{iter}_{r1}v{r2}"))
  
  region_key <-
    tibble::tribble(~num, ~abbrv, ~desc,
            2, "SE", "Southeast",
            8, "FB", "Fescue Belt",
            3, "HP", "High Plains", 
            5, "AP", "Arid Prairie",
            7, "FM", "Forested Mountains", 
            1, "D", "Desert",
            9, "UMWNE", "Upper Midwest & Northeast")
  
  r1_abbrv <-
    region_key %>%
    dplyr::filter(num == r1) %>%
    dplyr::pull(abbrv)
  
  
  r2_abbrv <-
    region_key %>%
    dplyr::filter(num == r2) %>%
    dplyr::pull(abbrv)
  
  r1_desc <-
    region_key %>%
    dplyr::filter(num == r1) %>%
    dplyr::pull(desc)
  
  
  r2_desc <-
    region_key %>%
    dplyr::filter(num == r2) %>%
    dplyr::pull(desc)
  
  fp <-
    glue::glue("data/derived_data/bootstrap_ww/{r1}v{r2}/iter{iter}/airemlf90.{run}.log")
  
  if (file.exists(here::here(fp))) {
    melt_aireml(
      path = fp,
      effect2 = c(glue::glue("{r1_abbrv}_dir"),
                  glue::glue("{r2_abbrv}_dir"),
                  glue::glue("{r1_abbrv}_mat"),
                  glue::glue("{r2_abbrv}_mat")),
      effect4 = c(glue::glue("{r1_abbrv}_mpe"),
                  glue::glue("{r2_abbrv}_mpe")),
      resids = c(glue::glue("{r1_abbrv}_res"),
                 glue::glue("{r2_abbrv}_res")))
  }
}

