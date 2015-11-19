function Fit_scanner(datapath,boardpath,savepath,numStarts,tasknum)
%% Load data
load(datapath);

%% Set up
numSubjects = length(subjMarkers);

% tasknum is from 1 to numSubjects
if (tasknum < 1 || tasknum > numSubjects)
    error('tasknum must be between 1 and numSubjects');
end

% Do params
% [lr,elig,temp,persev,w_MFG,w_MB]
bounds = [0 0 0 0 0 0; 1 1 2 5 1 1];
numParams = 5;

% Calculate starts
starts = zeros(numStarts,numParams);
for i=1:numParams
    starts(:,i) = linspace(bounds(1,i),bounds(2,i),numStarts);
end

thisSubj = tasknum;
optParams = zeros(numStarts,numParams);
lik = zeros(numStarts,1);

%% Start!
for thisStart = 1:numStarts
    options = psoptimset('CompleteSearch','on','SearchMethod',{@searchlhs});

    % Do patternsearch
    [optParams(thisStart,:),lik(thisStart),~] = patternsearch(@(params) getLikelihood_scanner(params,boardpath,Opt1(:,thisSubj),Opt2(:,thisSubj),Action(:,thisSubj),S2(:,thisSubj),Re(:,thisSubj)),starts(thisStart,:)',[0 0 0 1 1],1,[],[],bounds(1,:),bounds(2,:),options);
end

[~,bestStart] = min(lik);
name = [savepath '/Params_Subj' num2str(tasknum) '.txt'];
csvwrite(name,[lik(bestStart) optParams(bestStart,:)]);
end