
flexsurv.dists <- list(
                       genf = list(
                       pars=c("mu","sigma","Q","P"),
                       location="mu",
                       transforms=c(identity, log, identity, log),
                       inv.transforms=c(identity, exp, identity, exp),
                       inits=function(t){
                           lt <- log(t[t>0])
                           c(mean(lt), sd(lt), 0, 1)
                       }
                       ),
                       genf.orig = list(
                       pars=c("mu","sigma","s1","s2"),
                       location="mu",
                       transforms=c(identity, log, log, log),
                       inv.transforms=c(identity, exp, exp, exp),
                       inits=function(t){
                           lt <- log(t[t>0])
                           c(mean(lt), sd(lt), 1, 1)
                       }
                       ),
                       gengamma = list(
                       pars=c("mu","sigma","Q"),
                       location="mu",
                       transforms=c(identity, log, identity),
                       inv.transforms=c(identity, exp, identity),
                       inits=function(t){
                           lt <- log(t[t>0])
                           c(mean(lt), sd(lt), 0)
                       }
                       ),
                       gengamma.orig = list(
                       pars=c("shape","scale","k"),
                       location="scale",
                       transforms=c(log, log, log),
                       inv.transforms=c(exp, exp, exp),
                       inits=function(t){c(1, mean(t), 1)}
                       ),
                       exp = list(
                       pars=c("rate"),
                       location="rate",
                       transforms=c(log),
                       inv.transforms=c(exp),
                       inits=function(t){1 / mean(t)}
                       ),
                       weibull = list(
                       pars=c("shape","scale"),
                       location="scale",
                       transforms=c(log, log),
                       inv.transforms=c(exp, exp),
                       inits = function(t){
                           lt <- log(t[t>0])
                           c(1, exp(mean(lt) + 0.572))
                       }
                       ),
                       lnorm = list(
                       pars=c("meanlog","sdlog"),
                       location="meanlog",
                       transforms=c(identity, log),
                       inv.transforms=c(identity, exp),
                       inits=function(t){
                           lt <- log(t[t>0])
                           c(mean(lt), sd(lt))
                       }
                       ),
                       gamma = list(
                       pars=c("shape","rate"),
                       location="rate",
                       transforms=c(log, log),
                       inv.transforms=c(exp, exp),
                       inits=function(t){
                           m=mean(t); v=var(t);
                           c(m^2/v, m/v)
                       }
                       ),
                       gompertz = list(
                       pars=c("shape","rate"),
                       location="rate",
                       transforms=c(identity, log),
                       inv.transforms=c(identity, exp),
                       inits=function(t){c(0,1 / mean(t))}
                       )
                       )


minusloglik.flexsurv <- function(optpars, t, dead, X=0, dlist, inits, fixedpars=NULL) {
    pars <- inits
    npars <- length(pars)
    pars[setdiff(1:npars, fixedpars)] <- optpars
    nbpars <- length(dlist$pars)
    pars <- as.list(pars)
    if (npars > nbpars) {
        beta <- unlist(pars[(nbpars+1):npars])
        pars[[dlist$location]] <- pars[[dlist$location]] + X %*% beta
    }
    pcall <- list(q=t)
    dcall <- list(x=t)
    for (i in 1:nbpars)
        pcall[[names(pars)[i]]] <-
            dcall[[names(pars)[i]]] <-
                dlist$inv.transforms[[i]](pars[[i]])
    dcall$log <- TRUE
    probfn <- paste("p",dlist$name,sep="")
    densfn <- paste("d",dlist$name,sep="")
    ## Generic survival model likelihood
    logdens <- do.call(densfn, dcall)[dead==1]
    prob <- do.call(probfn, pcall)[dead==0]
    - ( sum(logdens) + sum(log(1 - prob)) )
}

