%% DDE Project Update - Morgan Henry, September 2015 %%
% This is our model for our experiment
% Meant to show model-free learning on model-based goals
% Model combines both types of RL learners
% Much of this is drawn from Daw's 2-step task

% Our model:
% One model-based RL learner
% Two dumb model-free SARSA learner (dumb because it doesn't recognize
%   trial type), one for each level of choice
% One goal-learning model-free learner

%% NOTES
% 1) I am pretty much ignoring any updates done to the ACTUAL numbers picked in the top level state, other than the fact that I write those down as PEs.
% 2) I've added a model free learner for the 2nd level choice, but not a model based learner because those transitions are deterministic. 
% 3) I'm using randomly generated critical trials and just making sure they
% are spaced at least 2 trials apart
% 4) Only using one trial type.

%% Inputs:
% params should be [lr beta elig_trace]
%   it can be just a 1x3 vector, in which case it applies to all agents
%   or it can be an nx3, where n is numAgents
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
% PEs is a numCritTrials x 6 x numAgents matrix, where the columns contain
%   the following prediction errors:
% (1) V(green) - V(top action)
% (2) reward - V(green)
% (3) reward - V(top action)
% (4) reward - V(top goal)

%% Remarks

% - Throughout this whole thing, be VERY careful to distinguish (and
%   convert) between action space, state space, and feature space

function [earnings, negLL, results, PEs] = runModel_scanner2b(agent_params, weights, numRounds, numAgents, boardName, magicBoard)

%% Defaults
if nargin < 6
    magicBoard = 0;
end
if nargin < 5
    boardName = 'board_scanner2b';
end
if nargin < 4
    numAgents = 20;
end
if nargin < 3
    numRounds = [0 400];
end
if nargin < 2
    weights = [.33 .33];
end
if nargin < 1
    agent_params = [.5 1 1];
end

