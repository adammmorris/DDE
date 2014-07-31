%% DDE Project - Adam Morris, Nov. 2013 %%
% This is our model for our experiment
% Meant to show model-free learning on model-based goals
% Model combines both types of RL learners
% Much of this is drawn from Daw's 2-step task

% Our model:
% One model-based RL learner
% One smart model-free SARSA learner (smart because it recognizes trial
%   type)
% One dumb model-free SARSA learner (dumb because it doesn't recognize
%   trial type)
% One goal-learning model-free learner

% Version 2:
% - Model-based learner now searches through feature space
% - We now can run multiple agents

% Version 3:
% - Added dumb model-free learner
% - Fixed major bug in model-based learner
% - Added goal-learning model-free learner

% Version 4:
% - Changing model-based learner to work off goals

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
% (8) goals(trialType,featureValue) gives you the corresponding goal #

%% Inputs:
% params should be [lr1 lr2 beta elig_trace stay_bonus]
% weights should be [modelBased smartModelFree dumbModelFree goalLearner]
% numRounds should be [numPracticeRounds numRealRounds]
% numAgents should be how many agents you want to run

%% Remarks

% - Throughout this whole thing, be VERY careful to distinguish (and
%   convert) between action space, state space, and feature space
% - '_equal' means that the goal learner is treated as an equal model
% - '_servant' means it's treated as a servant to the model-based system

function [avgEarnings, stdEarnings, negLL] = runModel_v4_equal(global_params, weights, numRounds, numAgents)

%% Set board params
load('E:\Personal\School\College\Brown\Psychology\DDE Project\Model\board.mat');

% Defaults
if nargin < 4
    numAgents = 100;
end
if nargin < 3
    numRounds = [25 125];
end
if nargin < 2
    weights = [1/4 1/4 1/4 1/4];
end
if nargin < 1
    global_params = [.2 .2 1 .8 0];
end

% Set up round parameters
numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);

% Get numOptions & numStates
numOptions = size(transitions,3);
numGoals = numFeatureValues * numTrialTypes;
numStates = numOptions+1; % remember to preserve the state # integrity

%% Set agent params
% For parameters across models, we currently have: learning rate 1, learning rate 2, temperature, eligibility trace, and stay bonus
lr1 = global_params(1);
lr2 = global_params(2);
beta = global_params(3);
elig_trace = global_params(4);
stay_bonus = global_params(5);

% Model weights
weight_modelBased = weights(1);
weight_smartModelFree = weights(2);
weight_dumbModelFree = weights(3);
weight_goalLearner = 1 - weight_modelBased - weight_smartModelFree - weight_dumbModelFree;

likelihood = zeros(numAgents,1);
earnings = zeros(numAgents,1);

