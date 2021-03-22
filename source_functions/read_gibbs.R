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
                       col_names = c("param", "eff1", "eff2", "trt1", "trt2", "mce", "mean", "hpd_lo", "hpd_hi", "effective_sample_size", "median", "mode", "idependent_chain_size")) %>% 
      dplyr::select(-eff1, -eff2, -trt1, -trt2) %>% 
      dplyr::mutate(param = dplyr::case_when(param == "1" ~ "dir1dir1",
                                             param == "2" ~ "dir1dir2",
                                             param == "3" ~ "dir1mat1",
                                             param == "4" ~ "dir1mat2",
                                             param == "5" ~ "dir2dir2",
                                             param == "6" ~ "dir2mat1",
                                             param == "7" ~ "dir2mat2",
                                             param == "8" ~ "mat1mat1",
                                             param == "9" ~ "mat1mat2",
                                             param == "10" ~ "mat2mat2",
                                             param == "11" ~ "mpe1mpe1",
                                             param == "12" ~ "mpe2mpe2",
                                             param == "13" ~ "res1res1",
                                             param == "14" ~ "res2res2"),
                    iter = iteration,
                    dataset = glue::glue("3v{region}")) %>% 
      dplyr::mutate(effective_sample_size = abs(effective_sample_size))
    
  }
  
}

read_gibbs_psd <- function(iteration, region) {
  
  fp <- glue::glue("data/derived_data/gibbs_varcomp/iter{iteration}/3v{region}/postout")
  
  if (file.exists(here::here(fp))) {
    
    readr::read_table2(here::here(fp),
                       skip = 22,
                       n_max = 14,
                       col_names = c("param", "eff1", "eff2", "trt1", "trt2", "psd", "mean", "psd_lo", "psd_hi", "geweke", "auto_lag1", "auto_lag10", "auto_lag50", "independent_batches")) %>% 
      dplyr::select(-eff1, -eff2, -trt1, -trt2) %>% 
      dplyr::mutate(param = dplyr::case_when(param == "1" ~ "dir1dir1",
                                             param == "2" ~ "dir1dir2",
                                             param == "3" ~ "dir1mat1",
                                             param == "4" ~ "dir1mat2",
                                             param == "5" ~ "dir2dir2",
                                             param == "6" ~ "dir2mat1",
                                             param == "7" ~ "dir2mat2",
                                             param == "8" ~ "mat1mat1",
                                             param == "9" ~ "mat1mat2",
                                             param == "10" ~ "mat2mat2",
                                             param == "11" ~ "mpe1mpe1",
                                             param == "12" ~ "mpe2mpe2",
                                             param == "13" ~ "res1res1",
                                             param == "14" ~ "res2res2"),
                    iter = iteration,
                    dataset = glue::glue("3v{region}")) %>% 
      dplyr::mutate_at(vars(contains("lag"), "geweke", "independent_batches"), ~ abs(.))
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
      purrr::set_names("3_dir",
                       glue("{dataset}_dir"),
                       "3_mat",
                       glue("{dataset}_mat"))
    
    corrmat %>%
      tibble::as.tibble() %>% 
      dplyr::mutate(val1 = colnames(.)) %>%
      tidyr::pivot_longer(-val1,
                          names_to = "val2",
                          values_to = "corr") %>% 
      dplyr::filter(!is.na(corr)) %>% 
      dplyr::mutate(iter = iteration,
                    dataset = glue::glue("3v{dataset}"))
  
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
      purrr::set_names("3_dir",
                       glue("{dataset}_dir"),
                       "3_mat",
                       glue("{dataset}_mat")) %>% 
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
      purrr::set_names("3_mpe",
                       glue("{dataset}_mpe")) %>% 
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
      purrr::set_names("3_res",
                       glue("{dataset}_res")) %>% 
      dplyr::mutate(val1 = colnames(.)) %>%
      tidyr::pivot_longer(-val1,
                          names_to = "val2",
                          values_to = "var_cov") 
    
    dplyr::bind_rows(g_cov,
                     mpe_cov,
                     r_cov) %>% 
      dplyr::mutate(iter = iteration,
                    dataset = glue::glue("3v{dataset}"))
    
  }
}

read_gibbs_h2 <- function(iteration, dataset) {
  
  source(here::here("source_functions/region_key.R"))
  source(here::here("source_functions/calculate_heritability.R"))
  
  desc1 <- "High Plains"
  
  desc2 <- 
    if(dataset == "3alt") {
      "High Plains (control)"
    } else {
      region_key %>% 
        filter(num == as.numeric(dataset)) %>% 
        pull(desc)
    }
  
  varcov <-
    read_gibbs_varcov(iteration = iteration, 
                      dataset = dataset) 
  
  if(!is.null(varcov)){
    varcov %<>% 
      biv_heritability(abbrvs = c("3", as.character(dataset)),
                     descs = c(desc1, desc2),
                     mat = TRUE,
                     mpe = TRUE) %>% 
    mutate(iter = iteration,
           dataset = glue::glue("3v{dataset}"))
    
    return(varcov)
  }
}