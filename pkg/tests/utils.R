## Test distribution functions

## note - standard q fns in R return zero for p=0 for positive dists, but -Inf for real dists.

library(flexsurv)

## for local use
if (0) {
    library(survival)
    for (i in list.files("../R", "*.R$"))
        source(paste("../R/",i,sep=""))
}

tol <- 1e-06
test <- function(x, y) {
    stopifnot(isTRUE(all.equal(x, y, tol=tol)))
}

## Generalized F

test(dgenf(c(-1,1,2,3,4), mu=0, sigma=1, Q=0, P=1), # FIXME add limiting value for x=0
     c(0, 0.353553390593274, 0.140288989252053, 0.067923038519582, 0.038247711235678))
test(dgenf(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=0, P=0),
     dgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=0))
x <- c(-1,0,1,2,3,4); mu <- 2.2; sigma <- 1.6; Q <- 0.2; P <- 1.2
delta <- (Q^2 + 2*P)^{1/2}
s1 <- 2 / (Q^2 + 2*P + Q*delta); s2 <- 2 / (Q^2 + 2*P - Q*delta)
test(dgenf(x, mu=mu, sigma=sigma, Q=Q, P=P),
     dgenf.orig(x, mu=mu, sigma=sigma/delta, s1=s1, s2=s2))
test(dgenf(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=c(0,1,2), P=0),
     dgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=c(0,1,2)))

x <- c(-1,1,2,3,4); mu <- 2.2; sigma <- 1.6; Q <- 0; P <- 1
s1 <- 2 / (Q^2 + 2*P + Q*delta); s2 <- 2 / (Q^2 + 2*P - Q*delta)
delta <- (Q^2 + 2*P)^{1/2}
if (is.element("eha", installed.packages()[,1])) {
    library(eha)
    test(dgenf(x, mu=mu, sigma=sigma, Q=Q, P=P),
         dllogis(x, shape=sqrt(2)/sigma, scale=exp(mu)))
    detach("package:eha")
}

test(dgengamma(x, mu=mu, sigma=sigma, Q=sigma),
     dgamma(x, shape=1/sigma^2, scale=exp(mu)*sigma^2))

test(pgenf(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=0, P=1),
     c(0, 0, 0.5, 0.727159434644773, 0.825443507527843, 0.876588815661789))
test(pgenf(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=0, P=0),
     pgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=0))
test(pgenf(x, mu=mu, sigma=sigma, Q=Q, P=P),
     pgenf.orig(x, mu=mu, sigma=sigma/delta, s1=s1, s2=s2))

test(qgenf(p=0.25, mu=0, sigma=1, Q=0, P=1), 0.459858613264917)
test(qgenf(p=0.25, mu=0, sigma=1, Q=0, P=1), qgeneric(pgenf, p=0.25, mu=0, sigma=1, Q=0, P=1))
test(qgenf(p=0, mu=0, sigma=1, Q=0, P=1), 0)
test(qgenf(p=0.25, mu=0, sigma=1, Q=0, P=0),  qgengamma(p=0.25, mu=0, sigma=1, Q=0))
test(qgenf(pgenf(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, Q=0, P=1), mu=0, sigma=1, Q=0, P=1),
     c(0,0,0,1,2,3,4))
test(qgenf(pgenf(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, Q=-1, P=1), mu=0, sigma=1, Q=-1, P=1),
     c(0,0,0,1,2,3,4))
test(qgengamma(pgenf(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, Q=0, P=0), mu=0, sigma=1, Q=0),
     c(0,0,0,1,2,3,4))
x <- c(0.1,0.4,0.6)
test(qgenf(x, mu=mu, sigma=sigma, Q=Q, P=P),
     qgenf.orig(x, mu=mu, sigma=sigma/delta, s1=s1, s2=s2))

