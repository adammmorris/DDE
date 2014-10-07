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
distance = [];
distance_cutoff = 1;

% IMPORTANT: Is this data simulated from the original 'board.mat'?
% If it is, set this to 1.  Otherwise, set to 0
orig_simulation = 1;

% If this is 1, the script will only do special critical trials (which are
%   the ones in which the goal option set changes - i.e. must involve a 5
%   in some capacity)
% This should pretty much always be 1
halfCrits = 1;

% If this is 1, the script will drop any trial that's not a critical trial
% If this is 0, the script will keep all trials
onlyCrits = 1;

% If this is 1, the script will not bother finding critical trials, and
%   will instead treat the MFonMB's just like the other vectors, and will
%   search back to find them on every trial
% If it's 0, the script will just do MFonMB's for critical trials
MFonMB_alltrials = 0;

% Set to 0 for full value, set to 1 for residuals
residuals = 0;

numDataPoints = length(id);

% The important data
MB_X = zeros(numDataPoints,1);
MB_Y = zeros(numDataPoints,1);
MF_X = zeros(numDataPoints,1);
MF_Y = zeros(numDataPoints,1);
SMF_X = zeros(numDataPoints,1);
SMF_Y = zeros(numDataPoints,1);
MFonMB_X = zeros(numDataPoints,1);
MFonMB_Y = zeros(numDataPoints,1);
subjIDs = zeros(numDataPoints,1);
choices = zeros(numDataPoints,1);

% For internal stuff
critTrials = zeros(numDataPoints,1);
critTrials_X = zeros(numDataPoints,1);
critTrials_Y = zeros(numDataPoints,1);

critTrials_incog = zeros(numDataPoints,1);

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
%                     optX = Opt1(thisRound);
%                     optY = Opt2(thisRound);
                %else
                %    optY = Opt1(thisRound);
                %    optX = Opt2(thisRound);
                %end
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
                
                % SMFs
                
                % Look back for SMF_X
                found = 0;
                counter = 1;
                % Loop until you find it or you hit the beginning of that
                %   subject's rounds
                while found == 0 && (thisRound - counter) >= index(1)
                    % In this round, did the subject choose optX?
                    if Type(thisRound-counter) == trialType && Action(thisRound-counter) == optX
                        % Woohoo!
                        SMF_X(thisRound) = Re(thisRound-counter);
                        found = 1;
                    else
                        counter = counter+1;
                    end
                end
          
                % Look back for SMF_Y
                found = 0;
                counter = 1;
                % Loop until you find it or you hit the beginning of that
                %   subject's rounds
                while found == 0 && (thisRound - counter) >= index(1)
                    % In this round, did the subject choose optY?
                    if Type(thisRound-counter) == trialType && Action(thisRound-counter) == optY
                        % Woohoo!
                        SMF_Y(thisRound) = Re(thisRound-counter);
                        found = 1;
                    else
                        counter = counter+1;
                    end
                end
                
                if MFonMB_alltrials == 1
                    % Look back for MFonMB_X
                    found = 0;
                    counter = 1;
                    % Loop until you find it or you hit the beginning of that
                    %   subject's rounds
                    while found == 0 && (thisRound - counter) >= index(1)
                        % In this round, did the subject choose optX?
                        if Type(thisRound-counter) == trialType && any(Action(thisRound-counter) == [optX optX_cor])
                            % Woohoo!
                            MFonMB_X(thisRound) = Re(thisRound-counter);
                            found = 1;
                        else
                            counter = counter+1;
                        end
                    end
                    
                    % Look back for MFonMB_Y
                    found = 0;
                    counter = 1;
                    % Loop until you find it or you hit the beginning of that
                    %   subject's rounds
                    while found == 0 && (thisRound - counter) >= index(1)
                        % In this round, did the subject choose optX?
                        if Type(thisRound-counter) == trialType && any(Action(thisRound-counter) == [optY optY_cor])
                            % Woohoo!
                            MFonMB_Y(thisRound) = Re(thisRound-counter);
                            found = 1;
                        else
                            counter = counter+1;
                        end
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
                if MFonMB_alltrials == 0
                    found = 0;
                    counter = 1;
                    while found == 0 && (thisRound - counter) >= index(1) && counter <= distance_cutoff
                        % Get info
                        chosenAction = Action(thisRound-counter);
                        chosenAction_cor = getCorrespondingAction(chosenAction,Type(thisRound-counter),orig_simulation);
                        receivedGoal = S2(thisRound-counter)-1; % -1 because S2 is from 2-6
                        
                        % Check..
                        % NOTE!! This only finds X crit trials now.  It
                        %   also drops the messed-up rounds (where
                        %   optY=optX_cor)
                        if Type(thisRound-counter)==trialType && ~any(receivedGoal==[chosenAction chosenAction_cor]) && chosenAction~=5 && any(chosenAction==[optX_cor]) && (halfCrits==0 || ~any(receivedGoal==[optX optX_cor optY optY_cor])) && optY~=optX_cor
                            % Woohoo! We're in a critical trial, and we've
                            %   found our prior low-prob transition
                            found = 1;
                            countCrits = countCrits + 1;
                            critTrials(thisRound) = 1;
                            
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
                                critTrials_X(thisRound) = 1;
                                
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
                                critTrials_Y(thisRound) = 1;
                                
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
                end
                
                % What do we do in rows that WEREN'T critical trials?
                if found == 0
                    % If onlyCrits is set to 1, remove it
                    if onlyCrits == 1
                        rowsToToss(end+1) = thisRound;
                    end
                end
                
                % Finally, get the choice & the subject ID
                choices(thisRound) = Action(thisRound)==optY; % 0 if optX, 1 if optY
                subjIDs(thisRound) = subjID;
            end
        end
    end
