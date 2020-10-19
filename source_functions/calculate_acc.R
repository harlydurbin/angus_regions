# * Square se to get diagonal element ($d_i$)
# * $PEV = d_i\sigma^2_e$
#   * $r^2 = 1-(\frac{PEV}{\sigma^2_u})$
#     + Assuming $\sigma^2_u$ is $\sigma^2_a$?
# 10/19/20
# * Mrode p. 44: "PEV is fraction of additive genetic variance not accounted for by prediction"
# * https://jvanderw.une.edu.au/Chapter02_GENE422_EBV.pdf p. 9: PEV is SEP^2
#     + Reliability is $r_{IA}$
#     + SEP = $\sqrt{1-r_{IA}^2(V_A)}$
# * This manual p. 103 http://nce.ads.uga.edu/wiki/lib/exe/fetch.php?media=tutorial_blupf90.pdf : s.e. reported in solutions IS SEP. 
#     + p. 116: "The reliability of the estimated breeding value of an animal can be calculated with the solutions from BLUPF90"
# acc <- (1-(se^2))/u

calculate_acc <- function(e, u, se, option = "reliability") {
  
  # 10/19/20 Took out multiplication by residual variance
  PEV <- (se ^ 2) #* e
  
  acc <- if (option == "reliability") {
    1 - (PEV / u)
  } else if(option == "bif"){

    1 - sqrt(PEV / u)

  }
  
  return(acc)
}