check.dlist <- function(dlist){
## TESTME
    if (is.null(dlist$name)) stop("\"name\" element of custom distribution list not given")
    if (!is.character(dlist$name)) stop("\"name\" element of custom distribution list should be a string")
    if (is.null(dlist$pars)) stop("Parameter names \"pars\" not given in custom distribution list")
    if (!is.character(dlist$pars)) stop("Parameter names \"pars\" should be a character vector")
    npars <- length(dlist$pars)
    if (is.null(dlist$location)) stop("Location parameter not given in custom distribution list")
    if (!(dlist$location %in% dlist$pars)) stop("Location parameter \"",dlist$location,"\" not in list of parameters")
    if (is.null(dlist$transforms)) stop("Transforms not given in custom distribution list")
    if (length(dlist$transforms) != npars) stop("Transforms vector of length ",length(dlist$transforms),", parameter names of length ",npars)
    if (is.null(dlist$inv.transforms)) stop("Inverse transformations not given in custom distribution list")
    if (length(dlist$inv.transforms) != npars) stop("Inverse transforms vector of length ",length(dlist$transforms),", parameter names of length ",npars)
    for (i in 1:npars){
        if (is.character(dlist$transforms[[i]])) dlist$transforms[[i]] <- get(dlist$transforms[[i]])
        if (is.character(dlist$inv.transforms[[i]])) dlist$inv.transforms[[i]] <- get(dlist$inv.transforms[[i]])
        if (!is.function(dlist$transforms[[i]])) stop("Transformation function for parameter ", i, " not defined")
        if (!is.function(dlist$inv.transforms[[i]])) stop("Inverse transformation function for parameter ", i, " not defined")
    }
    if (!is.function(dlist$inits)) stop("\"inits\" element of custom distribution list must be a function")
    res <- dlist$inits(1:10)
    if (!is.numeric(res) || (length(res) != npars))
        stop("\"inits\" function must return a numeric vector of length ", npars, " = number of parameters")
    dlist
}

