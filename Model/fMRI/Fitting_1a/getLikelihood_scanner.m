%% Inputs
% params: [lr elig beta persev w_MFG w_MB]
% boardName: name of the board to load
% MFG_S2_MB: set this to 1 if you want the MFG controller to be model-based in the stage 2 choice

function [negLL, PEs] = getLikelihood_scanner(params, boardName, MFG_S2_MB, opt1_all, opt2_all, actions_all, s2_all, re_all)
%% Set board params
load(boardName);

gamma = 1;
transition_probs = transition_probs0;

%% Outputs
likelihood = 0;
PEs = zeros(numTotalRounds,3,2); % 2nd dimension is which PE (MFG, MF, MB); 3rd dimension is which time point (1 = choice, 2 = reward)

%% Initialize params
lr = params(1);
elig = params(2);
beta = params(3);
persev = params(4);
w_MFG = params(5);
w_MB = params(6);

%% Initialize models
Q_MF = zeros(numStates, numActions_MF);
Q_MB = zeros(numStates,numActions); % flat MB
Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
P_H_actions = zeros(numStates,numOptions,numActions); % hierarchical intra-option action values

%% Go through rounds
for thisRound = 1:length(re_all)
    if actions_all(thisRound) ~= 0
        %% STAGE 1
        state1 = S1_state;
        S1_availableactions = [opt1_all(thisRound) opt2_all(thisRound)];
        
        % Update MB model
        % AM: This is our implementation of the formula in the latest
        % manuscript.
        for i = S1_availableactions
            Q_MB(state1,i) = 0;
            for j = S2_states
                S2_availableactions = nonzeros(availableS2Actions(j-numS1States,:));
                
                % We need the "reshape" in there (instead of squeeze) in case length(S2_availableactions) == 1
                Q_MB(state1,i) = Q_MB(state1,i) + transition_probs(state1,i,j)*max(reshape(transition_probs(j,S2_availableactions,S3_states), length(S2_availableactions), length(S3_states))*Q_MB(S3_states,S3_action));
            end
        end
        
        % Update intra-option action policies for MFG controller
        % For every available option..
        for i = S1_options
            % Find the action which is most likely to lead to its subgoal
            [~,b] = max(squeeze(transition_probs(state1,S1_actions,subgoals(state1,i))));
            % Assign that action 1, and everything else 0
            P_H_actions(state1,i,S1_actions) = S1_actions==S1_actions(b);
        end
        
        % Get weighted Q
        Q_weighted = w_MFG*Q_MFG_options(state1,S1_options)*reshape(P_H_actions(state1,S1_options,S1_availableactions), length(S1_options), length(S1_availableactions)) + w_MB*Q_MB(state1,S1_availableactions) + (1-w_MFG-w_MB)*Q_MF(state1,S1_availableactions);
        
        % Make choice
        if thisRound > 1, rep = S1_availableactions == actions_all(thisRound-1);
        else rep = zeros(1,length(S1_availableactions));
        end
        firstprobs = exp(beta*Q_weighted+persev*rep) / sum(exp(beta*Q_weighted));
        firstchoice = actions_all(thisRound);
        firstchoice_MF = firstchoice; % this is only to maintain some kind of compatibility with the "sum" version of the script
        
        % Infer option chosen
        [~, chosenOption1] = max(squeeze(transition_probs(state1, firstchoice, subgoals(state1, S1_options))));
        
        % Transition
        state2 = s2_all(thisRound);
        
        % Update PEs
        PEs(thisRound,1,1) = gamma*max(Q_MFG_options(state2,S2_availableactions)) - Q_MFG_options(state1,chosenOption1);
        PEs(thisRound,2,1) = gamma*max(Q_MF(state2,S2_availableactions)) - Q_MF(state1,firstchoice_MF);
        PEs(thisRound,3,1) = gamma*max(Q_MB(state2,S2_availableactions)) - Q_MB(state1,firstchoice);
        
        %% STAGE 2
        
        % Get available actions & options
        S2_availableactions = nonzeros(availableS2Actions(state2-numS1States,:));
        S2_availableoptions = nonzeros(availableS2Options(state2-numS1States,:));
        
        % Update models
        Q_MB(state2,S2_availableactions) = reshape(transition_probs(state2,S2_availableactions,S3_states), length(S2_availableactions), length(S3_states))*Q_MB(S3_states,S3_action);
        
        % Should the MFG controller be model-based in the second stage?
        % NOTE: this will only make a difference if availableS2Options contains
        if MFG_S2_MB, state2_MFGopt = 2; % options are not state dependent
        else state2_MFGopt = state2;
        end
        
        for i = S2_availableoptions'
            % Find the action which is most likely to lead to its subgoal
            [~,b] = max(squeeze(transition_probs(state2,S2_availableactions,subgoals(2,i))));
            % Assign that action 1, and everything else 0
            P_H_actions(state2_MFGopt,i,S2_availableactions) = S2_availableactions==S2_availableactions(b);
        end
        
        % Get weighted Q
        %Q_weighted = w_MFG*Q_MFG_options(state2_MFGopt,S2_availableoptions)*reshape(P_H_actions(state2_MFGopt,S2_availableoptions,S2_availableactions), length(S2_availableoptions), length(S2_availableactions)) + w_MB*Q_MB(state2,S2_availableactions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_availableactions);
        
        % Make choice
        %secondprobs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
        secondchoice = 1;
        state3 = likelyTransition(state2,secondchoice); % AM: I changed this so that termstate encodes the number of the third state. I think it'll simplify the models.
        
        [~, chosenOption2] = max(squeeze(transition_probs(state2, secondchoice, subgoals(2, S2_availableoptions))));
        chosenOption2 = S2_availableoptions(chosenOption2);
        
        reward = re_all(thisRound);
        
        % Add up likelihood
        likelihood = likelihood + log(firstprobs(S1_availableactions == firstchoice));
        %likelihood(thisAgent) = likelihood(thisAgent) + log(secondprobs(find(S2_availableactions == secondchoice)));
        
        % Record PEs
        PEs(thisRound,1,2) = reward - Q_MFG_options(state2,secondchoice);
        PEs(thisRound,2,2) = reward - Q_MF(state2,secondchoice);
        PEs(thisRound,3,2) = reward - Q_MB(state2,secondchoice);
        
        %% Update models
        % Update flat MF (and bottom-level MB estimate)
        
        % top level update
        delta = gamma*max(Q_MF(state2,S2_availableactions)) - Q_MF(state1,firstchoice_MF);
        Q_MF(state1,firstchoice_MF) = Q_MF(state1,firstchoice_MF) + lr*delta;
        
        % Do the update from the reward to the stage 2 state (we could include Q_MF(state3), but there's no point; it'll always be zero)
        delta = reward - Q_MF(state2,secondchoice);
        Q_MF(state2,secondchoice) = Q_MF(state2,secondchoice) + lr*delta;
        Q_MF(state1,firstchoice_MF) = Q_MF(state1,firstchoice_MF) + lr*elig*delta;
        
        Q_MB(state3,S3_action) = Q_MB(state3,S3_action)+lr*(reward-Q_MB(state3,S3_action));
        
        % Update MFonMB
        % top level update
        delta = gamma*max(Q_MFG_options(state2,S2_availableoptions)) - Q_MFG_options(state1,chosenOption1);
        Q_MFG_options(state1,chosenOption1) = Q_MFG_options(state1,chosenOption1) + lr*delta;
        
        delta = reward - Q_MFG_options(state2_MFGopt,chosenOption2);
        Q_MFG_options(state2_MFGopt,chosenOption2) = Q_MFG_options(state2_MFGopt,chosenOption2) + lr*delta;
        Q_MFG_options(state1,chosenOption1) = Q_MFG_options(state1,chosenOption1) + lr*elig*delta;
    end
end

negLL = -1*likelihood;