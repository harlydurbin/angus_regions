# Prep gwas output for plotting
# Stolen from Troy



chr_len <- function(df) {
  df %>%
    # Summarise each chromosome length
    group_by(chr) %>%
    summarise(chr_len = max(pos)) %>%
    # Total relative to entire genome
    mutate(tot = cumsum(chr_len) - chr_len) %>%
    select(-chr_len) %>%
    left_join(df, by = c("chr" = "chr")) %>%
    arrange(chr, pos) %>%
    mutate(BPcum = pos + tot) %>%
    ungroup()
}


regions_manhattan <-
  function(df,
           y_var,
           y_lab = NULL,
           plot_title = NULL,
           facet = FALSE,
           nfacets = 2,
           sigline = FALSE) {
    y_var <- rlang::enquo(y_var)
    
    axisdf <-
      df %>%
      # Add chromosome length for plotting
      chr_len() %>%
      group_by(chr) %>%
      summarize(center = (max(BPcum) + min(BPcum)) / 2)
    
    df <-
      df %>%
      chr_len() %>%
      left_join(region_key %>%
                  select(region = num, desc, color1, color2)) %>%
      # Alternating chromosome color
      mutate(chrcolor =
               case_when(chr %in% c(seq(
                 from = 1, to = 29, by = 2
               )) ~ color1,
               chr %in% c(seq(
                 from = 2, to = 29, by = 2
               )) ~ color2))
    
    
    gg <-
      df %>%
      ggplot(aes(x = BPcum,
                 y = !!y_var)) +
      geom_point(aes(color = chrcolor)) +
      scale_color_identity() +
      # scale_color_manual(values = rep(colors, 29), guide = "none") +
      # Every 3 chromosomes gets a label
      scale_x_continuous(label = axisdf$chr[c(TRUE, FALSE)],
                         breaks = axisdf$center[c(TRUE, FALSE)]) +
      theme_classic() +
      theme(
        plot.title = element_text(
          size = 24,
          face = "italic",
          margin = margin(
            t = 0,
            r = 0,
            b = 13,
            l = 0
          )
          ),
          plot.subtitle = element_text(
            size = 20,
            face = "italic",
            margin = margin(
              t = 0,
              r = 0,
              b = 13,
              l = 0
            ),
          ),
          axis.title = element_text(size = 18),
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
          strip.text = element_text(size = 14)
        ) +
          labs(x = NULL,
               y = y_lab,
               title = plot_title)
        
        gg <-
          if (facet == TRUE) {
            gg +
              facet_wrap(~ desc, nrow = nfacets, scales = "free_x")
          } else {
            gg
          }
        
        gg <-
          if (sigline == TRUE) {
            gg +
              geom_hline(
                yintercept = -log10(1e-5),
                color = "red",
                size = 0.25
              )
          } else {
            gg
          }
        
        return(gg)
  }
