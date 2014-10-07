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

countLowProbs = 0;
countCrits = 0;
critTrials = [];
distance = [];
distance_cutoff = 1;

% If this is 1, the script will only do special critical trials (which are
%   the ones in which the goal option set changes - i.e. must involve a 5
%   in some capacity)
halfCrits = 1;

% If this is 1, the script will drop any trial that's not a critical trial
onlyCrits = 0;

numDataPoints = length(id);

% The important data
MB_X = zeros(numDataPoints,1);
MB_Y = zeros(numDataPoints,1);
MF_X = zeros(numDataPoints,1);
MF_Y = zeros(numDataPoints,1);
MFonMB_X = zeros(numDataPoints,1);
MFonMB_Y = zeros(numDataPoints,1);
subjIDs = zeros(numDataPoints,1);
choices = zeros(numDataPoints,1);

% At the end, we want to drop all rows that are practice rounds or from
%   tossed subjects
rowsToToss = [];

%lowProbRewards = []; % reward from low-prob transition trial
%relativeValues = []; % true value of the critical option  - true value of other option (in critical trial)
%choices = []; % the actual choice made in critical trial (0 = didn't choose critical option, 1 = chose critical option)

%% Loop!
% Loop through subjects
for thisSubj = 1:numSubjects
    subjID = id(subjMarkers(thisSubj));
    
    % Get the subject's index
    if thisSubj < length(subjMarkers)
        index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
    else
        index = subjMarkers(thisSubj):length(id);
    end
    
    % Are we tossing this person?
    if any(tosslist == subjID)
        % Add all their rows to rowsToToss
        rowsToToss = horzcat(rowsToToss,index);
    else
        % Walk through rounds
        % Ignore practice rounds
        for thisRound = index
            if round1(thisRound) <= practiceCutoff
                rowsToToss(end+1) = thisRound;
            else
                % Get the relevant stuff
                %if mod(thisRound,2)==0
                    optX = Opt1(thisRound);
                    optY = Opt2(thisRound);
                %else
                %    optY = Opt1(thisRound);
                %    optX = Opt2(thisRound);
                %end
                trialType = Type(thisRound);
                
                % Get the corresponding actions for each option
                optX_cor = getCorrespondingAction(optX,trialType);
                optY_cor = getCorrespondingAction(optY,trialType);
                
                % For MBs, the rule is: MB_X is the last reinforcement
                %   value received from the goal associated with option X
                %   (note that the trials must be the same trial type)
                
                % Look back for MB_X
                found = 0;
                counter = 1;
                % Loop until you find it or you hit the beginning of that
                %   subject's rounds
                while found == 0 && (thisRound - counter) >= index(1)
                    % In this round, did the subject get the goal
                    %   corresponding with option X?
                    % For that to be true, the trial type must be the same, and S2 must either be optX or
                    %   optX_cor
                    if trialType == Type(thisRound-counter) && any((S2(thisRound-counter)-1) == [optX optX_cor])
                        % Woohoo!
                        MB_X(thisRound) = Re(thisRound-counter);
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
                while found == 0 && (thisRound - counter) >= index(1)
                    % In this round, did the subject get the goal
                    %   corresponding with option X?
                    % For that to be true, S2 must either be optY or
                    %   optY_cor
                    if trialType == Type(thisRound-counter) && any((S2(thisRound-counter)-1) == [optY optY_cor])
                        % Woohoo!
                        MB_Y(thisRound) = Re(thisRound-counter);
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
                while found == 0 && (thisRound - counter) >= index(1)
                    % In this round, did the subject choose optX?
                    if Action(thisRound-counter) == optX
                        % Woohoo!
                        MF_X(thisRound) = Re(thisRound-counter);
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
                while found == 0 && (thisRound - counter) >= index(1)
                    % In this round, did the subject choose optY?
                    if Action(thisRound-counter) == optY
                        % Woohoo!
                        MF_Y(thisRound) = Re(thisRound-counter);
                        found = 1;
                    else
                        counter = counter+1;
                    end
                end
                
                % Are we in a critical trial?
                % To be in a critical trial, a prior trial must..
                %   (1) have been the same trial type
                %   (2) have been a low-prob
                %       transition which led to a different goal
                %   (3) have had a chosen action which was not a 5, and
                %       which was either optX_cor or optY_cor
                %   (4) have been within a distance cutoff
                %   (5) have gotten an S2 which is NOT a goal option now
                %   (5 IS OPTIONAL)!
                found = 0;
                counter = 1;
                while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff
                    % Get info
                    chosenAction = Action(thisRound-counter);
                    chosenAction_cor = getCorrespondingAction(chosenAction,Type(thisRound-counter));
                    receivedGoal = S2(thisRound-counter)-1;
                    
                    % Check..
                    if Type(thisRound-counter)==trialType && ~any(receivedGoal==[chosenAction chosenAction_cor]) && chosenAction~=5 && any(chosenAction==[optX_cor optY_cor]) && (halfCrits==0 || ~any(receivedGoal==[optX optY optX_cor optY_cor]))
                        % Woohoo! We're in a critical trial, and we've
                        %   found our prior low-prob transition
                        found = 1;
                        countCrits = countCrits + 1;
                        critTrials(end+1) = thisRound;
                        
                        % What's the critical option?
                        % If it's optX, record the two important values
                        % MFonMB_X is easy, b/c you just get the
                        %   reinforcement value from the low-prob transition
                        %   trial
                        % MFonMB_Y is harder - you have to search back
                        %   until you hit either a chosen optY or optY_cor
                        if chosenAction==optX_cor
                            % Get MFonMB_X
                            MFonMB_X(thisRound) = Re(thisRound-counter);
                            
                            % Search for MFonMB_Y
                            %found2 = 0;
                            %counter2 = 1;
                            %while found2 == 0 && (thisRound - counter2) >= index(1)
                            %    % In this round, did the subject choose optY or optY_cor?
                            %    if Action(thisRound-counter2) == optY || Action(thisRound-counter2) == optY_cor
                            %        % Woohoo!
                            %        MFonMB_Y(thisRound) = Re(thisRound-counter2);
                            %        found2 = 1;
                            %    else
                            %        counter2 = counter2+1;
                            %    end
                            %end
                        elseif chosenAction==optY_cor
                            % Get MFonMB_Y
                            MFonMB_Y(thisRound) = Re(thisRound-counter);
                            
                            % Search for MFonMB_X
                            %found2 = 0;
                            %counter2 = 1;
                            %while found2 == 0 && (thisRound - counter2) >= index(1)
                            %    % In this round, did the subject choose optX or optX_cor?
                            %    if Action(thisRound-counter2) == optX || Action(thisRound-counter2) == optX_cor
                            %        % Woohoo!
                            %        MFonMB_X(thisRound) = Re(thisRound-counter2);
                            %        found2 = 1;
                            %    else
                            %        counter2 = counter2+1;
                            %    end
                            %end
                        end
                    else
                        counter = counter + 1;
                    end
                end
                
                % This is if you just wanna do crit trials
                if onlyCrits == 1 && found == 0
                    rowsToToss(end+1) = thisRound;
                end
                
                % Finally, get the choice & the subject ID
                choices(thisRound) = Action(thisRound)==optY; % 0 if optX, 1 if optY
                subjIDs(thisRound) = subjID;
            end
        end
    end
end

% Drop practice rounds
MB_X = removerows(MB_X,'ind',rowsToToss);
MB_Y = removerows(MB_Y,'ind',rowsToToss);
MF_X = removerows(MF_X,'ind',rowsToToss);
MF_Y = removerows(MF_Y,'ind',rowsToToss);
MFonMB_X = removerows(MFonMB_X,'ind',rowsToToss);
MFonMB_Y = removerows(MFonMB_Y,'ind',rowsToToss);
choices = removerows(choices,'ind',rowsToToss);
subjIDs = removerows(subjIDs,'ind',rowsToToss);

% Grand mean center everything
MB_X = MB_X - mean(MB_X);
MB_Y = MB_Y - mean(MB_Y);
MF_X = MF_X - mean(MF_X);
MF_Y = MF_Y - mean(MF_Y);
MFonMB_X = MFonMB_X - mean(MFonMB_X); % ??
MFonMB_Y = MFonMB_Y - mean(MFonMB_Y); % ??
%choices = choices - mean(choices);

%test = 63;
%[MB_X(test) MB_Y(test) MF_X(test) MF_Y(test) MFonMB_X(test) MFonMB_Y(test) choices(test)]

%csvwrite('test.csv',[MB_X MB_Y MF_X MF_Y MFonMB_X MFonMB_Y subjIDs choices]);