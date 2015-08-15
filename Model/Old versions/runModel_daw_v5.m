%% Inputs
% params: numAgents x [lr elig beta w_MF w_MB]

function [earnings, negLL, results] = runModel_daw_v5(params, boardPath)

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
likelihood = zeros(numAgents,1);
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
    %Q_MB = zeros(numStates,numActions); % flat MB
    Q_HMB_options = zeros(numStates,numOptions); % hierarchical MB option values
    Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
    Q_H_actions = zeros(numOptions,numActions); % hierarchical intra-option action values
    
    % Initialize transition counts/probabilities
    %transition_counts = zeros(numStates,numActions,numStates);
    transition_probs = transition_probs0;

    prevChoice = 1;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What trial type is this?
        trialType = TRIAL_TYPE;
        
        crit = any(criticalTrials==thisRound);

        % Are we still in practice rounds?
        if (thisRound <= numPracticeRounds)
            
            % STAGE 1
            state1 = 1;
            
            % Get available actions
            curActions = availableActions(thisRound,:,thisAgent);
            
            % Make choices randomly
            choice1 = curActions((rand() < .5) + 1); 

            if rand() < baseprob
                state2 = likelyTransition(state1,choice1);
            else
                state2 = unlikelyTransition;
            end

            % Update transition probabilities
            %transition_counts(state1,choice1,state2) = transition_counts(state1,choice1,state2) + 1;

            % STAGE 2
            choice2 = (rand()<.5)+1;
            state3 = likelyTransition(state2,choice2);
            
            %transition_counts(state2,choice2,state3) = transition_counts(state2,choice2,state3) + 1;
            
            reward = 0;
            
        % Now we're in the big leagues - the real rounds
        else
            %% STAGE 1
            
            % Get available actions
            % Are we in a crit trial?
            if crit
                % If we are, force option
                act1 = getCorrespondingAction(prevChoice,TRIAL_TYPE);
                act2 = getOtherAvailableAction(act1,TRIAL_TYPE);
                curActions = [act1 act2];
            else
                curActions = availableActions(thisRound,:,thisAgent);
            end
            
            %transition_probs = normalizeTransitionCounts(transition_counts);
            
            % Update MB models
            state1 = 1;
            
            % For flat MB, walk decision tree
            % (numCurActions x numStates) * ((numStates x numActions x numStates) *
            % (numStates x numActions x 1))
%             Q_MB(state1,curActions) = zeros(1,length(curActions));
%             for s2=S2_states
%                 Q_MB(state1,curActions) = Q_MB(state1,curActions) + squeeze(transition_probs(state1,curActions,s2)) * max((squeeze(transition_probs(s2,S2_actions,S3_states)) * Q_MB(S3_states,S3_action)));
%             end
            
            % Hierarchical stuff
            % For each option..
            for i=1:numOptions
                % Hierarchical MB evaluates options by walking down
                %   decision tree
                Q_HMB_options(state1,i) = max(squeeze(transition_probs(subgoals(i),S2_actions,S3_states))*Q_HMB_options(S3_states,S3_action));
            end
            
            % For MFonMB_actions, for each option we want to calculate the subgoal-reward
            % of each state times the probability of an action getting us
            % to that state.
            % ((numCurActions x numStates) * (numStates x numOptions))' = numOptions x numCurActions
            Q_H_actions(:,curActions) = (squeeze(transition_probs(state1,curActions,:)) * subgoalRewards)';
            
            %MFG_option = randsample(numOptions,1,true,softmax(Q_MFG_options(state1,:),beta));
            %MB_option = randsample(numOptions,1,true,softmax(Q_HMB_options(state1,:),beta));
            
            % Get weighted Q
            Q_weighted = w_MFG*Q_MFG_options(state1,:)*Q_H_actions(:,curActions) + w_MB*Q_HMB_options(state1,:)*Q_H_actions(:,curActions) + (1-w_MFG-w_MB)*Q_MF(state1,curActions);
            
            % Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice1 = randsample(curActions,1,true,probs);
            
            % Add up likelihood
            %likelihood(thisAgent) = likelihood(thisAgent) + log(probs(curActions == choice1));
            
            % Transition
            % Are we in a setup trial?
            if any(criticalTrials(:,1) == (thisRound+1)) || rand() > mainTransition
                state2 = unlikelyTransition; % force unlikely
            else
                state2 = likelyTransition(state1,choice1);
            end
            
            % Update transition counts
            %transition_counts(state1, choice1, state2) = transition_counts(state1, choice1, state2) + 1;
            %transition_probs = normalizeTransitionCounts(transition_counts);
            
            %% STAGE 2
            
            % Update models
           
            % For flat MB, walk decision tree
            %Q_MB(state2,S2_actions) = squeeze(transition_probs(state2,S2_actions,:)) * Q_MB(:,S3_action);
           
            Q_HMB_options(state2,S2_actions) = squeeze(transition_probs(state2,S2_actions,:)) * Q_HMB_options(:,S3_action);
            
            %MFG_option = randsample(numOptions,1,true,softmax(Q_MFG_options(state2,:),beta));
            %MB_option = randsample(numOptions,1,true,softmax(Q_HMB_options(state2,:),beta));
            
            % Get weighted Q
            Q_weighted = w_MFG*Q_MFG_options(state2,S2_actions) + w_MB*Q_HMB_options(state2,S2_actions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_actions);
            
            % Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice2 = randsample(S2_actions,1,true,probs);
            
            % Add up likelihood
            %likelihood(thisAgent) = likelihood(thisAgent) + log(probs(S2_actions == choice2));
            
            % Transition
            state3 = likelyTransition(state2,choice2);
            
            % Update transition probs - these get normalized on the next
            % loop
            %transition_counts(state2, choice2, state3) = transition_counts(state2, choice2, state3) + 1;
            
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
            
            % Update flat MF (and bottom-level MB estimate)
            delta = gamma*max(Q_MF(state2,:)) - Q_MF(state1,choice1);
            Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*delta;
            
            delta = gamma*max(Q_MF(state3,:)) - Q_MF(state2,choice2);
            Q_MF(state2,choice2) = Q_MF(state2,choice2) + lr*delta;
            Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*elig*delta;
            
            delta = reward - Q_MF(state3,S3_action);
            Q_MF(state3,S3_action) = Q_MF(state3,S3_action) + lr*delta;
            Q_MF(state2,choice2) = Q_MF(state2,choice2) + lr*elig*delta;
            Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr*(elig^2)*delta;
            
            %Q_MB(state3,S3_action) = Q_MF(state3,S3_action);
            Q_HMB_options(state3,S3_action) = Q_MF(state3,S3_action);
            
            % Update MFonMB
            % Infer option chosen
            [~,chosenOption] = max(squeeze(transition_probs(state1,choice1,subgoals)));
            Q_MFG_options(state1,chosenOption) = Q_MFG_options(state1,chosenOption) + lr*(reward - Q_MFG_options(state1,chosenOption));
            Q_MFG_options(state2,choice2) = Q_MFG_options(state2,choice2) + lr*(reward-Q_MFG_options(state2,choice2));
            
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

negLL = -1*likelihood;
end

function [transition_probs] = normalizeTransitionCounts(transition_counts)
transition_probs = transition_counts ./ repmat(sum(transition_counts,3),1,1,size(transition_counts,1));
end

function [probs] = softmax(Qs,beta)
probs = exp(beta*Qs) / sum(exp(beta*Qs));
end