flexsurvreg <- function(formula, data, dist, inits, fixedpars=NULL, cl=0.95,...)
{
    call <- match.call()
    indx <- match(c("formula", "data"), names(call), nomatch = 0)
    if (indx[1] == 0)
        stop("A \"formula\" argument is required")
    temp <- call[c(1, indx)]
    temp[[1]] <- as.name("model.frame")
    m <- eval(temp, parent.frame())
    Y <- model.extract(m, "response")
    if (!inherits(Y, "Surv"))
        stop("Response must be a survival object")
    Terms <- attr(m, "terms")
    X <- model.matrix(Terms, m)
    dat <- list(Y=Y, X=X[,-1,drop=FALSE], Xraw=m[,-1,drop=FALSE])
    X <- dat$X
    if (missing(dist)) stop("Distribution \"dist\" not specified")
    if (is.character(dist)) {
        match.arg(dist, names(flexsurv.dists))
        dlist <- flexsurv.dists[[dist]]
        dlist$name <- dist
    }
    else if (is.list(dist)) {
        dlist <- check.dlist(dist)
    }
    else stop("\"dist\" should be a string for a built-in distribution, or a list for a custom distribution")
    parnames <- dlist$pars
    ncovs <- ncol(dat$Xraw)
    ncoveffs <- ncol(X)
    nbpars <- length(parnames) # number of baseline parameters
    npars <- nbpars + ncoveffs
    if (!missing(inits) && (!is.numeric(inits) || (length(inits) != npars)))
        stop("inits must be a numeric vector of length ",npars)
    if (missing(inits) || any(is.na(inits)))
        default.inits <- c(dlist$inits(Y[,"time"]), rep(0,ncoveffs))
    if (missing(inits)) inits <- default.inits
    else if (any(is.na(inits))) inits[is.na(inits)] <- default.inits[is.na(inits)]
    for (i in 1:nbpars)
        inits[i] <- dlist$transforms[[i]](inits[i])
    outofrange <- which(is.nan(inits) | is.infinite(inits))
    if (any(outofrange)){
        plural <- if(length(outofrange) > 1) "s" else ""
        stop("Initial value", plural, " for parameter", plural, " ",
             paste(outofrange,collapse=","), " out of range")
    }
    cnames <- if(ncoveffs==0) NULL else colnames(X)
    names(inits) <- c(parnames, cnames)
    if (!is.null(fixedpars) && !is.logical(fixedpars) &&
        (!is.numeric(fixedpars) || any(!(fixedpars %in% 1:npars)))){
        dots <- if(npars>2) "...," else ""
        stop("fixedpars must be TRUE/FALSE or a vector of indices in 1,",dots,npars)
    }
    if ((is.logical(fixedpars) && fixedpars==TRUE) ||
        (is.numeric(fixedpars) && all(fixedpars == 1:npars))) {
        minusloglik <- minusloglik.flexsurv(inits, t=Y[,"time"], dead=Y[,"status"], X=X, dlist=dlist, inits=inits)
        for (i in 1:nbpars)
            inits[i] <- dlist$inv.transforms[[i]](inits[i])
        res <- matrix(inits, ncol=1)
        dimnames(res) <- list(names(inits), "est")
        ret <- list(call=call, dlist=dlist, res=res, npars=0,
                    loglik=-minusloglik, AIC=2*minusloglik,
                    data = dat, datameans = colMeans(dat$X),
                    N=nrow(dat$Y), events=sum(dat$Y[,"status"]), trisk=sum(dat$Y[,"time"]))
    }
    else {
        optpars <- inits[setdiff(1:npars, fixedpars)]
        opt <- optim(optpars, minusloglik.flexsurv, t=Y[,"time"], dead=Y[,"status"], X=X, dlist=dlist,
                     inits=inits, fixedpars=fixedpars, hessian=TRUE, ...)
        est <- opt$par
        if (all(!is.na(opt$hessian)) && all(!is.nan(opt$hessian)) && all(is.finite(opt$hessian)) &&
            all(eigen(opt$hessian)$values > 0))
        {
            cov <- solve(opt$hessian); se <- sqrt(diag(cov))
            if (!is.numeric(cl) || length(cl)>1 || !(cl>0) || !(cl<1))
                stop("cl must be a number in (0,1)")
            lcl <- est - qnorm(1 - (1-cl)/2)*se
            ucl <- est + qnorm(1 - (1-cl)/2)*se
        }
        else {
            warning("Optimisation has probably not converged to the maximum likelihood - Hessian is not positive definite. ")
            lcl <- ucl <- NA
        }
        res <- cbind(est=inits, lcl=NA, ucl=NA)
        res[setdiff(1:npars, fixedpars),] <- cbind(est, lcl, ucl)
        colnames(res) <- c("est", paste(c("L","U"), round(cl*100), "%", sep=""))
        res.t <- res # results on transformed (log) scale
        for (i in 1:nbpars) # results on natural scale
            res[i,] <- dlist$inv.transforms[[i]](res[i,])
        ret <- list(call=match.call(), dlist=dlist, res=res, res.t=res.t, cov=cov,
                    npars=length(est), fixedpars=fixedpars, optpars=setdiff(1:npars, fixedpars),
                    ncovs=ncovs, ncoveffs=ncoveffs, basepars=1:nbpars, covpars=(nbpars+1):npars,
                    loglik=-opt$value, AIC=2*opt$value + 2*length(est), cl=cl, opt=opt,
                    data = dat, datameans = colMeans(dat$X),
                    N=nrow(dat$Y), events=sum(dat$Y[,"status"]), trisk=sum(dat$Y[,"time"]))
    }
    class(ret) <- "flexsurvreg"
    ret
}

### Compute CIs for survival, cumulative hazard and hazard at supplied
### times t and covariates X, using random sample of size B from the
### assumed MVN distribution of MLEs. 

cisumm.flexsurvreg <- function(x, t, X, B=1000, cl=0.95) {
    if (B<2) stop("B should be an integer, 2 or greater")
    sim <- matrix(nrow=B, ncol=nrow(x$res))
    colnames(sim) <- rownames(x$res)
    sim[,x$optpars] <- rmvnorm(B, x$opt$par, x$cov)
    sim[,x$fixedpars] <- rep(x$res.t[x$fixedpars,"est"],each=B)
    ret <- array(dim=c(B, length(t), 3))
    for (i in 1:B) {
        pcall <- list(q=t)
        for (j in x$dlist$pars)
            pcall[[j]] <- sim[i,j]    
        beta <- if (x$ncoveffs==0) 0 else sim[i, x$covpars]
        mupar <- which(x$dlist$pars==x$dlist$location)
        mu <- pcall[[x$dlist$location]]
        mu <- mu + X %*% beta
        for (j in seq(along=x$dlist$pars))
            pcall[[x$dlist$pars[j]]] <- x$dlist$inv.transforms[[j]](pcall[[x$dlist$pars[j]]])
        probfn <- paste("p",x$dlist$name,sep="")
        prob <- do.call(probfn, pcall)   
        densfn <- paste("d",x$dlist$name,sep="")
        dcall <- pcall
        names(dcall)[names(dcall)=="q"] <- "x"
        dens <- do.call(densfn, dcall)
        haz <- dens / (1 - prob)
        ret[i,,] <- cbind(surv=1 - prob, cumhaz=-log(1-prob), haz=dens/(1-prob))
    }
    ret <- apply(ret, c(2,3), function(x)quantile(x, c((1-cl)/2, 1 - (1-cl)/2), na.rm=TRUE))
    ret <- aperm(ret, c(2,1,3))
    dimnames(ret)[[3]] <- c("surv","cumhaz","haz")
    ret
}

