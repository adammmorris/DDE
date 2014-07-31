%%%%% Building experiment board %%%%%

%% Versions

% Version3:
% - Changing my bounded drifting to random drifting
% - Inserting critical trials

path = 'C:\Personal\School\Brown\Psychology\DDE Project\Model\board3.mat';

%% Basic parameters
numOptions = 5; % # of horizontal choices
numStates = numOptions + 1; % # of states (not including trival third-level states)
numAvailable = 2; % # available at any given choice
numBoards = 100;
numRounds = 200;
numTrialTypes = 2; % 1 = shape trial, 2 = color trial
numFeatureValues = 3; % # of feature values for any given feature; i.e. for letter features, 1 = A, 2 = B, 3 = C

% Transition probabilities
main = .8;
other = (1-main)/(numOptions-1);
transition_probs = zeros(numOptions,numOptions); % rows are which action you chose in level 1; columns are which state you got to in level 2
for i=1:numOptions
    for j=1:numOptions
        if i == j
            transition_probs(i,j) = main;
        else
            transition_probs(i,j) = other;
        end
    end
end

% Board parameter matrices
trialTypes = zeros(numBoards,numRounds,1); % trialTypes(round) gives you the trial type of that round in that board; 1 = letter trial, 2 = color trial
options1 = zeros(numBoards,numRounds,numAvailable); % options1(round,:) gives you the actions available in state 1 for that round in that board
transitions = zeros(numBoards,numRounds,numOptions); % transitions(round,choice) gives you the second-level state to which you transition after taking action 'choice' in level 1 - so it should never be 1

%% Features
% For trial type 1 (aka shapes): 1 = square, 2 = circle, 3 = triangle
% For trial type 2 (aka colors): 1 = blue, 2 = red, 3 = green
features = zeros(numStates,numTrialTypes); % features(state,dimension) gives you the feature value of a particular state along one of the trial-type dimensions

% Let's set this statically right now
% NOTE: In the original 'board.mat', this was different.  It went blue
%   square, blue circle, red square, red circle, green triangle.
%   It's fixed now, but if you use 'board.mat', be wary of this.
features(1,:) = [1 1]; % first-level state has no features, but it's easier to set it to 1.  This should turn to 0 when multiplied by the transition probabilities, etc.
features(2,:) = [1 1]; % blue square
features(3,:) = [1 2]; % red square
features(4,:) = [2 1]; % blue circle
features(5,:) = [2 2]; % red circle
features(6,:) = [3 3]; % green triangle

% For our goal-learner, we're going to need a goal numbering system based
% off these feature types
goals = zeros(numTrialTypes,numFeatureValues);
for trialType = 1:numTrialTypes
    for featureValue = 1:numFeatureValues
        goals(trialType,featureValue) = numFeatureValues*(trialType-1) + featureValue;
    end
end

%% Rewards
% We need a separate reward structure for each trial type
% For a given trial type, all the second-level states with the same
%   feature value along that dimension have the same reward
% And those rewards drift over time
% So conceptually, states don't have individual rewards; feature values do
rewards = zeros(numBoards,numRounds,numTrialTypes,numFeatureValues); % rewards(board,round,trialType,featureValue) gives you the reward for a given feature value in a given trial type in a given round on a given board
rewardBound = 5;

% Drift parameters
% directions = zeros(numBoards,numTrialTypes,numFeatureValues);
% drift_weights = [.15 .5 .35]; % -increment zero increment
% increment = 1;

stdShift = 1.5;

%% Critical trials
% 2 types:
% Color trial, blue vs. green, sent to red; then red vs. green.  1st
%   should be predictive of 2nd only on color trials
% Letter trial, A vs. C, sent to B; then B vs. C.  1st should be predictive
%   of 2nd only on letter trials
numCriticalTrials = 0;
criticalTrials = randsample(numRounds,numCriticalTrials,false);

%% Loop through all boards
for thisBoard = 1:numBoards
    % Initialize random rewards & directions
    parfor trialType = 1:numTrialTypes
        rewards(thisBoard,1,trialType,:) = randsample(-rewardBound:rewardBound,numFeatureValues,true);
    end
    
    % Loop through all rounds
    % If we want to insert critical trials, it will be easy to do here
    for thisRound = 1:numRounds
        % Decide trial type randomly
        trialTypes(thisBoard,thisRound) = 1 + (1 * (rand() < .5));
        
        % Are we in a critical trial?
        %if any(criticalTrials == thisRound)
        % Choose available actions randomly
        %    options1(thisBoard,thisRound,:) = randsample(numOptions,2,false);
        % Are we in a test trial?
        %elseif any(criticalTrials == (thisRound-1))
        %else
        % Choose available actions randomly
        options1(thisBoard,thisRound,:) = randsample(numOptions,2,false);
        
        % Decide transitions randomly
        parfor thisChoice = 1:numOptions
            transitions(thisBoard,thisRound,thisChoice) = randsample(2:numStates,1,true,transition_probs(thisChoice,:)); % 2:(numOptions+1) to account for the first state
        end
        %end
        
        % Drift rewards for next round
        % We're only gonna drift the rewards of the trial type we just played
        for featureValue = 1:numFeatureValues % again, leave 1st state as zero
            trialType = trialTypes(thisBoard,thisRound);
            
            % Get shift according to weights & then multiply it by direction
            shift = round(randn()*stdShift);
            
            % Do it!
            rewards(thisBoard,thisRound+1,trialType,featureValue) = rewards(thisBoard,thisRound,trialType,featureValue) + shift;
        end
        % Keep other trial type rewards the same
        for trialType = 1:numTrialTypes
            if trialType ~= trialTypes(thisBoard,thisRound)
                rewards(thisBoard,thisRound+1,trialType,:) = rewards(thisBoard,thisRound,trialType,:);
            end
        end
    end
    fprintf(strcat('Completed board '),num2str(thisBoard));
end

%% Save
save(path,'options1','transitions','trialTypes','numTrialTypes','features','numFeatureValues','goals','rewards');