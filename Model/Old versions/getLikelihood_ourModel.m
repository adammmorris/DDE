%% getLikelihood_ourModel
% This calculates the likelihood of a given set of rounds given our
%    model, which currently has:
%    model-based system, smart model-free system, dumb model-free system,
%    & goal-learner

%% Inputs:
% params should be the 6x1 vector [lr,beta,elig_trace,mb_weight,smf_weight,dmf_weight]

function [negLL] = getLikelihood_ourModel(params,numRounds,trialTypes,option1,option2,choices,state2,rewards)

%% Set board params
load('C:\Personal\School\Brown\Psychology\DDE Project\Model\board.mat');

% Set up round parameters
numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);
numRealRounds = numRounds(2);

% Get numOptions & numStates
numOptions = size(transitions,3);
numGoals = numFeatureValues * numTrialTypes;
numStates = numOptions+1; % remember to preserve the state # integrity

%% Set agent params
% For parameters across models, we currently have: learning rate, temperature, eligibility trace
lr1 = params(1);
lr2 = lr1;
beta = params(2);
elig_trace = params(3);

weight_modelBased = params(4);
weight_smartModelFree = params(5);
weight_dumbModelFree = params(6);
weight_goalLearner = 1 - weight_modelBased - weight_smartModelFree - weight_dumbModelFree;

% Outputs
likelihood = 0;

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

%% Go through rounds
for thisRound = 1:numTotalRounds
    % What trial type is this?
    trialType = trialTypes(thisRound);
    
    % What options did we have?
    action_options = [option1(thisRound) option2(thisRound)]; % what are our action choices?
    [~,likely_state_options(1)] = max(transition_probs(action_options(1),:),[],2); % what will these likely lead to?
    [~,likely_state_options(2)] = max(transition_probs(action_options(2),:),[],2);
    goal_options = goals(trialType,features(likely_state_options,trialType)); % what are the corresponding goals?
    
    % What happened?
    choice = choices(thisRound);
    newstate = state2(thisRound);
    reward = rewards(thisRound);
    
    % Are we still in practice rounds?
    if (thisRound <= numPracticeRounds)
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
        %if sum(action_options == previousChoice) > 0
        %    Q_weighted(find(action_options == previousChoice)) = Q_weighted(find(action_options == previousChoice)) + stay_bonus;
        %end
        
        %% Make choice
        probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
        newstate_feature = features(newstate,trialType);
        
        % Add up likelihood - but start after the 50th real trial
        likelihood = likelihood + log(probs(find(action_options == choice)));
        
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
    end
end

negLL = -1*likelihood;
end