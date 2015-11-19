%% AnalyzeData_DDE
% Does the maximum-likelihood analysis on real subject data given a particular model

practiceCutoff = 75;
servant = 0;
boardName = 'board';
curTosslist = [];
prevOptParams = [];

% Note that everything below this point should be kept in-sync with
%   SimulateData
% Why not make it a separate function? B/c then if something goes wrong in
%   the middle, you'd lose all progress

% No SMF

% Do null model first
% lr beta elig weight_mb
%starts = [.25 1 .25 .25 .25; .75 2 .75 .5 .5];
starts = [0 0 0 0; .5 1 .5 .5; 1 2 1 1];
A = []; % constraint on weights
b = [];
bounds = [0 0 0 0; 1 3 1 1];
nullModel = @(params,servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v5([params,0,0],servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
[params_nullModel] = getIndivParams_DDE_v2(nullModel,servant,practiceCutoff,boardName,id,Type,Opt1,Opt2,Action,S2,Re,round1,starts,A,b,bounds,curTosslist,prevOptParams);

curTosslist = []; % CHANGE!

% Then do our model
% lr beta elig weight_mb weight_gl
%starts = [.25 1 .25 .25 .25 .25; .75 2 .75 .5 .5 .75];
starts = [0 0 0 0 0; .5 1 .5 .33 .33; 1 2 1 .5 .5];
A = [0 0 0 1 1]; % constraint on weights
b = 1;
bounds = [0 0 0 0 0; 1 3 1 1 1];
model = @(params,servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v5([params(1:4),0,params(5)],servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
[params_ourModel] = getIndivParams_DDE_v2(model,servant,practiceCutoff,boardName,id,Type,Opt1,Opt2,Action,S2,Re,round1,starts,A,b,bounds,curTosslist,prevOptParams);

A = [];
b = [];
normed = 0;

% ABT
starts = [0 0 .5; .5 .5 1; 1 1 1.5];
bounds = [0 0 0; 1 1 2];
%model = @(in_A1,in_S2,in_A2,in_Re,in_normed) getIndivLike_AC_comb_v5('ArApBrBpT',in_A1,in_S2,in_A2,in_Re,in_normed);
[optIndivParams_ABT] = getIndivParams_TDRL(@getIndivLike_AC,'ABT',id,A1,S2,A2,Re,normed,starts,A,b,bounds,tosslist);

% ArApBrBpT
starts = [0 0 0 0 .5; .5 .5 .5 .5 1; 1 1 1 1 1.5];
bounds = [0 0 0 0 0; 1 1 1 1 2];
%model = @(in_A1,in_S2,in_A2,in_Re,in_normed) getIndivLike_AC_comb_v5('ArApBrBpT',in_A1,in_S2,in_A2,in_Re,in_normed);
[optIndivParams_ArApBrBpT] = getIndivParams_TDRL(@getIndivLike_AC,'ArApBrBpT',id,A1,S2,A2,Re,normed,starts,A,b,bounds,tosslist);
