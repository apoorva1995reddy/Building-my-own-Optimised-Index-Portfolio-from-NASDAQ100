
constructFund = function (rho_cor, q, priceMat, sharesMat, unique_tickers, unique_dates) {
  
  library ('lpSolve')
  corr_vect = c(rep(0,100),t(as.vector(rho_cor)))
  
  
  # Let us first create the constraints matrix
  
  A = matrix(0, nrow = 10101,ncol = 10100)
  
  #Constraint 1  - Summation of y's is equal to q
  A[1,1:100] = c(rep(1,100))
  
  # Constraint 2 - Summation of x's must be 1
  j = 101
  for(i in 1:100){
    A[(i+1), j:(j+99)] = rep(1, 100)
    j = j + 100
  }
  
  #Constraint 3 - Each xij less than equal to yj
  
  A[102:10101, 101:10100] = diag(1, nrow = 10000, ncol = 10000)
  
  for(i in seq(from = 102, to = 10101, by = 100)){
    
    A[i:(i+99), 1:100] = diag(-1, nrow = 100, ncol = 100)
    
  }
  
  b = c(q,rep(1,100),rep(0,10000))
  
  dir = c(rep("=",101),rep("<=",10000))
  
  
  #Solve the linear program
  s = lp("max", corr_vect, A, dir, b, all.bin = TRUE)
  #s$objval

  weights = s$solution
  
  X = matrix(weights[101:10100], nrow = 100, ncol = 100, byrow = TRUE)
  y = weights[1:100]
  
  # We will now calculate the market cap of each stock on the last date of 2012 to compute    weights
  market_cap = priceMat["2012-12-31", ]*sharesMat["2012-12-31",]
  
  #calculate the weights for each of the stock
  weights = market_cap %*% X
  
  # Normalize the weights to get a fraction contribution from each of the stock
  weight_fraction = as.vector(weights/sum(weights))
  names(weight_fraction) <- as.character(unique_tickers)
  
  results <- list("weight_fraction" = weight_fraction,
                  "objval" = s$objval, 
                  "status" = s$status, 
                  "solution" = s$solution)
  
  
  return (results)
}