## Script for analyzing DDE game data.
# Adam Morris
# 10/22/2014

setwd("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Round 7/Take4");

require(lme4);
require(ggplot2);
require(reshape2);
source("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Functions.R");


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
t.test(re_lo,re_hi,paired=TRUE);
c(mean(re_hi),sd(re_hi)/sqrt(length(re_hi)),mean(re_lo),sd(re_lo)/sqrt(length(re_lo)))

numSubj_cong = numSubj;

# incongruent crit trials
data_crits_incog = data[data$Crits==0,];
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
c(mean(re_hi_incog),sd(re_hi_incog)/sqrt(length(re_hi_incog)),mean(re_lo_incog),sd(re_lo_incog)/sqrt(length(re_lo_incog)))

numSubj_incog = sum(keep_list);

# interaction
data.raw <- data.frame(id=c(rep(1:numSubj_cong,2),rep(1:numSubj_incog,2)),cong=c(rep('Congruent',numSubj_cong*2),rep('Incongruent',numSubj_incog*2)),trials=c(rep(c('MFonMB<0','MFonMB>0'),each=numSubj_cong),rep(c('MFonMB<0','MFonMB>0'),each=numSubj_incog)),value=c(re_lo,re_hi,re_lo_incog,re_hi_incog));
aov.out=aov(value~cong*trials + Error(id/(cong*trials)),data=data.raw);
summary(aov.out)


## MODELS
data_models = read.csv("Parsed_models.csv",header=FALSE);
colnames(data_models) <- c("MB","MF","MFonMB","Crits","Choice","Subj");

data_crits_models = data_models[data_models$Crits==1,];
model = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits_models);
model_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_models);
model_all = glmer(Choice~MB+MF+MFonMB+(1|Subj)+(0+MB+MF+MFonMB|Subj),family=binomial,data=data_crits_models);
model_all_null = glmer(Choice~MB+MF+(1|Subj)+(0+MB+MF|Subj),family=binomial,data=data_crits_models);

data_crits_incog_models = data_models[data_models$Crits==0,];
data_crits_comb_models = data_models[data_models$Crits>=0,];
model_incog = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits_incog_models);
model_incog_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_incog_models);
model_comb = glmer(Choice~MFonMB*Crits+(1|Subj)+(0+MFonMB*Crits|Subj),family=binomial,data=data_crits_comb_models);
model_comb_null = glmer(Choice~MFonMB+Crits+(1|Subj)+(0+MFonMB+Crits|Subj),family=binomial,data=data_crits_comb_models);

# Check convergence
modelToCheck = model_all; # update this
relgrad <- with(modelToCheck @ optinfo$derivs,solve(Hessian,gradient));
max(abs(relgrad))
