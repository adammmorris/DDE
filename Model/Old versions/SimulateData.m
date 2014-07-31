%% Collect simulated data

% Get data from random 'participants'
numSubjects = 75;
numRounds = [25 175];
servant = 0;
boardName = 'board';

%magic = 43;

% Set up their parameters
real_params = zeros(numSubjects,3);
real_weights = zeros(numSubjects,3);
for thisSubj = 1:numSubjects
    lr = rand();
    temp = rand()*2 + .5;
    elig_trace = rand()*(1/2) + .5;
    real_params(thisSubj,:) = [lr temp elig_trace];
    %real_params(thisSubj,:) = [.65 1.5 .75];
    
    weight_mb = rand(); % model-based
    weight_smf = 0; % smart model-free
    weight_dmf = rand(); % dumb model-free
    weight_gl = rand(); % goal-learner
    weightSum = weight_mb+weight_smf+weight_dmf+weight_gl;
    real_weights(thisSubj,:) = [weight_mb weight_smf weight_gl] / weightSum;
    %real_weights(thisSubj,:) = [.33 0 .33];
end

% Run them all!
[earnings, negLLs, results] = runModel_v7(real_params, real_weights, numRounds, numSubjects, servant, boardName);

%% Analyze it
% Treating GL as a servant here
simple = 1; % Do we want to do the simple (3 vs 4 params) or unsimplified (5 vs 6)?

if simple == 1
    % No SMF
    
    % Do null model first
    % lr beta elig weight_mb
    %starts = [.25 1 .25 .25 .25; .75 2 .75 .5 .5];
    starts = [.5 1.5 .5 .33];
    A = []; % constraint on weights
    b = [];
    bounds = [0 0 0 0; 1 3 1 1];
    nullModel = @(params,servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v4([params,0,0],servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
    [params_nullModel] = getIndivParams_DDE(nullModel,servant,numRounds(1),boardName,results(:,1),results(:,2),results(:,3),results(:,4),results(:,5),results(:,6),results(:,7),results(:,8),starts,A,b,bounds,[]);

    % Then do our model
    % lr beta elig weight_mb weight_gl
    %starts = [.25 1 .25 .25 .25 .25; .75 2 .75 .5 .5 .75];
    starts = [.5 1.5 .5 .33 .33];
    A = [0 0 0 1 1]; % constraint on weights
    b = 1;
    bounds = [0 0 0 0 0; 1 3 1 1 1];
    model = @(params,servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v4([params(1:4),0,params(5)],servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
    [params_ourModel] = getIndivParams_DDE(model,servant,numRounds(1),boardName,results(:,1),results(:,2),results(:,3),results(:,4),results(:,5),results(:,6),results(:,7),results(:,8),starts,A,b,bounds,[]);
else
    % Do null model first
    % lr beta elig weight_mb weight_smf
    %starts = [.25 1 .25 .25 .25; .75 2 .75 .5 .5];
    starts = [.5 1.5 .5 .33 .33];
    A = [0 0 0 1 1]; % constraint on weights
    b = 1;
    bounds = [0 0 0 0 0; 1 3 1 1 1];
    nullModel = @(params,servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds) getLikelihood_v4([params 0],servant,practiceCutoff,boardName,ourTrialTypes,ourOption1,ourOption2,ourChoices,ourState2,ourRewards,ourRounds);
    [params_nullModel] = getIndivParams_DDE(nullModel,servant,numRounds(1),boardName,results(:,1),results(:,2),results(:,3),results(:,4),results(:,5),results(:,6),results(:,7),results(:,8),starts,A,b,bounds,[]);
    
    % Then do our model (equal)
    %starts = [0 0 0 0 0 0; .5 .75 .5 .25 .25 .25; 1 1.5 1 .33 .33 .33];
    %A = [0 0 0 1 1 1];
    %bounds = [0 0 0 0 0 0; 1 2 1 1 1 1];
    %[params_ourModel] = getIndivParams(@getLikelihood_ourModel,numRounds,results(:,1),results(:,2),results(:,3),results(:,4),results(:,5),results(:,6),results(:,7),starts,A,bounds);
    
    % Then do our model (servant)
    % lr beta elig weight_mb weight_smf weight_gl
    %starts = [.25 1 .25 .25 .25 .25; .75 2 .75 .5 .5 .75];
    starts = [.5 1.5 .5 .33 .33 .5];
    A = [0 0 0 1 1 0]; % constraint on weights
    b = 1;
    bounds = [0 0 0 0 0 0; 1 3 1 1 1 1];
    model = @getLikelihood_v4;
    [params_ourModel] = getIndivParams_DDE(model,servant,numRounds(1),boardName,results(:,1),results(:,2),results(:,3),results(:,4),results(:,5),results(:,6),results(:,7),results(:,8),starts,A,b,bounds,[]);
end