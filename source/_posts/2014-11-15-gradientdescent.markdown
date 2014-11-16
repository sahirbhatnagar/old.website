---
layout: post
title: "Gradient Descent"
date: 2014-11-15 23:16
comments: true
categories: [R, optimization, regression]
published: true
---

I am taking the Machine Learning course on [Coursera](https://class.coursera.org/ml-007/lecture) being taught by Andrew Ng. It is turning out to be useful so far, and he has presented the material clearly. It's a nice introduction to the Machine Learning/Computer Science language, since I come from a statistics background. 

I learned about gradient descent today for simple linear regression. The following is my code in R and I compare it to the *lm* function in base *R*. 

I am using the **Prostate** dataset from the *lasso2* package. The model I am fitting is:

$$ lpsa = \beta_0 + \beta_1 \times lcavol $$


```r
#prostate cancer data set
library(lasso2)
```

```
## R Package to solve regression problems while imposing
## 	 an L1 constraint on the parameters. Based on S-plus Release 2.1
## Copyright (C) 1998, 1999
## Justin Lokhorst   <jlokhors@stats.adelaide.edu.au>
## Berwin A. Turlach <bturlach@stats.adelaide.edu.au>
## Bill Venables     <wvenable@stats.adelaide.edu.au>
## 
## Copyright (C) 2002
## Martin Maechler <maechler@stat.math.ethz.ch>
```

```r
data(Prostate)

# hypothesis
hypothesis <- function(x, theta0,theta1){
    h <- theta0 + theta1*x
    return(h)
}

# Jacobian
deriv <- function(x,y,theta0,theta1){
    dt0 <- (length(x))^(-1)* sum((hypothesis(x,theta0,theta1)-y))
    dt1 <- (length(x))^(-1)* t(x) %*% (hypothesis(x,theta0,theta1)-y)
    return(c(dt0,dt1))
}

theta <- c(0,0)
alpha <- 0.5
X <- Prostate$lcavol
Y <- Prostate$lpsa
i=1
#
theta.star <- deriv(Prostate$lcavol,Prostate$lpsa,theta[1],theta[2])
# set convergence threshold
threshold <- 1e-7
# logical to check if threshold has been achieved
continue=TRUE

while (continue){
    theta[1] <- theta.star[1] - alpha*deriv(x=X,y=Y,theta.star[1],theta.star[2])[1]
    theta[2] <- theta.star[2] - alpha*deriv(x=X,y=Y,theta.star[1],theta.star[2])[2]
    continue <- (abs((theta.star-theta)[1])>threshold & abs((theta.star-theta)[2])>threshold)
    theta.star[1] <- theta[1]
    theta.star[2] <- theta[2]
    i=i+1
}

# number of iterations
i
```

```
## [1] 214
```

```r
# beta0 and beta1
theta.star
```

```
## [1] 1.5073 0.7193
```

```r
# compare to lm
fit <- lm(lpsa~lcavol, data=Prostate)
summary(fit)
```

```
## 
## Call:
## lm(formula = lpsa ~ lcavol, data = Prostate)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -1.6762 -0.4165  0.0986  0.5071  1.8967 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)   1.5073     0.1219    12.4   <2e-16 ***
## lcavol        0.7193     0.0682    10.6   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.787 on 95 degrees of freedom
## Multiple R-squared:  0.539,	Adjusted R-squared:  0.535 
## F-statistic:  111 on 1 and 95 DF,  p-value: <2e-16
```
