%% DDE Project Update - Morgan Henry, September 2015 %%
% This is our model for our experiment
% Meant to show model-free learning on model-based goals
% Model combines both types of RL learners
% Much of this is drawn from Daw's 2-step task

% Our model:
% One model-based RL learner
% One model-free Q-learner
% One goal-learning model-free learner

%% Inputs
% params: numAgents x [lr elig beta w_MFG w_MB]
% boardName: name of the board to load
% MFG_S2_MB: set this to 1 if you want the MFG controller to be model-based in the stage 2 choice

%% Outputs
% earnings has the earnings for every agent
% results is a (numAgents*numRounds) x 8 matrix;
%   columns are id, trialType, option1, option2, choice, state2, reward,
%   and round#
% PEs is a numCritTrials x 3 x numAgents matrix

function [earnings, results, negLLs, PEs] = runModel_scanner_sum(params, boardName, MFG_S2_MB)

%% Defaults
if nargin < 3
    MFG_S2_MB = 1;
end
if nargin < 2
    boardName = 'board_scanner1b_sum.mat';
end
if nargin < 1
    %agent using all of them
    params = repmat([.2 .95 1 0.3 0.3],1,1);
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
likelihood = zeros(numAgents,1);
earnings = zeros(numAgents,1);
results = zeros(numAgents*numTotalRounds,8);
PEs = zeros(numTotalRounds,3,numAgents);
%critPEs = zeros(numTotalRounds,3,numAgents);

%% Let's do this!
for thisAgent = 1:numAgents
    %% Initialize params
    lr = params(thisAgent,1);
    elig = params(thisAgent,2);
    beta = params(thisAgent,3);
    w_MFG = params(thisAgent,4);
    w_MB = params(thisAgent,5);
        
    %% Initialize models
    % flat MF.
    % First choice exploits the larger set of numActions_MF; second choice just uses the first three.
    % The first choice action should be indexed as sub2ind([numActions_MF_low numActions_MF_high], lowerNumberSelected, higherNumberSelected)
    Q_MF = zeros(numStates, numActions_MF);
    Q_MB = zeros(numStates,numActions); % flat MB
    Q_MFG_options = zeros(numStates,numOptions); % hierarchical MF option values
    P_H_actions = zeros(numStates,numOptions,numActions); % hierarchical intra-option action values
        
    %thisCrit = 0;
    %lastS2 = 0;
    
    %% Go through rounds
    for thisRound = 1:numTotalRounds
        % Are we still in practice rounds?
        if thisRound > numPracticeRounds
            % Dealing w/ critical trials
            % If this is Experiment 1a or 1b..
            %   When it's NOT a numberSum version, critical trials are important, and you need to set the proper 
            %   But when it IS a numberSum version, the only thing that we would do on "critical trials" is make a novel sum. So I'm just gonna choose some
            %   trials randomly to be critical trials (following low-prob transitions), and make sure the PE is as if it were a novel number combination. Kinda
            %   cheap, but does the job.
             criticalTrial = 0;
