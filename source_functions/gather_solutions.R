
# Given a `rundate`, `r1`, `r2`, and `growth_trait`, imports univariate solutions from AIREML `solutions` file

gather_univ <- 
  function(rundate, r1, r2, growth_trait){
    
    region_key <-
      tribble(~num, ~abbrv, ~desc,
              2, "SE", "Southeast",
              8, "FB", "Fescue Belt",
              3, "HP", "High Plains", 
              5, "AP", "Arid Prairie",
              7, "FM", "Forested Mountains", 
              1, "D", "Desert",
              9, "UMWNE", "Upper Midwest & Northeast")
    
    # Set region 1 abbrv
    r1_abbrv <- 
      region_key %>% 
      filter(num == r1) %>% 
      pull(abbrv)
    
    # Set region 2 abbrv
    r2_abbrv <- 
      region_key %>% 
      filter(num == r2) %>% 
      pull(abbrv)
    
    # Read in univariate run solutions for each region
    c(glue::glue("data/f90/{rundate}_{r1}v{r2}_{growth_trait}/{r1_abbrv}/solutions"),
      glue::glue("data/f90/{rundate}_{r1}v{r2}_{growth_trait}/{r2_abbrv}/solutions")) %>%
      purrr::set_names(c(r1, r2)) %>%
      purrr::map( ~ read_table2(
        here::here(.x),
        skip = 1,
        col_names = c("trait", "effect", "id_biv", "solution")
      )) %>%
      purrr::imap( ~ mutate(.x, 
                     analysis_region = .y,
                     trait = growth_trait)) %>%
      reduce(bind_rows) %>%
      left_join(
        c(
          glue::glue("data/f90/{rundate}_{r1}v{r2}_{growth_trait}/{r1_abbrv}/renadd02.ped"),
          glue::glue("data/f90/{rundate}_{r1}v{r2}_{growth_trait}/{r2_abbrv}/renadd02.ped")
        ) %>%
          set_names(c(r1, r2)) %>%
          map_dfr(~ read_table2(here::here(.x),
                                col_names = FALSE),
                  .id = "analysis_region") %>%
          select(id_biv = X1, id_new = X10, analysis_region) 
      ) %>% 
  mutate(
    model = "univariate",
    analysis_region = as.numeric(analysis_region),
    effect =
      case_when(
        effect == 1 ~ "cg_sol",
        effect == 2 ~ "bv_sol",
        effect == 3 ~ "mat_sol",
        effect == 4 ~ "mpe"
      )
  )
  }

# Given a `rundate`, `r1`, `r2`, and `growth_trait`, imports bivariate solutions from AIREML `solutions` file
gather_biv <-
  function(rundate, r1, r2, growth_trait) {
    
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
    
    read_table2(
      here::here(
        glue::glue(
          "data/f90/{rundate}_{r1}v{r2}_{growth_trait}/solutions"
        )
      ),
      skip = 1,
      col_names = c("analysis_region", "effect", "id_biv", "solution")
    ) %>%
      mutate(analysis_region =
               case_when(analysis_region == 1 ~ r1,
                         analysis_region == 2 ~ r2),
             trait = growth_trait) %>%

      left_join(read_table2(here::here(
        glue::glue(
          "data/f90/{rundate}_{r1}v{r2}_{growth_trait}/renadd02.ped"
        )
      ),
      col_names = FALSE) %>%
        select(id_biv = X1, id_new = X10)) %>%
      mutate(
        model = "bivariate",
        analysis_region = as.numeric(analysis_region),
        effect =
          case_when(
            effect == 1 ~ "cg_sol",
            effect == 2 ~ "bv_sol",
            effect == 3 ~ "mat_sol",
            effect == 4 ~ "mpe"
          )
      )
    
  }