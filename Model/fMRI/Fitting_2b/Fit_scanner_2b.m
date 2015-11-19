function Fit_scanner_2b(datapath, boardpath, savepath, numStarts, tasknum, MFG_S2_MB)
%% Load data
% datapath should have realA1, realS2, realA2, realRe - each with numRounds x numSubjects
load(datapath);

%% Set up
numSubjects = size(realA1,2);

% tasknum is from 1 to numSubjects
if (tasknum < 1 || tasknum > numSubjects)
    error('tasknum must be between 1 and numSubjects');
end

% Do params
% [lr1, lr2, elig, temp1, temp2, stay, w_MFG, w_MB]
bounds = [0 0 0 0 0 0 0 0; 1 1 1 2 2 5 1 1];
numParams = size(bounds, 2); 

% Calculate starts
starts = zeros(numStarts,numParams);
for i=1:numParams
    starts(:,i) = linspace(bounds(1,i),bounds(2,i),numStarts);
end

thisSubj = tasknum;
optParams = zeros(numStarts,numParams); % for MFG_S2_MB
lik = zeros(numStarts,1);

%% Start!
options = psoptimset('CompleteSearch','on','SearchMethod',{@searchlhs});
for thisStart = 1:numStarts
    % Do patternsearch
    [optParams(thisStart,:),lik(thisStart),~] = patternsearch(@(params) getLikelihood_scanner_2b([params MFG_S2_MB],boardpath,realA1(:,thisSubj),realS2(:,thisSubj),realA2(:,thisSubj),realRe(:,thisSubj)),starts(thisStart,:),[0 0 0 0 0 0 1 1],1,[],[],bounds(1,:),bounds(2,:),options);
end

[~,bestStart] = min(lik);
name = [savepath '/Params_Subj' num2str(tasknum) '.csv'];
csvwrite(name,[lik(bestStart) optParams(bestStart,:) MFG_S2_MB]);
end