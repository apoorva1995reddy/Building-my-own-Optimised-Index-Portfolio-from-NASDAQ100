---
title: MY INDEX PORTFOLIO
author: "Apoorva_Reddy_Adavalli"
date: "28 February 2019"
output:
  html_document: default
  pdf_document: default
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## R Markdown

This is an R Markdown document. Markdown is a simple formatting syntax for authoring HTML, PDF, and MS Word documents. For more details on using R Markdown see <http://rmarkdown.rstudio.com>.



### Loading Libraries 

```{r}
# The package scales is only used to present things nicely. You can ignore it.
library('scales')
library('lpSolve')
```

### Basic Cleaning of Data 
```{r}
#setwd('D:/UT_Austin/Spring/OPTIMISATION/Project2')
# read in the data
data = read.csv("N100StkPrices.csv", header = TRUE)
# clean up data
data = na.omit(data)
ticker = data$TICKER
# spun off MDLZ
delete = seq(1, dim(data)[1])[ticker == "MDLZ"]
data = data[-delete, ]
date = apply(as.matrix(data$date), MARGIN = 1, FUN = "toString")
date = as.Date(date, "%Y%m%d")
ticker = data$TICKER
price = data$PRC
shares = data$SHROUT
# Accounting for changes in ticker names
# KFT changed to KRFT in Oct 2012.
ticker[ticker == "KFT"] = "KRFT"
# SXCI changed to CTRX in Jul 2012.
ticker[ticker == "SXCI"] = "CTRX"
# HANS changed to MNST in Jan 2012.
ticker[ticker == "HANS"] = "MNST"
# convert prices to a matrix, arranged by rows of dates and columns of tickers
unique_dates = sort(unique((date)))
unique_tickers = sort(unique(ticker))
```

### Daily and Monthly Price matrices

```{r}
priceMat = matrix(NA, length(unique_dates), length(unique_tickers))
sharesMat = matrix(0, length(unique_dates), length(unique_tickers))

for (i in 1:length(unique_tickers)) {
  tic = unique_tickers[i]
  #print (tic)
  idx = is.element(unique_dates, date[ticker == tic])
  priceMat[idx, i] = price[ticker == tic]
  sharesMat[idx, i] = shares[ticker == tic]
}

rownames(priceMat) = as.character(unique_dates)
rownames(sharesMat) = as.character(unique_dates)

rm(list = c("data", "delete", "i", "idx", "price", "shares", "tic", "ticker", "date"))

# Read Monthly Data -------------------------------------------------------

# read in the data
mdata = read.csv("N100Monthly.csv", header = TRUE, stringsAsFactors = FALSE)

# clean up data
mdate = apply(as.matrix(mdata$date), MARGIN = 1, FUN = "toString")
mdate = as.Date(mdate, "%Y%m%d")

mticker = mdata$TICKER
mprice = mdata$PRC
mshares = mdata$SHROUT
mticker[mticker == "FOXA"] = "NWSA"


unique_mdates = sort(unique((mdate)))
unique_mtickers = sort(unique(mticker))

idx = is.element(unique_mtickers, unique_tickers)

# if (!all(idx)) {
#   print("Warning: Some tickers seem to be missing")
# }

monthlyPriceMat = matrix(NA, length(unique_mdates), length(unique_tickers))

for (i in 1:length(unique_tickers)) {
  tic = unique_tickers[i]
  idx = is.element(unique_mdates, mdate[mticker == tic])
  monthlyPriceMat[idx, i] = mprice[mticker == tic]
}

rm("mdata", "i", "idx", "mprice", "mshares", "mticker", "tic", "mdate")

```


## The Specifics

## Question 1
Calculate the daily returns for each stock using the 2012 price data

```{r}
priceToday = priceMat[2:nrow(priceMat),]
priceYesterday = priceMat[1:(nrow(priceMat)-1),]
dailyReturn = priceToday/priceYesterday - 1
# To keep the environment clean, delete variable priceToday and priceYesterday
rm('priceToday','priceYesterday')
# Print out the top 5 periods of the first 5 stocks' daily return
# The function percent() is from package 'scales' which gives the
# percentage presentation of a number.
display = apply(dailyReturn[1:5,1:5],2,percent)
rownames(display) = rownames(priceMat)[1:5]
print(display)
```

