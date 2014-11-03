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
practiceCutoff = 50;

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
MB_X = zeros(numDataPoints,1);
MB_Y = zeros(numDataPoints,1);
MF_X = zeros(numDataPoints,1);
MF_Y = zeros(numDataPoints,1);

MB = zeros(numDataPoints,1);
MF = zeros(numDataPoints,1);
MFonMB = zeros(numDataPoints,1);
unlikely = zeros(numDataPoints,1); % unlikely transitions that WEREN'T crit trials

subjIDs = zeros(numDataPoints,1);
choices = zeros(numDataPoints,1); % 0 is left, 1 is right
critTrials_comb = -2*ones(numDataPoints,1); % -2 for nothing, -1 for unlikely transition but not crit trial, 0 for incongruent crit trial, 1 for congruent crit trial
%roundNum = zeros(numDataPoints,1);

% At the end, we want to drop all rows that are practice rounds or from
%   tossed subjects
rowsToToss = [];

%% Loop!
% Loop through subjects
for thisSubj = 1:numSubjects
    subjID = thisSubj;
    
    % Get the subject's index
    if thisSubj < length(subjMarkers)
        index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
    else
        index = subjMarkers(thisSubj):length(id);
    end
    
    % Are we tossing this person?
    %if any(tosslist == subjID)
    if numTrialsCompleted(subjID) < 200 || numTrialsCompleted(subjID) > 250
        % Add all their rows to rowsToToss
        rowsToToss = horzcat(rowsToToss,index);
    else
        % Walk through rounds
        % Ignore practice rounds
        for thisRound = index
            if round1(thisRound) <= practiceCutoff
                rowsToToss(end+1) = thisRound;
            else
                if Opt1(thisRound)<Opt2(thisRound)
                    optX = Opt1(thisRound);
                    optY = Opt2(thisRound);
                else
                    optX = Opt2(thisRound);
                    optY = Opt1(thisRound);
                end
                trialType = Type(thisRound);
                
                % Get the corresponding actions for each option
                optX_cor = getCorrespondingAction(optX,trialType,orig_simulation);
                optY_cor = getCorrespondingAction(optY,trialType,orig_simulation);
                
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
                    if trialType == Type(thisRound-counter) && any((S2(thisRound-counter)-1) == [optX optX_cor])
                        % Woohoo!
                        MB_X(thisRound) = Re(thisRound-counter)*(gamma^(counter-1)); % time discount by gamma for every trial before the last trial this is
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
                    if trialType == Type(thisRound-counter) && any((S2(thisRound-counter)-1) == [optY optY_cor])
                        % Woohoo!
                        MB_Y(thisRound) = Re(thisRound-counter)*(gamma^(counter-1));
                        found = 1;
                    else
                        counter = counter+1;
                    end
                end
                
                MB(thisRound) = MB_Y(thisRound)-MB_X(thisRound);
                
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
                    if Action(thisRound-counter) == optX
                        % Woohoo!
                        MF_X(thisRound) = Re(thisRound-counter)*(gamma^(counter-1));
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
                    if Action(thisRound-counter) == optY
                        % Woohoo!
                        MF_Y(thisRound) = Re(thisRound-counter)*(gamma^(counter-1));
                        found = 1;
                    else
                        counter = counter+1;
                    end
                end
                
                MF(thisRound) = MF_Y(thisRound)-MF_X(thisRound);
                
                % Are we in a critical trial?
                % Last trial was a low-prob transition to 5, and then this
                %   trial has chosenAction_cor as one of its options (and
                %   not chosenAction)
                found = 0;
                counter = 1;
                while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff
                    % Get info
                    chosenAction = Action(thisRound-counter);
                    chosenAction_cor = getCorrespondingAction(chosenAction,Type(thisRound-counter),orig_simulation);
                    receivedGoal = S2(thisRound-counter)-1; % -1 because S2 is from 2-6
                    
                    % Check..
                    % Includes both x & y trials now
                    %if ~any(receivedGoal==[chosenAction chosenAction_cor]) && chosenAction~=5 && any(chosenAction_cor==[optX optY]) && (halfCrits==0 || ~any(receivedGoal==[optX optX_cor optY optY_cor])) && optY~=optX_cor
                    if receivedGoal==5 && ~any(chosenAction==[optX optY]) && any(chosenAction_cor==[optX optY])    
                        found = 1;
                        
                        % Congruent crit trial?
                        if Type(thisRound-counter)==trialType
                            % Woohoo! We're in a critical trial, and we've
                            %   found our prior low-prob transition
                            critTrials_comb(thisRound) = 1;
                  
                            if optX==chosenAction_cor
                                MFonMB(thisRound) = -Re(thisRound-counter);
                            elseif optY==chosenAction_cor
                                MFonMB(thisRound) = Re(thisRound-counter);
                            end
                        else
                            % Incongruent crit trial
                            critTrials_comb(thisRound) = 0;
                            
                            if optX==chosenAction_cor
                                MFonMB(thisRound) = -Re(thisRound-counter);
                            else
                                MFonMB(thisRound) = Re(thisRound-counter);
                            end
                        end
                    else
                        counter = counter + 1;
                    end
                end
                
                % Unlikely transitions that aren't crit trials
                found = 0;
                counter = 1;
                while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff
                    chosenAction = Action(thisRound-counter);
                    chosenAction_cor = getCorrespondingAction(chosenAction,Type(thisRound-counter),orig_simulation);
                    receivedGoal = S2(thisRound-counter)-1; % -1 because S2 is from 2-6
                    
                    if receivedGoal==5 && any(chosenAction==[optX optY]) && ~any(chosenAction_cor==[optX optY]) && Type(thisRound-counter)==trialType
                        critTrials_comb(thisRound) = -1;
                        
                        if optX==chosenAction
                            unlikely(thisRound) = -Re(thisRound-counter);
                        else
                            unlikely(thisRound) = Re(thisRound-counter);
                        end
                        found = 1;
                    else
                        counter = counter+1;
                    end
                end
                
                % Finally, get the choice & the subject ID
                choices(thisRound) = Action(thisRound)==optY; % 0 if optX, 1 if optY
                subjIDs(thisRound) = subjID;
                %roundNum(thisRound) = round1(thisRound);
            end
        end
    end
end

% Drop practice rounds
MB = removerows(MB,'ind',rowsToToss);
MF = removerows(MF,'ind',rowsToToss);
MFonMB = removerows(MFonMB,'ind',rowsToToss);
unlikely = removerows(unlikely,'ind',rowsToToss);
critTrials_comb = removerows(critTrials_comb,'ind',rowsToToss);
choices = removerows(choices,'ind',rowsToToss);
subjIDs = removerows(subjIDs,'ind',rowsToToss);
%roundNum = removerows(roundNum,'ind',rowsToToss);

% Grand mean center everything
MB = MB - mean(MB);
MF = MF - mean(MF);
MFonMB = MFonMB - mean(MFonMB);
unlikely = unlikely - mean(unlikely);

csvwrite('Parsed.csv',[MB MF MFonMB unlikely critTrials_comb choices subjIDs]);