rgenf(n=10, mu=0, sigma=1, Q=0, P=1)
set.seed(22061976)
x <- rgenf(n=10, mu=0, sigma=1, Q=0, P=0)
set.seed(22061976)
y <- rgengamma(n=10, mu=0, sigma=1, Q=0)
test(x, y)
if (interactive())  {
    x <- c(-1,0,1,2,3,4); mu <- 2.2; sigma <- 0.6; Q <- 0.2; P=0.1
    delta <- (Q^2 + 2*P)^{1/2}
    s1 <- 2 / (Q^2 + 2*P + Q*delta); s2 <- 2 / (Q^2 + 2*P - Q*delta)
    plot(density(rgenf(10000, mu=mu, sigma=sigma, Q=Q, P=P)))
    lines(density(rgenf.orig(10000, mu=mu, sigma=sigma/delta, s1=s1, s2=s2)), lty=2)
}

## Generalized gamma

test(dgengamma(c(-1,1,2,3,4), mu=0, sigma=1, Q=1),  # FIXME value for x=0 and add here
     c(0, 0.367879441171442, 0.135335283236613, 0.0497870683678639, 0.0183156388887342))
test(dgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=0),
     dlnorm(c(-1,0,1,2,3,4), meanlog=0, sdlog=1))
test(dgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1:3, Q=0),
     dlnorm(c(-1,0,1,2,3,4), meanlog=0, sdlog=1:3))
test(dgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1:3, Q=0, log=TRUE),
     dlnorm(c(-1,0,1,2,3,4), meanlog=0, sdlog=1:3, log=TRUE))
test(dgengamma(c(1,2,3,4), mu=0.1, sigma=1.2, Q=1),
     dweibull(c(1,2,3,4), shape=1/1.2, scale=exp(0.1)))  # only defined for x>0 anyway
x <- c(1,2,3,4); mu <- 0.4; sigma <- 1.2
test(dgengamma(x, mu=mu, sigma=sigma, Q=sigma),
     dgamma(x, shape=1/sigma^2, scale=exp(mu)*sigma^2))

x <- c(-1,1,2,3,4); shape <- 2.2; scale <- 1.6; k <- 1.9
# FIXME add limiting value for x=0
test(dgengamma.orig(x, shape=shape, scale=scale, k=k),
     dgengamma(x, mu=log(scale) + log(k)/shape, sigma=1/(shape*sqrt(k)), Q=1/sqrt(k)))

test(pgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=1),
     c(0, 0, 0.632120558828558, 0.864664716763387, 0.950212931632136, 0.981684361111266))
test(pgengamma(c(-1,0,1,2,3,4), mu=0, sigma=1, Q=0),
     plnorm(c(-1,0,1,2,3,4), meanlog=0, sdlog=1))
test(pgengamma(c(-1,0,1,2,3,4), mu=0.1, sigma=1.2, Q=1),
     pweibull(c(-1,0,1,2,3,4), shape=1/1.2, scale=exp(0.1)))
x <- c(1,2,3,4); mu <- 0.4; sigma <- 1.2
test(pgengamma(x, mu=mu, sigma=sigma, Q=sigma),
     pgamma(x, shape=1/sigma^2, scale=exp(mu)*sigma^2))

test(qgengamma(p=0.25, mu=0, sigma=1, Q=1), 0.287682072451781)
test(qgengamma(p=0.25, mu=0, sigma=1, Q=1), qgeneric(pgengamma, p=0.25, mu=0, sigma=1, Q=1))
test(qgengamma(p=0, mu=0, sigma=1, Q=1), 0)
test(qgengamma(p=0.25, mu=0, sigma=1, Q=0), qlnorm(p=0.25, meanlog=0, sdlog=1))
test(qgengamma(p=0.25, mu=0.1, sigma=1.2, Q=1), qweibull(p=0.25, scale=exp(0.1), shape=1/1.2))
test(qgengamma(pgengamma(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, Q=1), mu=0, sigma=1, Q=1),
     c(0,0,0,1,2,3,4))
test(qgengamma(pgengamma(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, Q=-1), mu=0, sigma=1, Q=-1),
     c(0,0,0,1,2,3,4))
test(qlnorm(pgengamma(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, Q=0), meanlog=0, sdlog=1),
     c(0,0,0,1,2,3,4))
