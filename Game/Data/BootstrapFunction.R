#myfn <- function(.) {
#return(coef(summary(DDEModel2_justcrits))[2,"z value"]);
#}

## generic parametric bootstrapping function; return a single simulated deviance
##  difference between full (m1) and reduced (m0) models under the
##  null hypothesis that the reduced model is the true model
pboot <- function(m0,m1) {
  s <- simulate(m0)
  L0 <- logLik(refit(m0,s))
  L1 <- logLik(refit(m1,s))
  2*(L1-L0)
}
 
obsdev <- c(2*(logLik(fit)-logLik(fit_null)))
 
## Not run:
## parametric bootstrap test of significance of correlation between
##   random effects of `(Intercept)` and Days
## Timing: approx. 70 secs on a 2.66 GHz Intel Core Duo laptop
set.seed(1001)
sleepstudy_PB <- replicate(250,pboot(fit_null,fit))
## End(Not run)
 
library(lattice)
## null value for correlation parameter is *not* on the boundary
## of its feasible space, so we would expect chisq(1)
qqmath(sleepstudy_PB,distribution=function(p) qchisq(p,df=1),
     type="l",
            prepanel = prepanel.qqmathline,
            panel = function(x, ...) {
               panel.qqmathline(x, ...)
               panel.qqmath(x, ...)
            })
## classical test
pchisq(obsdev,df=1,lower.tail=FALSE)
## parametric bootstrap-based test
mean(sleepstudy_PB>obsdev)