## Question 2
As our initial candidate for the similarity matrix, find the correlation matrix for the returns of the 100
stocks. Note that there will be missing data in the price matrix (NA which stands for Not Available).
You need to specify 'use' argument in the 'cor' function to handle NAs.


```{r}
rhoCor = cor(dailyReturn,use = 'complete')
#display the correlation matrix of the first 5 stocks
print(rhoCor[1:5,1:5],digit = 2)
```

## Question 3

Code the integer program above as another function that returns the weights for each of the stock that
needs to be in your portfolio.

### Calling ConstructFund function 
```{r}
source('constructFund.R')
#Weights for each stock
allocation = constructFund(rhoCor, q = 25, priceMat, sharesMat, unique_tickers, unique_dates)
y_correlation=allocation$solution[1:100]
y_correlation
```

This will amount to simply formulating the integer program, solving it and then using the market
capitalization of each company on the last date to compute weights. The output weights will be a
vector of size n with only q non-zero elements denoting the weights.

```{r}
#Basic checks
# Check1 - Number of stocks picked out of 100 in NASDAQ is 25   
sum(y_correlation)
# Check2 - The sum of weights is 1 after normalisation
sum(allocation$weight_fraction)
```

## Question 4

Use your weights to construct an index portfolio at the end of 2012.

### Portfolio of stocks 
```{r}
Portfolio_weights_correlation <- data.frame("Stock_name" = as.character(unique_tickers),
                                   "weights" = as.vector(allocation$weight_fraction))
Portfolio_weights_correlation=Portfolio_weights_correlation[Portfolio_weights_correlation$weights>0,]
Portfolio_weights_correlation
```

. Compare how this index portfolio performs monthly in 2013 as compared to the NASDAQ 100
index using the 2013 stock data provided.Here you may assume that you can directly invest in
the Index as if it is stock. 

Part 1: First, calculate the number of shares for every stock in your fund at
the end of 2012 using 1 million dollars in cash. 

```{r}
Investment_money=1000000
price_dec_end=priceMat["2012-12-31",]
price_dec_beg=priceMat["2012-12-03",]
Invested_money=as.vector(allocation$weight_fraction)*Investment_money
Index_portfolio=data.frame("Stock" = as.character(unique_tickers),"Investment"=Invested_money,"Price_dec_end"=price_dec_end,
                           "Price_dec_beg"=price_dec_beg,"Shares_bought" = Invested_money/price_dec_end)
Index_portfolio_25=(Index_portfolio[Index_potfolio$Investment>0,])
Index_portfolio_25
```

Part 2: Then calculate the value of your fund starting December 2012. 

```{r}
sum(Index_portfolio$Shares_bought*Index_portfolio$Price_dec_beg)
```


Part3: Next using the value of the index in December and 1 million cash, calculate the units of index you will buy. Then calculate the value of the index. 

```{r}
Index_value_NASDAQ_dec=2660.93 # Given
units_NASDAQ_dec=Investment_money/Index_value_NASDAQ_dec
units_NASDAQ_dec
```

We can buy the above number of units of NASDAQ 100 index (Assuming we can directly invest in the index as if it is a stock)

### Final Part: Portfolio vs NASDAQ Returns ( Dec 2012)

### Returns on our portfolio at the end of 2012 
```{r}
price_dec_beg_portfolio=price_dec_beg[which(y_correlation > 0)]
price_dec_end_portfolio=price_dec_end[which(y_correlation > 0)]
pct_returns_portfolio_dec <-(price_dec_end_portfolio - price_dec_beg_portfolio) / price_dec_beg_portfolio
Return_on_portfolio <- sum(allocation$weight_fraction * pct_returns_portfolio_dec) 
cat("Return on our protfolio for Dec 2012 is ", round(Return_on_portfolio*100,2),'%')
```

### Returns on NASDAQ at the end of 2012 
```{r}

share_dec_end_NASDAQ <- sharesMat["2012-12-31", 1:ncol(sharesMat)]
mcap_NASDAQ_dec_end=price_dec_end*share_dec_end_NASDAQ
NASDAQ_weight_correlation <- mcap_NASDAQ_dec_end/sum(mcap_NASDAQ_dec_end)
pct_returns_NASDAQ_dec <-(price_dec_end - price_dec_beg) / price_dec_beg
Return_on_NASDAQ <- sum(NASDAQ_weight_correlation * pct_returns_NASDAQ_dec)
cat("Return on our protfolio for Dec 2012 is ", round(Return_on_NASDAQ*100,2),'%')
```

