# PUT MODELS HERE
fit = model_all;
fit_null = model_all_null;

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
 
set.seed(1001)
sleepstudy_PB <- replicate(1000,pboot(fit_null,fit))
 
mean(sleepstudy_PB>obsdev)