### Compute CIs for the hazard under spline-based models at supplied
### times t and covariates X, using random sample of size B from the
### assumed MVN distribution of MLEs.

cihaz.spline <- function(x, t, X, B=1000, cl=0.95) {
    sim <- rmvnorm(B, x$opt$par, x$cov)
    ret <- matrix(nrow=B, ncol=length(t))
    for (i in 1:B) {
        gamma <- sim[i, 1:(x$k + 2)]
        beta <- if (x$ncovs==0) 0 else sim[i, (x$k+3):(x$k + 2 + x$ncoveffs)]
        eta <- fs.spline(gamma, log(t), x$knots) + as.numeric(X %*% beta)
        surv <- if (x$scale=="hazard") exp(-exp(eta)) else if (x$scale=="odds") 1 / (exp(eta) + 1) else if (x$scale=="normal") pnorm(-eta)
        dens <- 1 / t * fs.dspline(gamma, log(t), x$knots) * exp(eta - exp(eta))
        ret[i,] <- dens / surv
    }
    ret <- t(apply(ret, 2, function(x)quantile(x, c((1-cl)/2, 1 - (1-cl)/2), na.rm=TRUE)))
    ret
}

print.flexsurvreg <- function(x, ...)
{
    covs <- names(x$covmeans)
    covinds <- match(covs, rownames(x$res))
    cat("\nCall:\n", deparse(x$call), "\n\n", sep = "")
    res <- signif(x$res, 3)
    cat ("Maximum likelihood estimates: \n")
    if (any(covinds)) {
        ecoefs <- matrix(NA, nrow=nrow(x$res), ncol=3)
        colnames(ecoefs) <- c("exp(est)", colnames(res)[2:3])
        means <- rep(NA,nrow(x$res))
        ecoefs[covinds,] <- signif(exp(x$res[covinds,,drop=FALSE]), 3)
        means[covinds] <- signif(x$covmeans, 3)
        res <- cbind(means, res, ecoefs)
        colnames(res)[1] <- "data mean"
    }
    print(res, quote=FALSE, na.print="")
    cat("\nN = ", x$N, ",  Events: ", x$events,
        ",  Censored: ", x$N - x$events,
        "\nTotal time at risk: ", x$trisk,
        "\nLog-likelihood = ", x$loglik, ", df = ", x$npars,
        "\nAIC = ", x$AIC, "\n\n", sep="")
}

