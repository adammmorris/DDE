%% Collect simulated data

% Get data from random 'participants'
numSubjects = 100;

% Set up their parameters
params = zeros(numSubjects,5);
for thisSubj = 1:numSubjects
    % This is all very random
    lr = rand();
    elig = rand()*(1/2) + .5;
    %temp = rand()*(1/2)+1;
    temp = .5;
    
    w_MFG = rand(); % model-based
    w_MB = rand(); % dumb model-free
    w_MF = rand(); % goal-learner

    weights = [w_MFG w_MB] / (w_MFG + w_MB + w_MF);
    params(thisSubj,:) = [lr elig temp weights(1) weights(2)];
end

% Run them all!
[earnings_MF,results_MF] = runModel_daw([params(:,1:3) repmat([0 0],numSubjects,1)]);
[earnings_MB,results_MB] = runModel_daw([params(:,1:3) repmat([0 1],numSubjects,1)]);
%[earnings_MFG,results_MFG] = runModel_daw([params(:,1:3) repmat([1 0],numSubjects,1)]);