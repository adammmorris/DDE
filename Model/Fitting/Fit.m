function Fit(datapath,savepath,tasknum)
%% Load data
load(datapath);

%% Prep data
[Opt1,Opt2] = convertOptNumToOptions(OptNum);

% Convert S2 to 2:4 instead of 1:5
S2(S2==1 | S2==3) = 2;
S2(S2==2 | S2==4) = 3;
S2(S2==5) = 4;

% Convert Action2 to 1:2 instead of 1:6
Action2 = mod(Action2,2);
Action2(Action2==0) = 2;

%% Set up
boardpath = 'C:\Personal\Psychology\Projects\DDE\git\Model\Fitting\board_daw_fit.mat';

numStarts = 100;
%numSubjects = length(subjMarkers);
numSubjects = 3;

% tasknum is from 1 to numSubjects
if (tasknum < 1 || tasknum > numSubjects)
    error('tasknum must be between 1 and numSubjects');
end

% Do params
% [lr,elig,temp,w_MFG,w_MB]
bounds = [0 0 0 0 0; 1 1 2 1 1];
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
    if thisSubj < length(subjMarkers)
        index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
    else
        index = subjMarkers(thisSubj):length(id);
    end
    
    options = psoptimset('CompleteSearch','on','SearchMethod',{@searchlhs});

    % Do patternsearch
    [optParams(thisStart,:),lik(thisStart),~] = patternsearch(@(params) getLikelihood_daw(params,boardpath,Opt1(index),Opt2(index),Action(index),S2(index),Action2(index),Re(index),round1(index)),starts(thisStart,:),[],[],[],[],bounds(1,:),bounds(2,:),options);
end

[~,bestStart] = min(lik);
name = [savepath '/Params_Subj' num2str(tasknum) '.txt'];
csvwrite(name,[lik(bestStart) optParams(bestStart)]);
end