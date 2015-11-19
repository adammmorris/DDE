%%------------------------------------------
% Generative model for Experiment 1b in Cushman & Morris (2015). Habitual control of goal selection in humans. PNAS.
%
% Adam Morris, 2015
% 
% Note that many of the variables used here are set in "buildEnvironment.mat" and "environment_1B.mat".
%%------------------------------------------

%% Inputs
% params: Each row should contain the five parameters that characterize a simulated agent: [learning rate, eligibility trace, inverse temperature, model-free goal weight, model-based weight].
%   So if you want to simulate 100 agents, params should have 100 rows and 5 columns.

%% Outputs
% earnings: A vector containing the total accumulated reward for each simulated agent.
% results: A matrix recording every simulated round from every simulated agent. Each row is one round, and has 0 columns:
%   [agentNumber, 1st available stage 1 action, 2nd available stage 1 action, stage 1 choice, stage 2 state, stage 2 choice, reward, round number, critical
%   trial]
%   The "critical trial" variable is 1 if the round was a critical trial, and 0 otherwise.

function [earnings, results] = generativeModel(params)

%% Defaults
if nargin < 1
    params = repmat([.2 .95 1 .33 .33],100,1);
end

%% Set up
load('environment_1B.mat');

gamma = 1;
numAgents = size(params,1);

% Set agent's transition matrix to correct one (see SI)
transition_probs = transition_probs0;

% Outputs
earnings = zeros(numAgents,1);
results = zeros(numAgents*numRounds,9);
roundIndex = 1; % Row index for results matrix

%% Start simulation
for thisAgent = 1:numAgents
    %% Initialize this agent's params
    
    lr = params(thisAgent,1);
    elig = params(thisAgent,2);
    beta = params(thisAgent,3);
    w_MFG = params(thisAgent,4);
    w_MB = params(thisAgent,5);
        
    %% Initialize models
    Q_MF = zeros(numStates,numActions); % flat MF
    Q_MB = zeros(numStates,numActions); % flat MB
    Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
    Prob_MFG_actions = zeros(numOptions,numActions); % the probability of selecting a given action under a given option
    
    prevChoice = -1;
    
    %% Go through rounds
    for thisRound = 1:numRounds
        crit = any(criticalTrials==thisRound); % Are we in a critical trial? (The critical trial numbers are generated in buildEnvironment.m)
        
        %% Stage 1
        state1 = 1;
        
        % Get available actions
        if crit
            % If we're in a critical trial, choose actions appropriately (see main text)
            act1 = getSameGoalAction(prevChoice);
            act2 = getOtherAvailableAction(act1);
            curActions = [act1 act2];
        else
            % Otherwise, use what environment_1B.mat gives us
            curActions = availableActions(thisRound,:,thisAgent);
        end
                
        % Update MB models (see SI)
        % S2_states, S2_actions, etc. are set in buildEnvironment.m
        for i=1:length(curActions)
            Q_MB(state1,curActions(i)) = 0;
            for j=1:length(S2_states)
                Q_MB(state1,curActions(i)) = Q_MB(state1,curActions(i)) + transition_probs(state1,curActions(i),S2_states(j))*max(squeeze(transition_probs(S2_states(j),S2_actions,S3_states))*Q_MB(S3_states,S3_action));
            end
        end
        
        % Update MFG action probabilities (see SI)
        for i=1:numOptions
            [~,b] = max(squeeze(transition_probs(state1,curActions,subgoals(i))));
            Prob_MFG_actions(i,curActions) = curActions==curActions(b);
        end
        
        % Get weighted Q
        Q_weighted = w_MFG*Q_MFG_options(state1,:)*Prob_MFG_actions(:,curActions) + w_MB*Q_MB(state1,curActions) + (1-w_MFG-w_MB)*Q_MF(state1,curActions);
        
        % Make choice
        probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
        choice1 = randsample(curActions,1,true,probs);
        
        % Transition
        if any(criticalTrials(:,1) == (thisRound+1)) || rand() > lowProb_corrected
            % If the next round is a critical trial (or if we randomly get a low-probability transition), then transition to the unlikely stage 2 state
            state2 = unlikelyTransition;
        else
            state2 = likelyTransition(state1,choice1);
        end
        
        %% Stage 2
        
        % Update MB model
        Q_MB(state2,S2_actions) = squeeze(transition_probs(state2,S2_actions,S3_states))*Q_MB(S3_states,S3_action);
        
        % Get weighted Q
        % Note that in the second stage choice, the math works out such that you can just treat Q_MFG_options as action values.
        Q_weighted = w_MFG*Q_MFG_options(state2,S2_actions) + w_MB*Q_MB(state2,S2_actions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_actions);
        
        % Make choice
        probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
        choice2 = randsample(S2_actions,1,true,probs);
        
        % Transition
        state3 = likelyTransition(state2,choice2);
        
        % Get reward
        reward = rewards(thisRound,state3,thisAgent);
        
        % If in crit trial..
        if any(criticalTrials(:,1) == (thisRound+1))
            % Polarize reward
            d = (reward > 0)*2-1;
            boost = 2;
            reward = reward+boost*d;
            if (reward > rewardRange_hi), reward = rewardRange_hi*d;
            elseif (reward < rewardRange_lo), reward = abs(rewardRange_lo)*d;
            end
        end
        
        % Update flat MF
        delta = gamma*max(Q_MF(state2,S2_actions)) - Q_MF(state1,choice1);
        Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*delta;
        
        delta = gamma*max(Q_MF(state3,S3_action)) - Q_MF(state2,choice2);
        Q_MF(state2,choice2) = Q_MF(state2,choice2) + lr*delta;
        Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*elig*delta;
        
        % We treat state 3 as having 1 action; there's no actual stage 3 choice
        delta = reward - Q_MF(state3,S3_action);
        Q_MF(state3,S3_action) = Q_MF(state3,S3_action) + lr*delta;
        Q_MF(state2,choice2) = Q_MF(state2,choice2) + lr*elig*delta;
        Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*(elig^2)*delta;
        
        % Update bottom-level MB estimate
        Q_MB(state3,S3_action) = Q_MF(state3,S3_action);
        
        % Update MFG
        % Infer option chosen
        [~,chosenOption] = max(squeeze(transition_probs(state1,choice1,subgoals)));
        
        delta = gamma*max(Q_MFG_options(state2,:)) - Q_MFG_options(state1,chosenOption);
        Q_MFG_options(state1,chosenOption) = Q_MFG_options(state1,chosenOption) + lr*delta;
        
        delta = reward-Q_MFG_options(state2,choice2);
        Q_MFG_options(state2,choice2) = Q_MFG_options(state2,choice2) + lr*delta;
        Q_MFG_options(state1,chosenOption) = Q_MFG_options(state1,chosenOption) + lr*elig*delta;
        
        % Update earnings
        earnings(thisAgent) = earnings(thisAgent) + reward;
        
        % Update previous choice
        prevChoice = choice1;
        
        %% Update 'results' array
        results(roundIndex,:) = [thisAgent curActions(1) curActions(2) choice1 state2 choice2 reward thisRound crit];
        
        % Move round index forward
        roundIndex = roundIndex + 1;
    end
end
end

%% getSameGoalAction
% Returns the Stage 1 action with the same goal as inputted action.

function [sgAction] = getSameGoalAction(action)
if action == 1 % blue
    sgAction = 3;
elseif action == 3 % blue
    sgAction = 1;
elseif action == 2 % red
    sgAction = 4;
elseif action == 4 % red
    sgAction = 2;
elseif action == 5
    sgAction = 5;
end
end