summary.flexsurvreg <- function(x, X=NULL, type="survival", t=NULL, B=1000, cl=0.95, ...)
{
    dat <- x$data
    isfac <- sapply(dat$Xraw,is.factor)
    ncovs <- x$ncovs
    if (ncovs > 0 && is.null(X)) {
        ## if any continuous covariates, calculate fitted survival for "average" covariate value
        if (!all(isfac))
            X <- matrix(colMeans(dat$X) ,nrow=1)
        ## else calculate for all different factor groupings
        else X <- unique(dat$X)
    }
    else if (is.null(X)) X <- as.matrix(0, nrow=1, ncol=max(ncol(dat$X),1))
    if (is.null(t))
        t <- sort(unique(dat$Y[,"time"]))
    pcall <- list(q=t)
    if (!is.null(x$knots)) {
        gamma <- x$res[1:(x$k + 2),"est"]
        segamma <- x$res[1:(x$k + 2),"se"]
        beta <- if (ncovs==0) 0 else x$res[(x$k+3):(x$k + 2 + ncol(X)),"est"]
        sebeta <- if (ncovs==0) 0 else x$res[(x$k+3):(x$k + 2 + ncol(X)),"se"]
    }
    else beta <- if (ncovs==0) 0 else x$res[setdiff(rownames(x$res), x$dlist$pars),"est"]
    if (ncol(X) != length(beta)){
        isare <- if(length(beta)==1) "is" else "are"
        plural <- if(ncol(X)==1) "" else "s"
        pluralc <- if(length(beta)==1) "" else "s"
        stop("Supplied X has ", ncol(X), " column",plural," but there ",isare," ",
             length(beta), " covariate effect", pluralc)
    }
    dlist <- x$dlist
    ret <- vector(nrow(X), mode="list")
    ## build names for elements of returned list from unique combinations of factor levels
    if (nrow(X) > 1) { 
        nam <- as.matrix(unique(dat$Xraw))
        for (i in 1:ncol(nam)) nam[,i] <- paste(colnames(nam)[i], nam[,i], sep="=")
        names(ret) <- apply(nam, 1, paste, collapse=",")
    }
    for (i in 1:nrow(X)) {
        if (is.null(x$knots)) {
            for (j in dlist$pars)
                pcall[[j]] <- x$res[j,"est"]
            mupar <- which(dlist$pars==dlist$location)
            mu <- dlist$transforms[[mupar]](pcall[[dlist$location]])
            mu <- mu + X[i,] %*% beta
            pcall[[dlist$location]] <- dlist$inv.transforms[[mupar]](mu)
            probfn <- paste("p",dlist$name,sep="")
            prob <- do.call(probfn, pcall)
            res.ci <- cisumm.flexsurvreg(x, t, X[i,], B=B, cl=cl)
            if (type=="survival") { 
                y <- 1 - prob
                ly <- res.ci[,1,"surv"]
                uy <-  res.ci[,2,"surv"]
            }
            else if (type=="cumhaz"){
                y <- -log(1 - prob)
                ly <- res.ci[,1,"cumhaz"]
                uy <-  res.ci[,2,"cumhaz"]
            }
            else if (type=="hazard") {
                densfn <- paste("d",dlist$name,sep="")
                dcall <- pcall
                names(dcall)[names(dcall)=="q"] <- "x"
                dens <- do.call(densfn, dcall)
                y <- dens / (1 - prob)
                ly <- res.ci[,1,"haz"]
                uy <-  res.ci[,2,"haz"]
            }            
        }
        else {
            eta <- fs.spline(gamma, log(t), x$knots) + as.numeric(X[i,] %*% beta)
            xd <- cbind(basis(x$knots, log(t)))
            nobs <- length(t)
            if (ncovs>0) xd <- cbind(xd, matrix(rep(X[i,],each=nobs),nrow=nobs))
            seeta <- numeric(nobs)
            for (j in 1:nobs) seeta[j] <- sqrt(xd[j,] %*% x$cov %*% xd[j,])
            cl <- 0.95
            lcleta <- eta - qnorm(1 - (1-cl)/2)*seeta
            ucleta <- eta + qnorm(1 - (1-cl)/2)*seeta
            surv <- if (x$scale=="hazard") exp(-exp(eta)) else if (x$scale=="odds") 1 / (exp(eta) + 1) else if (x$scale=="normal") pnorm(-eta)
            lclsurv <- if (x$scale=="hazard") exp(-exp(lcleta)) else if (x$scale=="odds") 1 / (exp(lcleta) + 1) else if (x$scale=="normal") pnorm(-lcleta)
            uclsurv <- if (x$scale=="hazard") exp(-exp(ucleta)) else if (x$scale=="odds") 1 / (exp(ucleta) + 1) else if (x$scale=="normal") pnorm(-ucleta)
            if (type=="survival") {y <- surv; ly <- lclsurv; uy <- uclsurv}
            else if (type=="cumhaz") {y <- -log(surv); ly <- -log(lclsurv); uy <- -log(uclsurv)}
            else if (type=="hazard") {
                dens <- 1 / t * fs.dspline(gamma, log(t), x$knots) * exp(eta - exp(eta))
                y <- dens/surv
                haz.ci <- cihaz.spline(x, t, X[i,], B=B, cl=cl)
                ly <- haz.ci[,1]; uy <- haz.ci[,2]
            }
        }
        ret[[i]] <- data.frame(time=t, est=y, lcl=ly, ucl=uy)
    }
    if (ncovs>0) ret$X <- X
    ret
}

