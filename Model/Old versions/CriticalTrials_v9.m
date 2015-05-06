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

%% Notes
% - I'm currently keeping in trials that have the same corresponding goal
% for both options (these only exist because I messed up)

%% Initialize shit
subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

% MAKE SURE THIS IS SET RIGHT!!!!
% If from simulations, 50
% If from real data, 75
practiceCutoff = 75;

% IMPORTANT: Is this data simulated from the original 'board.mat'?
% If it is, set this to 1.  Otherwise, set to 0
orig_simulation = 0;

numDataPoints = length(id);

% Distance cutoffs / time discounting
distance_cutoff = 1; % for MFonMB
distance_cutoff_MB = numDataPoints; % no distance cutoff for these two
distance_cutoff_MF = numDataPoints;
gamma = 1; % instead, time discounting

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

% Right now, we're only keeping critTrials >= 0 from non-tossed subjects
keep = false(numDataPoints,1);

%% Loop!
% Loop through subjects
for thisSubj = 1:numSubjects
    subjID = thisSubj;
    
    if numTrialsCompleted(subjID) > 200 && numTrialsCompleted(subjID) <= 250 && finalScores(subjID)>194
        
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
                
                % For MBs, the rule is: MB_X is the last reinforcement
                %   value received from the goal associated with option X
                %   (note that the trials must be the same trial type)
                
                % Look back for MB_X
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
                
                % Look back for MB_Y
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
                
                % For MFs, the rule is: MF_X is the reinforcement value
                %   received from the last time the subject chose option X,
                %   no matter what the result or trial type
                %   (note that we're using dumb MF here, not smart MF)
                
                % Look back for MF_X
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
                
                % Look back for MF_Y
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
                
                % Are we in a congruent goal trial?
                if receivedGoal==5 && ~any(chosenAction==[opt1 opt2]) && any(chosenAction_cor==[opt1 opt2])
                    % We're in a critical trial!
                    keep(thisRound) = true;
                    
                    % 0 for incongruent, 1 for congruent
                    critTrials(thisRound) = Type(thisRound-1)==trialType;
                   
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
                    
                % Are we in a congruent goal+action trial?   
                elseif receivedGoal==5 && any(chosenAction==[opt1 opt2]) && Type(thisRound-1)==trialType
                    keep(thisRound) = false;
                    critTrials(thisRound) = -1;
                    unlikely(thisRound) = Re(thisRound-1);
                    
                    if opt1==chosenAction
                        choices(thisRound) = Action(thisRound)==opt1;
                    else
                        choices(thisRound) = Action(thisRound)==opt2;
                    end
                
                % Are we in an incongruent goal, congruent action trial?
                elseif receivedGoal==5 && any(chosenAction==[opt1 opt2]) && Type(thisRound-1)~=trialType
                    keep(thisRound) = false;
                    critTrials(thisRound) = -2;
                    unlikely(thisRound) = Re(thisRound-1);
                    
                    if opt1==chosenAction
                        choices(thisRound) = Action(thisRound)==opt1;
                    else
                        choices(thisRound) = Action(thisRound)==opt2;
                    end
                else
                    % Likely transitions
                    keep(thisRound) = false;
                    choices(thisRound) = Action(thisRound)==opt2;
                    MB(thisRound)=MB_2(thisRound)-MB_1(thisRound);
                    MF(thisRound)=MF_2(thisRound)-MF_1(thisRound);
                end    
            end
        end
    end
end

% Drop practice rounds
MB = MB(keep);
MF = MF(keep);
MFonMB = MFonMB(keep);
unlikely = unlikely(keep);
critTrials = critTrials(keep);
choices = choices(keep);
subjIDs = subjIDs(keep);
%roundNum = removerows(roundNum,'ind',rowsToToss);

% Grand mean center everything
MB = MB - mean(MB);
MF = MF - mean(MF);
MFonMB = MFonMB - mean(MFonMB);
unlikely = unlikely - mean(unlikely);

csvwrite('Parsed_ttests.csv',[MFonMB critTrials choices subjIDs]);
csvwrite('Parsed_models.csv',[MB MF MFonMB critTrials choices subjIDs]);