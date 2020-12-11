library(ggplot2)

# Given a `df`, `trait_var`, `effect_var`, plot geographic distribution of samples, colored by region
# Uses `lat`, `lng` and numeric `region` in either `cg_regions` or `animal_regions`


plot_samples_map <-
  
  function(df, effect_var, trait_var, plot_title) {
    
    usa <- 
      ggplot2::borders("state", regions = ".", fill = "transparent", colour = "black")
    
    df %>%
      dplyr::filter(var == effect_var & trait == trait_var) %>%
      #filter(n_animals > 4) %>%
      #sample_frac(0.01) %>%
      ggplot2::ggplot(aes(
        x = lng,
        y = lat,
        color = as.character(region),
        size = n_animals
      )) +
      ggplot2::geom_point(alpha = 0.35) +
      usa +
      ggplot2::scale_color_manual(
        values = c(
          "1" = "tomato2",
          "2" = "darkslategray4",
          "3" = "springgreen3",
          "4" = "brown",
          "5" = "goldenrod1",
          "6" = "gray50",
          "7" = "deeppink3",
          "8" = "gray17",
          "9" = "slateblue2"
        ),
        labels = c(
          "1" = "Desert",
          "2" = "Southeast",
          "3" = "High Plains",
          "4" = "Rainforest",
          "5" = "Arid Prairie",
          "6" = "Cold Desert",
          "7" = "Forested Mountains",
          "8" = "Fescue Belt",
          "9" = "Upper Midwest & Northeast"
        )
      ) +
      ggplot2::scale_x_continuous(expand = c(0, 0)) +
      ggplot2::scale_y_continuous(expand = c(0, 0)) +
      ggplot2::coord_map("albers", lat0 = 39, lat1 = 45) +
      cowplot::theme_map() +
      ggplot2::guides(color = ggplot2::guide_legend(
        nrow = 3,
        byrow = TRUE,
        override.aes = list(alpha = 1)
      ),
      size = FALSE) +
      ggplot2::labs(x = NULL,
           y = NULL,
           title = plot_title) +
      # Set the "anchoring point" of the legend (bottom-left is 0,0; top-right is 1,1)
      # Put bottom-left corner of legend box in bottom-left corner of graph
      ggplot2::theme(
        axis.title.x = ggplot2::element_blank(),
        axis.title.y = ggplot2::element_blank(),
        # legend.justification = c(0, .05),
        legend.position = "bottom",
        # legend.key.size = unit(1, "cm"),
        legend.title = ggplot2::element_blank(),
        legend.text = ggplot2::element_text(# family = "catamaran",
          size = 14),
        # top, right, bottom, left
        legend.box.margin = ggplot2::margin(b = 0.4, unit = "cm"),
        plot.margin = ggplot2::margin(
          t = 0.7,
          r = 0,
          b = 0,
          l = 0,
          unit = "cm"
        ),
        plot.title = ggplot2::element_text(
          # size = 56,
          # family =  "lato",
          size = 22,
          hjust = 0.5,
          vjust = 6,
          face = "italic"
        )
      )
    
  }