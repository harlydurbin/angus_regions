library(stringr)

cg_regions %>% 
  filter(var == "cg_sol" & trait == "ww") %>% 
  mutate(weigh_month = lubridate::month(weigh_date),
         weigh_week = lubridate::week(weigh_date)) %>% 
  group_by(region) %>% 
  mutate(total = sum(n_animals)) %>% 
  ungroup() %>% 
  group_by(region, total, weigh_week) %>% 
  summarise(n_weaned = sum(n_animals)) %>% 
  ungroup() %>% 
  mutate(percent_weaned = n_weaned/total) %>% 
  ggplot(aes(
    x = weigh_week,
    y = percent_weaned, 
    color = forcats::as_factor(region)
  )) +
  geom_line(alpha = 0.8,
            size = 2) +
  scale_y_continuous(labels = scales::percent) +
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
    axis.title = element_text(
      size = 16),
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
    axis.text = element_text(
      size = 14),
    legend.text = element_text(
      size = 14)
  ) +
  labs(
    x = "Wean date (week of the year)",
    y = "Percentage weaned",
    color = NULL,
    linetype = NULL,
    title = str_wrap(
      "Calving season distribution by region",
      width = 55
    )
  )

ggsave(here::here("figures/regional_calving_season.png"), width = 10, height = 5.4)


cg_regions %>% 
  filter(trait == "ww" & region == 5) %>% 
  mutate(
    wean_szn = 
      case_when(
        between(lubridate::month(weigh_date), left = 1, right = 6) ~ "SPRING",
        between(lubridate::month(weigh_date), left = 7, right = 12) ~ "FALL",
      )) %>% 
  # summarise(
  #   percent_CA = (.[herd_state == "CA",] %>% nrow(.))/(nrow(.)),
  #   percent_CA_spring = (.[wean_szn == "SPRING" & herd_state == "CA",] %>% nrow(.))/(nrow(.)),
  #   percent_CA_fall = (.[wean_szn == "FALL" & herd_state == "CA",] %>% nrow(.))/(nrow(.))
  #   )
  group_by(herd_state) %>% 
  summarise(
    percent_spring_wean = 
      (.[wean_szn == "SPRING",] %>% nrow(.))/(nrow(.)),
    percent_fall_wean = 
      (.[wean_szn == "FALL",] %>% nrow(.))/(nrow(.)),
    n_weaned = sum(n_animals),
    perc
  ) %>% 
  arrange(desc(percent_fall_wean))