test(qlnorm(pgengamma(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, Q=0, log=TRUE), meanlog=0, sdlog=1, log=TRUE),
     c(0,0,0,1,2,3,4))
test(qgengamma(p=0.25, mu=0, sigma=1, Q=1, lower.tail=TRUE), qgeneric(pgengamma, p=0.25, mu=0, sigma=1, Q=1, lower.tail=TRUE))

rgengamma(n=10, mu=0, sigma=1, Q=0)
set.seed(22061976)
x <- rgengamma(n=10, mu=0, sigma=1, Q=0)
set.seed(22061976)
y <- rlnorm(n=10, meanlog=0, sdlog=1)
test(x, y)

## Generalised F (original)

## FIXME add value for x=0
test(dgenf.orig(c(-1,1,2,3,4), mu=0, sigma=1, s1=1, s2=1),
     c(0, 0.25, 0.111111111111111, 0.0625, 0.04))
x <- c(-1,0,1,2,3,4); mu <- 0.1; sigma <- 1.2; s1 <- 1.7; s2 <- 10000000
dgenf.orig(x, mu=mu, sigma=sigma, s1=s1, s2=s2)
dgengamma.orig(x, shape=1/sigma, scale=exp(mu) / s1^sigma, k=s1) # equal for large s2

test(pgenf.orig(c(-1,0,1,2,3,4), mu=0, sigma=1, s1=1, s2=1),
     c(0, 0, 0.5, 0.666666666666667, 0.75, 0.8))
x <- c(-1,0,1,2,3,4); mu <- 0.1; sigma <- 1.2; s1 <- 1.7; s2 <- 10000000
pgenf.orig(x, mu=mu, sigma=sigma, s1=s1, s2=s2)
pgengamma.orig(x, shape=1/sigma, scale=exp(mu) / s1^sigma, k=s1) # equal for large s2

test(qgenf.orig(p=0.25, mu=0, sigma=1, s1=1, s2=1), 0.333333333333333)
test(qgenf.orig(p=0.25, mu=0, sigma=1, s1=1, s2=1), qgeneric(pgenf.orig, p=0.25, mu=0, sigma=1, s1=1, s2=1))
test(qgenf.orig(p=0, mu=0, sigma=1, s1=1, s2=1), 0)
test(qgenf.orig(pgenf.orig(q=c(-2,-1,0,1,2,3,4), mu=0, sigma=1, s1=1, s2=1), mu=0, sigma=1, s1=1, s2=1),
     c(0,0,0,1,2,3,4))
x <- c(0.1, 0.4, 0.7); mu <- 0.1; sigma <- 1.2; s1 <- 1.7; s2 <- 10000000
qgenf.orig(x, mu=mu, sigma=sigma, s1=s1, s2=s2)
qgengamma.orig(x, shape=1/sigma, scale=exp(mu) / s1^sigma, k=s1) # equal for large s2

rgenf.orig(n=10, mu=0, sigma=1, s1=1, s2=1)
if (interactive())  {
    mu <- 0.1; sigma <- 1.2; s1 <- 1.7; s2 <- 100000000
    plot(density(rgenf.orig(10000, mu=mu, sigma=sigma, s1=s1, s2=s2)))
    lines(density(rgengamma.orig(10000, shape=1/sigma, scale=exp(mu) / s1^sigma, k=s1)), lty=2)
}

## Generalised gamma (original)
test(dgengamma.orig(c(-1,0,1,2,3,4), shape=1.2, scale=1.3, k=1.4),
     c(0, 0, 0.419477559803262, 0.260699967439176, 0.120081193404263, 0.0474236822588797))
test(dgengamma.orig(c(1,2,3,4), shape=1.2, scale=1.3, k=1),
     dweibull(c(1,2,3,4), shape=1.2, scale=1.3))
test(dgengamma.orig(c(1,2,3,4), shape=1, scale=1.3, k=1),
     dexp(c(1,2,3,4), rate=1/1.3))