As we can see, our Portfolio performs much better than NASDAQ index in December. 
Now moving on to monthly performance comparision of our portfolio with NASDAQ 100 in 2013 


### 2013 Monthly Returns 
```{r}
#Index_Portfolio Monthly returns

#Step 1:  Calculate stock wise percentage returns for each consecutive month in 2013.

monthly_return=rbind(diff(monthlyPriceMat),rep(0,100))
pct_returns <- monthly_return/monthlyPriceMat
pct_returns_index_portfolio <- pct_returns[1:nrow(pct_returns), which(y_correlation > 0)]

#Step 2: Because our investment proportion remains constant for our index, replicating these weights for each month in 2013
# and multiplying with returns to calucate overall monthly returns
overall_monthly_return_index=NULL
for (i in 1:nrow(pct_returns)){
  overall_monthly_return_index[i]=sum(pct_returns_index_portfolio[i,]*fund_fraction_correl[which(y_correl > 0)])
          }

# NASDAQ Monthly returns

pct_returns_NASDAQ=(pct_returns)

overall_monthly_return_NASDAQ=NULL
for (i in 1:nrow(pct_returns_NASDAQ)){
  overall_monthly_return_NASDAQ[i]=sum(pct_returns_NASDAQ[i,]*NASDAQ_fraction_correl)
}

```

Visualisations: Present your findings using any visualizations or tabulations. You can leave the shares as non-integers because the effect that the non-integer parts of shares have should be marginal.

```{r}
plot(overall_monthly_return_NASDAQ, col="black", pch="*", lty=1, ylim=c(-0.1,0.15),ylab='Returns',xlab='Month' )
lines(overall_monthly_return_NASDAQ, col="black",lty=1)
points(overall_monthly_return_index, col="red", pch="+")
lines(overall_monthly_return_index, col="red",lty=2)
legend(9.8,0.15,legend=c("NASDAQ","Portfolio"),col=c("black","red"),pch=c("","+"),lty=c(1,2), ncol=1)
```

Insights & Conclusion: 
1) On an average, it appears that our portfolio closely follows trends in NASDAQ 100 across months which means that our portfolio can be considered as a good representation of the entire Index.
2) Also our portfolio is doing better than NASDAQ in extreme highs. We can infer that our portfolio is slightly a riskier fund as the stocks picked are not diverse. 


## Question 5

Earlier you used correlation as the similarity measure. Now instead create your similarity measure and
put it in a function similarityMat that has the same inputs and outputs
This criterion is linked to a Learning Outcome explanation of similarity matrix

. Use this rho in your function call to constructFund and as in Step 4, evaluate the performance of
this fund as well. Please compare the new fund to the previous fund. Explain why the performance
is better (or worse). Repeating the above steps and comparing the performance in case of a new similarity measure 
 
We have selected Cosine similarity as our new measure 
Reasons are stated below:
Cosine similarity is a measure of similarity between two non-zero vectors of an inner product space that measures the cosine of the angle between them. Further, cosine similarity remains same for a subset of data, however correlation changes for each subset. Since we are dealing with a subset of stocks from NASDAQ 100, a constant measure of similarity across different subsets would be better.

```{r}
#Step 1: Calculating cosine similarity matrix
source('similarityMat.R')
rhoCor_cosine=similarityMat(priceMat, sharesMat, unique_tickers, unique_dates)

#Step2 : Finding the weights for each stock based on new similarity matrix
allocation2 = constructFund(rhoCor_cosine, q = 25, priceMat, sharesMat, unique_tickers, unique_dates)
y_cosine <-allocation2$solution[1:100]
```



```{r}
#Basic checks
# Check1 - Number of stocks picked out of 100 in NASDAQ is 25   
sum(y_cosine)
# Check2 - The sum of weights is 1 after normalisation
sum(allocation2$weight_fraction)
``` 
 stock_weights_cosine <- data.frame("stocks" = as.character(unique_tickers),
                                   "weights" = as.vector(fund_fraction_cosine))
stock_weights_cosine=stock_weights_cosine[stock_weights_cosine$weights>0,]

# Weights of each stocks that's in the fund 
stock_weights_cosine_sorted=stock_weights_cosine[order(-stock_weights_cosine[,2]),] 
dim(stock_weights_cosine_sorted)


