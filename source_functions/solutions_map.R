library(ggplot2)

usa <- 
  borders("state", regions = ".", fill = "transparent", colour = "black")


solutions_map <-
  
  function(df, effect_var, trait_var, plot_title, size_var, color_var, size_range) {
    
    color_var <- rlang::enquo(color_var)
    size_var <- rlang::enquo(size_var)
    
    df %>%
      filter(var == effect_var & trait == trait_var) %>%
      ggplot(aes(
        x = lng,
        y = lat,
        color := !!color_var,
        size := !!size_var
      )) +
      geom_point(
        alpha = 0.7,
        #size = 0.5
        ) +
      scale_size(
        range = size_range
      ) +
      usa +
      viridis::scale_color_viridis(direction = -1, option = "A") +
      scale_x_continuous(expand = c(0, 0)) +
      scale_y_continuous(expand = c(0, 0)) +
      coord_map("albers", lat0 = 39, lat1 = 45) +
      cowplot::theme_map() +
      labs(
        x = NULL,
        y = NULL,
        color = NULL,
        title = plot_title, width = 55
      ) +
      #Set the "anchoring point" of the legend (bottom-left is 0,0; top-right is 1,1)
      #Put bottom-left corner of legend box in bottom-left corner of graph
      theme(
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        # Put legend in bottom right
        legend.justification = c(0, 0),
        legend.position = c(0, 0),
        # https://cran.rstudio.com/web/packages/showtext/vignettes/introduction.html
        legend.title = element_text(# size = 24,
          # family = "catamaran"
          size = 16),
        legend.text = element_text(
          # size = 28,
          # family = "catamaran",
          size = 12,
          angle = 30,
          margin = margin(
            t = 0,
            r = 0,
            b = 0,
            l = 0
          )
        ),
        legend.direction = "horizontal",
        legend.key = element_rect(color = NA,
                                  fill = NA),
        # Padding around the legend
        # top, right, bottom, left
        # legend.box.margin = margin(b = 0, r = 0.2, unit = "cm"),
        # Padding around the plot
        plot.margin = margin(
          t = 0.7,
          r = 0,
          b = 0.7,
          l = 1,
          unit = "cm"
        ),
        plot.title = element_text(
          # size = 56,
          # family =  "lato",
          size = 22,
          vjust = 6,
          face = "italic"
        )
      ) +
      # https://stackoverflow.com/questions/32656553/plot-legend-below-the-graphs-and-legend-title-above-the-legend-in-ggplot2
      guides(
        color = guide_colorbar(
          title.position = "top",
          frame.colour = "black",
          barwidth = 8,
          barheight = 2
        ),
        size = FALSE
      )
    
  }