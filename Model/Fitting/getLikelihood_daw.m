%% Inputs
% params: numAgents x [lr elig beta stay w_MF w_MB]

function [negLL] = getLikelihood_daw(params, boardPath, practiceCutoff, realOpt1, realOpt2, realAction, realS2, realAction2, realRe, realRound)

%% Set board params
load(boardPath);

gamma = 1;
numTotalRounds = size(realOpt1,1);

transition_probs = transition_probs0;
likelihood = 0;

%% Let's do this!
%% Initialize params
lr = params(1);
elig = params(2);
beta = params(3);
stay = params(4);
w_MFG = params(5);
w_MB = params(6);

%% Initialize models
Q_MF = zeros(numStates,numActions); % flat MF
Q_MB = zeros(numStates,numActions);
Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
P_H_actions = zeros(numOptions,numActions); % hierarchical intra-option action values

%% Go through rounds
lastAction = 0;

for thisRound = 1:numTotalRounds
    curActions = [realOpt1(thisRound) realOpt2(thisRound)];
    
    
    if realRound(thisRound) > practiceCutoff
        %% STAGE 1
        state1 = 1;
        
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
        probs = exp(beta*Q_weighted + stay*(curActions == lastAction)) / sum(exp(beta*Q_weighted));
        choice1 = realAction(thisRound);
        likelihood = likelihood + log(probs(curActions == choice1));
        
        % Transition
        state2 = realS2(thisRound);
        
        %% STAGE 2
        
        Q_MB(state2,S2_actions) = squeeze(transition_probs(state2,S2_actions,S3_states))*Q_MB(S3_states,S3_action);
            
        % Get weighted Q
        Q_weighted = w_MFG*Q_MFG_options(state2,S2_actions) + w_MB*Q_MB(state2,S2_actions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_actions);
        
        % Make choice
        probs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
        choice2 = realAction2(thisRound);
        likelihood = likelihood + log(probs(S2_actions == choice2));
        
        % Transition
        state3 = likelyTransition(state2,choice2);
        
        % Get reward
        reward = realRe(thisRound);
        
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
        
        delta = gamma*max(Q_MFG_options(state2,S2_actions)) - Q_MFG_options(state1,chosenOption);
        Q_MFG_options(state1,chosenOption) = Q_MFG_options(state1,chosenOption) + lr*delta;
        
        delta = reward-Q_MFG_options(state2,choice2);
        Q_MFG_options(state2,choice2) = Q_MFG_options(state2,choice2) + lr*delta;
        Q_MFG_options(state1,chosenOption) = Q_MFG_options(state1,chosenOption) + lr*elig*delta;
        
        lastAction = choice1;
    end
end

negLL = -likelihood;
end