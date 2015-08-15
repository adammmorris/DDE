%% Inputs
% params: numAgents x [

function [earnings, negLL, results] = runModel_daw_v1(params, boardPath)

%% Defaults
if nargin < 2
    boardPath = 'C:\Personal\Psychology\Projects\DDE\git\Model\board_daw.mat';
end
if nargin < 1
    params = [.2 1 .75];
end

%% Set board params
load(boardPath);

%% Outputs
likelihood = zeros(numAgents,1);
earnings = zeros(numAgents,1);
results = zeros(numAgents*numTotalRounds,8); % []

roundIndex = 1; % for 'results'

%% Let's do this!
for thisAgent = 1:numAgents
    %% Initialize params
    
    %% Initialize models
    Q_MF = zeros(numStates,numActions); % flat MF
    Q_MB = zeros(numStates,numActions); % flat MB
    
    Q_optionsMB = zeros(numStates,numOptions);
    Q_optionsMF = zeros(numStates,numOptions);
    Q_actionsMB = zeros(numOptions,numStates,numActions);
    Q_actionsMF = zeros(numOptions,numStates,numActions);
    
    Q_options = zeros(numStates,numOptions); % Hierarchical system's Q values for all options (inc. Stage 2 choices)
    Q_actions = zeros(numOptions,numStates,numActions); % Hierarchical system's Q option-specific primitive state-action values
    
    
    % Initialize transition counts/probabilities
    transition_counts = ones(numStates,numActions,numStates);
    transition_probs = normalizeTransitionCounts(transition_counts);
    
    prevChoice = 0;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What trial type is this?
        trialType = TRIAL_TYPE;
        
        % Are we in a crit trial?
        if any(criticalTrials(:,1)==thisRound)
            % If we are, force option
            act1 = getCorrespondingAction(prevChoice,TRIAL_TYPE);
            act2 = getOtherAvailableAction(act1,TRIAL_TYPE);
            curActions = [act1 act2];
        else
            curActions = availableActions(thisRound,:,thisAgent);
        end
        
        % Are we still in practice rounds?
        if (thisRound <= numPracticeRounds)

            % STAGE 1
            state = 1;
            
            % Make choices randomly
            choice1 = curActions((rand() < .5) + 1); 

            if rand() < baseprob
                state2 = likelyTransition(state,choice1);
            else
                state2 = unlikelyTransition;
            end

            % Update transition probabilities
            transition_counts(state,choice1,state2) = transition_counts(state,choice1,state2) + 1;

            % STAGE 2
            state = state2;
            choice1 = curActions((rand()<.5)+1);
            if rand() < baseprob
                state2 = likelyTransition(state,choice1);
            else
                state2 = unlikelyTransition;
            end
            
            transition_counts(state,choice1,state2) = transition_counts(state,choice1,state2) + 1;
            transition_probs = normalizeTransitionCounts(transition_counts);
            
            reward = 0;
            
        % Now we're in the big leagues - the real rounds
        else
            % Update MB models
            state1 = 1;
            
            % For flat MB, walk decision tree
            Q_MB(state1,curActions) = squeeze(transition_probs(state1,curActions,:)) * max(Q_MB,[],2);
            
            % MB inter-option choice
            Q_optionsMB(state1,:) = max(Q_optionsMB(2:3,1),[],2);
            Q_options(state1,:) = w_interMF*Q_optionsMF(state1,:) + (1-w_interMF)*Q_optionsMB(state1,:);
            
            % MB intra-option choice
            Q_actions(:,state1,curActions) = w_intraMF*Q_actions(:,state1,curActions)+(1-w_intraMF)*(squeeze(transition_probs(state1,curActions,:)) * subgoalRewards)';

            % Get weighted Q
            Q_weighted = w_MF*Q_MF(state1,curActions) + w_MB*Q_MB(state1,curActions) + (1-w_MF-w_MB)*Q_options(state1,:)*Q_actions(:,curActions);

            % Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice1 = randsample(curActions,1,true,probs);
            
            % Add up likelihood
            likelihood(thisAgent) = likelihood(thisAgent) + log(probs(curActions == choice1));
            
            % Transition
            % Are we in a setup trial?
            if any(criticalTrials(:,1) == (thisRound-1))
                state2 = unlikelyTransition; % force unlikely
                reward = rewards(thisRound,TRIAL_TYPE,features(newstate),thisAgent);
                
                % Polarize reward
                d = (reward > 0)*2-1;
                boost = 2;
                reward = reward+boost*d;
                if (reward > rewardRange_hi), reward = rewardRange_hi*d;
                elseif (reward < rewardRange_lo), reward = abs(rewardRange_lo)*d;
                end
            else
                state2 = likelyTransition(state,choice1);
                reward = rewards(thisRound,TRIAL_TYPE,features(newstate),thisAgent);
            end
            
            % Update transition counts
            transition_counts(state1, choice1, state2) = transition_counts(state1, choice1, state2) + 1;
            transition_probs = normalizeTransitionCounts(transition_counts);

            % Update MF models
            
            % Flat MF
            % First action
            delta = Q_MF(state2,1) - Q_MF(state1,choice1);
            Q_MF(state1,choice1) = Q_MF(state1,choice1) + lr * delta;
            % Second action
            delta = reward - Q_MF(state2,1);
            Q_MF(state2,1) = Q_MF(state2,1) + lr * delta;
            Q_MF(state1,choice) = Q_MF(state1,choice) + elig * lr * delta;
            
            % MF inter-option choice
            % Which option did we choose?
            [~,chosenOption] = max(Q_actions(:,curAction)); % Infer that we chose the option which corresponds to the action we took
            Q_optionsMF(state1,chosenOption) = Q_optionsMF(state1,chosenOption) + lr * (reward - Q_optionsMF(state1,chosenOption));
            
            % MF intra-option choice
            Q_actions(state1,chosenAction)
            
            %% STAGE 2
            
            % Update models
           
            % For flat MB, walk decision tree
            Q_MB(state2,1:2) = squeeze(transition_probs(state2,1:2,:)) * max(Q_MB,[],2);
            
            % MB inter-option choice
            Q_options(1,:) = w_interMF*Q_options(1,:)+(1-w_interMF)*max(Q_options(2:3,:),[],2);
            
            % MB intra-option choice
            Q_actions(:,curActions) = w_intraMF*Q_actions(:,curActions)+(1-w_intraMF)*(squeeze(transition_probs(1,curActions,:)) * subgoalRewards)';

            % Get weighted Q
            Q_weighted = w_MF*Q_MF(1,curActions) + w_MB*Q_MB(1,curActions) + (1-w_MF-w_MB)*Q_options(1,:)*Q_actions(:,curActions);

            % Make choice
            probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            choice1 = randsample(curActions,1,true,probs);
            
            % Add up likelihood
            likelihood(thisAgent) = likelihood(thisAgent) + log(probs(curActions == choice1));
            
                        % Are we in a setup trial?
            if any(criticalTrials(:,1) == (thisRound-1))
                state2 = unlikelyTransition; % force unlikely
                reward = rewards(thisRound,trialType,features(???),thisAgent);
                
                % Polarize reward
                d = (reward > 0)*2-1;
                boost = 2;
                reward = reward+boost*d;
                if (reward > rewardRange_hi), reward = rewardRange_hi*d;
                elseif (reward < rewardRange_lo), reward = abs(rewardRange_lo)*d;
                end
            else
                state2 = transitions(thisRound,choice1,magic);
                newstate_feature = features(state2,trialType);
                reward = rewards(thisRound,trialType,newstate_feature,magic);
            end
            % Update transition probabilities
            
            % Get our goal (to be used later in updating the goal learner)
            thisGoal = goals(trialType,features(likely_state_options(find(curActions==choice1)),trialType));

            %% Update smart model-free
            % First, do the update from doing this first, nonrewarding
            %   transition
            delta = Q_smartModelFree(state2,1,trialType) - Q_smartModelFree(1,choice1,trialType);
            Q_smartModelFree(1,choice1,trialType) = Q_smartModelFree(1,choice1,trialType) + lr1(thisAgent) * delta;

            % Then, do the update from the second 'action', which we don't have
            %   to simulate because there was no choice
            delta = reward - Q_smartModelFree(state2,1,trialType);
            Q_smartModelFree(state2,1,trialType) = Q_smartModelFree(state2,1,trialType) + lr2(thisAgent) * delta;
            Q_smartModelFree(1,choice1,trialType) = Q_smartModelFree(1,choice1,trialType) + elig_trace(thisAgent) * lr1(thisAgent) * delta;

            %% Update dumb model-free
            delta = Q_dumbModelFree(state2,1) - Q_dumbModelFree(1,choice1);
            Q_dumbModelFree(1,choice1) = Q_dumbModelFree(1,choice1) + lr1(thisAgent) * delta;

            % Then, do the update from the second 'action', which we don't have
            %   to simulate because there was no choice
            delta = reward - Q_dumbModelFree(state2,1);
            Q_dumbModelFree(state2,1) = Q_dumbModelFree(state2,1) + lr2(thisAgent) * delta;
            Q_dumbModelFree(1,choice1) = Q_dumbModelFree(1,choice1) + elig_trace(thisAgent) * lr1(thisAgent) * delta;
            
            %% Update goal learner
            delta = reward - Q_goalLearner(1,thisGoal);
            Q_goalLearner(1,thisGoal) = Q_goalLearner(1,thisGoal) + lr1(thisAgent)*delta;
            
            %% Update model-based Q value
            % We have to convert to goal space here (hence the +1)
            Q_modelBased(newstate_feature+1,1,trialType) = Q_smartModelFree(state2,1,trialType);

            % Update earnings
            earnings(thisAgent) = earnings(thisAgent) + reward;

            % Update previous choice
            prevChoice = choice1;
            prevType = trialType;
        end
        
        %% Update 'results' array
        results(roundIndex,:) = [thisAgent trialType curActions(1) curActions(2) choice1 state2 reward thisRound];
        
        % Move round index forward
        roundIndex = roundIndex + 1;
    end
end

negLL = -1*likelihood;
end

function [transition_probs] = normalizeTransitionCounts(transition_counts)
transition_probs = transition_counts ./ repmat(sum(transition_counts,3),1,1,numStates);
end