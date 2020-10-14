read_gibbs_samples <- function(iteration, region) {
  
  fp <- glue::glue("data/derived_data/varcomp_ww/iter{iteration}/3v{region}/gibbs/postgibbs_samples")
  
  if (file.exists(here::here(fp))) {
    
    readr::read_table2(here::here(fp),
                       col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      dplyr::mutate(iter = iteration,
                    dataset = glue::glue("3v{region}"))
  }
}

read_gibbs_mce <- function(iteration, region) {
  
  fp <- glue::glue("data/derived_data/varcomp_ww/iter{iteration}/3v{region}/gibbs/postout")
  
  if (file.exists(here::here(fp))) {
    
    readr::read_table2(here::here(fp),
                       skip = 4,
                       n_max = 18,
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
                                             param == "14" ~ "r2r2",
                                             param == "15" ~ "se(d1d2)",
                                             param == "16" ~ "se(m1m2)",
                                             param == "17" ~ "se(d1m1)",
                                             param == "18" ~ "se(d2m2)"),
                    iter = iteration,
                    dataset = glue::glue("3v{region}")) 
    
  }
  
}

read_gibbs_psd <- function(iteration, region) {
  
  fp <- glue::glue("data/derived_data/varcomp_ww/iter{iteration}/3v{region}/gibbs/postout")
  
  if (file.exists(here::here(fp))) {
    
    readr::read_table2(here::here(fp),
                       skip = 27,
                       n_max = 18,
                       col_names = c("param", "eff1", "eff2", "trt1", "trt2", "psd", "mean", "psd_interval_lo", "psd_interval_hi", "convergence", "auto_lag1", "auto_lag10", "auto_lag50", "independent_batches")) %>% 
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
                                             param == "14" ~ "r2r2",
                                             param == "15" ~ "se(d1d2)",
                                             param == "16" ~ "se(m1m2)",
                                             param == "17" ~ "se(d1m1)",
                                             param == "18" ~ "se(d2m2)"),
                    iter = iteration,
                    dataset = glue::glue("3v{region}")) 
  }
  
}