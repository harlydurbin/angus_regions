usa <- 
  ggplot2::borders("state",
                   regions = ".",
                   fill = "transparent",
                   colour = "black")

samples_map <-
  cg_regions %>%
  ggplot2::ggplot(aes(x = lng,
                      y = lat,
                      color = as.character(region),
                      size = n_animals)) +
  ggplot2::geom_point(alpha = 0.35) +
  usa +
  ggplot2::scale_color_manual(values = c("1" = "tomato2",
                                         "2" = "darkslategray4",
                                         "3" = "springgreen3",
                                         "5" = "goldenrod1",
                                         "7" = "deeppink3",
                                         "8" = "gray17",
                                         "9" = "slateblue2"),
                              labels = c("1" = "Desert",
                                         "2" = "Southeast",
                                         "3" = "High Plains",
                                         "5" = "Arid Prairie",
                                         "7" = "Forested Mountains",
                                         "8" = "Fescue Belt",
                                         "9" = "Upper Midwest & Northeast")) +
  ggplot2::scale_x_continuous(expand = c(0, 0)) +
  ggplot2::scale_y_continuous(expand = c(0, 0)) +
  ggplot2::coord_map("albers",
                     lat0 = 39,
                     lat1 = 45) +
  cowplot::theme_map() +
  ggplot2::guides(color = ggplot2::guide_legend(nrow = 3,
                                                byrow = TRUE,
                                                override.aes = list(alpha = 1)),
                  size = FALSE) +
  ggplot2::labs(x = NULL,
                y = NULL,
                title = NULL) +
  # Set the "anchoring point" of the legend (bottom-left is 0, top-right is 1,1)
  # Put bottom-left corner of legend box in bottom-left corner
  ggplot2::theme(axis.title.x = ggplot2::element_blank(),
                 axis.title.y = ggplot2::element_blank(),
                 legend.position = "bottom",
                 legend.title = ggplot2::element_blank(),
                 legend.text = ggplot2::element_text(size = 14),
                 # top, right, bottom, left
                 legend.box.margin = ggplot2::margin(b = 0.4, unit = "cm"),
                 plot.margin = ggplot2::margin(t = 0.7,
                                               r = 0,
                                               b = 0,
                                               l = 0,
                                               unit = "cm"))