test(dgengamma.orig(c(1,2,3,4), shape=1, scale=1.3, k=1.4),
     dgamma(c(1,2,3,4), shape=1.4, scale=1.3))

shape <- 1.2; scale <- 1.3; k <- 10000
pgengamma.orig(2800 + 1:4, shape=shape, scale=scale, k=k)
plnorm(2800 + 1:4, log(scale) + log(k)/shape, 1/(shape*sqrt(k)))

test(pgengamma.orig(c(1,2,3,4), shape=1.2, scale=1.3, k=1),
     pweibull(c(1,2,3,4), shape=1.2, scale=1.3))
test(pgengamma.orig(c(1,2,3,4), shape=1, scale=1.3, k=1),
     pexp(c(1,2,3,4), rate=1/1.3))
test(pgengamma.orig(c(1,2,3,4), shape=1, scale=1.3, k=1.4),
     pgamma(c(1,2,3,4), shape=1.4, scale=1.3))

test(qgengamma.orig(p=0.25, shape=1.2, scale=1.3, k=1), qgeneric(pgengamma.orig, p=0.25, shape=1.2, scale=1.3, k=1))
test(qgengamma.orig(c(0.1, 0.4, 0.7), shape=1.2, scale=1.3, k=1),
     qweibull(c(0.1, 0.4, 0.7), shape=1.2, scale=1.3))
test(qgengamma.orig(c(0.1, 0.4, 0.7), shape=1, scale=1.3, k=1),
     qexp(c(0.1, 0.4, 0.7), rate=1/1.3))
test(qgengamma.orig(c(0.1, 0.4, 0.7), shape=1, scale=1.3, k=1.4),
     qgamma(c(0.1, 0.4, 0.7), shape=1.4, scale=1.3))

if (interactive()){
    plot(density(rgengamma.orig(100000, shape=1.2, scale=1.3, k=1)))
    lines(density(rweibull(100000, shape=1.2, scale=1.3)), lty=2)
    plot(density(rgengamma.orig(100000, shape=1, scale=1.5, k=1)))
    lines(density(rexp(100000, rate=1/1.5)), lty=2)
    plot(density(rgengamma.orig(100000, shape=1, scale=3.3, k=1.2)))
    lines(density(rgamma(100000, shape=1.2, scale=3.3)), lty=2)
}

## warnings/errors
try({
dgengamma.orig(c(1,2,3,4), shape=-1.2, scale=-1.3, k=-1)
dgengamma.orig(c(1,2,3,4), shape=c(-1.2, 1), scale=1.3, k=1)
dgengamma.orig(c(2,4), shape=1, scale=1.3, k=1)
pgengamma.orig(c(1,2,3,4), shape=-1.2, scale=-1.3, k=-1)
qgengamma.orig(c(1,2,3,4), shape=-1.2, scale=-1.3, k=-1)
rgengamma.orig(3, shape=-1.2, scale=-1.3, k=-1)
dgengamma(1, 1, -2, 1)
pgengamma(1, 1, -2, 1)
qgengamma(0.1, 1, -2, 1)
rgengamma(1, 1, -2, 1)
dgenf(c(1,1), 1, -2, 1, -1)
pgenf(1, 1, -2, 1, 1)
qgenf(0.1, 1, -2, 1, 0)
rgenf(4, 1, -2, 1, 1)
})


## TODO test haz and cum haz functions - common shapes?
x <- seq(0.1, 100, by=0.1)
plot(x, hgengamma.orig(x, 1, 1, 1), type="l")
## eh why does it blow up at 35?   supposed to be constant
## Num and denom both converge to 0.
## FIXME should provide actual hazard functions


## Gompertz

x <- c(-1,0,1,2,3,4)
test(dgompertz(x, shape=0.1, rate=0.2), c(0, 0.2, 0.179105591827508, 0.156884811322895, 0.134101872197705, 0.111571759992743))
dgompertz(x, shape=0.0001, rate=0.2)
dgompertz(x, shape=-0.0001, rate=0.2)
dexp(x, rate=0.2)
test(dgompertz(x, shape=0, rate=0.2), dexp(x, rate=0.2))
d <- numeric(6); for (i in 1:6) d[i] <- dgompertz(x[i], shape=-0.0001, rate=i/5)
test(d, dgompertz(x, shape=-0.0001, rate=1:6/5))

