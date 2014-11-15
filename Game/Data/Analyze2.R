## Script for analyzing DDE game data.
# Adam Morris
# 10/22/2014

setwd("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Round 5/Take3");

require(lme4);
require(ggplot2);
require(reshape2);
source("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Functions.R");

data = read.csv("Parsed.csv");
data_crits = data[data$Crits==1,];
data_crits_incog = data[data$Crits==0,];
data_crits_comb = data[data$Crits>=0,];

## mixed effect models

model = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits);
model_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits);

model_all = glmer(Choice~MB+MF+MFonMB+(1|Subj)+(0+MB+MF+MFonMB|Subj),family=binomial,data=data_crits);
model_all_null = glmer(Choice~MB+MF+(1|Subj)+(0+MB+MF|Subj),family=binomial,data=data_crits);

## check convergence
modelToCheck = model_all; # update this
relgrad <- with(modelToCheck @ optinfo$derivs,solve(Hessian,gradient));
max(abs(relgrad))

## t-tests & bar-plots

# normal crit trials
numSubj = length(unique(data_crits$Subj));
re_lo <- vector(mode='integer',length=numSubj);
re_hi = vector(mode='integer',length=numSubj);
for (i in 1:numSubj) {
	subj = unique(data_crits$Subj)[i];
	re_lo[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB<0]);
	re_hi[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB>0]);
}
t.test(re_lo,re_hi,paired=TRUE);
c(mean(re_hi),sd(re_hi)/sqrt(length(re_hi)),mean(re_lo),sd(re_lo)/sqrt(length(re_lo)),mean(re_hi)-mean(re_lo))
	
## stuff for 2-trial-type version only
# models
model_incog = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits_incog);
model_incog_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_incog);

model_comb = glmer(Choice~MFonMB+MFonMB:Crits+(1|Subj)+(0+MFonMB+MFonMB:Crits|Subj),family=binomial,data=data_crits_comb);
model_comb_null = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits_comb);

# t-test
numSubj = length(unique(data_crits_incog$Subj));
re_lo_incog <- vector(mode='integer',length=numSubj);
re_hi_incog = vector(mode='integer',length=numSubj);
for (i in 1:numSubj) {
	subj = unique(data_crits_incog$Subj)[i];
	re_lo_incog[i] = mean(data_crits_incog[data_crits_incog$Subj==subj,]$Choice[data_crits_incog[data_crits_incog$Subj==subj,]$MFonMB<0]);
	re_hi_incog[i] = mean(data_crits_incog[data_crits_incog$Subj==subj,]$Choice[data_crits_incog[data_crits_incog$Subj==subj,]$MFonMB>0]);
}
keep_list = !is.nan(re_lo_incog)&!is.nan(re_hi_incog);
re_lo_incog=re_lo_incog[keep_list];
re_hi_incog=re_hi_incog[keep_list];

t.test(re_lo_incog,re_hi_incog,paired=TRUE);
c(mean(re_hi_incog),sd(re_hi_incog)/sqrt(length(re_hi_incog)),mean(re_lo_incog),sd(re_lo_incog)/sqrt(length(re_lo_incog)),mean(re_hi_incog)-mean(re_lo_incog))