# Script for analyzing DDE game data.
# Adam Morris
# 8/16/2014

setwd("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Round 6");

# Get data
data = read.csv("Parsed_SMF.csv");
data_crits = data[data$Crits==1,];
data_crits_incog = data[data$Crits_incog==1,];

# Create tosslist
DDEModel_noncrits <- glmer(Choice~MB_X+MB_Y+MF_X+MF_Y+(1+MB_X+MB_Y+MF_X+MF_Y|Subj),family=binomial,data=data);
DDEModel_noncrits_coef = coef(DDEModel_noncrits);
slopes_MBX = DDEModel_noncrits_coef$Subj$MB_X;
slopes_MBY = DDEModel_noncrits_coef$Subj$MB_Y;
slopes_MFX = DDEModel_noncrits_coef$Subj$MF_X;
slopes_MFY = DDEModel_noncrits_coef$Subj$MF_Y;
slopes_MB = -slopes_MBX+slopes_MBY;
slopes_MF = -slopes_MFX+slopes_MFY;

tosslist = (slopes_MB < quantile(slopes_MB,.2,type=1) & slopes_MF < quantile(slopes_MF,.2,type=1));
#tosslist = (slopes_MB < quantile(slopes_MB,.2,type=1));
tosslist <- as.numeric(row.names(DDEModel_noncrits_coef$Subj)[tosslist]);

tosslist_crits <- matrix(FALSE,length(data_crits$Subj),1);
for (i in 1:length(data_crits$Subj)) {
	if (any(data_crits$Subj[i]==tosslist)) tosslist_crits[i]=TRUE;
}
tosslist_crits_incog <- matrix(FALSE,length(data_crits_incog$Subj),1);
for (i in 1:length(data_crits_incog$Subj)) {
	if (any(data_crits_incog$Subj[i]==tosslist)) tosslist_crits_incog[i]=TRUE;
}

#tosslist_crits_dummy <- matrix(FALSE,length(data_crits_dummy$Subj),1);
#for (i in 1:length(data_crits_dummy$Subj)) {
#	if (any(data_crits_dummy$Subj[i]==tosslist)) tosslist_crits_dummy[i]=TRUE;
#}
#tosslist_crits_dummy_incog <- matrix(FALSE,length(data_crits_dummy_incog$Subj),1);
#for (i in 1:length(data_crits_dummy_incog$Subj)) {
#	if (any(data_crits_dummy_incog$Subj[i]==tosslist)) tosslist_crits_dummy_incog[i]=TRUE;
#}

# Do models
model_crits = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits);
model_crits_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits);

model_crits_all = glmer(Choice~MB_X+MB_Y+MF_X+MF_Y+MFonMB+(1|Subj)+(0+MB_X+MB_Y+MF_X+MF_Y+MFonMB|Subj),family=binomial,data=data_crits);

model_crits_incog = glmer(Choice~MFonMB+(1|Subj)+(0+MFonMB|Subj),family=binomial,data=data_crits_incog);
model_crits_incog_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_incog);

model_crits_notoss = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits,control=glmerControl(optimizer="bobyqa"));
model_crits_notoss_coef = coef(model_crits_notoss);
slopes_MFonMB = model_crits_notoss_coef$Subj$MFonMB;

test <- glm(slopes_MFonMB~slopes_MB*slopes_MF);

model_crits_roundnum = glmer(Choice~MFonMB*RoundNum+(1+MFonMB*RoundNum|Subj),family=binomial,data=data_crits[!tosslist_crits,],control=glmerControl(optimizer="bobyqa"));

# Check convergence
relgrad <- with(model_crits_all @ optinfo$derivs,solve(Hessian,gradient));
max(abs(relgrad))

# Tests
model_crits_test = glmer(Choice~MFonMB+MB_X+(1+MFonMB+MB_X|Subj),family=binomial,data=data_crits[!tosslist_crits,],control=glmerControl(optimizer="bobyqa"));

# Collapse across subjects, t-test
numSubj = length(unique(data_crits$Subj));
re_lo <- vector(mode='integer',length=numSubj);
re_hi = vector(mode='integer',length=numSubj);
for (i in 1:numSubj) {
	subj = unique(data_crits$Subj)[i];
	re_lo[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB<0]);
	re_hi[i] = mean(data_crits[data_crits$Subj==subj,]$Choice[data_crits[data_crits$Subj==subj,]$MFonMB>0]);
}
t.test(re_lo,re_hi,paired=TRUE);

# t-test for incog
# Collapse across subjects, t-test
numSubj = length(unique(data_crits$Subj));
re_lo_incog <- vector(mode='integer',length=numSubj);
re_hi_incog = vector(mode='integer',length=numSubj);
for (i in 1:numSubj) {
	subj = unique(data_crits_incog$Subj)[i];
	re_lo_incog[i] = mean(data_crits_incog[data_crits_incog$Subj==subj,]$Choice[data_crits_incog[data_crits_incog$Subj==subj,]$MFonMB<0]);
	re_hi_incog[i] = mean(data_crits_incog[data_crits_incog$Subj==subj,]$Choice[data_crits_incog[data_crits_incog$Subj==subj,]$MFonMB>0]);
}
t.test(re_lo_incog,re_hi_incog,paired=TRUE);

# Draw bar plot
alpha = .05;
data.raw <- data.frame(trials=rep(c('MFonMB<0','MFonMB>0'),each=numSubj),value=c(re_lo_incog,re_hi_incog));
data.summary <- data.frame(
    trials=levels(data.raw$trials),
    mean.choice=tapply(data.raw$value, data.raw$trials, mean),
    n=tapply(data.raw$value, data.raw$trials, length),
    sd=tapply(data.raw$value, data.raw$trials, sd)
    );
data.summary$sem <- data.summary$sd/sqrt(data.summary$n);
data.summary$me <- qt(1-alpha/2, df=data.summary$n)*data.summary$sem;

png('barplot-ci.png') # Write to PNG
ggplot(data.summary, aes(x = trials, y = mean.choice)) + 
  geom_bar(position = position_dodge(), stat="identity", fill="blue") +
  geom_errorbar(aes(ymin=mean.choice-me, ymax=mean.choice+me)) +
  ggtitle("With 2 Trial Types - Incongruent") + # plot title
  theme_bw() + # remove grey background (because Tufte said so)
  theme(panel.grid.major = element_blank()) # remove x and y major grid lines (because Tufte said so)
dev.off() # Close PNG

# 2-way repeated measures anova
data.raw <- data.frame(id=rep(1:numSubj,4),cong=rep(c('Congruent','Incongruent'),each=(numSubj*2)),trials=rep(rep(c('MFonMB<0','MFonMB>0'),each=numSubj),2),value=c(re_lo,re_hi,re_lo_incog,re_hi_incog));
aov.out=aov(value~cong*trials + Error(id/(cong*trials));
summary(aov.out)