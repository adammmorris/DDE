%%%%% Building experiment board %%%%%

path = 'E:\Personal\School\College\Brown\Psychology\DDE Project\Model\board.mat';

%% Basic parameters
numOptions = 5; % # of horizontal choices
numStates = numOptions + 1; % # of states (not including trival third-level states)
numAvailable = 2; % # available at any given choice
numRounds = 1000;
numTrialTypes = 2; % 1 = letter trial, 2 = color trial
numFeatureValues = 3; % # of feature values for any given feature; i.e. for letter features, 1 = A, 2 = B, 3 = C

% Transition probabilities
boost = 50; % this is the boost to the normal transition
transition_counts = ones(numOptions,numOptions) + diag(boost*ones(numOptions,1),0); % rows are which action you chose in level 1; columns are which state you got to in level 2
transition_probs = transition_counts ./ repmat(sum(transition_counts,2),1,numOptions); % normalize

% Board parameter matrices
trialTypes = zeros(numRounds,1); % trialTypes(round) gives you the trial type of that round; 1 = letter trial, 2 = color trial
options1 = zeros(numRounds,numAvailable); % options1(round,:) gives you the actions available in state 1 for that round
transitions = zeros(numRounds,numOptions); % transitions(round,choice) gives you the second-level state to which you transition after taking action 'choice' in level 1 - so it should never be 1

%% Rewards
% We need a separate reward structure for each trial type
% For a given trial type, all the second-level states with the same
%   feature value along that dimension have the same reward
% And those rewards drift over time
% So conceptually, states don't have individual rewards; feature values do
rewards = zeros(numRounds,numStates,numTrialTypes); % rewards(round,trialType,featureValue) gives you the reward for a given feature value in a given trial type

% Initialize random rewards
rewardBound = 5;
for trialType = 1:numTrialTypes
    rewards(1,2:end,trialTypes) = randsample(-rewardBound:rewardBound,numOptions,true);
end

% Drift parameters
weights = [.25 .25 .5]; % -increment zero increment

directions = zeros(numTrialTypes,numFeatureValues);
for trialType = 1:numTrialTypes
    directions(trialType,:) = randsample([1 -1],numFeatureValues,true);
end

%% Loop through all rounds
% If we want to insert critical trials, it will be easy to do here
for thisRound = 1:numRounds
    % Decide trial type randomly
    trialTypes(thisRound) = 1 + (1 * (rand() < .5));
    
    % Choose available actions randomly
    options1(thisRound,:) = randsample(numOptions,2,false);
    
    % Decide transition probabilities
    for thisChoice = 1:numOptions
        transitions(thisRound,thisChoice) = randsample(2:numStates,1,true,transition_probs(thisChoice,:)); % 2:(numOptions+1) to account for the first state
    end

    % Drift rewards for next round
    % We're only gonna drift the rewards of the trial type we just played
    for featureValue = 1:numFeatureValues % again, leave 1st state as zero
        trialType = trialTypes(thisRound);
        
        % Are we at an extreme?
        if rewards(thisRound,trialType,featureValue) >= rewardBound
            directions(trialType,featureValue) = -1;
        elseif rewards(thisRound,trialType,featureValue) <= -rewardBound
            directions(trialType,featureValue) = 1;
        end

        increment = ceil(abs(randn())); % keep things interesting
        
        % Get shift according to weights & then multiply it by direction
        shift = randsample([-increment 0 increment], 1, true, weights) * directions(trialType,featureValue);

        % Do it!
        rewards(thisRound+1,trialType,featureValue) = rewards(thisRound,trialType,featureValue) + shift;
    end
    % Keep other trial type rewards the same
    for trialType = 1:numTrialTypes
        if trialType ~= trialTypes(thisRound)
            rewards(thisRound+1,trialType,:) = rewards(thisRound,trialType,:);
        end
    end
end

%% Save
save('E:\Personal\School\College\Brown\Psychology\DDE Project\Model\board.mat','options1','transitions','trialTypes','numTrialTypes','features','numFeatureValues','rewards');