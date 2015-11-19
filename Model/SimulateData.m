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
    %w_MFG = 0;
    %w_MB = rand(); % dumb model-free
    w_MB = 0;
    %w_MF = rand(); % goal-learner
    w_MF = 0;

    weights = [w_MFG w_MB] / (w_MFG + w_MB + w_MF);
    params(thisSubj,:) = [lr elig temp weights(1) weights(2)];
end

% Run them all!
[earnings_MF,results_MF] = runModel_daw([params(:,1:3) repmat([0 0],numSubjects,1)]);
[earnings_MB,results_MB] = runModel_daw([params(:,1:3) repmat([0 1],numSubjects,1)]);
%[earnings_MFG,results_MFG] = runModel_daw([params(:,1:3) repmat([1 0],numSubjects,1)]);

%[earnings_t,~] = runModel_scanner_sum(params,'board_scanner1b_sum.mat',1);
%[earnings_f,~] = runModel_scanner_sum(params,'board_scanner1b_sum.mat',0);

% [finalScores,results,negLLs,PEs,critPEs] = runModel_scanner_sum(params,'board_scanner2b.mat');

% id = results(:,1);
% Type = results(:,2);
% Opt1 = results(:,3);
% Opt2 = results(:,4);
% Action = results(:,5);
% S2 = results(:,6);
% Action2 = results(:,7);
% Re = results(:,8);
% round1 = results(:,9);
% Crit = results(:,10);
% 
% numTrialsCompleted = 175*ones(numSubjects,1);
% subjMarkers = getSubjMarkers(id);