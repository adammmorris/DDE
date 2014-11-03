%% DDE Project - Adam Morris, Nov. 2013 %%
% This is our model for our experiment
% Meant to show model-free learning on model-based goals
% Model combines both types of RL learners
% Much of this is drawn from Daw's 2-step task

% Our model:
% One model-based RL learner
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

% Version 5:
% - Reducing # of parameters
% - Made 'params' able to be different for each agent

% Version 6:
% - Cutting out the dumb model-free learner from the decision-making (too many parameters)
% - Fixed major bug in model-based learner

% Version 7:
% - Trying to add back in dumb model-free learner (now that I have 4 cores
%   on my laptop ^^ yay parfor)
% - Making the servant/equal thing a parameter
% - Added round# to the results array

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
% params should be [lr beta elig_trace]
%   it can be just a 1x4 vector, in which case it applies to all agents
%   or it can be an nx4, where n is numAgents
% weights should be [modelBased smartModelFree goalLearner]
% numRounds should be [numPracticeRounds numRealRounds]
% numAgents should be how many agents you want to run
% servant: set to 0 if you want the goal learner to be treated equally
%   (i.e. an independent weight parameter), or set to 1 if you want the
%   goal learner to be treated as a servant to the model-based system (i.e.
%   its weight must be <= to the model-based weight; its weight here really represents what % of the model-based weight it should have)
% boardName: should be something like 'board', or 'board_no5'
% magicBoard: this is gimmicky, but set this to anything nonzero to make
%   every agent play that same board#

%% Outputs
% earnings has the earnings for every agent
% negLL has the negLL for every agent
% results is a (numAgents*numRounds) x 8 matrix;
%   columns are id, trialType, option1, option2, choice, state2, reward,
%   and round#

%% Remarks

% - Throughout this whole thing, be VERY careful to distinguish (and
%   convert) between action space, state space, and feature space

function [earnings, negLL, results] = runModel_v10(agent_params, weights, numRounds, numAgents, boardName, magicBoard, twoTrialTypes)

%% Defaults
if nargin < 7
    twoTrialTypes = 1;
end
if nargin < 6
    magicBoard = 0;
end
if nargin < 5
    boardName = 'board';
end
if nargin < 4
    numAgents = 80;
end
if nargin < 3
    numRounds = [25 125];
end
if nargin < 2
    weights = [.33 0 .33];
end
if nargin < 1
    agent_params = [.2 1 .75];
end

