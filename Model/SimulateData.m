%% Collect simulated data

% Get data from random 'participants'
numSubjects = 200;
numRounds = [50 175];
practiceCutoff = numRounds(1);
servant = 0;
boardName = 'board3';
connected = 1;
numCrits = 26;

% Set 'magic' to a nonzero number if you want all agents to run on just
%   that board
magic = 0;
%magic = 43;
%magic = 48;

% Set up their parameters
real_params = zeros(numSubjects,3);
real_weights = zeros(numSubjects,4-connected);
for thisSubj = 1:numSubjects
    % This is all very random
    lr = rand();
    temp = rand()*1.5 + .5;
    elig = rand()*(1/2) + .5;
    
    % This is all more realistic
    %     lr = .5 + randn()*.2;
    %     if lr < 0
    %         lr = 0;
    %     elseif lr > 1
    %         lr = 1;
    %     end
    %
    %     temp = chi2rnd(4)*.05+.05;
    %
    %     if rand() < .5
    %         elig = 1;
    %     else
    %         elig = rand()*.9;
    %     end
    
    real_params(thisSubj,:) = [lr temp elig];
    
    weight_mb = rand(); % model-based
    weight_smf = rand(); % smart model-free
    weight_dmf = rand(); % dumb model-free
    weight_gl = 0; % goal-learner

    if connected==1
        real_weights(thisSubj,:) = [weight_mb weight_smf weight_gl] / (weight_mb+weight_smf+weight_dmf+weight_gl);
    else
        real_weights(thisSubj,:) = [weight_mb weight_smf weight_dmf weight_gl];
    end
end

% Run them all!
if connected == 1
    [earnings, negLLs, results] = runModel_v10(real_params, real_weights, numRounds, numSubjects, boardName, magic);
else
    [earnings, negLLs, results] = runModel_v7_unconnected(real_params, real_weights, numRounds, numSubjects, servant, boardName, magic);
end

id = results(:,1);
Type = results(:,2);
Opt1 = results(:,3);
Opt2 = results(:,4);
Action = results(:,5);
S2 = results(:,6);
Re = results(:,7);
round1 = results(:,8);

%% Analyze it
curTosslist = [];
prevOptParams = [];

elig = .75;

% Note that everything below this point should be kept in-sync with
%   AnalyzeData_DDE
% Why not make it a separate function? B/c then if something goes wrong in
%   the middle, you'd lose all progress

% No SMF

% Do null model first
% lr beta elig weight_mb
%starts = [0 0 0 0];
starts = [.25 .25 .25; .75 .75 .75];
%starts = [0 0 0 0; .5 1 .5 .5; 1 2 1 1];
A = []; % constraint on weights
b = [];
bounds = [0 0 0; 1 3 1];
nullModel = @(params,servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v5([params(1:2),elig,params(3),0,0],servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
[params_nullModel] = getIndivParams_DDE_v2(nullModel,servant,practiceCutoff,boardName,id,Type,Opt1,Opt2,Action,S2,Re,round1,starts,A,b,bounds,curTosslist,prevOptParams);

% Then do our model
% lr beta elig weight_mb weight_gl
%starts = [0 0 0 0 0];
starts = [.25 .25 .25 .25; .75 .75 .5 .5];
%starts = [0 0 0 0 0; .5 1 .5 .33 .33; 1 2 1 .5 .5];
A = [0 0 1 1]; % constraint on weights
b = 1;
bounds = [0 0 0 0; 1 3 1 1];
model = @(params,servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v5([params(1:2),elig,params(3),0,params(4)],servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
[params_ourModel] = getIndivParams_DDE_v2(model,servant,practiceCutoff,boardName,id,Type,Opt1,Opt2,Action,S2,Re,round1,starts,A,b,bounds,curTosslist,prevOptParams);
