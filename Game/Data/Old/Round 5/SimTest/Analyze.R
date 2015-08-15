# Script for analyzing DDE game data.
# Adam Morris
# 8/16/2014

# Get data
data = read.csv("NoGL.csv");
data_crits = data[data$Crits==1,];
data_crits_incog = data[data$Crits_incog==1,];

# Do models
model_crits = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits,control=glmerControl(optimizer="bobyqa"));
model_crits_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits,control=glmerControl(optimizer="bobyqa"));

model_crits_incog = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits_incog,control=glmerControl(optimizer="bobyqa"));
model_crits_incog_null = glmer(Choice~1+(1|Subj),family=binomial,data=data_crits_incog,control=glmerControl(optimizer="bobyqa"));