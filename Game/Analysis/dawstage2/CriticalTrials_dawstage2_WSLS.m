%% CriticalTrials
% This script gathers the data for a logistic regression analysis.

%% Parameters to set
practiceCutoff = 75;

% Final score cutoffs
% If using 1 trial type, set it to 194
% If using 2 trial types, set it to 126
% If you want to stop using this toss criteria, set it to 0.
scoreCutoff = -realmax;

% Trial completion cutoffs
minNumTrials = 200; % I usually set this to 50 less than the total number of rounds
maxNumTrials = 250; % this should be equal to the total number of rounds

%% Initialize shit
subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

numDataPoints = length(id);

rewards = zeros(numDataPoints,1);
subjIDs = zeros(numDataPoints,1);
choices = zeros(numDataPoints,1); % 1 is corresponding action, 0 is not
keep = false(numDataPoints,1);

%% Calculate stuff
for thisSubj = 1:numSubjects
    subjID = thisSubj;
    
    % Get the subject's index
    if thisSubj < length(subjMarkers)
        index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
    else
        index = subjMarkers(thisSubj):length(id);
    end
    
    if numTrialsCompleted(subjID) > minNumTrials && numTrialsCompleted(subjID) <= maxNumTrials && finalScores(subjID) > scoreCutoff
        for thisRound = index
            if round1(thisRound) > practiceCutoff && Crit(thisRound) == 1 && thisRound < index(end)
                if Action(thisRound) ~= getCorrespondingAction(Action(thisRound-1),1); % if we stayed/switched..
                    keep(thisRound) = true;
                    rewards(thisRound) = Re(thisRound-1);
                    subjIDs(thisRound) = id(thisRound+1);
                    choices(thisRound) = any(Action(thisRound+1) == [Action(thisRound-1) getCorrespondingAction(Action(thisRound-1),1)]);
                end
            end
        end
    end
end

%% Write t-test
csvwrite('Parsed_ttests.csv',[rewards(keep) choices(keep) subjIDs(keep)]);

%% Write models
% For the models, we need to drop people who made the same choice
%   every critical trial
keep_models = keep;
% subjIDs_unique = unique(id);
% for i = 1:numSubjects
%     if length(unique(choices(keep & id==subjIDs_unique(i))))==1, keep_models(id==subjIDs_unique(i)) = false; end
% end

% Grand mean center
rewards(keep_models) = rewards(keep_models) - mean(rewards(keep_models));
csvwrite('Parsed_models.csv',[rewards(keep_models) choices(keep_models) subjIDs(keep_models)]);

clear i; clear distance_cutoff; clear distance_cutoff_MB; clear distance_cutoff_MF; clear gamma; clear index; clear maxNumTrials; clear minNumTrials; clear numDataPoints; clear subjID; clear subjIDs_unique; clear thisRound; clear thisSubj; clear unlikely;

%% Other stuff?
length(unique(subjIDs(keep)))
sum(keep)
length(unique(subjIDs(keep_models)))
sum(keep_models)