%% Set board params
load(['C:\Personal\School\Brown\Psychology\DDE Project\git\Model\' boardName '.mat']);

% Set up round parameters
numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);
numRealRounds = numRounds(2);

%% Set agent params
% For parameters across models, we currently have: learning rate, temperature, eligibility trace
if size(agent_params,1) == 1 % if they only gave us one row vector
    lr1 = repmat(agent_params(1),numAgents,1);
    lr2 = lr1;
    beta = repmat(agent_params(2),numAgents,1);
    elig_trace = repmat(agent_params(3),numAgents,1);
elseif size(agent_params,1) == numAgents
    lr1 = agent_params(:,1);
    lr2 = lr1;
    beta = agent_params(:,2);
    elig_trace = agent_params(:,3);
else
    error('# of rows in agent_params must be either 1 or numAgents');
end
%stay_bonus = global_params(5);

% The model weights calculation depend on whether it's servant or not
% We either have three weights that must sum to 1, or 4 weights that must
%   sum to 1
if size(weights,1) == 1 % if they only gave us one row vector
    weight_modelBased = repmat(weights(1),numAgents,1);
    weight_smartModelFree = repmat(weights(2),numAgents,1);
    weight_goalLearner = repmat(weights(3),numAgents,1);
elseif size(weights,1) == numAgents
    weight_modelBased = weights(:,1);
    weight_smartModelFree = weights(:,2);
    weight_goalLearner = weights(:,3);
else
    error('# of rows in weights must be either 1 or numAgents');
end

weight_dumbModelFree = ones(numAgents,1) - weight_modelBased - weight_smartModelFree - weight_goalLearner;

% Outputs
likelihood = zeros(numAgents,1);
earnings = zeros(numAgents,1);
results = zeros(numAgents*numTotalRounds,8);

roundIndex = 1; % for 'results'

%% Let's do this!
for thisAgent = 1:numAgents
    % This is kinda gimmicky, but it's here in case I want to set all
    %   agents to use a specific board (a 'magic' board)
    % If not, just set it to thisAgent
    if magicBoard == 0
        magic = thisAgent;
    else
        magic = magicBoard;
    end
    
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
    Q_modelBased = zeros(numFeatureValues+1,numOptions,numTrialTypes);

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
    %transition_counts = repmat(zeros(1,numStates),numOptions,1); % rows are which action you chose in level 1; columns are which state you got to in level 2 (so first column should be zeros)
    transition_counts = zeros(numOptions,numStates);
    initialProbs = [0 (1/(numStates-1))*ones(1,numStates-1)]; % for any given row, initially a uniform dist. (except state 1)
    transition_probs = repmat(initialProbs,numOptions,1);
    
    prevChoice = 0;
    prevType = 0;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What trial type is this?
        if twoTrialTypes == 1, trialType = trialTypes(thisRound,magic);
        else trialType = 2; % If we're not doing the version w/ two trial types, it's always color
        end
        
        % Are we in a test trial? (i.e. was last trial a critical trial?
        if any(criticalTrials(:,1)==(thisRound-1))
            % If we are, force options & trial type
            
            % Are we in a congruent test trial (or in the version w/ only 1
            % trial type)?
            if (twoTrialTypes == 0) || (criticalTrials(find(criticalTrials(:,1)==(thisRound-1)),2) == 1), trialType = prevType;
            else trialType = 1+1*(prevType==1); end
            
            opt1 = getCorrespondingAction(prevChoice,prevType,orig_simulation);
            opt2 = getOtherOption(opt1,trialType);
            action_options = [opt1 opt2];
       else
            %action_options = squeeze(options1(magic,thisRound,:)); % what are our action choices?
            action_options = options(thisRound,:,magic);
        end
        
        [~,likely_state_options(1)] = max(transition_probs(action_options(1),:),[],2); % what will these likely lead to?
        [~,likely_state_options(2)] = max(transition_probs(action_options(2),:),[],2);
        goal_options = goals(trialType,features(likely_state_options,trialType)); % what are the corresponding goals?
        
        % Are we still in practice rounds?
        if (thisRound <= numPracticeRounds)

            % Make choices randomly
            choice = action_options((rand() < .5) + 1); 

            newstate = transitions(thisRound,choice,magic);

            % Update transition probabilities
            transition_counts(choice, newstate) = transition_counts(choice, newstate) + 1;
            transition_probs = transition_counts ./ repmat(sum(transition_counts,2),1,numStates);

            % Technically there's another action here, which technically leads to
            %   another state in which the agent actually receives his rewards.
            % (i.e. clicking the letter)
            % But those transitions are deterministic and don't need to be
            %   learned, so maybe we won't have them in the practice rounds?
            % Either way we don't need to model them here

            reward = 0;
            
        % Now we're in the big leagues - the real rounds
        else
            %% Update model-based
            % Transition probs for each state-option * that feature-options Q value
            % We don't need to max over those second-level Q values, because
            %   only one action at each second-level state
            % Watch out - there's tricky conversions here between state space and
            %   feature space
            Q_modelBased(1,action_options,trialType) = (transition_probs(action_options,:) * Q_modelBased(features(:,trialType)+1,1,trialType))';

            %% Get weighted Q
            % Are we treating goal learner as a servant or no?
            Q_weighted = weight_modelBased(thisAgent) * Q_modelBased(1,action_options,trialType)' + weight_smartModelFree(thisAgent) * Q_smartModelFree(1,action_options,trialType)' + weight_dumbModelFree(thisAgent) * Q_dumbModelFree(1,action_options)' + weight_goalLearner(thisAgent) * Q_goalLearner(1,goal_options)';

            % Does our option set include our previous choice?
            % If so, give the stay bonus
            %if sum(action_options == previousChoice) > 0
            %    Q_weighted(find(action_options == previousChoice)) = Q_weighted(find(action_options == previousChoice)) + stay_bonus;
            %end

            %% Make choice
            probs = exp(beta(thisAgent)*Q_weighted) / sum(exp(beta(thisAgent)*Q_weighted));
            choice = randsample(action_options,1,true,probs);
            
            % Are we in a critical trial?
            if any(criticalTrials(:,1) == thisRound)
                newstate = 6; % force to green triangle
                newstate_feature = features(newstate,trialType);
                reward = rewards(thisRound,trialType,newstate_feature,magic);
                
                % Polarize reward
                d = (reward > 0)*2-1;
                boost = 2;
                reward = reward+boost*d;
                if (reward > rewardRange_hi), reward = rewardRange_hi*d;
                elseif (reward < rewardRange_lo), reward = abs(rewardRange_lo)*d;
                end
            else
                newstate = transitions(thisRound,choice,magic);
                newstate_feature = features(newstate,trialType);
                reward = rewards(thisRound,trialType,newstate_feature,magic);
            end
        
            
            % Add up likelihood
            likelihood(thisAgent) = likelihood(thisAgent) + log(probs(find(action_options == choice)));

            % Update transition probabilities
            transition_counts(choice, newstate) = transition_counts(choice, newstate) + 1;
            transition_probs = transition_counts ./ repmat(sum(transition_counts,2),1,numStates);
            
            % Get our goal (to be used later in updating the goal learner)
            thisGoal = goals(trialType,features(likely_state_options(find(action_options==choice)),trialType));

            %% Update smart model-free
            % First, do the update from doing this first, nonrewarding
            %   transition
            delta = Q_smartModelFree(newstate,1,trialType) - Q_smartModelFree(1,choice,trialType);
            Q_smartModelFree(1,choice,trialType) = Q_smartModelFree(1,choice,trialType) + lr1(thisAgent) * delta;

            % Then, do the update from the second 'action', which we don't have
            %   to simulate because there was no choice
            delta = reward - Q_smartModelFree(newstate,1,trialType);
            Q_smartModelFree(newstate,1,trialType) = Q_smartModelFree(newstate,1,trialType) + lr2(thisAgent) * delta;
            Q_smartModelFree(1,choice,trialType) = Q_smartModelFree(1,choice,trialType) + elig_trace(thisAgent) * lr1(thisAgent) * delta;

            %% Update dumb model-free
            delta = Q_dumbModelFree(newstate,1) - Q_dumbModelFree(1,choice);
            Q_dumbModelFree(1,choice) = Q_dumbModelFree(1,choice) + lr1(thisAgent) * delta;

            % Then, do the update from the second 'action', which we don't have
            %   to simulate because there was no choice
            delta = reward - Q_dumbModelFree(newstate,1);
            Q_dumbModelFree(newstate,1) = Q_dumbModelFree(newstate,1) + lr2(thisAgent) * delta;
            Q_dumbModelFree(1,choice) = Q_dumbModelFree(1,choice) + elig_trace(thisAgent) * lr1(thisAgent) * delta;
            
            %% Update goal learner
            delta = reward - Q_goalLearner(1,thisGoal);
            Q_goalLearner(1,thisGoal) = Q_goalLearner(1,thisGoal) + lr1(thisAgent)*delta;
            
            %% Update model-based Q value
            % We have to convert to goal space here (hence the +1)
            Q_modelBased(newstate_feature+1,1,trialType) = Q_smartModelFree(newstate,1,trialType);

            % Update earnings
            earnings(thisAgent) = earnings(thisAgent) + reward;

            % Update previous choice
            prevChoice = choice;
            prevType = trialType;
        end
        
        %% Update 'results' array
        results(roundIndex,:) = [thisAgent trialType action_options(1) action_options(2) choice newstate reward thisRound];
        
        % Move round index forward
        roundIndex = roundIndex + 1;
    end
end

negLL = -1*likelihood;
end