```{r}
# Allocation of weights in new portfolio 
Invested_money_P2=as.vector(allocation2$weight_fraction)*Investment_money
Index_portfolio_new=data.frame("Stock" = as.character(unique_tickers),"Investment"=Invested_money_P2,
                               "weights"= as.vector(allocation2$weight_fraction),
                               "Price_dec_end"=price_dec_end,"Price_dec_beg"=price_dec_beg,
                           "Shares_bought" = Invested_money_P2/price_dec_end)
Index_portfolio_new_25=(Index_portfolio_new[Index_portfolio_new$Investment>0,])
Index_portfolio_new_25
```

# Observations 
1) New stocks that have come up with minor changes in the weights in the rest of the stocks 
```{r}
setdiff((Index_portfolio_new_25$Stock),(Index_portfolio_25$Stock))
```
2) Old stocks that have been replaced with minor changes in the weights in the rest of the stocks 
```{r}
setdiff((Index_portfolio_25$Stock),(Index_portfolio_new_25$Stock))
```

3) Comparision of returns at the end of 2012


```{r}
# Constructing new Index portfolion at the end of 2012.
price_dec_end=priceMat["2012-12-31",] #End of 2012 price matrix 
Investment_money=1000000
Invested_money=as.vector(allocation2$weight_fraction)*Investment_money
Index_portfolio_cosine=data.frame("Stock" = as.character(unique_tickers),"Investment"=Invested_money,"Price"=price_dec_end,
                           "Shares_bought" = Invested_money/price_dec_end)
#Index_portfolio_cosine[Index_portfolio_cosine$Shares_bought>0,]
#Returns on our portfolio at the end of 2012 

price_dec_beg_new_portfolio=priceMat["2012-12-03",][which(y_cosine > 0)]
price_dec_end_new_portfolio=priceMat["2012-12-31",][which(y_cosine > 0)]

pct_returns_new_portfolio_dec <-(price_dec_end_new_portfolio - price_dec_beg_new_portfolio) / price_dec_beg_new_portfolio
Return_on_new_portfolio <- sum(allocation2$weight_fraction * pct_returns_new_portfolio_dec) *Investment_money
ROI_new_portfolio <- round((Return_on_new_portfolio/Investment_money)*100,2)
ROI_new_portfolio

```

Our new portfolio with ROI of 5.03% performs better than our NASDAQ 100. But earlier portfolio with correlation earned us  return (3.25%) 


4) Comparision of overall_monthly returns in 2013 
```{r}
#New Index Portfolio monthly returns

#Step 1:  Calculate stock wise percentage returns for each consecutive month in 2013.

monthly_return=rbind(diff(monthlyPriceMat),rep(0,100))
pct_returns <- monthly_return/monthlyPriceMat
pct_returns_index_new_portfolio <- pct_returns[1:nrow(pct_returns), which(y_cosine > 0)]
dim(pct_returns_index_new_portfolio)

#Step 2: Because our investment proportion remains constant for our index, replicating these weights for each month in 2013
# and multiplying with returns to calucate overall monthly returns
new_overall_monthly_return_index=NULL
for (i in 1:nrow(pct_returns)){
  new_overall_monthly_return_index[i]=sum(pct_returns_index_new_portfolio[i,]*allocation2$weight_fraction[which(y_cosine > 0)])
}
new_overall_monthly_return_index

overall_monthly_return_index

#overall_monthly_return_NASDAQ


#Compaision of all 2 portfolios wrt NASDAQ
plot(overall_monthly_return_NASDAQ, col="black", pch="*", lty=1, ylim=c(-0.1,0.15),ylab='Returns',xlab='Month' )
lines(overall_monthly_return_NASDAQ, col="black",lty=1)
points(overall_monthly_return_index, col="blue", pch="+")
lines(overall_monthly_return_index, col="blue",lty=2)
points(new_overall_monthly_return_index, col="red", pch="-")
lines(new_overall_monthly_return_index, col="red",lty=3)
legend(9,0.15,legend=c("NASDAQ","Portfolio","New_Portfolio"),col=c("black","blue","red"),
       pch=c("o","*","l"),lty=c(1,2,3), ncol=1)

```

Considering that cosine similarity is a very similar similarity metric as correlation, with only a small variation. Cosine similarity is a dot product of unit vectors, while correlation is a cosine similarity between centered vectors. Thus effectively ther ae very similar metrics. This is also reflected in the fact that they have very similar performance across all the months in 2013. 