pgompertz(x, shape=0, rate=0.2)
pgompertz(x, shape=0.001, rate=0.2)
pgompertz(x, shape=-0.001, rate=0.2)
test(pgompertz(x, shape=0, rate=0.2), pexp(x, rate=0.2))
p <- numeric(6); for (i in 1:6) p[i] <- pgompertz(x[i], shape=-0.0001, rate=i/5)
test(p, pgompertz(x, shape=-0.0001, rate=1:6/5))

x <- c(0.1, 0.2, 0.7)
test(qgompertz(x, shape=0.1, rate=0.2), qgeneric(pgompertz, p=x, shape=0.1, rate=0.2))
test(qgompertz(x, shape=0, rate=0.2), qexp(x, rate=0.2))
test(x, pgompertz(qgompertz(x, shape=0.1, rate=0.2), shape=0.1, rate=0.2))
q <- numeric(3); for (i in 1:3) q[i] <- qgompertz(x[i], shape=-0.0001, rate=i/5)
test(q, qgompertz(x, shape=-0.0001, rate=1:3/5))
x <- c(0.5, 1.06, 4.7)
test(x, qgompertz(pgompertz(x, shape=0.1, rate=0.2), shape=0.1, rate=0.2))
q <- numeric(3); for (i in 1:3) q[i] <- qgompertz(x[i], shape=-0.0001, rate=i/5)
test(q, qgompertz(x, shape=-0.0001, rate=1:3/5))
qgompertz(p=c(-1, 0, 1, 2), 1, 1)

if (interactive()) {
    plot(density(rgompertz(10000, shape=0.1, rate=0.2)))
    x <- seq(0, 20, by=0.001)
    lines(x, dgompertz(x, shape=0.1, rate=0.2), lty=2)
}
## Gompertz with chance of living forever
shape <- -0.6; rate <- 1.8
x <- c(0.8, 0.9, 0.97, 0.99)
test(qgompertz(x, shape=shape, rate=rate), c(1.28150707286845, 2.4316450975351, Inf, Inf))
# qgeneric(pgompertz, p=x, shape=shape, rate=rate) # won't work - needs smoothness
test(pgompertz(Inf, shape=shape, rate=rate), 0.950212931632136)

set.seed(1); rgompertz(4, shape=shape, rate=1:4)
set.seed(1);
rgompertz(1, shape=shape, rate=1)
rgompertz(1, shape=shape, rate=2)
rgompertz(1, shape=shape, rate=3)
rgompertz(1, shape=shape, rate=4)
rgompertz(1:2, shape=1, rate=1)
rgompertz(3, shape=c(1,NaN, NA), rate=1)
rgompertz(3, shape=c(NaN), rate=1)
rgompertz(4, shape=c(1,NA), rate=1)



