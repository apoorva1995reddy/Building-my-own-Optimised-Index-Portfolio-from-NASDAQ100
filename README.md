# Building my own index fund that outperforms NASDAQ 100 returns 

Objective: Integer Programming - Optimisation problem

Constructing an index fund that tracks a specific broad market index could be done simply purchasing all
the stocks in the index, with the same weights as in the index. However, this approach is impractical (many
small positions) and expensive. An index fund with q stocks, where q is substantially lower than the size of
the target population (n), seems desirable.

 I'm planning to create an Index fund with 25 stocks to track the NASDAQ-100 index. 

Approach : 

Step 1:  First, I will formulate an integer program that picks exactly 25 out of 100 stocks for my portfolio 

Step 2:  Solving the integer problem using the similarity of daily returns among 100 stocks and some other constraints to arrive at the best pcik of 25 stocks

Step 3:  Constructing a portfolio with appropriate weights for the investments based on the weighted average of the market cap of the selected 25 stocks 

Step 4:  Performance comparsion of next year's monthly returns based on the current portfolio weights with the returns of NASDAQ 100 index


