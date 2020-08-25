readgwas2 <- function(filepath){
  gwas = 
    read_tsv(filepath, col_names = TRUE) %>% 
    mutate(q = qvalue(p_score)$qvalues) %>% mutate(chr = as.numeric(str_split_fixed(rs, ":", n = 2)[,1])) %>% 
    mutate(pos = as.numeric(str_split_fixed(rs, ":", n = 2)[,2])) %>% 
    #left_join(., genefromsnp(.)) %>% 
    select(rs, chr, pos , af, p = p_score, q)
  
  don = gwas %>% 
    group_by(chr) %>% 
    summarise(chr_len=max(pos)) %>% 
    mutate(tot=cumsum(chr_len)-chr_len) %>%
    select(-chr_len) %>%
    left_join(gwas, ., by=c("chr"="chr")) %>%
    arrange(chr, pos) %>%
    mutate( BPcum=pos+tot) %>% 
    ungroup()
  
  return(don)
}

ggmanhattan = function(inputfile, 
                       prune = 1.0, 
                       value = p, 
                       alpha = 0.5, 
                       pcol = "p_score", 
                       pointsize = 1.0,
                       colors = c("grey10", "grey55"), 
                       sigsnps = NULL, 
                       sigsnps2 = NULL,
                       sigsnpcolor = "springgreen3",
                       sigsnpcolor2 = "goldenrod1"){
  require(qvalue)
  require(dplyr)
  require(stringr)
  require(ggplot2)
  require(cowplot)
  require(viridis)
  #Allows p or q value to be interpreted as column name in ggplot call
  v = enexpr(value)
  gwas = inputfile %>% #reads in input file
    filter(., if (v == "p") p < prune else q < prune)
  
  
  axisdf = gwas %>% group_by(chr) %>% summarize(center=( max(BPcum) + min(BPcum) ) / 2 )  
  
  #v from above 
  gwas_plot = ggplot(gwas, aes(x=BPcum, y=-log10(!!v))) + 
    geom_point(aes(color=as.factor(chr)), alpha=alpha, size = pointsize) +
    scale_color_manual(values = rep(colors, 29)) +
    scale_x_continuous(label = axisdf$chr[c(TRUE, FALSE, FALSE)], breaks= axisdf$center[c(TRUE, FALSE, FALSE)] ) +
    labs(x = "",
         y = case_when(v == "p" ~ expression(paste(-log10, "(", italic('p'), ")")),
                       v == "q" ~ expression(paste(-log10, "(", italic('q'), ")"))))+
    theme_bw() +
    geom_point(data = subset(gwas, rs %in% sigsnps), color=sigsnpcolor, size = pointsize, alpha = 0.5) +
    geom_point(data = subset(gwas, rs %in% sigsnps2), color=sigsnpcolor2, size = pointsize, alpha = 0.5) +
    geom_hline(yintercept = case_when(v == "p" ~ -log10(1e-5),
                                      v == "q" ~ -log10(0.1)), 
               color = "red", 
               size = 0.25) +
    theme(legend.position="none", 
          panel.border = element_blank(), 
          panel.grid.major.x = element_blank(), 
          panel.grid.minor = element_blank()
    )+
    theme(
      panel.background = element_rect(fill = "transparent") # bg of the panel
      , plot.background = element_rect(fill = "transparent", color = NA) # bg of the plot
      , panel.grid.major = element_blank() # get rid of major grid
      , panel.grid.minor = element_blank() # get rid of minor grid
      , legend.background = element_rect(fill = "transparent") # get rid of legend bg
      , legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
    )
  return(gwas_plot)
}