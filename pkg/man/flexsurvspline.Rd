\name{flexsurvspline}
\alias{flexsurvspline}
\title{
  Flexible survival regression using the Royston/Parmar spline model.
}
\description{
  Flexible parametric modelling of time-to-event data using the spline
  model of Royston and Parmar (2002).
}
\usage{
flexsurvspline(formula, data, k=0, knots=NULL, scale="hazard", weights,
               subset, na.action, inits=NULL, fixedpars=NULL, cl=0.95,...)
}
\arguments{
  \item{formula}{
    A formula expression in conventional R linear modelling
    syntax. The response must be a survival object as returned by the
    \code{\link{Surv}} function, and any covariates are given on the
    right-hand side.  For example,

    \code{Surv(time, dead) ~ age + sex}

    If there are no covariates, specify \code{1} on the right hand side,
    for example \code{Surv(time, dead) ~ 1}.  Only \code{Surv} objects
    of \code{type="right"} or \code{type="counting"}, corresponding to
    right-censored and/or left-truncated observations, are supported.
  }
  \item{data}{
    A data frame in which to find variables supplied in \code{formula}.
    If not given, the variables should be in the working environment.
  }
  \item{k}{
    Number of knots in the spline. The default \code{k=0} gives
    a Weibull, log-logistic or lognormal model, if \code{"scale"} is
    \code{"hazard"}, \code{"odds"} or \code{"normal"} respectively.  \code{k} is equivalent
    to  \code{df-1} in the notation of \code{stpm} for Stata.  The knots
    are then chosen as equally-spaced quantiles of the log uncensored
    survival times, for example, at the median with one knot,
    or at the 33\% and 67\% quantiles of log time with two knots.
    To override this default knot placement, specify \code{knots} instead.
  }
  \item{knots}{
    Locations of knots on the axis of log time.  If not specified, knot
    locations are chosen as described in \code{k} above.
    Either \code{k} or \code{knots} must be
    specified. If both are specified, \code{knots} overrides \code{k}.
  }
  \item{scale}{
    If \code{"hazard"}, the log cumulative hazard is modelled as a spline
    function of log time.

    If \code{"odds"}, the log cumulative odds is modelled as a spline
    function of log time.

    If \code{"normal"}, \eqn{-\Phi^{-1}(S(t))}{-InvPhi(S(t))} is modelled as a spline
    function of log time, where \eqn{\Phi^{-1}()}{InvPhi()} is the
    inverse normal distribution function \code{\link{qnorm}}.
  }
  \item{weights}{
    Optional vector of case weights.
  }
  \item{subset}{
    Vector of integer or logicals specifying the subset of the
    observations to be used in the fit.
  }
  \item{na.action}{a missing-data filter function, applied after any
    'subset' argument has been used. Default is 'options()$na.action'.
  }
  \item{inits}{
    A numeric vector giving initial values for each unknown parameter.
    If not specified, default initial values are chosen by estimating
    the baseline survival at each observed death time from the
    equivalent Cox model,
    transforming to the log cumulative hazard \eqn{\log(H)}{log(H)} (or
    equivalent under the odds or normal models) then
    performing a linear regression of \eqn{\log(H)}{log(H)} on the
    spline basis and covariates.
  }
  \item{fixedpars}{Vector of indices of parameters whose values will be
    fixed at their initial values during optimisation.  The indices
    are ordered with the intercept \code{"gamma0"} first, then the remaining spline
    coefficients \code{"gamma1","gamma2"...} followed by covariate effects.
  }
  \item{cl}{
    Width of symmetric confidence intervals for maximum
    likelihood estimates, by default 0.95.
  }
  \item{...}{
    Optional arguments to the general-purpose \R
    optimisation routine \code{\link{optim}}. See
    \code{\link{flexsurvreg}} for examples.  }
}
\details{
  In the spline-based survival model of Royston and Parmar (2002),
  a transformation \eqn{g(S(t,z))} of the survival function is modelled
  as a natural cubic spline function of log time \eqn{x = \log(t)}{x = log(t)}
  plus linear effects of covariates \eqn{z}.

  \deqn{g(S(t,z)) = s(x, \bm{\gamma}) + \bm{\beta}^T \mathbf{z}}{g(S(t,z)) = s(x, gamma) + beta^T z}

  The proportional hazards model (\code{scale="hazard"}) defines
  \eqn{g(S(t,\mathbf{z})) = \log(-\log(S(t,\mathbf{z}))) = \log(H(t,\mathbf{z}))}{g(S(t,z)) =
  log(-log(S(t,z))) = log(H(t,z))}, the log
  cumulative hazard.

  The proportional odds model (\code{scale="odds"}) defines \eqn{g(S(t,\mathbf{z}))
  = \log(S(t,\mathbf{z})^{-1} - 1)}{g(S(t,z)) = log(1/S(t,z) - 1)}, the log
  cumulative odds.

  The probit model (\code{scale="normal"}) defines \eqn{g(S(t,\mathbf{z})) =
    -\Phi^{-1}(S(t,\mathbf{z}))}{g(S(t,z)) = -InvPhi(S(t,z))},
  where \eqn{\Phi^{-1}()}{InvPhi()} is the
    inverse normal distribution function \code{\link{qnorm}}.

    With no knots, the spline reduces to a linear function, and these
    models are equivalent to Weibull, log-logistic and lognormal models
    respectively.

    Natural cubic splines are cubic splines constrained to be linear beyond boundary
    knots \eqn{k_{min},k_{max}}{kmin,kmax}.  The spline function is
    defined as

    \deqn{s(x,\bm{\gamma}) = \gamma_0 + \gamma_1 x + \gamma_2 v_1(x) + \ldots +
    \gamma_{m+1} v_m(x)}{s(x,gamma) = gamma0 + gamma1 x + gamma2 v1(x) + ... + gamma_{m+1} vm(x)}

  where \eqn{v_j(x)}{vj(x)} is the \eqn{j}th basis function

  \deqn{v_j(x) = (x - k_j)^3_+ - \lambda_j(x - k_{min})^3_+ - (1 -
  \lambda_j) (x - k_{max})^3_+}{vj(x) = (x - kj)^3_+ - \lambda_j(x - kmin)^3_+ - (1 -\lambda_j) (x - kmax)^3_+}

\deqn{\lambda_j = \frac{k_{max} - k_j}{k_{max} - k_{min}}}{\lambda_j = (kmax - kj) / (kmax - kmin)}

and \eqn{(x - a)_+ = max(0, x - a)}.

  Parameters \eqn{\bm{\gamma},\bm{\beta}}{gamma,beta} are estimated by maximum likelihood
  using the algorithms available in the standard R
  \code{\link{optim}} function.  Confidence intervals are estimated from
  the Hessian at the maximum.  }
