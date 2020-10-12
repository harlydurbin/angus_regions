require(stringr)

solutions_line <-
  
  function(df,
           effect_var,
           trait_var,
           y_lab,
           plot_title,
           national_avg,
           stat = "mean") {
    sum1 <-
      df %>%
      filter(trait == trait_var & var == effect_var) %>%
      mutate(#yr = lubridate::year(weigh_date),
        yr = year,
        region = as.character(region)) %>%
      group_by(region, yr) %>%
      summarise(mean = mean(value),
                median = median(value))
    
    sum2 <-
      if (national_avg == TRUE) {
        sum1 %>%
          bind_rows(
            df %>%
              filter(trait == trait_var & var == effect_var) %>%
              mutate(# yr = lubridate::year(weigh_date)
                yr = year) %>%
              group_by(yr) %>%
              summarise(mean = mean(value),
                        median = median(value)) %>%
              mutate(region = "All regions")
          )
      }
    else {
      sum1
    }
    
    sum3 <- 
      if(stat == "mean") {
        sum2 %>% 
          rename(stat = mean)
      } else {
        sum2 %>% 
          rename(stat = median)
      }
    
    sum3 %>%
      mutate(
        line =
          case_when(region == "All regions" ~ "twodash",
                    TRUE ~ "solid"),
        size =
          case_when(region == "All regions" ~ 2,
                    TRUE ~ 1)
      ) %>%
      filter(!yr %in% c(1972, 2019)) %>%
      ggplot(aes(
        x = yr,
        y = stat,
        color = forcats::as_factor(region),
        linetype = line,
        size = size
      )) +
      geom_line(alpha = 0.8,
                key_glyph = "timeseries") +
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
        labels = c(
          "1" = "1: Desert",
          "2" = "2: Southeast",
          "3" = "3: High Plains",
          "4" = "4: Rainforest",
          "5" = "5: Arid Prairie",
          "6" = "6: Cold Desert",
          "7" = "7: Forested Mountains",
          "8" = "8: Fescue Belt",
          "9" = "9: Upper Midwest & Northeast",
          "All regions" = "National average"
        )
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
        legend.text = element_text(size = 14)
      ) +
      labs(
        x = NULL,
        y = y_lab,
        color = NULL,
        linetype = NULL,
        title = plot_title
      )
    
  }