end

critTrials = logical(critTrials);

% Residuals
if residuals == 1
    MF_X = MF_X - MB_X; % I think we have to make these residuals also?  B/c otherwise which would MFonMB be a residual in reference to?
    MF_Y = MF_Y - MB_Y;
    SMF_X = SMF_X-MB_X;
    SMF_Y = SMF_Y-MB_Y;
    MFonMB_X=MFonMB_X-MB_X;
    MFonMB_Y=MFonMB_Y-MB_Y;
    
    if MFonMB_alltrials == 0
%         MFonMB_X(critTrials)=MFonMB_X(critTrials)-MB_X(critTrials);
%         MFonMB_Y(critTrials)=MFonMB_Y(critTrials)-MB_Y(critTrials);
        MFonMB_X(~critTrials) = 0;
        MFonMB_Y(~critTrials)=0;
    end
    
    % To further reduce collinearity between MFonMB and MF/SMF, force this
    %   to 0 on all non-crits
    %MFonMB_X(~critTrials) = 0;
    %MFonMB_Y(~critTrials) = 0;
    
    %critTrials_logical = logical(critTrials);
    %MFonMB_X(critTrials_logical) = MFonMB_X(critTrials_logical) - MB_X(critTrials_logical);
    %MFonMB_Y(critTrials_logical) = MFonMB_Y(critTrials_logical) - MB_Y(critTrials_logical);
end

% Drop practice rounds
MB_X = removerows(MB_X,'ind',rowsToToss);
MB_Y = removerows(MB_Y,'ind',rowsToToss);
MF_X = removerows(MF_X,'ind',rowsToToss);
MF_Y = removerows(MF_Y,'ind',rowsToToss);
SMF_X = removerows(SMF_X,'ind',rowsToToss);
SMF_Y = removerows(SMF_Y,'ind',rowsToToss);
MFonMB_X = removerows(MFonMB_X,'ind',rowsToToss);
MFonMB_Y = removerows(MFonMB_Y,'ind',rowsToToss);
choices = removerows(choices,'ind',rowsToToss);
subjIDs = removerows(subjIDs,'ind',rowsToToss);
critTrials = removerows(critTrials,'ind',rowsToToss);

% Let's try setting all the non-crit MFonMB's to the mean value of the
%   crit trials
%if MFonMB_alltrials == 0
%    MFonMB_X(~critTrials) = mean(MFonMB_X(critTrials));
%    MFonMB_Y(~critTrials) = mean(MFonMB_Y(critTrials));
%end

% Grand mean center everything
MB_X = MB_X - mean(MB_X);
MB_Y = MB_Y - mean(MB_Y);
MF_X = MF_X - mean(MF_X);
MF_Y = MF_Y - mean(MF_Y);
SMF_X = SMF_X - mean(SMF_X);
SMF_Y = SMF_Y - mean(SMF_Y);
MFonMB_X = MFonMB_X - mean(MFonMB_X); % ??
MFonMB_Y = MFonMB_Y - mean(MFonMB_Y); % ??

% MFonMB_X_dummy = MFonMB_X>median(MFonMB_X);
% MFonMB_X_dummy = removerows(MFonMB_X_dummy,'ind',MFonMB_X==median(MFonMB_X));
% choices_dummy = removerows(choices,'ind',MFonMB_X==median(MFonMB_X));
% subj_dummy = removerows(subjIDs,'ind',MFonMB_X==median(MFonMB_X));
MFonMB_X_dummy = (MFonMB_X>median(MFonMB_X))-(MFonMB_X<median(MFonMB_X));
% MFonMB_X_dummy = zeros(length(MFonMB_X),1);
% for i = 1:length(MFonMB_X)
%     if MFonMB_X(i)>median(MFonMB_X), MFonMB_X_dummy(i) = 1;
%     elseif MFonMB_X(i)==median(MFonMB_X)
%         if rand() < .5, MFonMB_X_dummy(i) = 1; end
%     end
% end

%test = 63;
%[MB_X(test) MB_Y(test) MF_X(test) MF_Y(test) MFonMB_X(test) MFonMB_Y(test) choices(test)]

%csvwrite('test.csv',[MB_X MB_Y MF_X MF_Y SMF_X SMF_Y MFonMB_X MFonMB_Y subjIDs choices]);
%csvwrite('test.csv',[MFonMB_X subjIDs choices]);