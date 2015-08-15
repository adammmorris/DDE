# How I tossed

DDEModel_noncrits_coef = coef(DDEModel_noncrits);
slopes_MBX = DDEModel_noncrits_coef$Subj$MB_X;
slopes_MBY = DDEModel_noncrits_coef$Subj$MB_Y;
slopes_MFX = DDEModel_noncrits_coef$Subj$MF_X;
slopes_MFY = DDEModel_noncrits_coef$Subj$MF_Y;

#tosslist = which(slopes_MBX > quantile(slopes_MBX,.8,type=1) & slopes_MBY < quantile(slopes_MBY,.2,type=1) & slopes_MFX > quantile(slopes_MFX,.8,type=1) & quantile(slopes_MBX,.2,type=1));
tosslist = (-slopes_MBX+slopes_MBY < quantile(-slopes_MBX+slopes_MBY,.2,type=1) & -slopes_MFX+slopes_MFY < quantile(-slopes_MFX+slopes_MFY,.2,type=1));
tosslist <- as.numeric(row.names(model_noncrits_coef$Subj)[tosslist]);

tosslist_crits <- matrix(FALSE,length(data_crits$Subj),1);
for (i in 1:length(data_crits$Subj)) {
	if (any(data_crits$Subj[i]==tosslist)) tosslist_crits[i]=TRUE;
}
tosslist_crits_incog <- matrix(FALSE,length(data_crits_incog$Subj),1);
for (i in 1:length(data_crits_incog$Subj)) {
	if (any(data_crits_incog$Subj[i]==tosslist)) tosslist_crits_incog[i]=TRUE;
}
tosslist_crits_dummy <- matrix(FALSE,length(data_crits_dummy$Subj),1);
for (i in 1:length(data_crits_dummy$Subj)) {
	if (any(data_crits_dummy$Subj[i]==tosslist)) tosslist_crits_dummy[i]=TRUE;
}
tosslist_crits_dummy_incog <- matrix(FALSE,length(data_crits_dummy_incog$Subj),1);
for (i in 1:length(data_crits_dummy_incog$Subj)) {
	if (any(data_crits_dummy_incog$Subj[i]==tosslist)) tosslist_crits_dummy_incog[i]=TRUE;
}

first_half_crits = matrix(FALSE,length(data_crits$Subj),1);
first_half_crits[1:(length(data_crits$Subj)/2)]=TRUE;

first_half_crits_dummy = matrix(FALSE,length(data_crits_dummy$Subj),1);
first_half_crits_dummy[1:(length(data_crits_dummy$Subj)/2)]=TRUE;

# Do models
model_crits = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits[!tosslist_crits,]);
model_crits_dummy = glmer(Choice~MFonMB+(1+MFonMB|Subj),family=binomial,data=data_crits_dummy[!tosslist_crits_dummy&first_half_crits_dummy,]);
