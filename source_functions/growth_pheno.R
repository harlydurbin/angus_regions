# Import growth phenotypes

growth_pheno <-
  readr::read_table2(here::here("data/raw_data/import_regions/renf90.dat"),
                     col_names = FALSE) %>%
  # X7 is a unique identifier?
  # What is X8??
  rename(
    bw = X1,
    ww = X2,
    pwg = X3,
    bw_cg = X4,
    ww_cg = X5,
    pwg_cg = X6,
    id_new = X7
  ) %>%
  select(-X8) %>%
  # hacky work around because I've spend too much time on this
  bind_rows(
    select(., pwg, pwg_cg, id_new) %>%
      rename(weight = pwg,
             cg_new = pwg_cg) %>%
      mutate(trait = "pwg"),
    select(., ww, ww_cg, id_new) %>%
      rename(weight = ww,
             cg_new = ww_cg) %>%
      mutate(trait = "ww"),
    select(., bw, bw_cg, id_new) %>% 
      rename(weight = bw,
             cg_new = bw_cg) %>% 
      mutate(trait = "bw")
  ) %>% 
  select(-(bw:pwg_cg)) %>%
  filter(!is.na(trait)) %>%
  filter(cg_new != 0)
