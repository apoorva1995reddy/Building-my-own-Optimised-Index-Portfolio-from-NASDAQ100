similarityMat <- function(priceMat, sharesMat, unique_tickers, unique_dates){
  source("readData.R")
  library(lsa)
  daily_returns <- rbind(diff(priceMat), c(rep(0, 100)))
  daily_returns <- daily_returns[!rowSums(!is.finite(daily_returns)),]
  rho <- cosine(daily_returns)
  return(rho)
}