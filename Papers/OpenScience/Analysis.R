##---------------------------------
# Analysis for Cushman & Morris (2015). Habitual control of goal selection in humans. PNAS.
# 
# Adam Morris, 2015
##---------------------------------

if (!require(lme4)) {install.packages("lme4"); require(lme4);}

## Analysis behind the t-tests reported in main text
ttest.analysis <- function(data) {
  numSubj = length(unique(data$Subj));
  choice_re <- vector(mode='integer',length=numSubj); # For each subject, the % of critical trials w/ same goal choice after a reward
  choice_pun <- vector(mode='integer',length=numSubj); #For each subject, the % of critical trials w/ same goal choice after a punishment
  
  for (i in 1:numSubj) {
    subj = unique(data$Subj)[i];
    choice_pun[i] = mean(data[data$Subj==subj,]$Choice[data[data$Subj==subj,]$Rewards<0]);
    choice_re[i] = mean(data[data$Subj==subj,]$Choice[data[data$Subj==subj,]$Rewards>0]);
  }
  
  cat("Percent choosing same goal after reward: ", mean(choice_re,na.rm=TRUE), ", SE = ", sd(choice_re,na.rm=TRUE)/sqrt(numSubj),"\n")
  cat("Percent choosing same goal after punishment: ", mean(choice_pun,na.rm=TRUE), ", SE = ", sd(choice_pun,na.rm=TRUE)/sqrt(numSubj),"\n")
  t.test(choice_pun,choice_re,paired=TRUE);
}

## Analysis behind the mixed-effects models reported in SI
mixedeffects.analysis <- function(data) {
  data$Rewards <- data$Rewards - mean(data$Rewards); # Grand mean centering
  model = glmer(Choice~Rewards+(1|Subj)+(0+Rewards|Subj),family=binomial,data=data); # Full model
  model_null = glmer(Choice~1+(1|Subj),family=binomial,data=data); # Null model, with "Rewards" regressor removed
  
  cat("MODEL SUMMARY\n")
  print(summary(model))
  cat("\n\nLIKELIHOOD RATIO TEST\n")
  print(anova(model,model_null))
}

# Experiment 1A
data.1a <- read.csv("Expt1A.csv",header=FALSE);
colnames(data.1a) <- c("Rewards","Choice","Subj");
ttest.analysis(data.1a);
mixedeffects.analysis(data.1a);

# Experiment 1B
data.1b <- read.csv("Expt1B.csv",header=FALSE);
colnames(data.1b) <- c("Rewards","Choice","Subj");
ttest.analysis(data.1b);
mixedeffects.analysis(data.1b);

# Experiment 2A
data.2a <- read.csv("Expt2A.csv",header=FALSE);
colnames(data.2a) <- c("Rewards","Choice","Subj");
ttest.analysis(data.2a);
mixedeffects.analysis(data.2a);

# Experiment 2B
data.2b <- read.csv("Expt2B.csv",header=FALSE);
colnames(data.2b) <- c("Rewards","Choice","Subj");
ttest.analysis(data.2b);
mixedeffects.analysis(data.2b);