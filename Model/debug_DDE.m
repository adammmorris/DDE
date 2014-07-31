%% debug_DDE
% It's hard to debug internal functions such as getLikelihood using the
%   normal top-level scripts, because they're wrapped in patternsearch
% So this script is just meant to help debug those functions

%% Simulations
numSubjects = 10;
numRounds = [25 175];
practiceCutoff = numRounds(1);
servant = 0;
boardName = 'board';
realPeople = 0;

% Set 'magic' to a nonzero number if you want all agents to run on just
%   that board
magic = 0;
%magic = 43;
%magic = 48;

% Set up their parameters
real_params = zeros(numSubjects,3);
real_weights = zeros(numSubjects,3);
for thisSubj = 1:numSubjects
    % This is all very random
    %lr = rand();
    %temp = rand()*2 + .5;
    %elig_trace = rand()*(1/2) + .5;
    %real_params(thisSubj,:) = [lr temp elig_trace];
    %real_params(thisSubj,:) = [.65 1.5 .75];
    
    % This is all more realistic
    lr = .5 + randn()*.2;
    if lr < 0
        lr = 0;
    elseif lr > 1
        lr = 1;
    end
    
    temp = chi2rnd(5)*.05;
    
    if rand() < .5
        elig = 1;
    else
        elig = rand()*.9;
    end
    
    real_params(thisSubj,:) = [lr temp elig];
    
    weight_mb = rand(); % model-based
    weight_smf = 0; % smart model-free
    weight_dmf = rand(); % dumb model-free
    weight_gl = rand(); % goal-learner
    weightSum = weight_mb+weight_smf+weight_dmf+weight_gl;
    real_weights(thisSubj,:) = [weight_mb weight_smf weight_gl] / weightSum;
end

% Run them all!
[earnings, negLLs, results] = runModel_v7(real_params, real_weights, numRounds, numSubjects, servant, boardName, magic);

%% Analysis
% Only doing full model for now
id = results(:,1);
Type = results(:,2);
Opt1 = results(:,3);
Opt2 = results(:,4);
Action = results(:,5);
S2 = results(:,6);
Re = results(:,7);
round1 = results(:,8);

subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

for thisSubj = 1:numSubjects
    % Get the appropriate index
    if thisSubj < length(subjMarkers)
        index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
    else
        index = subjMarkers(thisSubj):length(id);
    end
    
    params = [real_params(thisSubj,:)' real_weights(thisSubj,:)'];
    getLikelihood_v5(params,servant,practiceCutoff,boardName,realPeople,Type(index),Opt1(index),Opt2(index),Action(index),S2(index),Re(index),round1(index));
end