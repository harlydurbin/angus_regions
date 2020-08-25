start <-
  animal_regions %>%
  filter(var == "weight" & trait == "ww") %>%
  # Only 1990 and beyond
  filter(year >= 1990) %>%
  # At least 15 animals per cg
  filter(n_animals >= 15) %>%
  left_join(
    ped %>%
      select(id_new, sire_id, dam_id, birth_year)
  ) %>%
  group_by(trait, cg_new) %>%
  # Remove single sire single dam contemporary groups
  filter(n_distinct(sire_id) > 1) %>%
  filter(n_distinct(dam_id) > 1) %>%
  ungroup()

write_rds(start, here::here("data/derived_data/bootstrap_ww_start.rds"))
