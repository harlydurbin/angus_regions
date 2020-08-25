
ww_datuniv_ped <-
  # Univariate data
  c(
    "data/f90/190812_3v1_ww/D/data.D.txt",
    "data/f90/190812_3v2_ww/SE/data.SE.txt",
    "data/f90/190812_3v1_ww/HP/data.HP.txt",
    "data/f90/190812_3v5_ww/AP/data.AP.txt",
    "data/f90/190812_3v7_ww/FM/data.FM.txt",
    "data/f90/190812_3v8_ww/FB/data.FB.txt",
    "data/f90/190812_3v9_ww/UMWNE/data.UMWNE.txt"
  ) %>%
  purrr::set_names(c(
    "1",
    "2",
    "3",
    "5",
    "7",
    "8",
    "9"
  )) %>%
  purrr::map(~ readr::read_table2(here::here(.x),
                    col_names = c("id_new", "cg_new", "weight"))) %>%
  purrr::imap(~ dplyr::mutate(.x, region = .y)) %>%
  purrr::reduce(bind_rows) %>%
  dplyr::left_join(
    c(
      "data/f90/190812_3v1_ww/D/ped.D.txt",
      "data/f90/190812_3v2_ww/SE/ped.SE.txt",
      "data/f90/190812_3v1_ww/HP/ped.HP.txt",
      "data/f90/190812_3v5_ww/AP/ped.AP.txt",
      "data/f90/190812_3v7_ww/FM/ped.FM.txt",
      "data/f90/190812_3v8_ww/FB/ped.FB.txt",
      "data/f90/190812_3v9_ww/UMWNE/ped.UMWNE.txt"
    ) %>%
      purrr::set_names(c("1", "2", "3", "5", "7", "8", "9")) %>%
      purrr::map_dfr( ~ readr::read_table2(
        here::here(.x),
        col_names = c("id_new", "sire_id", "dam_id")
      ),
      .id = "region")
  )
