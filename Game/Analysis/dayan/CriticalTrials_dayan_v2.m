%% CriticalTrials
% This script gathers the data for a logistic regression analysis.

%% Parameters to set
practiceCutoff = 75;

% Final score cutoffs
% If using 1 trial type, set it to 194
% If using 2 trial types, set it to 126
% If you want to stop using this toss criteria, set it to 0.
scoreCutoff = 0;

% Trial completion cutoffs
minNumTrials = 200; % I usually set this to 50 less than the total number of rounds
maxNumTrials = 250; % this should be equal to the total number of rounds

%% Initialize shit
subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

NUMBERS = [16 21];

numDataPoints = length(id);

rewards = zeros(numDataPoints,1);
foregone = zeros(numDataPoints,1);
subjIDs = zeros(numDataPoints,1);
choices = zeros(numDataPoints,1); % 1 is corresponding action, 0 is not
keep = false(numDataPoints,1);

numOptions = length(unique(OptNum));

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
    novel = true(20,1);
    
    if numTrialsCompleted(subjID) > minNumTrials && numTrialsCompleted(subjID) <= maxNumTrials && finalScores(subjID) > scoreCutoff
        for thisRound = index
            if round1(thisRound) > practiceCutoff && Action(thisRound) ~= -1 && Action2(thisRound) == 1 %&& (novel(OptNum(thisRound)) && novel(NUMBERS(Action(thisRound-1)+1)-OptNum(thisRound)))
                keep(thisRound) = true;
                rewards(thisRound) = Re(thisRound-2);
                subjIDs(thisRound) = id(thisRound);
                choices(thisRound) = Action(thisRound)==Action(thisRound-2);
                
                %foundCondition = (Action(thisRound-1) == 0) * 2; % if 16, value of triangle (2); if 21, value of square (0)
                foundCondition = Action(thisRound-1)==0; % if 16 (aka 0), 21 (aka 1); if 21 (aka 1), 0 (aka 16)
                found = 0;
                counter = 1;
                while found == 0 && (thisRound - counter) >= index(1)
                    if Action(thisRound-counter) == foundCondition
                        foregone(thisRound) = Re(thisRound-counter);
                        found = 1;
                    else
                        counter = counter+1;
                    end
                end
            end
            
            % Every time we see a particular way of summing to 16 or 21,
            % cross it off the novel list
            novel(OptNum(thisRound)) = false;
        end
    end
end

%% Write t-test
csvwrite('Parsed_ttests.csv',[rewards(keep) choices(keep) subjIDs(keep)]);

%% Write models
% For the models, we need to drop people who made the same choice
%   every critical trial
keep_models = keep;

% Grand mean center
rewards(keep_models) = rewards(keep_models) - mean(rewards(keep_models));
foregone(keep_models) = foregone(keep_models) - mean(foregone(keep_models));
csvwrite('Parsed_models.csv',[rewards(keep_models) foregone(keep_models) choices(keep_models) subjIDs(keep_models)]);

clear i; clear distance_cutoff; clear distance_cutoff_MB; clear distance_cutoff_MF; clear gamma; clear index; clear maxNumTrials; clear minNumTrials; clear numDataPoints; clear subjID; clear subjIDs_unique; clear thisRound; clear thisSubj; clear unlikely;

%% Other stuff?
length(unique(subjIDs(keep)))
sum(keep)
% length(unique(subjIDs(keep_models)))
% sum(keep_models)