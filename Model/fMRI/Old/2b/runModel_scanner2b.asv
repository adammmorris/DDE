%% DDE Project Update - Morgan Henry, September 2015 %%
% This is our model for our experiment
% Meant to show model-free learning on model-based goals
% Model combines both types of RL learners
% Much of this is drawn from Daw's 2-step task

% Our model:
% One model-based RL learner
% One model-free Q-learner
% One goal-learning model-free learner

%% NOTES
% 1) I am pretty much ignoring any updates done to the ACTUAL numbers picked in the top level state, other than the fact that I write those down as PEs.
% 2) I've added a model free learner for the 2nd level choice, but not a model based learner because those transitions are deterministic. 
% 3) I'm using randomly generated critical trials and just making sure they
% are spaced at least 2 trials apart
% 4) Only using one trial type.

%% Inputs
% params: numAgents x [lr1 lr2 elig beta1 beta2 w_MFG w_MB]

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

function [earnings, results, PEs] = runModel_scanner2b(params, boardName)

%% Defaults
if nargin < 2
    boardName = 'board_scanner2b.mat';
end
if nargin < 1
    %agent using all of them
    params = repmat([.2 .2 .95 .95 1 0.3 0.3],1,1);
end

%% Set board params
load(boardName);

gamma = 1;
numAgents = size(params,1);
%numAgents = 1;

%% Outputs
roundIndex = 1; % for 'results'

transition_probs = transition_probs0;

% Outputs
likelihood_firstchoice = zeros(numAgents,1);
likelihood_secondchoice = zeros(numAgents,1);
earnings = zeros(numAgents,1);
results = zeros(numAgents*numTotalRounds,8);
PEs = zeros(numTotalRounds,5,numAgents);
critPEs = zeros(numTotalRounds,5,numAgents);

%% Let's do this!
for thisAgent = 1:numAgents
    %% Initialize params
    lr1 = params(thisAgent,1);
    lr2 = params(thisAgent,2);
    elig = params(thisAgent,3);
    beta1 = params(thisAgent,4);
    beta2 = params(thisAgent,5);
    w_MFG = params(thisAgent,6);
    w_MB = params(thisAgent,7);
        
    %% Initialize models
    % flat MF.
    % First choice exploits the larger set of numActions_MF; second choice just uses the first three.
    % The first choice action should be indexed as sub2ind([numActions_MF_low numActions_MF_high], lowerNumberSelected, higherNumberSelected)
    Q_MF = zeros(numStates, numActions_MF);
    Q_MB = zeros(numStates,numActions); % flat MB
    Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
    P_H_actions = zeros(numOptions,numActions); % hierarchical intra-option action values
        
    criticalTrial = 0;
    thisCrit = 0;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % Are we still in practice rounds?
        if thisRound > numPracticeRounds
            %% STAGE 1
            state1 = S1_state;
            
            % For MF model, calculate the current options
            % Get the current number options
            curOptNum = optNums(thisRound, thisAgent); % the "base" number
            curNumberSet = numberSets(thisRound, thisAgent); % 1 if [16 40], 2 if [32 24]
            lowGoalNumber = min(goalNumbers(curNumberSet,:)); % the lower of those two goal numbers
            highGoalNumber = max(goalNumbers(curNumberSet,:)); % the higher of those two goal numbers
            numberOptions = [curOptNum, lowGoalNumber-curOptNum, highGoalNumber-curOptNum]; % the three Stage 1 numbers available
            
            % Are we in a "switched" trial (where the "left" goal number is higher)?
            switched = goalNumbers(curNumberSet,1) > goalNumbers(curNumberSet,2);
            % actionEquivalents converts from high-level actions to indices in numberOptions (top row is "left" action, bottom row is "right" action)
            if switched, actionEquivalents = [1 3; 1 2]; % if the left goal number is higher (e.g. 32), then the equivalent of high-level action 1 is [curOptNum, highGoalNumber-curOptNum]
            else actionEquivalents = [1 2; 1 3]; end % if the left goal number is lower (e.g. 16), then the equivalent of high-level action 1 is [curOptNum, lowGoalNumber-curOptNum]
            
            curMFValues = [Q_MF(state1, sub2ind([numActions_MF_low numActions_MF_high], min(numberOptions(actionEquivalents(1,:))), max(numberOptions(actionEquivalents(1,:))))) 
                Q_MF(state1, sub2ind([numActions_MF_low numActions_MF_high], min(numberOptions(actionEquivalents(2,:))), max(numberOptions(actionEquivalents(2,:)))))]; % ordered [MFValue_left MFValue_right]
            
            % Update MB model
            % AM: This is our implementation of the formula in the latest
            % manuscript.
            for i = S1_actions
                Q_MB(state1,i) = 0;
                for j = S2_states
                    S2_availableactions = terminalactions(j-1,:);
                    if ~all(S2_availableactions)
                         S2_availableactions = S2_availableactions(1:2);
                     end
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
            Q_weighted = w_MFG*Q_MFG_options(state1,S1_options)*P_H_actions(S1_options,S1_actions) + w_MB*Q_MB(state1,S1_actions) + (1-w_MFG-w_MB)*curMFValues';
            
            % Make choice
            firstprobs = exp(beta1*Q_weighted) / sum(exp(beta1*Q_weighted));
            firstchoice = randsample(S1_actions,1,true,firstprobs);
            chosenNumbers = numberOptions(actionEquivalents(firstchoice,:));
            firstchoice_MF = sub2ind([numActions_MF_low numActions_MF_high], min(chosenNumbers), max(chosenNumbers));
            
            % Infer option chosen
            if ~all(subgoals(1,:))
                [~,chosenOption1] = max(squeeze(transition_probs(state1,firstchoice,subgoals(1,1:2))));
            else
                [~,chosenOption1] = max(squeeze(transition_probs(state1,firstchoice,subgoals(1,:))));
            end
            
            
            % Transition
            if rand() > mainTransition
                state2 = unlikelyTransition;
            else
                state2 = likelyTransition(state1,firstchoice);
            end
            
            % AM: So this is to prevent people from getting too many
            % unlikely transitions in a row?
            % TODO: check with Morgan on this
