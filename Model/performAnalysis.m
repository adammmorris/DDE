%% performAnalysis
% This function does the actual dirty work of the analysis - sets up the
%   models, performs the patternsearches, etc.
% I made it a function in order to standardize procedure across wrapper scripts
% NOT CURRENTLY USING THIS

%% Current models
% Null model: lr, temp, elig, weight_MB (weight_SMF is set to 0, so
%   weight_DMF is implicit)
% Our model: lr, temp, elig, weight_MB, weight_GL (weight_SMF is set to 0, so
%   weight_DMF is implicit)

%% Inputs

function [params_nullModel, params_ourModel] = performAnalysis(servant, practiceCutoff, boardName, realPeople, id, Type, Opt1, Opt2, Action, S2, Re, round1,
% Do null model first
% lr beta elig weight_mb
%starts = [.25 1 .25 .25 .25; .75 2 .75 .5 .5];
starts = [0 0 0 0; .5 1 .5 .5; 1 2 1 1];
A = []; % constraint on weights
b = [];
bounds = [0 0 0 0; 1 3 1 1];
nullModel = @(params,servant,practiceCutoff,boardName,realPeople,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v5([params,0,0],servant,practiceCutoff,boardName,realPeople,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
[params_nullModel] = getIndivParams_DDE(nullModel,servant,practiceCutoff,boardName,realPeople,id,Type,Opt1,Opt2,Action,S2,Re,round1,starts,A,b,bounds,curTosslist);

% Then do our model
% lr beta elig weight_mb weight_gl
%starts = [.25 1 .25 .25 .25 .25; .75 2 .75 .5 .5 .75];
starts = [0 0 0 0 0; .5 1 .5 .33 .33; 1 2 1 .5 .5];
A = [0 0 0 1 1]; % constraint on weights
b = 1;
bounds = [0 0 0 0 0; 1 3 1 1 1];
model = @(params,servant,practiceCutoff,boardName,realPeople,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v5([params(1:4),0,params(5)],servant,practiceCutoff,boardName,realPeople,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
[params_ourModel] = getIndivParams_DDE(model,servant,practiceCutoff,boardName,realPeople,id,Type,Opt1,Opt2,Action,S2,Re,round1,starts,A,b,bounds,curTosslist);
