usage_summary <-
  function(process, keyword) {
    list.files(
      path = here::here(glue::glue("log/psrecord/{process}/{keyword}/")),
      full.names = TRUE
    ) %>%
      set_names(nm = (basename(.) %>%
                        tools::file_path_sans_ext())) %>%
      map_dfr(~ read_table2(
        .x,
        skip = 1,
        col_names = c("time", "cpu_percent", "real_mb", "virtual_mb")
      ), .id = "file") %>%
      mutate(rule = keyword) %>%
      filter(virtual_mb > 0) %>% 
      summarise(max_time_hours = max(time, na.rm = TRUE),
                max_cpu_percent = max(cpu_percent, na.rm = TRUE),
                max_mb = max(real_mb, na.rm = TRUE)) %>%
      mutate(max_time_hours = (max_time_hours / 60)/60,
             max_gb = max_mb * 0.001)
    
  }

usage_facets <-
  function(process, keyword, search_pattern = NULL) {
    logs <-
      list.files(
        path = here::here(glue::glue("log/psrecord/{process}/{keyword}/")),
        full.names = TRUE,
        pattern = search_pattern
      ) %>%
      set_names(nm = (basename(.) %>%
                        tools::file_path_sans_ext())) %>%
      map_dfr(~ read_table2(
        .x,
        skip = 1,
        col_names = c("time", "cpu_percent", "real_mb", "virtual_mb")
      ), .id = "file") %>%
      mutate(rule = keyword) %>% 
      filter(virtual_mb > 0)
    
    # logs <- 
    #   if(!is.null(sample_num)){
    #     logs %>% 
    #       filter(file %in% sample(file, sample_num))
    #   } else logs
    
    logs %>% 
      ggplot(aes(x = time, y = real_mb)) +
      geom_line() +
      facet_wrap( ~ file)
    
  }