\value{
  A list of class \code{"flexsurvreg"} with the following elements.

  \item{call}{A copy of the function call,
    for use in post-processing.}
  \item{k}{Number of knots.}
  \item{knots}{Location of knots on the log time axis.}
  \item{res}{Matrix of maximum likelihood estimates and confidence
  limits.  Spline coefficients are labelled \code{"gamma..."}, and covariate
  effects are labelled with the names of the covariates.

    Coefficients \code{gamma1,gamma2,...} here are the equivalent of
    \code{s0,s1,...} in Stata \code{streg}, and \code{gamma0} is the
    equivalent of the \code{xb} constant term.  To reproduce results,
    use the \code{noorthog} option in Stata, since no orthogonalisation
    is performed on the spline basis here.

    In the Weibull model, for example, \code{gamma0,gamma1} are
    \code{-shape log(scale), shape} respectively in
    \code{\link{dweibull}} or \code{\link{flexsurvreg}} notation, or
    (\code{-Intercept/scale}, \code{1/scale}) in \code{\link[survival]{survreg}}
    notation.

    In the log-logistic model with shape \code{a} and scale \code{b} (as
    in \code{\link[eha]{dllogis}} from the \pkg{eha} package),
    \code{1/b^a} is equivalent to \code{exp(gamma0)}, and \code{a} is
    equivalent to \code{gamma1}.

    In the log-normal model with log-scale mean \code{mu} and standard
    deviation \code{sigma}, \code{-mu/sigma} is equivalent to
    \code{gamma0} and \code{1/sigma} is equivalent to \code{gamma1}.
  }
  \item{loglik}{The maximised log-likelihood.  This will
    differ from Stata, where the sum of the log uncensored survival
    times is added to the log-likelihood in survival models, to remove
    dependency on the time scale.}

  \item{AIC}{Akaike's information criterion (-2*log likelihood + 2*number of
    estimated parameters)}
}
\references{
  Royston, P. and Parmar, M. (2002).  Flexible parametric
  proportional-hazards and proportional-odds models for censored survival
  data, with application to prognostic modelling and estimation of
  treatment effects. Statistics in Medicine 21(1):2175-2197.
}
\author{
  Christopher Jackson <chris.jackson@mrc-bsu.cam.ac.uk>
}
\seealso{
  \code{\link{flexsurvreg}} for flexible survival modelling using
  fully parametric distributions including the generalized F and gamma.

  \code{\link{plot.flexsurvreg}} and \code{\link{lines.flexsurvreg}} to
  plot fitted survival, hazards and cumulative hazards from models fitted
  by \code{\link{flexsurvspline}} and \code{\link{flexsurvreg}}.

}
\examples{
data(bc)
bc$recyrs <- bc$rectime/365

## Best-fitting model to breast cancer data from Royston and Parmar (2002)
## One internal knot (2 df) and cumulative odds scale
spl <- flexsurvspline(Surv(recyrs, censrec) ~ group, data=bc, k=1, scale="odds")

## Fitted survival
plot(spl, ci=TRUE, lwd=3, lwd.ci=1, col.ci="gray")

## Simple Weibull model fits much less well
splw <- flexsurvspline(Surv(recyrs, censrec) ~ group, data=bc, k=0, scale="hazard")
lines(splw, col="blue")

## Alternative way of fitting the Weibull
splw2 <- flexsurvreg(Surv(recyrs, censrec) ~ group, data=bc, dist="weibull")

}
\keyword{models}
\keyword{survival}