%% Set board params
%load(['C:\Personal\School\Brown\Psychology\DDE Project\git\Model\' boardName '.mat']);
load board_scanner2b.mat;
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
    %weight_smartModelFree = repmat(weights(2),numAgents,1);
    weight_goalLearner = repmat(weights(2),numAgents,1);
elseif size(weights,1) == numAgents
    weight_modelBased = weights(:,1);
    %weight_smartModelFree = weights(:,2);
    weight_goalLearner = weights(:,2);
else
    error('# of rows in weights must be either 1 or numAgents');
end

weight_dumbModelFree = ones(numAgents,1) - weight_modelBased - weight_goalLearner;

% Outputs
likelihood_firstchoice = zeros(numAgents,1);
likelihood_secondchoice = zeros(numAgents,1);
earnings = zeros(numAgents,1);
results = zeros(numAgents*numTotalRounds,7);
PEs = zeros(numCrits,5,numAgents);

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
    %Q_smartModelFree = zeros(numStates,numOptions,numTrialTypes);
    
    % The dumb model-free system is the same as the smart one, except it
    %   doesn't know about trial types
    Q_dumbModelFree = zeros(numStates,numOptions);
    Q_dumbModelFree_terminal = zeros(numTerminalStates,numTerminalStates);
    
    % The goal-learning model-free system is special.
    % It has one state, the first one, and it has numGoals actions
    % The way goals are numbered is captured in 'goals' (set in board.mat)
    Q_goalLearner = zeros(1,numGoals);
    
    % Initialize transition counts/probabilities
    %transition_counts = repmat(zeros(1,numStates),numOptions,1); % rows are which action you chose in level 1; columns are which state you got to in level 2 (so first column should be zeros)
    transition_counts = ones(numOptions,numStates);
    initialProbs = [0 (1/(numStates-1))*ones(1,numStates-1)]; % for any given row, initially a uniform dist. (except state 1)
    transition_probs = repmat(initialProbs,numOptions,1);
    
    criticalTrial = 0;
    criticalChoice = 0;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What trial type is this?
        trialType = trialTypes(thisRound,magic);
        
        action_options = [1 2];
        
        
        [~,likely_state_options(1)] = max(transition_probs(action_options(1),:),[],2); % what will these likely lead to?
        [~,likely_state_options(2)] = max(transition_probs(action_options(2),:),[],2);
        goal_options = goals(trialType,features(likely_state_options,trialType)); % what are the corresponding goals?
        
        % Are we still in practice rounds?
        if (thisRound <= numPracticeRounds)
            
            % Make choices randomly
            firstchoice = action_options((rand() < .5) + 1);
            
            newstate = transitions(thisRound,firstchoice,magic);
            
            rewardstate_options = terminaloptions(newstate-1,:);
            if ~all(rewardstate_options)
                rewardstate_options = rewardstate_options(1:2);
                secondchoice = rewardstate_options((rand() < .5) + 1);
            else
                secondchoice = rewardstate_options(randi(3,1,1));
            end
            termstate = secondchoice;
            
            
            % Update transition probabilities
            transition_counts(firstchoice, newstate) = transition_counts(firstchoice, newstate) + 1;
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
            Q_modelBased(1,action_options,trialType) = (transition_probs(action_options,:) * Q_modelBased(features(1:4,1),1,trialType))';
            
            %% Get weighted Q
            % Are we treating goal learner as a servant or no?
            Q_weighted = weight_modelBased(thisAgent) * Q_modelBased(1,action_options,trialType)' + weight_dumbModelFree(thisAgent) * Q_dumbModelFree(1,action_options)' + weight_goalLearner(thisAgent) * Q_goalLearner(1,goal_options)';
 
            %% Make choice
            probs = exp(beta(thisAgent)*Q_weighted) / sum(exp(beta(thisAgent)*Q_weighted));
            firstchoice = randsample(action_options,1,true,probs);
            
            
            
            % Get our goal (to be used later in updating the goal learner)
            thisGoal = goals(trialType,features(likely_state_options(find(action_options==firstchoice)),trialType));
      
                criticalTrial = 0;
                newstate = transitions(thisRound,firstchoice,magic);
                newstate_feature = features(newstate,trialType);
                   
                   if newstate == 4 && (results(roundIndex-1,3)==4 || results(roundIndex-2,3)==4)
                       if rand<0.5
                           newstate = 2;
                       else
                           newstate = 3;
                       end
                   end
                   
                   if newstate == 4
                       criticalTrial = 1;
                       if rand <0.5
                        reward= round((Q_dumbModelFree(newstate,1)+Q_goalLearner(1,thisGoal))/2);
                       else
                           if rand<0.15
                           reward = round(Q_dumbModelFree(newstate,1));
                           elseif rand <0.3
                            reward = round(Q_goalLearner(1,thisGoal));  
                           else
                               reward = 0;
                           end
                       end
                   end
  
            
            
            rewardstate_options = terminaloptions(newstate-1,:);
            if ~all(rewardstate_options)
                rewardstate_options = rewardstate_options(1:2);
            end
            
            %% here, i was going to take in to account what states they were trying to get to
            %% for example, if they tried to get to state 16, they probably won't pick terminal 3
            %% fiery says dont do this
%             if newstate ==4 
%                 if thisGoal==1
%                 rewardstate_options = [1 2];
%                 elseif thisGoal ==2
%                     rewardstate_options = [2 3];
%                 end
%             end
            
            Q_weighted_terminal = 1*Q_dumbModelFree_terminal(rewardstate_options,1)';
            secondprobs = exp(beta(thisAgent)*Q_weighted_terminal) / sum(exp(beta(thisAgent)*Q_weighted_terminal));
            secondchoice = randsample(rewardstate_options,1,true,secondprobs);
            termstate=secondchoice;
            
            
            
           if newstate ~=4
                reward = rewards(thisRound,trialType,secondchoice,magic);
           end
            
            
           
            
            
            % Add up likelihood
            likelihood_firstchoice(thisAgent) = likelihood_firstchoice(thisAgent) + log(probs(find(action_options == firstchoice)));
            likelihood_secondchoice(thisAgent) = likelihood_secondchoice(thisAgent) + log(secondprobs(find(rewardstate_options == secondchoice)));
            
            % Update transition probabilities
            transition_counts(firstchoice, newstate) = transition_counts(firstchoice, newstate) + 1;
            transition_probs = transition_counts ./ repmat(sum(transition_counts,2),1,numStates);
            
            % Record prediction errors before we update shit
            
           % PEs(thisRound,1,thisAgent) = Q_dumbModelFree(newstate,1); %val of stage minus val of top level numbers (zero)
           % PEs(thisRound,2,thisAgent) = Q_dumbModelFree_terminal(termstate,1) - Q_dumbModelFree(newstate,1);
           % PEs(thisRound,3,thisAgent) = Q_dumbModelFree_terminal(termstate,1); %val of terminal state minus val of numbers
            PEs(thisRound,1,thisAgent) = reward ; %val of reward minus val of top level numbers (zero)
            PEs(thisRound,2,thisAgent) = reward - Q_dumbModelFree(newstate,1) ; %update stage 2 state
            PEs(thisRound,3,thisAgent) = reward - Q_dumbModelFree_terminal(termstate,1); %update terminal state
            % maybe this #3 is not needed?
            PEs(thisRound,4,thisAgent) = reward - Q_goalLearner(1,thisGoal); %MFMB
            
            
            
            %% Update dumb model-free
            % no top level update, because the choices are unique enough
            
            % Do the update from the reward to the stage 2 state
            delta = reward - Q_dumbModelFree(newstate,1);
            Q_dumbModelFree(newstate,1) = Q_dumbModelFree(newstate,1) + lr2(thisAgent) * delta;
            
            % Do the update from the reward to the terminal state, and also
            % update the stage 2 state via eligibility
            delta = reward - Q_dumbModelFree_terminal(termstate,1);
            Q_dumbModelFree_terminal(termstate,1) = Q_dumbModelFree_terminal(termstate,1) + lr2(thisAgent) * delta;
            Q_dumbModelFree(newstate,1) = Q_dumbModelFree(newstate,1) + elig_trace(thisAgent) * lr1(thisAgent) * delta;
            
            %% Update goal learner
            delta = reward - Q_goalLearner(1,thisGoal);
            Q_goalLearner(1,thisGoal) = Q_goalLearner(1,thisGoal) + lr1(thisAgent)*delta;
            
            %% Update model-based Q value
            % We have to convert to goal space here (hence the +1)
            Q_modelBased(newstate_feature+1,1,trialType) = Q_dumbModelFree(newstate,1);
            
            % We shouldn't need MB for the terminal state, because
            % transitions are deterministic
            %Q_modelBased_terminal(newstate_feature+1,1,trialType) = Q_dumbModelFree_terminal(termstate,1);
            
            
            % Update earnings
            earnings(thisAgent) = earnings(thisAgent) + reward;
            
            
            
        end
        
        %% Update 'results' array
        results(roundIndex,:) = [thisAgent firstchoice newstate termstate reward thisRound criticalTrial];
        
        % Move round index forward
        roundIndex = roundIndex + 1;
    end
end

negLLfirst = -1*likelihood_firstchoice;
negLLsecond = -1*likelihood_secondchoice;


save('model_scanner2b.mat')
