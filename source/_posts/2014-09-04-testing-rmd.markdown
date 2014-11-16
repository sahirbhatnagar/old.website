---
layout: post
title: "testing Rmd"
date: 2014-09-04 14:37
comments: true
categories: [R, Rmarkdown]
published: true
---


```
## Error: Invalid name specified, see ?BibOptions
```


It has been quiet the last months here - main reason is that I'm working on my master's thesis.
I have already prepared some more examples from 'Quantitative Ecotoxicolgy', but I didn't come to publish them here.


This post is about collinearity and the implications for linear models. The best way to explore this is by simulations - where I create data with known properties and look what happens.


### Create correlated random variables

The first problem for this simulation was: How can we create correlated random variables?

This simulation is similar to the one in, where it is also mentioned that one could use Cholesky Decompostion to create correlated variables:

What this function function does:

* Create two normal random variables (X1, X2 ~ N(0, 1))
* Create desired correlation matrix
* Compute the Choleski factorization of the correlation matrix ( R )
* Apply the resulting matrix on the two variables (this rotates, shears and scales the variables so that they are correlated)
* Create a dependent variable `y` after the model:

`y ~ 5 + 7*X1 + 7*X2 + e` with `e ~ N(0, 1)`



```r
#############################################################################
# create two correlated variables and a dependent variable
# n : number of points
# p:correlation

datagen <- function(n , p){
  # random points N(0,1)
  x1 <- rnorm(n)
  x2 <- rnorm(n)
  X <- cbind(x1, x2)
  
  # desired correlation matrix
  R <- matrix(c(1, p, p, 1), ncol = 2)
  
  # use cholesky decomposition `t(U) %*% U = R`
  U <- chol(R)
  corvars <- X %*% U
  
  # create dependent variable after model:
  # y ~ 5 + 7 * X1 + 7 * X2 + e | E ~ N(0,10)
  y <- 5 + 7*corvars[,1] + 7*corvars[,2] + rnorm(n, 0, 1)
  df <- data.frame(y, corvars)
  return(df)
}
```


Let's see if it works. 
This creates two variables with 1000 observations with a correlation of 0.8 between them and a dependent variable.

```r
df1 <- datagen(n = 1000, p = 0.8)
```

The correlation between X1 and X2 is as desired nearly 0.8

```r
cor(df1)
```

```
##          y      X1      X2
## y  1.00000 0.94390 0.94367
## X1 0.94390 1.00000 0.79192
## X2 0.94367 0.79192 1.00000
```

And the data follows the specified model.

```r
mod <- lm(y~X1+X2, data = df1)
summary(mod)
```

```
## 
## Call:
## lm(formula = y ~ X1 + X2, data = df1)
## 
## Residuals:
##    Min     1Q Median     3Q    Max 
## -2.908 -0.685  0.008  0.692  3.180 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)   5.0440     0.0316     160   <2e-16 ***
## X1            7.0517     0.0530     133   <2e-16 ***
## X2            6.9496     0.0524     133   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.997 on 997 degrees of freedom
## Multiple R-squared:  0.994,	Adjusted R-squared:  0.994 
## F-statistic: 8.48e+04 on 2 and 997 DF,  p-value: <2e-16
```

```r
pairs(df1)
```

![plot of chunk example_datagen3](../figure/2014-09-04-testing-rmd-example_datagen3.png) 