%             if thisRound>2 && state2 == 4 && (results(thisRound-1,3)==4 || results(thisRound-2,3)==4)
%                 if rand<0.5
%                     state2 = 2;
%                 else
%                     state2 = 3;
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
            Q_weighted = w_MFG*Q_MFG_options(state2,S2_availableactions) + w_MB*Q_MB(state2,S2_availableactions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_availableactions);
            
            % Make choice
            secondprobs = exp(beta2*Q_weighted) / sum(exp(beta2*Q_weighted));
            secondchoice = randsample(S2_availableactions,1,true,secondprobs);
            state3 = likelyTransition(state2,secondchoice); % AM: I changed this so that termstate encodes the number of the third state. I think it'll simplify the models.
                        
%             if state2 == 4
%                 criticalTrial = 1;
%                 thisCrit = thisCrit +1;
%                 if rand <0.25
%                     reward= round((Q_MF(state2,secondchoice)+Q_MFG_options(state1,chosenOption1))/2); 
%                 elseif rand<0.5
%                     reward= round((Q_MB(state3,S3_action)+Q_MFG_options(state1,chosenOption1))/2); 
%                 else
%                     if rand<0.3
%                         reward = round(Q_MF(state2,secondchoice));
%                     elseif rand <0.6
%                         reward =round(Q_MFG_options(state1,chosenOption1));
%                         
%                     elseif rand<0.9
%                         reward = round(Q_MB(state3,S3_action));
%                     else
%                         reward = 0;
%                     end
%                 end
%             else
%                 criticalTrial = 0;
%             end
%             
%             
%             if state2 ~=4
%                 reward = rewards(thisRound,state3,thisAgent);
%             end

            % Not doing anything special w/ rewards right now
            if state2 == unlikelyTransition
                criticalTrial = 1;
                thisCrit = thisCrit+1;
            end

            reward = rewards(thisRound, state3, thisAgent);
            
            % Add up likelihood
            likelihood_firstchoice(thisAgent) = likelihood_firstchoice(thisAgent) + log(firstprobs(find(S1_actions == firstchoice)));
            likelihood_secondchoice(thisAgent) = likelihood_secondchoice(thisAgent) + log(secondprobs(find(S2_availableactions == secondchoice)));
            
            %% Record prediction errors before we update shit
            if criticalTrial ==1
                critPEs(thisCrit,1,thisAgent) = Q_MF(state2,secondchoice) - Q_MF(state1,firstchoice_MF); %val of reward minus val of top level numbers (which is zero)
                critPEs(thisCrit,2,thisAgent) = reward - Q_MF(state2,secondchoice) ; %update 2nd level, happens at reward 
                critPEs(thisCrit,3,thisAgent) = reward - Q_MB(state3,S3_action); %update terminal state, happens at reward
                critPEs(thisCrit,4,thisAgent) = gamma*max(Q_MFG_options(state2,S2_availableactions)) - Q_MFG_options(state1,chosenOption1); %MFMB update at stage 2
                critPEs(thisCrit,5,thisAgent) = reward - Q_MFG_options(state1,chosenOption1);
            end
                
            PEs(thisRound,1,thisAgent) = gamma*max(Q_MFG(state2,S2_availableactions)) - Q_MFG(state1,firstchoice_MF);
            PEs(thisRound,2,thisAgent) = gamma*max(Q_MF(state2,S2_availableactions)) - Q_MF(state1,firstchoice_MF);
            PEs(thisRound,3,thisAgent) = reward - Q_MB(state3,S3_action); %update terminal state, happens at reward
            
            %% Update models
            % AM: We switched to Q-learning instead of SARSA
            
            % Update flat MF (and bottom-level MB estimate)
            
            % top level update
            delta = gamma*max(Q_MF(state2,S2_availableactions)) - Q_MF(state1,firstchoice_MF);
            Q_MF(state1,firstchoice_MF) = Q_MF(state1,firstchoice_MF) + lr1*delta;
            
            % Do the update from the reward to the stage 2 state (we could include Q_MF(state3), but there's no point; it'll always be zero)
            delta = reward - Q_MF(state2,secondchoice);
            Q_MF(state2,secondchoice) = Q_MF(state2,secondchoice) + lr2*delta;
            Q_MF(state1,firstchoice_MF) = Q_MF(state1,firstchoice_MF) + lr1*elig*delta;
            
            Q_MB(state3,S3_action) = Q_MB(state3,S3_action)+lr1*(reward-Q_MB(state3,S3_action));
            
            % Update MFonMB
            % top level update
            delta = gamma*max(Q_MFG_options(state2,S2_availableactions)) - Q_MFG_options(state1,chosenOption1);
            Q_MFG_options(state1,chosenOption1) = Q_MFG_options(state1,chosenOption1) + lr1*delta;
            
            delta = reward - Q_MFG_options(state2,secondchoice);
            Q_MFG_options(state2,secondchoice) = Q_MFG_options(state2,secondchoice) + lr2*delta;
            Q_MFG_options(state1,chosenOption1) = Q_MFG_options(state1,chosenOption1) + lr1*elig*delta;
            
            % Update earnings
            earnings(thisAgent) = earnings(thisAgent) + reward;
        end
        
        %% Update 'results' array
        % AM: We have to be careful to note how secondchoice is coded. If the person chooses the left action in state 3, secondchoice = 2; if the person chooses
        % the right action in state 3, secondchoice = 3.
        results(roundIndex,:) = [thisAgent firstchoice state2 secondchoice reward thisRound criticalTrial earnings(thisAgent)];

        % Move round index forward
        roundIndex = roundIndex + 1;
        
    end
end

negLLfirst = -1*likelihood_firstchoice;
negLLsecond = -1*likelihood_secondchoice;
critPEs = critPEs(1:thisCrit,:,:);

save('model_scanner2b.mat')
