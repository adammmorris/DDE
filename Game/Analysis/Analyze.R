## Script for analyzing DDE game data.
# Adam Morris
# 10/22/2014

#setwd("C:/Personal/Psychology/Projects/DDE/git/Game/Data/baseline");

require(lme4);
#require(ggplot2);
#require(reshape2);
#source("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Functions.R");

## T-TESTS
data = read.csv("Parsed_ttests.csv",header=FALSE);
colnames(data) <- c("MFonMB","Choice","Subj");

# normal crit trials
data_crits = data;
numSubj = length(unique(data_crits$Subj));
re_lo <- vector(mode='integer',length=numSubj);
re_hi <- vector(mode='integer',length=numSubj);

for (i in 1:numSubj) {
	subj = unique(data_crits$Subj)[i];
	re_lo[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB<0]);
	re_hi[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB>0]);
}
t.test(re_lo,re_hi,paired=TRUE);
re_hi = re_hi[!is.nan(re_hi)];
re_lo = re_lo[!is.nan(re_lo)];
c(mean(re_hi),sd(re_hi)/sqrt(length(re_hi)),mean(re_lo),sd(re_lo)/sqrt(length(re_lo)))

## MODELS
data_models = read.csv("Parsed_models.csv",header=FALSE);
colnames(data_models) <- c("MFonMB","Choice","Subj");

data_crits_models = data_models;
model = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits_models);
model_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_models);

# Check convergence
modelToCheck = model_all; # update this
relgrad <- with(modelToCheck @ optinfo$derivs,solve(Hessian,gradient));
max(abs(relgrad))