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

%% Initialize shit
subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

% MAKE SURE THIS IS SET RIGHT!!!!
practiceCutoff = 55;

% IMPORTANT: Is this data simulated from the original 'board.mat'?
% If it is, set this to 1.  Otherwise, set to 0
orig_simulation = 0;

numDataPoints = length(id);

% Distance cutoffs / time discounting
distance_cutoff = 1; % for MFonMB
distance_cutoff_MB = numDataPoints; % no distance cutoff for these two
distance_cutoff_MF = numDataPoints;
gamma = .85; % instead, time discounting

% The important data
MB_1 = zeros(numDataPoints,1);
MB_2 = zeros(numDataPoints,1);
MF_1 = zeros(numDataPoints,1);
MF_2 = zeros(numDataPoints,1);

MB = zeros(numDataPoints,1);
MF = zeros(numDataPoints,1);
MFonMB = zeros(numDataPoints,1);
unlikely = zeros(numDataPoints,1); % unlikely transitions that WEREN'T crit trials

subjIDs = zeros(numDataPoints,1);
choices = zeros(numDataPoints,1); % 0 is left, 1 is right

% Code for critTrials:
% congruent goal = 1
% incongruent goal = 0
% congruent goal+action = -1
% incongruent goal, congruent action = -2
% likely transition = -3
critTrials = -3*ones(numDataPoints,1);

% Hardcoded crit trial #s
critTrialNumbers = [68 74 79 86 95 99 105 112 119 125 130 136 143 148 152 159 165 170 178 182 186 194 199 203 210 225];

% Right now, we're only keeping critTrials >= 0 from non-tossed subjects
keep_ttests = false(numDataPoints,1);
keep_models = false(numDataPoints,1);

%% Toss criteria
% MAKE SURE THESE ARE RIGHT ALSO

% Final score cutoffs
% If using 1 trial type, set it to 194
% If using 2 trial types, set it to 126
% If you want to stop using this toss criteria, set it to 0.
scoreCutoff = 194;

% Trial completion cutoffs
minNumTrials = 180; % I usually set this to 50 less than the total number of rounds
maxNumTrials = 230; % this should be equal to the total number of rounds

