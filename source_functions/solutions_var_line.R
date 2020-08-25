
solutions_var_line <-
  function(df, effect_var, trait_var, y_lab, plot_title) {
    df %>%
      filter(trait == trait_var & var == effect_var) %>%
      mutate(yr = lubridate::year(weigh_date),
             region = as.character(region)) %>%
      group_by(region, yr) %>%
      summarise(mean = mean(value),
                sd = sd(value)) %>%
      ungroup() %>%
      bind_rows(
        growth_regions %>%
          filter(trait == trait_var & var == effect_var) %>%
          mutate(yr = lubridate::year(weigh_date)) %>%
          group_by(yr) %>%
          summarise(mean = mean(value),
                    sd = sd(value)) %>%
          mutate(region = "All regions") %>%
          ungroup()
      ) %>%
      mutate(
        line =
          case_when(region == "All regions" ~ "twodash",
                    TRUE ~ "solid"),
        size =
          case_when(region == "All regions" ~ 2,
                    TRUE ~ 1),
        desc =
          case_when(
            region == "1" ~ "1: Desert",
            region == "2" ~ "2: Southeast",
            region == "3" ~ "3: High Plains",
            region == "4" ~ "4: Rainforest",
            region == "5" ~ "5: Arid Prairie",
            region == "6" ~ "6: Cold Desert",
            region == "7" ~ "7: Forested Mountains",
            region == "8" ~ "8: Fescue Belt",
            region == "9" ~ "9: Upper Midwest & Northeast",
            region == "All regions" ~ "National average"
          )
      ) %>%
      filter(!yr %in% c(1972, 2019)) %>% 
      #filter(region %in% c(1, 2, 5, "All regions")) %>%
      # arrange(desc(mean))
      ggplot(aes(
        x = yr,
        y = mean,
        color = forcats::as_factor(region),
        linetype = line,
        size = size
      )) +
      geom_line() +
      # Ribbon is +/- one SD
      geom_ribbon(aes(ymin = mean - sd,
                      ymax = mean + sd),
                  alpha = 0.2,
                  # No lines around ribbon
                  color = NA) +
      scale_linetype_identity(guide = "none") +
      scale_size_identity(guide = "none") +
      scale_color_manual(
        values = c(
          "1" = "tomato2",
          "2" = "darkslategray4",
          "3" = "springgreen3",
          "4" = "brown",
          "5" = "goldenrod1",
          "6" = "gray50",
          "7" = "deeppink3",
          "8" = "gray17",
          "9" = "slateblue2",
          "All regions" = "red"
        ),
        guide = "none"
      ) +
      scale_fill_manual(
        values = c(
          "1" = "tomato2",
          "2" = "darkslategray4",
          "3" = "springgreen3",
          "4" = "brown",
          "5" = "goldenrod1",
          "6" = "gray50",
          "7" = "deeppink3",
          "8" = "gray17",
          "9" = "slateblue2",
          "All regions" = "red"
        ),
        guide = "none"
      ) +
      theme_classic() +
      theme(
        plot.title = element_text(
          size = 22,
          face = "italic",
          margin = margin(
            t = 0,
            r = 0,
            b = 13,
            l = 0
          )
        ),
        axis.title = element_text(size = 16),
        axis.title.y = element_text(margin = margin(
          t = 0,
          r = 13,
          b = 0,
          l = 0
        )),
        axis.title.x = element_text(margin = margin(
          t = 13,
          r = 0,
          b = 0,
          l = 0
        )),
        axis.text = element_text(size = 14),
        legend.text = element_text(size = 14),
        strip.text.x = element_text(size = 16)
      ) +
      labs(
        x = NULL,
        y = y_lab,
        color = NULL,
        linetype = NULL,
        title = str_wrap(plot_title,
                         width = 55)
      ) +
      facet_wrap( ~ desc, nrow = 8)
    
  }
