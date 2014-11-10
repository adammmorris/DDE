## Script for analyzing DDE game data.
# Adam Morris
# 10/22/2014

setwd("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Round 5/Take3");

require(lme4);
require(ggplot2);
require(reshape2);
source("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Functions.R");

data = read.csv("WithGL.csv");
data_noncrits = data[data$Crits==-2,];
data_crits = data[data$Crits==1,];
data_crits_incog = data[data$Crits==0,];
data_crits_comb = data[data$Crits>=0,];
data_unlikely = data[data$Crits==-1,];

## tossing?
#model_tossing = glmer(Choice~MB+MF+(1+MB+MF|Subj),family=binomial,data=data_noncrits);

## mixed effect models

model = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits);
model_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits);

model_all = glmer(Choice~MB+MF+MFonMB+(1|Subj)+(0+MB+MF+MFonMB|Subj),family=binomial,data=data_crits);
model_all_null = glmer(Choice~MB+MF+(1|Subj)+(0+MB+MF|Subj),family=binomial,data=data_crits);

# if those are overspecified, can use:
#model_all_uncor = glmer(Choice~MB+MF+MFonMB+(1|Subj)+(0+MB|Subj)+(0+MF|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits);
#model_all_uncor_null = glmer(Choice~MB+MF+(1|Subj)+(0+MB|Subj)+(0+MF|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits);

model_unlikely = glmer(Choice~Unlikely+(1|Subj)+(0+Unlikely|Subj),family=binomial,data=data_unlikely);

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
#keep_list = slopes$Subj$MF>quantile(slopes$Subj$MF,.2,type=1);
#re_lo = re_lo[keep_list];
#re_hi = re_hi[keep_list];

t.test(re_lo,re_hi,paired=TRUE);
c(mean(re_hi),mean(re_lo),mean(re_hi)-mean(re_lo))

data.raw <- data.frame(trials=rep(c('Reward < 0','Reward > 0'),each=numSubj),value=c(re_lo,re_hi),subj=rep(1:numSubj,2));
doBarPlot(data.raw=data.raw,"Baseline","barplot-congruent.png");

# unlikely trials
numSubj = length(unique(data_unlikely$Subj));
re_lo_unlikely <- vector(mode='integer',length=numSubj);
re_hi_unlikely = vector(mode='integer',length=numSubj);
for (i in 1:numSubj) {
	subj = unique(data_unlikely$Subj)[i];
	re_lo_unlikely[i] = mean(data_unlikely[data_unlikely$Subj==subj,]$Choice[data_unlikely[data_unlikely$Subj==subj,]$Unlikely<0]);
	re_hi_unlikely[i] = mean(data_unlikely[data_unlikely$Subj==subj,]$Choice[data_unlikely[data_unlikely$Subj==subj,]$Unlikely>0]);
}
keep_list = !is.nan(re_lo_unlikely)&!is.nan(re_hi_unlikely);
re_lo_unlikely=re_lo_unlikely[keep_list];
re_hi_unlikely=re_hi_unlikely[keep_list];

t.test(re_lo_unlikely,re_hi_unlikely,paired=TRUE);
c(mean(re_hi_unlikely),mean(re_lo_unlikely),mean(re_hi_unlikely)-mean(re_lo_unlikely))

#data.raw <- data.frame(trials=rep(c('Unlikely<0','Unlikely>0'),each=numSubj),value=c(re_lo_unlikely,re_hi_unlikely),subj=rep(1:numSubj,2));
#doBarPlot(data.raw,"Baseline - unlikely");



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
c(mean(re_hi_incog),mean(re_lo_incog),mean(re_hi_incog)-mean(re_lo_incog))

data.raw <- data.frame(trials=rep(c('MFonMB<0','MFonMB>0'),each=length(which(keep_list))),value=c(re_lo_incog,re_hi_incog));
doBarPlot(data.raw,"With 2 Trial Types - Incongruent Trials","barplot-incongruent.png");

# 2-way repeated measures anova
# (I used this to try to check significant interaction.. no luck)
data.raw <- data.frame(id=rep(1:numSubj,4),cong=rep(c('Congruent','Incongruent'),each=(numSubj*2)),trials=rep(rep(c('MFonMB<0','MFonMB>0'),each=numSubj),2),value=c(re_lo,re_hi,re_lo_incog,re_hi_incog));
aov.out=aov(value~cong*trials + Error(id/(cong*trials));
summary(aov.out)
