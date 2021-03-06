# Script for analyzing DDE game data.
# Adam Morris
# 8/16/2014

setwd("C:/Personal/School/Brown/Psychology/DDE Project/git/Game/Data/Round 6");

# Get data
data = read.csv("Parsed.csv");
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
model_crits = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits[!tosslist_crits,],control=glmerControl(optimizer="bobyqa"));
model_crits_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits[!tosslist_crits,],control=glmerControl(optimizer="bobyqa"));

model_crits_incog = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits_incog[!tosslist_crits_incog,],control=glmerControl(optimizer="bobyqa"));
model_crits_incog_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_incog[!tosslist_crits_incog,],control=glmerControl(optimizer="bobyqa"));

model_crits_notoss = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits,control=glmerControl(optimizer="bobyqa"));
model_crits_notoss_coef = coef(model_crits_notoss);
slopes_MFonMB = model_crits_notoss_coef$Subj$MFonMB;

test <- glm(slopes_MFonMB~slopes_MB*slopes_MF);

model_crits_roundnum = glmer(Choice~MFonMB*RoundNum+(1+MFonMB*RoundNum|Subj),family=binomial,data=data_crits[!tosslist_crits,],control=glmerControl(optimizer="bobyqa"));

# Check convergence
relgrad <- with(model_all_rp @ optinfo$derivs,solve(Hessian,gradient));
max(abs(relgrad))

# Tests
model_crits_test = glmer(Choice~MFonMB+MB_X+(1+MFonMB+MB_X|Subj),family=binomial,data=data_crits[!tosslist_crits,],control=glmerControl(optimizer="bobyqa"));