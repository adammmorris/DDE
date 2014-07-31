%%%%% DDE Project - Adam Morris, Nov. 2013 %%%%%
% This is our model for our experiment
% Meant to show model-free learning on model-based goals
% Model combines both types of RL learners
% Much of this is drawn from Daw's 2-step task

% We currently have:
% One model-based RL learner
% One model-free SARSA learner

%% From 'board.mat':
% (1) trialTypes(thisBoard,thisRound) gives you the trial type of this round
% (2) options1(thisBoard,thisRound,:) gives you the actions (2 of them) available to the agent in the
%   first level at the given round
% (3) transitions(thisBoard,thisRound,choice) gives you the second-level state to which agent transitions (the actual one, not
%   the prob) by taking 'choice' in the given round
%   Note that choice is the option #
% (4) rewards(thisBoard,thisRound, trialType, featureValue) gives you the reward of the
%   feature value along the given trial type dimension
%   Technically you only get rewards in the third-level, but, since there's
%   only action you can do (i.e. click on the letter), for now we can just
%   treat it this way
% (5) numTrialTypes: this is 2 right now
% (6) features(state, trialType) gives you the feature value for the given
%   state along the given trial type dimension
% (7) numFeatureValues: this is 3 right now


%% Inputs:
% params should be [lr1 lr2 beta elig_trace stay_bonus modelbased_weight]
% numRounds should be [numPracticeRounds numRealRounds]

function [avgEarnings, stdEarnings, negLL] = runModel_v2(params, numRounds, numAgents)

%% Set board params
load('E:\Personal\School\College\Brown\Psychology\DDE Project\Model\board.mat');

% Defaults
if nargin < 3
    numAgents = 100;
end
if nargin < 2
    numRounds = [25 125];
end
if nargin < 1
    params = [.2 .2 1 .8 0 .5];
end

% Set up round parameters
numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);

% Get numOptions & numStates
numOptions = size(transitions,3);
numStates = numOptions+1; % remember to preserve the state # integrity

%% Set agent params
% We currently have: learning rate, eligibility trace, stay bonus,
%   weighting for model-based learner
lr1 = params(1);
lr2 = params(2);
beta = params(3);
elig_trace = params(4);
stay_bonus = params(5);
modelbased_weight = params(6);

likelihood = zeros(numAgents,1);
earnings = zeros(numAgents,1);

%% Let's do this!
for thisAgent = 1:numAgents
    %% Initialize stuff
    
    % Set up the Q matrices
    % Each matrix has the form: numRelevantStates x numActions x
    %   numTrialTypes
    %
    % The numAction is always going to be numRelevantStates - 1
    % Why? The top-level state has that many choices.  So just to keep things
    %   all in one matrix, we'll set that many actions for each state.
    % But for all rows > 1, all columns > 1 should be zero
    %
    % What about numRelevantStates?
    % There are subtleties here.

    % For the model-based system, we have (numFeatureValues + 1) relevant
    %   states for each trial type
    % Why? Because for second-level states, it seeks feature values, not states
    % This is how it 'sets goals'
    % But we still need the +1 for the top-level state
    Q_modelbased = zeros(numFeatureValues+1,numFeatureValues,numTrialTypes);

    % For the model-free system, it doesn't know about feature values; it just
    %   learns about states & action choices
    % So numRelevantStates = numStates
    Q_modelfree = zeros(numStates,numOptions,numTrialTypes);
  
    % Initialize transition counts/probabilities
    transition_counts = repmat([0 ones(1,numOptions)],numOptions,1); % rows are which action you chose in level 1; columns are which state you got to in level 2 (so first column should be zeros)
    initialProbs = [0 (1/numOptions)*ones(1,numOptions)]; % for any given row, initially a uniform dist. (except state 1)
    transition_probs = repmat(initialProbs,numOptions,1);
    
    previousChoice = 0;

    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What options do we have?
        state_options = squeeze(options1(thisAgent,thisRound,:));

        % What trial type is this?
        trialType = trialTypes(thisAgent,thisRound);

        % Are we still in practice rounds?
        if (thisRound <= numPracticeRounds)

            % Make choices randomly
            choice = state_options((rand() < .5) + 1); 

            newstate = transitions(thisAgent,thisRound,choice);

            % Update transition probabilities
            transition_counts(choice, newstate) = transition_counts(choice, newstate) + 1;
            transition_probs = transition_counts ./ repmat(sum(transition_counts,2),1,numStates);

            % Technically there's another action here, which technically leads to
            %   another state in which the agent actually receives his rewards.
            % (i.e. clicking the letter)
            % But those transitions are deterministic and don't need to be
            %   learned, so maybe we won't have them in the practice rounds?
            % Either way we don't need to model them here

        % Now we're in the big leagues - the real rounds
        else        
            % Translate our state options into feature options for the
            % model-based system
            feature_options = features(state_options,trialType);

            % Update model-based
            % Transition probs for each state-option * that feature-options Q value
            % We don't need to max over those second-level Q values, because
            %   only one action at each second-level state
            % Watch out - there's tricky conversions here between state space and
            %   feature space
            Q_modelbased(1,feature_options,trialType) = (transition_probs(state_options,:) * Q_modelbased(features(:,trialType),1,trialType))';

            % Get weighted Q
            Q_weighted = modelbased_weight * Q_modelbased(1,feature_options,trialType)' + (1-modelbased_weight) * Q_modelfree(1,state_options,trialType)';

            % Does our option set include our previous choice?
            % If so, give the stay bonus
            if sum(state_options == previousChoice) > 0
                Q_weighted(find(state_options == previousChoice)) = Q_weighted(find(state_options == previousChoice)) + stay_bonus;
            end

            % Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice = randsample(state_options,1,true,probs);
            newstate = transitions(thisAgent,thisRound,choice);
            newstate_feature = features(newstate,trialType);

            % Add up likelihood - but start after the 50th real trial
            if thisRound > (numPracticeRounds + 50)
                likelihood(thisAgent) = likelihood(thisAgent) + log(probs(find(state_options == choice)));
            end

            % Update transition probabilities
            transition_counts(choice, newstate) = transition_counts(choice, newstate) + 1;
            transition_probs = transition_counts ./ repmat(sum(transition_counts,2),1,numStates);

            % Update model-free
            % First, do the update from doing this first, nonrewarding
            %   transition
            delta = Q_modelfree(newstate,1,trialType) - Q_modelfree(1,choice,trialType);
            Q_modelfree(1,choice,trialType) = Q_modelfree(1,choice,trialType) + lr1 * delta;

            % Then, do the update from the second 'action', which we don't have
            %   to simulate because there was no choice
            reward = rewards(thisAgent,thisRound,trialType,newstate_feature);
            delta = reward - Q_modelfree(newstate,1,trialType);
            Q_modelfree(newstate,1,trialType) = Q_modelfree(newstate,1,trialType) + lr2 * delta;
            Q_modelfree(1,choice,trialType) = Q_modelfree(1,choice,trialType) + elig_trace * lr1 * delta;

            % Update model-based Q value
            % Again, we have to convert to feature space
            Q_modelbased(newstate_feature,1,trialType) = Q_modelfree(newstate,1,trialType);

            % Update earnings
            earnings(thisAgent) = earnings(thisAgent) + reward;

            % Update previous choice
            previousChoice = choice;
        end
    end
end

avgEarnings = mean(earnings);
stdEarnings = std(earnings);
negLL = -mean(likelihood);
end