%% Loop!
% Loop through subjects
for thisSubj = 1:numSubjects
    subjID = thisSubj;
    
    if numTrialsCompleted(subjID) > minNumTrials && numTrialsCompleted(subjID) <= maxNumTrials && finalScores(subjID) > scoreCutoff
        
        % Get the subject's index
        if thisSubj < length(subjMarkers)
            index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
        else
            index = subjMarkers(thisSubj):length(id);
        end
        
        % Walk through rounds
        % Ignore practice rounds
        for thisRound = index
            if round1(thisRound) > practiceCutoff
                subjIDs(thisRound) = subjID;
                
                % Last round's stuff
                chosenAction = Action(thisRound-1);
                chosenAction_cor = getCorrespondingAction(chosenAction,Type(thisRound-1),orig_simulation);
                receivedGoal = S2(thisRound-1)-1; % -1 because S2 is from 2-6
                
                % This round's stuff
                opt1 = Opt1(thisRound);
                opt2 = Opt2(thisRound);
                trialType = Type(thisRound);
                
                % Get the corresponding actions for each option
                opt1_cor = getCorrespondingAction(opt1,trialType,orig_simulation);
                opt2_cor = getCorrespondingAction(opt2,trialType,orig_simulation);
                
                % Are we in a congruent goal trial?
                if receivedGoal==5 && ~any(chosenAction==[opt1 opt2]) && any(chosenAction_cor==[opt1 opt2]) && any(critTrialNumbers == round1(thisRound))
                    % We're in a critical trial!
                    keep_ttests(thisRound) = true;
                    keep_models(thisRound) = true;
                    
                    % 0 for incongruent, 1 for congruent
                    critTrials(thisRound) = Type(thisRound-1)==trialType;
                    
                    % MBs
                    found = 0;
                    counter = 1;
                    % Loop until you find it or you hit the beginning of that
                    %   subject's rounds
                    while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff_MB
                        % In this round, did the subject get the goal
                        %   corresponding with option X?
                        % For that to be true, the trial type must be the same, and S2 must either be optX or
                        %   optX_cor
                        if trialType == Type(thisRound-counter) && any((S2(thisRound-counter)-1) == [opt1 opt1_cor])
                            % Woohoo!
                            MB_1(thisRound) = Re(thisRound-counter)*(gamma^(counter-1)); % time discount by gamma for every trial before the last trial this is
                            found = 1;
                        else
                            counter = counter+1;
                        end
                    end
                    
                    found = 0;
                    counter = 1;
                    % Loop until you find it or you hit the beginning of that
                    %   subject's rounds
                    while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff_MB
                        % In this round, did the subject get the goal
                        %   corresponding with option X?
                        % For that to be true, S2 must either be optY or
                        %   optY_cor
                        if trialType == Type(thisRound-counter) && any((S2(thisRound-counter)-1) == [opt2 opt2_cor])
                            % Woohoo!
                            MB_2(thisRound) = Re(thisRound-counter)*(gamma^(counter-1));
                            found = 1;
                        else
                            counter = counter+1;
                        end
                    end
                    
                    
                    % MFs
                    found = 0;
                    counter = 1;
                    % Loop until you find it or you hit the beginning of that
                    %   subject's rounds
                    while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff_MF
                        % In this round, did the subject choose optX?
                        if Action(thisRound-counter) == opt1
                            % Woohoo!
                            MF_1(thisRound) = Re(thisRound-counter)*(gamma^(counter-1));
                            found = 1;
                        else
                            counter = counter+1;
                        end
                    end
                    
                    found = 0;
                    counter = 1;
                    % Loop until you find it or you hit the beginning of that
                    %   subject's rounds
                    while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff_MF
                        % In this round, did the subject choose optY?
                        if Action(thisRound-counter) == opt2
                            % Woohoo!
                            MF_2(thisRound) = Re(thisRound-counter)*(gamma^(counter-1));
                            found = 1;
                        else
                            counter = counter+1;
                        end
                    end
                    
                    % MFonMB
                    MFonMB(thisRound) = Re(thisRound-1);
                    
                    % What's the critical option?
                    if opt1==chosenAction_cor
                        choices(thisRound) = Action(thisRound)==opt1;
                        MB(thisRound)=MB_1(thisRound)-MB_2(thisRound);
                        MF(thisRound)=MF_1(thisRound)-MF_2(thisRound);
                    else
                        choices(thisRound) = Action(thisRound)==opt2;
                        MB(thisRound)=MB_2(thisRound)-MB_1(thisRound);
                        MF(thisRound)=MF_2(thisRound)-MF_1(thisRound);
                    end
                end
            end
        end
    end
end

%% Write t-test
csvwrite('Parsed_ttests.csv',[MFonMB(keep_ttests) critTrials(keep_ttests) choices(keep_ttests) subjIDs(keep_ttests)]);

%% Write models
% For the models, we need to drop people who made the same choice
%   every critical trial
subjIDs_unique = unique(subjIDs);
numSubj = length(subjIDs_unique);
for i = 1:numSubj
    if length(unique(choices(critTrials>=0&subjIDs==subjIDs_unique(i))))==1, keep_models(subjIDs==subjIDs_unique(i)) = false; end
end

% Grand mean center
MB(keep_models) = MB(keep_models) - mean(MB(keep_models));
MF(keep_models) = MF(keep_models) - mean(MF(keep_models));
MFonMB(keep_models) = MFonMB(keep_models) - mean(MFonMB(keep_models));

csvwrite('Parsed_models.csv',[MB(keep_models) MF(keep_models) MFonMB(keep_models) critTrials(keep_models) choices(keep_models) subjIDs(keep_models)]);