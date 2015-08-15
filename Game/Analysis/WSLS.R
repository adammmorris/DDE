data_models = read.csv("Parsed_WSLS.csv",header=FALSE);
colnames(data_models) <- c("R1","R2","Stay","Choice","Subj");

data_crits_models = data_models;
model = glmer(Choice~R1+R2+Stay+(1|Subj)+(0+R1+R2+Stay|Subj),family=binomial,data=data_crits_models);
model_null = glmer(Choice~R2+Stay+(1|Subj)+(0+R2+Stay|Subj),family=binomial,data=data_crits_models);