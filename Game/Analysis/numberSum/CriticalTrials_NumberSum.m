%% CriticalTrials
% This script gathers the data for a logistic regression analysis.

%% Fixed Effects
% What are the predictors for a given trial with options X and Y?
% - MB_X: The last reinforcement value from the goal associated with option
%   X
% - MB_Y: The last reinforcement value from the goal associated with option
%   Y
% - MF_X: The last reinforcement value from choosing option X
% - MF_Y: The last reinforcement value from choosing option Y
% - MFonMB_X:
%   If on a critical trial w/ critical option X, use the reinforcement value from the last trial.
%   If on a critical trial w/ critical option Y, use the reinforcement
%       value from the last time you chose either option Y or its other
%       corresponding option
%   Otherwise, 0
% - MFonMB_Y:
%   If on a critical trial w/ critical option Y, use the reinforcement value from the last trial.
%   If on a critical trial w/ critical option X, use the reinforcement
%       value from the last time you chose either option X or its other
%       corresponding option
%   Otherwise, 0

%% Random Effects
% Subject: the subject ID number

%% Dependent Variable
% choices: 0 for option X, 1 for option Y

%% Parameters to set
practiceCutoff = 75;

% Final score cutoffs
% If using 1 trial type, set it to 194
% If using 2 trial types, set it to 126
% If you want to stop using this toss criteria, set it to 0.
scoreCutoff = 0;

% Trial completion cutoffs
minNumTrials = 0; % I usually set this to 50 less than the total number of rounds
maxNumTrials = 250; % this should be equal to the total number of rounds

% Set condition
condition = zeros(length(id),1);

% Restrict to novel critical trials
novelOnly = true;

%% Initialize shit
subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

numDataPoints = length(id);

% Distance cutoffs / time discounting
distance_cutoff = 1; % for MFonMB
distance_cutoff_MB = numDataPoints; % no distance cutoff for these two
distance_cutoff_MF = numDataPoints;
gamma = .85; % instead, time discounting

% The important data
MB = zeros(numDataPoints,1);
MF = zeros(numDataPoints,1);
MFonMB = zeros(numDataPoints,1);
unlikely = zeros(numDataPoints,1); % unlikely transitions that WEREN'T crit trials

subjIDs = zeros(numDataPoints,1);
choices = zeros(numDataPoints,1); % 1 is corresponding action, 0 is not
keep = true(numDataPoints,1);
keep_models = true(numDataPoints,1);

%% Calculate stuff

for thisSubj = 1:numSubjects
    subjID = thisSubj;
    
    % Get the subject's index
    if thisSubj < length(subjMarkers)
        index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
    else
        index = subjMarkers(thisSubj):length(id);
    end
    
    % Toss people
    if numTrialsCompleted(subjID) < minNumTrials || numTrialsCompleted(subjID) > maxNumTrials || finalScores(subjID) < scoreCutoff, keep(index) = false; end
    
    for thisRound = index
        % Toss non-crit trials
        if Crit(thisRound)==0, keep(thisRound) = false;
        elseif Action(thisRound-1)==REF_FAIL, keep(thisRound) = false; % special to numberSum
        elseif novelOnly && any(OptNum(index(1):(thisRound-1)) == OptNum(thisRound) | OptNum(index(1):(thisRound-1)) == (numberArray(S2(thisRound-1)+1) - OptNum(thisRound))), keep(thisRound) = false;
        else
            MFonMB(thisRound) = Re(thisRound-1);
            subjIDs(thisRound) = id(thisRound);
            choices(thisRound) = Action(thisRound)==Action(thisRound-1); % special to numberSum
        end
    end
end

%% Write t-test
% For the t-tests, we need to drop anyone who didn't have trials both with
% MFonMB > 0 and MFonMB < 0
% This is only really a problem for the "novel" case
keep_ttests = keep;
subjIDs_unique = unique(id);
for i = 1:numSubjects
    if sum(MFonMB > 0 & id==subjIDs_unique(i)) == 0 || sum(MFonMB < 0 & id==subjIDs_unique(i)) == 0, keep_ttests(id==subjIDs_unique(i)) = false; end
end

if novelOnly, filename = 'Parsed_ttests_novel.csv';
else filename = 'Parsed_ttests.csv'; end
csvwrite(filename,[MFonMB(keep_ttests) choices(keep_ttests) subjIDs(keep_ttests) condition(keep_ttests)]);

%% Write models
% For the models, we need to drop people who made the same choice
%   every critical trial
keep_models = keep_ttests;
subjIDs_unique = unique(id);
for i = 1:numSubjects
    if length(unique(choices(Crit==1 & id==subjIDs_unique(i))))==1, keep_models(id==subjIDs_unique(i)) = false; end
end

% Grand mean center
MB(keep_models) = MB(keep_models) - mean(MB(keep_models));
MF(keep_models) = MF(keep_models) - mean(MF(keep_models));
MFonMB(keep_models) = MFonMB(keep_models) - mean(MFonMB(keep_models));

if novelOnly, filename = 'Parsed_models_novel.csv';
else filename = 'Parsed_models.csv'; end
csvwrite(filename,[MB(keep_models) MF(keep_models) MFonMB(keep_models) choices(keep_models) subjIDs(keep_models) condition(keep_models)]);

clear i; clear distance_cutoff; clear distance_cutoff_MB; clear distance_cutoff_MF; clear gamma; clear index; clear maxNumTrials; clear minNumTrials; clear numDataPoints; clear subjID; clear subjIDs_unique; clear thisRound; clear thisSubj; clear unlikely;

%% Other tests?
% length(unique(subjIDs(keep)))
% sum(keep)
% length(unique(subjIDs(keep_models)))
% sum(keep_models)
%mean(rt1(keep & ((MFonMB > 0 & choices == 1) | (MFonMB < 0 & choices == 0))))
%mean(rt1(keep & ((MFonMB > 0 & choices == 0) | (MFonMB < 0 & choices == 1))))