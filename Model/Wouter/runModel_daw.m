%% Inputs
% params: numAgents x [lr elig beta w_MF w_MB]

function [earnings, results] = runModel_daw(params, boardPath)

%% Defaults
if nargin < 2
    boardPath = 'C:\Personal\Psychology\Projects\DDE\git\Model\board_daw.mat';
end
if nargin < 1
    params = repmat([.2 .95 1 0 1],5,1);
end

%% Set board params
load(boardPath);

gamma = 1;
numAgents = size(params,1);

%% Outputs
earnings = zeros(numAgents,1);
results = zeros(numAgents*numTotalRounds,10);

roundIndex = 1; % for 'results'

transition_probs0 = zeros(numStates,numActions,numStates);
transition_probs0(1,[1 3],2) = baseprob;
transition_probs0(1,[2 4],3) = baseprob;
transition_probs0(1,[1 2 3 4],4) = 1-baseprob;
for i=2:4
    for j=1:2
        transition_probs0(i,j,likelyTransition(i,j)) = 1;
    end
end
transition_probs = transition_probs0;

%% Let's do this!
for thisAgent = 1:numAgents
    %% Initialize params
    
    lr = params(thisAgent,1);
    elig = params(thisAgent,2);
    beta = params(thisAgent,3);
    w_MFG = params(thisAgent,4);
    w_MB = params(thisAgent,5);
        
    %% Initialize models
    Q_MF = zeros(numStates,numActions); % flat MF
    %Q_HMB_options = zeros(numStates,numOptions); % hierarchical MB option values
    Q_MB = zeros(numStates,numActions);
    Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
    P_H_actions = zeros(numOptions,numActions); % hierarchical intra-option action values
    
    prevChoice = 1;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What trial type is this?
        trialType = TRIAL_TYPE;
        
        crit = any(criticalTrials==thisRound);

        % Are we still in practice rounds?
        if thisRound > numPracticeRounds
            %% STAGE 1
            
            % Get available actions
            % Are we in a crit trial?
            if crit
                % If we are, force option
                act1 = getCorrespondingAction(prevChoice);
                act2 = getOtherAvailableAction(act1);
                curActions = [act1 act2];
            else
                curActions = availableActions(thisRound,:,thisAgent);
            end
            
            %transition_probs = normalizeTransitionCounts(transition_counts);
            
            % Update MB models
            state1 = 1;
            
            % Hierarchical stuff
            % For each option..
%             for i=1:numOptions
%                 % Hierarchical MB evaluates options by walking down
%                 %   decision tree
%                 Q_HMB_options(state1,i) = max(squeeze(transition_probs(subgoals(i),S2_actions,S3_states))*Q_HMB_options(S3_states,S3_action));
%             end
            
            for i=1:length(curActions)
                Q_MB(state1,curActions(i)) = 0;
                for j=1:length(S2_states)
                    Q_MB(state1,curActions(i)) = Q_MB(state1,curActions(i)) + transition_probs(state1,curActions(i),S2_states(j))*max(squeeze(transition_probs(S2_states(j),S2_actions,S3_states))*Q_MB(S3_states,S3_action));
                end
            end
            
            % For MFonMB_actions, for each option we want to calculate the subgoal-reward
            % of each state times the probability of an action getting us
            % to that state.
            % ((numCurActions x numStates) * (numStates x numOptions))' = numOptions x numCurActions
            for i=1:numOptions
                [~,b] = max(squeeze(transition_probs(state1,curActions,subgoals(i))));
                P_H_actions(i,curActions) = curActions==curActions(b);
            end
            
            % Get weighted Q
            Q_weighted = w_MFG*Q_MFG_options(state1,:)*P_H_actions(:,curActions) + w_MB*Q_MB(state1,curActions) + (1-w_MFG-w_MB)*Q_MF(state1,curActions);
            
            % Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice1 = randsample(curActions,1,true,probs);
            
            % Transition
            % Are we in a setup trial?
            if any(criticalTrials(:,1) == (thisRound+1)) || rand() > mainTransition
                state2 = unlikelyTransition; % force unlikely
            else
                state2 = likelyTransition(state1,choice1);
            end
            
            %% STAGE 2
            
            % Update models
            %Q_HMB_options(state2,S2_actions) = squeeze(transition_probs(state2,S2_actions,:)) * Q_HMB_options(:,S3_action);
            Q_MB(state2,S2_actions) = squeeze(transition_probs(state2,S2_actions,S3_states))*Q_MB(S3_states,S3_action);
            
            % Get weighted Q
            Q_weighted = w_MFG*Q_MFG_options(state2,S2_actions) + w_MB*Q_MB(state2,S2_actions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_actions);
            
            % Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice2 = randsample(S2_actions,1,true,probs);
            
            % Transition
            state3 = likelyTransition(state2,choice2);
            
            % Get reward
            reward = rewards(thisRound,state3,thisAgent);
            
            % If in crit trial..
%             if any(criticalTrials(:,1) == (thisRound+1))
%                 % Polarize reward
%                 d = (reward > 0)*2-1;
%                 boost = 2;
%                 reward = reward+boost*d;
%                 if (reward > rewardRange_hi), reward = rewardRange_hi*d;
%                 elseif (reward < rewardRange_lo), reward = abs(rewardRange_lo)*d;
%                 end
%             end
            
            % Update flat MF (and bottom-level MB estimate)
            delta = gamma*max(Q_MF(state2,S2_actions)) - Q_MF(state1,choice1);
            Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*delta;
            
            delta = gamma*max(Q_MF(state3,S3_action)) - Q_MF(state2,choice2);
            Q_MF(state2,choice2) = Q_MF(state2,choice2) + lr*delta;
            Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*elig*delta;
            
            delta = reward - Q_MF(state3,S3_action);
            Q_MF(state3,S3_action) = Q_MF(state3,S3_action) + lr*delta;
            Q_MF(state2,choice2) = Q_MF(state2,choice2) + lr*elig*delta;
            Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*(elig^2)*delta;
            
            Q_MB(state3,S3_action) = Q_MF(state3,S3_action);
            
            % Update MFonMB
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
        end
        
        %% Update 'results' array
        results(roundIndex,:) = [thisAgent trialType curActions(1) curActions(2) choice1 state2 choice2 reward thisRound crit];
        
        % Move round index forward
        roundIndex = roundIndex + 1;
    end
end
end