plot.flexsurvreg <- function(x, X=NULL, type="survival", t=NULL,
                             est=TRUE, ci=NULL, B=1000, cl=0.95,
                             col.obs="black", lty.obs=1, lwd.obs=1,
                             col="red",lty=1,lwd=2,
                             col.ci=NULL,lty.ci=2,lwd.ci=NULL,
                             add=FALSE,...)
{    
    type <- match.arg(type, c("survival","cumhaz","hazard"))
    summ <- summary.flexsurvreg(x, X=X, type=type, t=t, B=B, cl=cl)
    t <- summ[[1]]$time
    X <- if (is.null(summ$X)) as.matrix(0, nrow=1, ncol=max(x$ncoveffs,1)) else summ$X
    if (is.null(ci)) ci <- (nrow(X)==1)
    if (is.null(col.ci)) col.ci <- col
    if (is.null(lwd.ci)) lwd.ci <- lwd
    dat <- x$data
    ncovs <- x$ncovs
    isfac <- sapply(dat$Xraw,is.factor)
    if (!add) {
        if (ncovs > 0 && all(isfac))
            form <- as.formula(paste("dat$Y ~ ", paste("dat$X[,",1:x$ncoveffs,"]", collapse=" + ")))
        else form <- dat$Y ~ 1
        ## If any continuous covariates, it is hard to define subgroups
        ## so just plot the population survival
        if (type=="survival") {
            plot(survfit(form, data=as.data.frame(dat$X)), col=col.obs, lty=lty.obs, lwd=lwd.obs, ...)
        }
        else if (type=="cumhaz") {
            plot(survfit(form, data=as.data.frame(dat$X)), fun="cumhaz", col=col.obs, lty=lty.obs, lwd=lwd.obs, ...)
        }
        else if (type=="hazard") {
            if (!all(isfac))
                plot(muhaz(dat$Y[,"time"], dat$Y[,"status"], ...),
                     col=col.obs, lty=lty.obs, lwd=lwd.obs)
            else {
                ## plot hazard for all groups defined by unique combinations of covariates
                group <- if(ncovs>0) do.call("interaction", as.data.frame(dat$X)) else factor(rep(1,nrow(dat$Y)))
                haz <- list()
                for (i in 1:nrow(X)) {
                    subset <- (group == unique(group)[i])
                    haz[[i]] <- muhaz(dat$Y[,"time"], dat$Y[,"status"], subset=subset, ...)
                }
                plot(haz[[1]], col=col.obs, lty=lty.obs, lwd=lwd.obs,
                     ylim=range(sapply(haz, function(x)range(x$haz.est))), ...)
                if (nrow(X)>1) {
                    for (i in 1:nrow(X)) {
                        lines(haz[[i]], col=col.obs, lty=lty.obs, lwd=lwd.obs)
                    }
                }
            }
        }
    }
    for (i in 1:nrow(X)) {
        if (est) lines(summ[[i]]$t, summ[[i]]$est, col=col, lty=lty, lwd=lwd)
        if (ci) {
            lines(summ[[i]]$t, summ[[i]]$lcl, col=col.ci, lty=lty.ci, lwd=lwd.ci)
            lines(summ[[i]]$t, summ[[i]]$ucl, col=col.ci, lty=lty.ci, lwd=lwd.ci)
        }
    }
}

lines.flexsurvreg <- function(x, X=NULL, type="survival", t=NULL,
                              est=TRUE, ci=NULL, B=1000, cl=0.95,
                              col="red",lty=1,lwd=2,
                              col.ci=NULL,lty.ci=2,lwd.ci=NULL, ...)
{
    plot.flexsurvreg(x, X, type=type, t=t, est=est, ci=ci, B=B, cl=cl,
                     col=col, lty=lty, lwd=lwd, col.ci=col.ci,lty.ci=lty.ci,lwd.ci=lwd.ci, add=TRUE, ...)
}