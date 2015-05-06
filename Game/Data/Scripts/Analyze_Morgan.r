## Script for analyzing DDE game data.
# Adam Morris
# 10/22/2014

setwd("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Round 7/Take4");

require(lme4);
#require(ggplot2);
#require(reshape2);
#source("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Functions.R");

## T-TESTS
data = read.csv("Parsed_ttests.csv",header=FALSE);
colnames(data) <- c("MFonMB","Crits","Choice","Subj");

# normal crit trials
data_crits = data[data$Crits==1,];
numSubj = length(unique(data_crits$Subj));
re_lo <- vector(mode='integer',length=numSubj);
re_hi = vector(mode='integer',length=numSubj);

for (i in 1:numSubj) {
	subj = unique(data_crits$Subj)[i];
	re_lo[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB<0]);
	re_hi[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB>0]);
}
c(mean(re_hi),sd(re_hi)/sqrt(length(re_hi)),mean(re_lo),sd(re_lo)/sqrt(length(re_lo)))
t.test(re_lo,re_hi,paired=TRUE);


## MODELS
data_models = read.csv("Parsed_models.csv",header=FALSE);
colnames(data_models) <- c("MB","MF","MFonMB","Crits","Choice","Subj");

data_crits_models = data_models[data_models$Crits==1,];
model = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits_models);
model_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_models);
model_all = glmer(Choice~MB+MF+MFonMB+(1|Subj)+(0+MB+MF+MFonMB|Subj),family=binomial,data=data_crits_models);
model_all_null = glmer(Choice~MB+MF+(1|Subj)+(0+MB+MF|Subj),family=binomial,data=data_crits_models);

# Check convergence
modelToCheck = model; # update this
relgrad <- with(modelToCheck @ optinfo$derivs,solve(Hessian,gradient));
max(abs(relgrad))
