read_gibbs_samples <- function(iteration, region) {
  
  fp <- glue::glue("data/derived_data/gibbs_varcomp/iter{iteration}/3v{region}/postgibbs_samples")
  
  if (file.exists(here::here(fp))) {
    
    readr::read_table2(here::here(fp),
                       col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      dplyr::mutate(iter = iteration,
                    dataset = glue::glue("3v{region}"))
  }
}

read_gibbs_mce <- function(iteration, region) {
  
  fp <- glue::glue("data/derived_data/gibbs_varcomp/iter{iteration}/3v{region}/postout")
  
  if (file.exists(here::here(fp))) {
    
    readr::read_table2(here::here(fp),
                       skip = 4,
                       n_max = 14,
                       col_names = c("param", "eff1", "eff2", "trt1", "trt2", "mce", "mean", "hdp", "effective_sample_size", "median", "mode")) %>% 
      dplyr::select(-eff1, -eff2, -trt1, -trt2) %>% 
      dplyr::mutate(param = dplyr::case_when(param == "1" ~ "d1d1",
                                             param == "2" ~ "d1d2",
                                             param == "3" ~ "d1m1",
                                             param == "4" ~ "d1m2",
                                             param == "5" ~ "d2d2",
                                             param == "6" ~ "d2m1",
                                             param == "7" ~ "d2m2",
                                             param == "8" ~ "m1m1",
                                             param == "9" ~ "m1m2",
                                             param == "10" ~ "m2m2",
                                             param == "11" ~ "mpe1mpe1",
                                             param == "12" ~ "mpe2mpe2",
                                             param == "13" ~ "r1r1",
                                             param == "14" ~ "r2r2"),
                    iter = iteration,
                    dataset = glue::glue("3v{region}"),
                    effective_sample_size = abs(effective_sample_size)) 
    
  }
  
}

read_gibbs_psd <- function(iteration, region) {
  
  fp <- glue::glue("data/derived_data/gibbs_varcomp/iter{iteration}/3v{region}/postout")
  
  if (file.exists(here::here(fp))) {
    
    readr::read_table2(here::here(fp),
                       skip = 22,
                       n_max = 14,
                       col_names = c("param", "eff1", "eff2", "trt1", "trt2", "psd", "mean", "psd_interval_lo", "psd_interval_hi", "geweke", "auto_lag1", "auto_lag10", "auto_lag50", "independent_batches")) %>% 
      dplyr::select(-eff1, -eff2, -trt1, -trt2) %>% 
      dplyr::mutate(param = dplyr::case_when(param == "1" ~ "d1d1",
                                             param == "2" ~ "d1d2",
                                             param == "3" ~ "d1m1",
                                             param == "4" ~ "d1m2",
                                             param == "5" ~ "d2d2",
                                             param == "6" ~ "d2m1",
                                             param == "7" ~ "d2m2",
                                             param == "8" ~ "m1m1",
                                             param == "9" ~ "m1m2",
                                             param == "10" ~ "m2m2",
                                             param == "11" ~ "mpe1mpe1",
                                             param == "12" ~ "mpe2mpe2",
                                             param == "13" ~ "r1r1",
                                             param == "14" ~ "r2r2"),
                    iter = iteration,
                    dataset = glue::glue("3v{region}"),
                    geweke = abs(geweke)) 
  }
  
}

read_gibbs_corr <- function(iteration, dataset) {
  
  fp <- glue::glue("data/derived_data/gibbs_varcomp/iter{iteration}/3v{dataset}/postmeanCorr")
  
  if (file.exists(here::here(fp))) {
    corrmat <-
      readr::read_table2(here::here(fp),
                         skip = 1,
                         n_max = 4,
                         col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      purrr::set_names("3_dir", glue("{dataset}_dir"), "3_mat", glue("{dataset}_mat"))
    
    corrmat %>%
      tibble::as.tibble() %>% 
      dplyr::mutate(val1 = colnames(.)) %>%
      tidyr::pivot_longer(-val1,
                          names_to = "val2",
                          values_to = "corr") %>% 
      dplyr::filter(!is.na(corr)) %>% 
      mutate(iter = iteration)
  
  }
}

read_gibbs_varcov <- function(iteration, dataset) {
  
  fp <- glue("data/derived_data/gibbs_varcomp/iter{iteration}/3v{dataset}/postmean")
  
  if (file.exists(here::here(fp))) {
    
    g_cov <-
      read_table2(here::here(fp),
                  skip = 1,
                  n_max = 4,
                  col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      purrr::set_names("3_dir", glue("{dataset}_dir"), "3_mat", glue("{dataset}_mat")) %>% 
      dplyr::mutate(val1 = colnames(.)) %>%
      tidyr::pivot_longer(-val1,
                          names_to = "val2",
                          values_to = "var_cov") 
    
    mpe_cov <-
      read_table2(here::here(fp),
                  skip = 6,
                  n_max = 2,
                  col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      purrr::set_names("3_mpe", glue("{dataset}_mpe")) %>% 
      dplyr::mutate(val1 = colnames(.)) %>%
      tidyr::pivot_longer(-val1,
                          names_to = "val2",
                          values_to = "var_cov")
    
    r_cov <-
      read_table2(here::here(fp),
                  skip = 9,
                  n_max = 2,
                  col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      purrr::set_names("r3", glue("r{dataset}")) %>% 
      dplyr::mutate(val1 = colnames(.)) %>%
      tidyr::pivot_longer(-val1,
                          names_to = "val2",
                          values_to = "var_cov") 
    
    bind_rows(g_cov,
              mpe_cov,
              r_cov) %>% 
      mutate(iter = iteration)
    
  }
}

read_gibbs_h2 <- function(iteration, dataset) {
  
  source(here::here("source_functions/region_key.R"))
  
  
  desc1 <- "High Plains"
  
  desc2 <- 
    region_key %>% 
    filter(num == dataset) %>% 
    pull(desc)
  
  varcov <-
    read_gibbs_varcov(iteration = iteration, 
                    dataset = dataset) 
  
  if(!is.null(varcov)){
    varcov %<>% 
      biv_heritability(abbrvs = c("3", as.character(dataset)),
                     descs = c(desc1, desc2),
                     mat = TRUE,
                     mpe = TRUE) %>% 
    mutate(iter = iteration)
    
    return(varcov)
  }
}