%% Let's do this!
for thisAgent = 1:numAgents
    %% Initialize stuff
    
    % Set up the Q matrices
    % Each matrix has the form: numRelevantStates x numActions x
    %   numTrialTypes
    %
    % The numAction is always going to be numStates - 1
    % Why? The top-level state has that many choices.  So just to keep things
    %   all in one matrix, we'll set that many actions for each state.
    % But for all rows > 1, all columns > 1 should be zero
    %
    % What about numRelevantStates?
    % There are subtleties here.

    % For the model-based system, we have numGoals states
    % Why? Because for second-level states, it seeks feature values, not states
    % This is how it 'sets goals'
    % But we still need the +1 for the top-level state
    % And we still have numOptions actions
    % So it conceptualizes the world as numOptions actions in the first
    %   level which can lead to numGoals states in the second level
    Q_modelBased = zeros(numGoals+1,numOptions);

    % For the smart model-free system, it doesn't know about feature values; it just
    %   learns about states & action choices
    % So numRelevantStates = numStates
    % But it still knows about trial types
    Q_smartModelFree = zeros(numStates,numOptions,numTrialTypes);
    
    % The dumb model-free system is the same as the smart one, except it
    %   doesn't know about trial types
    Q_dumbModelFree = zeros(numStates,numOptions);
  
    % The goal-learning model-free system is special.
    % It has one state, the first one, and it has numGoals actions
    % The way goals are numbered is captured in 'goals' (set in board.mat)
    Q_goalLearner = zeros(1,numGoals);
    
    % Initialize transition counts/probabilities
    transition_counts = repmat([0 ones(1,numOptions)],numOptions,1); % rows are which action you chose in level 1; columns are which state you got to in level 2 (so first column should be zeros)
    initialProbs = [0 (1/numOptions)*ones(1,numOptions)]; % for any given row, initially a uniform dist. (except state 1)
    transition_probs = repmat(initialProbs,numOptions,1);
    
    previousChoice = 0;

    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What trial type is this?
        trialType = trialTypes(thisAgent,thisRound);
        
        % What options do we have?
        action_options = squeeze(options1(thisAgent,thisRound,:)); % what are our action choices?
        [~,likely_state_options(1)] = max(transition_probs(action_options(1),:),[],2); % what will these likely lead to?
        [~,likely_state_options(2)] = max(transition_probs(action_options(2),:),[],2);
        goal_options = goals(trialType,features(likely_state_options,trialType)); % what are the corresponding goals?
        
        % Are we still in practice rounds?
        if (thisRound <= numPracticeRounds)

            % Make choices randomly
            choice = action_options((rand() < .5) + 1); 

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
            %% Update model-based
            % Transition probs for each state-option * that feature-options Q value
            % We don't need to max over those second-level Q values, because
            %   only one action at each second-level state
            % Watch out - there's tricky conversions here between state space and
            %   feature space
            
            % Are we going to treat the goal learner as a servant to
            %   modelBased?
            Q_modelBased(1,action_options) = (transition_probs(action_options,:) * Q_modelBased(goals(trialType,features(:,trialType)),1))';
            
            %% Get weighted Q
            Q_weighted = weight_modelBased * Q_modelBased(1,action_options)' + weight_smartModelFree * Q_smartModelFree(1,action_options,trialType)' + weight_dumbModelFree * Q_dumbModelFree(1,action_options)' + weight_goalLearner * Q_goalLearner(1,goal_options)';

            % Does our option set include our previous choice?
            % If so, give the stay bonus
            if sum(action_options == previousChoice) > 0
                Q_weighted(find(action_options == previousChoice)) = Q_weighted(find(action_options == previousChoice)) + stay_bonus;
            end

            %% Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice = randsample(action_options,1,true,probs);
            newstate = transitions(thisAgent,thisRound,choice);
            newstate_feature = features(newstate,trialType);
            reward = rewards(thisAgent,thisRound,trialType,newstate_feature);

            % Add up likelihood - but start after the 50th real trial
            if thisRound > (numPracticeRounds + 50)
                likelihood(thisAgent) = likelihood(thisAgent) + log(probs(find(action_options == choice)));
            end

            % Update transition probabilities
            transition_counts(choice, newstate) = transition_counts(choice, newstate) + 1;
            transition_probs = transition_counts ./ repmat(sum(transition_counts,2),1,numStates);
            
            % Get our goal (to be used later in updating the goal learner)
            thisGoal = goals(trialType,features(likely_state_options(find(action_options==choice)),trialType));

            %% Update smart model-free
            % First, do the update from doing this first, nonrewarding
            %   transition
            delta = Q_smartModelFree(newstate,1,trialType) - Q_smartModelFree(1,choice,trialType);
            Q_smartModelFree(1,choice,trialType) = Q_smartModelFree(1,choice,trialType) + lr1 * delta;

            % Then, do the update from the second 'action', which we don't have
            %   to simulate because there was no choice
            delta = reward - Q_smartModelFree(newstate,1,trialType);
            Q_smartModelFree(newstate,1,trialType) = Q_smartModelFree(newstate,1,trialType) + lr2 * delta;
            Q_smartModelFree(1,choice,trialType) = Q_smartModelFree(1,choice,trialType) + elig_trace * lr1 * delta;

            %% Update dumb model-free
            delta = Q_dumbModelFree(newstate,1) - Q_dumbModelFree(1,choice);
            Q_dumbModelFree(1,choice) = Q_dumbModelFree(1,choice) + lr1 * delta;

            % Then, do the update from the second 'action', which we don't have
            %   to simulate because there was no choice
            delta = reward - Q_dumbModelFree(newstate,1);
            Q_dumbModelFree(newstate,1) = Q_dumbModelFree(newstate,1) + lr2 * delta;
            Q_dumbModelFree(1,choice) = Q_dumbModelFree(1,choice) + elig_trace * lr1 * delta;
            
            %% Update goal learner
            delta = reward - Q_goalLearner(1,thisGoal);
            Q_goalLearner(1,thisGoal) = Q_goalLearner(1,thisGoal) + lr1*delta;
            
            %% Update model-based Q value
            % Again, we have to convert to feature space
            Q_modelBased(goals(trialType,newstate_feature),1) = Q_smartModelFree(newstate,1,trialType);

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