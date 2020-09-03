start <-
  read_rds(here::here("data/derived_data/animal_regions.rds")) %>% 
  filter(var == "weight") %>% 
  filter(trait == "ww") %>% 
  filter(!region %in% c(4, 6)) %>% 
  left_join(ped %>%
              select(full_reg, format_reg)) %>% 
  filter(year >= 1990) %>% 
  filter(n_animals > 4) %>% 
  left_join(
    ped %>%
      select(id_new, sire_id, dam_id)
  ) %>%
  group_by(cg_new) %>%
  # Remove single sire single dam contemporary groups
  filter(n_distinct(sire_id) > 1) %>%
  filter(n_distinct(dam_id) > 1) %>%
  ungroup() %>% 
  group_by(zip) %>% 
  filter(n_distinct(year) >= 10) %>% 
  ungroup() %>% 
  select(full_reg, format_reg, id_new, value, weigh_date, year, cg_new, n_animals, region, zip)


write_rds(start, here::here("data/derived_data/bootstrap_ww_start2.rds"))
