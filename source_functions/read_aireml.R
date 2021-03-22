# Read in all iterations in all regions of `aireml.log` files (if they exist)
# Pull out genetic correlations

read_aireml_corr <- function(iteration, dataset) {
  
  fp <-
    glue::glue("data/derived_data/aireml_varcomp/iter{iteration}/3v{dataset}/airemlf90.iter{iteration}.3v{dataset}.log")
  
  print(glue::glue("Iteration {iteration}, 3v{dataset}"))
  
  if (file.exists(here::here(fp))) {
    
    corrmat <-
      readr::read_table2(here::here(fp),
                         skip = 9,
                         n_max = 4,
                         col_names = FALSE) %>% 
      janitor::remove_empty(which = c("rows", "cols")) %>% 
      purrr::set_names("3_dir",
                       glue::glue("{dataset}_dir"),
                       "3_mat",
                       glue::glue("{dataset}_mat")) %>% 
      mutate(val2 = colnames(.)) %>%
      tidyr::pivot_longer(cols = -val2,
                          names_to = "val1",
                          values_to = "corr") %>% 
      mutate(iter = iteration,
             dataset = glue::glue("3v{dataset}"))
    
    return(corrmat)
    
 
  }
}

# Read in all iterations in all regions of `aireml.log` files (if they exist)
# Use `melt_aireml` to convert to "long" variance/covariance matrices
# Calculate heritabilities using `biv_heritability`

# read_bootstrap_h2 <- function(iteration, r1, r2) {
#   
#   iter <- iteration
#   
#   run <- as.character(glue::glue("iter{iter}_{r1}v{r2}"))
#   
#   region_key <-
#     tibble::tribble(~num, ~abbrv, ~desc,
#                     2, "SE", "Southeast",
#                     8, "FB", "Fescue Belt",
#                     3, "HP", "High Plains", 
#                     5, "AP", "Arid Prairie",
#                     7, "FM", "Forested Mountains", 
#                     1, "D", "Desert",
#                     9, "UMWNE", "Upper Midwest & Northeast")
#   
#   r1_abbrv <-
#     region_key %>%
#     dplyr::filter(num == r1) %>%
#     dplyr::pull(abbrv)
#   
#   
#   r2_abbrv <-
#     region_key %>%
#     dplyr::filter(num == r2) %>%
#     dplyr::pull(abbrv)
#   
#   r1_desc <-
#     region_key %>%
#     dplyr::filter(num == r1) %>%
#     dplyr::pull(desc)
#   
#   
#   r2_desc <-
#     region_key %>%
#     dplyr::filter(num == r2) %>%
#     dplyr::pull(desc)
#   
#   fp <-
#     glue::glue("data/derived_data/bootstrap_ww/{r1}v{r2}/iter{iter}/airemlf90.{run}.log")
#   
#   if (file.exists(here::here(fp))) {
#     melt_aireml(
#       path = fp,
#       effect2 = c(glue::glue("{r1_abbrv}_dir"),
#                   glue::glue("{r2_abbrv}_dir"),
#                   glue::glue("{r1_abbrv}_mat"),
#                   glue::glue("{r2_abbrv}_mat")),
#       effect4 = c(glue::glue("{r1_abbrv}_mpe"),
#                   glue::glue("{r2_abbrv}_mpe")),
#       resids = c(glue::glue("{r1_abbrv}_res"),
#                  glue::glue("{r2_abbrv}_res"))) %>% 
#       biv_heritability(
#         abbrvs = c(r1_abbrv, r2_abbrv),
#         descs = c(r1_desc, r2_desc),
#         mat = TRUE,
#         mpe = TRUE
#       ) %>% 
#       dplyr::mutate(run = run)
#     
#   }
# }
# 
read_aireml_varcov <- function(iteration, dataset) {
  
  source(here::here("source_functions/melt_aireml.R"))
  
  fp <-
    glue::glue("data/derived_data/aireml_varcomp/iter{iteration}/3v{dataset}/airemlf90.iter{iteration}.3v{dataset}.log")
  
  print(glue::glue("Iteration {iteration}, 3v{dataset}"))

  if (file.exists(here::here(fp))) {
    varcov <-
      melt_aireml(path = fp,
                  effect2 = c("3_dir",
                              glue::glue("{dataset}_dir"),
                              "3_mat",
                              glue::glue("{dataset}_mat")),
                  effect4 = c("3_mpe",
                              glue::glue("{dataset}_mpe")),
                  resids = c("3_res",
                             glue::glue("{dataset}_res")))
    
    varcov %>% 
      dplyr::mutate(iter = iteration,
                    dataset = glue::glue("3v{dataset}"))
  }
}

