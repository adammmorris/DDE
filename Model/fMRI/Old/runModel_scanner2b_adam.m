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

%% Outputs
% earnings has the earnings for every agent
% results is a (numAgents*numRounds) x 8 matrix;
%   columns are id, trialType, option1, option2, choice, state2, reward,
%   and round#
% PEs is a numCritTrials x 6 x numAgents matrix, where the columns contain
%   the following prediction errors:
% (1) V(green) - V(top action)
% (2) reward - V(green)
% (3) reward - V(top action)
% (4) reward - V(top goal)

function [earnings, results, PEs] = runModel_scanner2b_adam(params, boardName)

%% Defaults
if nargin < 2
    boardName = 'board_scanner2b.mat';
end
if nargin < 1
    params = repmat([.2 .95 1 0 1],5,1);
end

%% Set board params
load(boardName);

gamma = 1;
numAgents = size(params,1);

%% Outputs
roundIndex = 1; % for 'results'

transition_probs = transition_probs0;

% Outputs
likelihood_firstchoice = zeros(numAgents,1);
likelihood_secondchoice = zeros(numAgents,1);
earnings = zeros(numAgents,1);
results = zeros(numAgents*numTotalRounds,10);
PEs = zeros(numCrits,5,numAgents);

%% Let's do this!
for thisAgent = 1:numAgents
    %% Initialize params
    lr = params(thisAgent,1);
    elig = params(thisAgent,2);
    beta = params(thisAgent,3);
    w_MFG = params(thisAgent,4);
    w_MB = params(thisAgent,5);
        
    %% Initialize models
    % AM: This changed a lot
    Q_MF = zeros(numStates,numActions); % flat MF; AM: we stopped calling it dumb (b/c there's no smart one to contrast it with anymore)
    Q_MB = zeros(numStates,numActions); % flat MB
    Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
    P_H_actions = zeros(numOptions,numActions); % hierarchical intra-option action values
    
    prevChoice = 1;
    
    criticalTrial = 0;
    criticalChoice = 0;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % What trial type is this?
        trialType = TRIAL_TYPE;
        
        % Are we still in practice rounds?
        if thisRound > numPracticeRounds
            %% STAGE 1
            state1 = S1_state;
            
            % Update MB model
            % AM: This is our implementation of the formula in the latest
            % manuscript.
            for i = S1_actions
                Q_MB(state1,i) = 0;
                for j = S2_states
                    Q_MB(state1,i) = Q_MB(state1,i) + transition_probs(state1,i,j)*max(squeeze(transition_probs(j,S2_availableactions,S3_states))*Q_MB(S3_states,S3_action));
                end
            end
            
            % Update intra-option action policies for MFG controller
            % For every available option..
            for i = S1_options
                % Find the action which is most likely to lead to its subgoal
                [~,b] = max(squeeze(transition_probs(state1,S1_actions,subgoals(state1,i))));
                % Assign that action 1, and everything else 0
                P_H_actions(i,S1_actions) = S1_actions==S1_actions(b);
            end
            
            % Get weighted Q
            Q_weighted = w_MFG*Q_MFG_options(state1,S1_options)*P_H_actions(S1_options,S1_actions) + w_MB*Q_MB(state1,S1_actions) + (1-w_MFG-w_MB)*Q_MF(state1,S1_actions);
            
            % Make choice
            firstprobs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            firstchoice = randsample(S1_actions,1,true,firstprobs);
            
            % Infer option chosen
            [~,chosenOption1] = max(squeeze(transition_probs(state1,firstchoice,subgoals(1,:))));
            
            % Transition
            if rand() > mainTransition
                state2 = unlikelyTransition;
            else
                state2 = likelyTransition(state1,firstchoice);
            end
            
            % AM: So this is to prevent people from getting too many
            % unlikely transitions in a row?
            if state2 == 4 && (results(roundIndex-1,3)==4 || results(roundIndex-2,3)==4)
                if rand<0.5
                    state2 = 2;
                else
                    state2 = 3;
                end
            end
            
            % AM: Ah, so this corresponds to what you said before about
            % making every unlikely transition a critical trial
            % TODO: FIX THIS
            if state2 == 4
                criticalTrial = 1;
                if rand <0.5
                    reward= round((Q_MF(state2,secondchoice)+Q_MFG_options(state1,chosenOption1))/2); % AM: Whether we use the first or second option choice here depends on what we decide about PEs
                else
                    if rand<0.15
                        reward = round(Q_MF(state2,secondchoice));
                    elseif rand <0.3
                        reward = round(Q_MFG_options(state1,chosenOption1));
                    else
                        reward = 0;
                    end
                end
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
            
            %% STAGE 2
            
            % AM: Cool, so we're setting up the available actions from our state2
            % So this is either gonna be 1:2 (in state 2), 2:3 (in state 3), or 1:3 (in state 4)
            S2_availableactions = terminalactions(state2-1,:);
            if ~all(S2_availableactions)
                S2_availableactions = S2_availableactions(1:2);
            end
            
            % Update models
            Q_MB(state2,S2_availableactions) = squeeze(transition_probs(state2,S2_availableactions,S3_states))*Q_MB(S3_states,S3_action);
            
            % AM: I'm being a bit lazy & not going through the full rigamarole of the MFG controller for the second choice, because here actions and options are
            % isomorphic.
            
            % Get weighted Q
            % AM: We were now using all three models to determine the second choice. Not sure if you still wanted to do that.
            %Q_weighted_terminal = 1*Q_dumbModelFree_terminal(rewardstate_actions,1)';
            Q_weighted = w_MFG*Q_MFG_options(state2,S2_availableactions) + w_MB*Q_MB(state2,S2_availableactions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_availableactions);
            
            % Make choice
            secondprobs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            secondchoice = randsample(S2_availableactions,1,true,secondprobs);
            state3 = likelyTransition(state2,secondchoice); % AM: I changed this so that termstate encodes the number of the third state. I think it'll simplify the models.
                        
            if state2 ~=4
                reward = rewards(thisRound,state3,thisAgent);
            end
            
            % Add up likelihood
            likelihood_firstchoice(thisAgent) = likelihood_firstchoice(thisAgent) + log(firstprobs(find(S1_actions == firstchoice)));
            likelihood_secondchoice(thisAgent) = likelihood_secondchoice(thisAgent) + log(secondprobs(find(S2_availableactions == secondchoice)));
            
            %% Record prediction errors before we update shit
            % TODO: FIX THIS
            
           % PEs(thisRound,1,thisAgent) = Q_dumbModelFree(newstate,1); %val of stage minus val of top level numbers (zero)
           % PEs(thisRound,2,thisAgent) = Q_dumbModelFree_terminal(termstate,1) - Q_dumbModelFree(newstate,1);
           % PEs(thisRound,3,thisAgent) = Q_dumbModelFree_terminal(termstate,1); %val of terminal state minus val of numbers
            PEs(thisRound,1,thisAgent) = reward; %val of reward minus val of top level numbers (zero)
            PEs(thisRound,2,thisAgent) = reward - Q_MF(state2,) ; %update stage 2 state
            PEs(thisRound,3,thisAgent) = reward - Q_dumbModelFree_terminal(state3,1); %update terminal state
            % maybe this #3 is not needed?
            PEs(thisRound,4,thisAgent) = reward - Q_goalLearner(1,thisGoal); %MFMB
            
            %% Update models
            % AM: We switched to Q-learning instead of SARSA
            
            % Update flat MF (and bottom-level MB estimate)
            
            % no top level update, because the choices are unique enough
            % AM: We should probably check with Fiery if that's okay to assume (not sure if you asked him already). Here's the code, in case we decide to put it
            % in. (We'd also have to change the indexing of S1 actions.)
            %delta = gamma*max(Q_MF(state2,S2_availableactions)) - Q_MF(state1,firstchoice);
            %Q_MF(state1,firstchoice) = Q_MF(state1,firstchoice) + lr*delta;
            
            % Do the update from the terminal state to the stage 2 state
            % TODO: DECIDE THIS. Do we want PE directly from reward to stage 2 state?
            delta = gamma*max(Q_MF(state3,S3_action)) - Q_MF(state2,secondchoice);
            Q_MF(state2,secondchoice) = Q_MF(state2,secondchoice) + lr*delta;
            %Q_MF(state1,firstchoice) = Q_MF(state1,firstchoice) + lr*elig*delta;
            
            % Do the update from the reward to the terminal state, and update others via eligibility
            delta = reward - Q_MF(state3,S3_action);
            Q_MF(state3,S3_action) = Q_MF(state3,S3_action) + lr*delta;
            Q_MF(state2,secondchoice) = Q_MF(state2,secondchoice) + lr*elig*delta;
            %Q_MF(state1,firstchoice) = Q_MF(state1,firstchoice) + lr*(elig^2)*delta;
            
            Q_MB(state3,S3_action) = Q_MF(state3,S3_action);
            
            % Update MFonMB
            delta = gamma*max(Q_MFG_options(state2,S2_availableactions)) - Q_MFG_options(state1,chosenOption1);
            Q_MFG_options(state1,chosenOption1) = Q_MFG_options(state1,chosenOption1) + lr*delta;
            
            % TODO: DECIDE THIS ALSO. Do we want PE directly from reward to first chosen option?
            delta = reward-Q_MFG_options(state2,secondchoice);
            Q_MFG_options(state2,secondchoice) = Q_MFG_options(state2,secondchoice) + lr*delta; % We don't need to infer the chosen option, b/c options & actions are isomorphic in the stage 2 choice
            Q_MFG_options(state1,chosenOption1) = Q_MFG_options(state1,chosenOption1) + lr*elig*delta;
            
            % Update earnings
            earnings(thisAgent) = earnings(thisAgent) + reward;
        end
        
        %% Update 'results' array
        % AM: We have to be careful to note how secondchoice is coded. If the person chooses the left action in stage 3, secondchoice = 2; if the person chooses
        % the right action in stage 3, secondchoice = 3.
        results(roundIndex,:) = [thisAgent firstchoice state2 secondchoice reward thisRound criticalTrial];

        % Move round index forward
        roundIndex = roundIndex + 1;
    end
end

negLLfirst = -1*likelihood_firstchoice;
negLLsecond = -1*likelihood_secondchoice;


save('model_scanner2b.mat')