## Spline distribution functions
regscale <- 0.786; cf <- 1.82
a <- 1/regscale; b <- exp(cf)
d1 <- dweibull(1, shape=a, scale=b)
d2 <- dsurvspline(1, gamma=c(log(1 / b^a), a))
test(d1, d2)
p1 <- pweibull(1, shape=a, scale=b)
p2 <- psurvspline(1, gamma=c(log(1 / b^a), a))
test(p1, p2)
meanlog <- 1.52; sdlog <- 1.11
d1 <- dlnorm(1, meanlog, sdlog)
d2 <- dsurvspline(1, gamma = c(-meanlog/sdlog, 1/sdlog), scale="normal")
test(d1, d2)
p1 <- plnorm(1, meanlog, sdlog)
p2 <- psurvspline(1, gamma = c(-meanlog/sdlog, 1/sdlog), scale="normal")
test(p1, p2)
# TODO document 
#H1 <- Hlnorm(1, meanlog, sdlog)
#H2 <- Hsurvspline(1, gamma = c(-meanlog/sdlog, 1/sdlog), scale="normal")
#test(H1, H2)
g <- c(0.1, 0.2, 0.3); k <- c(2,3,4)
test(dsurvspline(1,g,knots=k)/(1 - psurvspline(1,g,knots=k)),  hsurvspline(1,g,knots=k))
test(dsurvspline(1,g,knots=k,scale="odds")/(1 - psurvspline(1,g,knots=k,scale="odds")),  hsurvspline(1,g,knots=k,scale="odds"))
test(dsurvspline(1,g,knots=k,scale="normal")/(1 - psurvspline(1,g,knots=k,scale="normal")),  hsurvspline(1,g,knots=k,scale="normal"))
test(-log(1 - psurvspline(0.2,g,knots=k)), Hsurvspline(0.2,g,knots=k))
test(-log(1 - psurvspline(0.2,g,knots=k,scale="odds")), Hsurvspline(0.2,g,knots=k,scale="odds"))
test(-log(1 - psurvspline(0.2,g,knots=k,scale="normal")), Hsurvspline(0.2,g,knots=k,scale="normal"))


## Hazards

## Different x
test(hexp(c(-Inf, NaN, Inf, NA, -1, 0, 1), c(1,2,3)), c(0,NaN,3,NA,0,3,1))
test(hexp(c(-Inf, NaN, Inf, NA, -1, 0, 1), c(1,2,3), log=TRUE), log(c(0,NaN,3,NA,0,3,1)))
## Different rates
test(Hexp(c(-Inf, NaN, Inf,  NA, -1, 0,  1, 2, 4), c(1,2,3)), c(0,NaN,Inf, NA,0,0, 1, 4, 12))
test(Hexp(c(-Inf, NaN, Inf,  NA, -1, 0,  1, 2, 4), c(1,2,3), log=TRUE), log(c(0,NaN,Inf, NA,0,0, 1, 4, 12)))
## Hazard def
test(dexp(c(1,2,3), c(2,3,4)) / (1 - pexp(c(1,2,3), c(2,3,4))), hexp(c(1,2,3), c(2,3,4)))
test(-log(1 - pexp(c(1,2,3), c(2,3,4))), Hexp(c(1,2,3), c(2,3,4)))
test(log(-log(1 - pexp(c(1,2,3), c(2,3,4)))), Hexp(c(1,2,3), c(2,3,4), log=TRUE))
## warnings
hexp(c(1,1,1), c(-1, 0, 2))
dexp(c(1,1,1), c(-1, 0, 2))

### Weibull
test(hweibull(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3)), 
     dweibull(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3)) / (1 - pweibull(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3))))
test(Hweibull(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3)),
     -pweibull(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3), lower.tail=FALSE, log.p=TRUE))
## exponential reduction
test(hweibull(c(-Inf, NaN, Inf, NA, -1, 0, 1), c(1,1,1), c(1,2,3)), c(0,NaN,1/3,NA,0,1/3,1))
### positive shape, increasing 
hweibull(c(-Inf, -1, 0, 1, 2, Inf), 2, 2.5)
### neg shape, decreasing 
hweibull(c(-Inf, -1, 0, 1, 2, Inf), 0.5, 1)
test(Hexp(c(-Inf, NaN, Inf,  NA, -1, 0,  1, 2, 4), c(1,2,3)), c(0,NaN,Inf, NA,0,0, 1, 4, 12))

## Gompertz
test(hgompertz(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3)),
     dgompertz(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3)) / (1 - pgompertz(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3))))
test(Hgompertz(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3)), 
     -pgompertz(c(1,1,1,1), c(1,1,2,2), c(1,3,1,3), lower.tail=FALSE, log.p=TRUE))
## reduction to exponential
test(hgompertz(c(2,4), c(0,0), c(2,2)), hexp(c(2,4), c(2,2)))
test(Hgompertz(c(2,4), c(0,0), c(2,2)), Hexp(c(2,4), c(2,2)))

