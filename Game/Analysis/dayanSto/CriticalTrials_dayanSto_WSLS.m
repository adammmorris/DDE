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

NUMBERS = [16 21];
numOptions = length(unique(OptNum));

rewards1 = zeros(numDataPoints,1);
rewards2 = zeros(numDataPoints,1);
subjIDs = zeros(numDataPoints,1);
stay = zeros(numDataPoints,1);
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
    
    novel = true(20,1);

    if numTrialsCompleted(subjID) > minNumTrials && numTrialsCompleted(subjID) <= maxNumTrials && finalScores(subjID) > scoreCutoff
        for thisRound = index
            if round1(thisRound) > practiceCutoff && Crit(thisRound) == 1 && Action(thisRound-1) ~= -1 && thisRound < index(end) && (novel(OptNum(thisRound)) && novel(NUMBERS(Action(thisRound-1)+1)-OptNum(thisRound)))
                stay(thisRound) = Action(thisRound-1) == Action(thisRound); % if we stayed/switched..
                keep(thisRound) = true;
                rewards1(thisRound) = Re(thisRound-1);
                rewards2(thisRound) = Re(thisRound);
                subjIDs(thisRound) = id(thisRound+1);
                choices(thisRound) = Action(thisRound-1) == Action(thisRound+1);
            end
            
            novel(OptNum(thisRound)) = false;
        end
    end
end

%% Write
csvwrite('Parsed_WSLS.csv',[rewards1(keep) rewards2(keep) stay(keep) choices(keep) subjIDs(keep)]);

clear i; clear distance_cutoff; clear distance_cutoff_MB; clear distance_cutoff_MF; clear gamma; clear index; clear maxNumTrials; clear minNumTrials; clear numDataPoints; clear subjID; clear subjIDs_unique; clear thisRound; clear thisSubj; clear unlikely;

%% Other stuff?
length(unique(subjIDs(keep)))
sum(keep)