%             if lastS2 == unlikelyTransition
%                 if rand() < .7
%                     criticalTrial = 1;
%                     thisCrit = thisCrit + 1;
%                 end
%             end
            
            %% STAGE 1
            state1 = S1_state;
            
            % For MF model, calculate the current available numbers
            % Get the current numbers
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
            
            % Query the MF values
            curMFValues = [Q_MF(state1, sub2ind([numActions_MF_low numActions_MF_high], min(numberOptions(actionEquivalents(1,:))), max(numberOptions(actionEquivalents(1,:))))) 
                Q_MF(state1, sub2ind([numActions_MF_low numActions_MF_high], min(numberOptions(actionEquivalents(2,:))), max(numberOptions(actionEquivalents(2,:)))))]; % ordered [MFValue_left MFValue_right]
            
            % Update MB model
            % AM: This is our implementation of the formula in the latest
            % manuscript.
            for i = S1_actions
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
            Q_weighted = w_MFG*Q_MFG_options(state1,S1_options)*reshape(P_H_actions(state1,S1_options,S1_actions), length(S1_options), length(S1_actions)) + w_MB*Q_MB(state1,S1_actions) + (1-w_MFG-w_MB)*curMFValues';
            
            % Make choice
            firstprobs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            firstchoice = randsample(S1_actions,1,true,firstprobs);
            chosenNumbers = numberOptions(actionEquivalents(firstchoice,:));
            firstchoice_MF = sub2ind([numActions_MF_low numActions_MF_high], min(chosenNumbers), max(chosenNumbers));
            
            % Infer option chosen
            [~, chosenOption1] = max(squeeze(transition_probs(state1, firstchoice, subgoals(state1, S1_options))));
            
            % Transition
            if rand() > mainTransition
                state2 = unlikelyTransition;
            else
                state2 = likelyTransition(state1,firstchoice);
            end
            
            PEs(thisRound,1,thisAgent) = gamma*max(Q_MFG_options(state2,S2_availableactions)) - Q_MFG_options(state1,chosenOption1);
            PEs(thisRound,2,thisAgent) = gamma*max(Q_MF(state2,S2_availableactions)) - Q_MF(state1,firstchoice_MF);
            PEs(thisRound,3,thisAgent) = gamma*max(Q_MB(state2,S2_availableactions)) - Q_MB(state1,firstchoice);
            
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
            % AM: We were now using all three models to determine the second choice. Not sure if you still wanted to do that.
            Q_weighted = w_MFG*Q_MFG_options(state2_MFGopt,S2_availableoptions)*reshape(P_H_actions(state2_MFGopt,S2_availableoptions,S2_availableactions), length(S2_availableoptions), length(S2_availableactions)) + w_MB*Q_MB(state2,S2_availableactions) + (1-w_MFG-w_MB)*Q_MF(state2,S2_availableactions);
            
            % Make choice
            secondprobs = exp(beta*Q_weighted) / sum(exp(beta*Q_weighted));
            secondchoice = randsample(S2_availableactions,1,true,secondprobs);
            state3 = likelyTransition(state2,secondchoice); % AM: I changed this so that termstate encodes the number of the third state. I think it'll simplify the models.
            
            [~, chosenOption2] = max(squeeze(transition_probs(state2, secondchoice, subgoals(2, S2_availableoptions))));
            chosenOption2 = S2_availableoptions(chosenOption2);

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
            reward = rewards(thisRound, state3, thisAgent);
            
            % Add up likelihood
            likelihood(thisAgent) = likelihood(thisAgent) + log(firstprobs(find(S1_actions == firstchoice)));
            likelihood(thisAgent) = likelihood(thisAgent) + log(secondprobs(find(S2_availableactions == secondchoice)));
            
            %% Record prediction errors before we update shit
%             if criticalTrial ==1
%                 critPEs(thisRound,1,thisAgent) = gamma*max(Q_MFG_options(state2,S2_availableactions)) - Q_MFG_options(state1,chosenOption1);
%                 critPEs(thisRound,2,thisAgent) = gamma*max(Q_MF(state2,S2_availableactions)) - 0;
%                 critPEs(thisRound,3,thisAgent) = gamma*max(Q_MB(state2,S2_availableactions)) - Q_MB(state1,firstchoice);
%             end
            
            %% Update models
            % AM: We switched to Q-learning instead of SARSA
            
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
            
            % Update earnings
            earnings(thisAgent) = earnings(thisAgent) + reward;
        end
        
        %% Update 'results' array
        results(roundIndex,:) = [thisAgent firstchoice state2 secondchoice reward thisRound criticalTrial earnings(thisAgent)];

        % Move round index forward
        roundIndex = roundIndex + 1;
        
%        lastS2 = state2;
    end
end

negLLs = -1*likelihood;
%critPEs = critPEs(1:thisCrit,:,:);

%save('model_scanner2b.mat')
