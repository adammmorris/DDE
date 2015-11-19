%%%%% Building experiment board %%%%%
clear
path = 'board_scanner1a_fit.mat';

numAgents = 200;
numRounds = [0 400];

numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);
numRealRounds = numRounds(2);

numCrits = 0; %not hardcoding any of these now
%goalNumbers = [16 40; 32 24]; % rows are numberSet, columns are "to left state" and "to right state"
numS1States = 1;
numS2States = 3;
numTerminalStates = 3;
%numNumberSets = size(goalNumbers,1);
numStates = 7; % AM: we can't really ignore the bottom level with the new way the computations are done

% numActions_MF_low = max(min(goalNumbers,[],2))-1; % the highest the lower option # could be is 23
% numActions_MF_high = max(max(goalNumbers,[],2))-1; % the highest the higher option # could be is 39
% numActions_MF = numActions_MF_low * numActions_MF_high;

% AM: I made these all constants so we don't have to hardcode them in the
% model
S1_state = 1;
S1_actions = 1:4;
S1_options = 1:2;

S2_states = 2:4;
S2_actions = 1;
S2_options = 1:3;

S3_states = 5:7;
S3_action = 1; % We only allow one "action" in the terminal states (it never actually gets chosen, it just makes the coding easier)

numActions = 4; % should be the maximum number of actions available at any point to other systems
numActions_MF = numActions;
numOptions = 3; % should be the maximum number of options available at any point to the MFG system

%% Available actions from each S2 state
% Should be numS2States x numActions
% the numbering doesn't really matter here. Just has to be within 1:numActions.
% in other words, these will always be prefixed with different states in state-option pairs
availableS2Actions = [1; 1; 1];

% Should be numS2States x numOptions
% here, the numbering matters. If an option in one state is numbered X, and an option in another state is numbered X, then the MFG system (when MFG_S2_MB is TRUE) will treat them as the same
% in other words, these could be prefixed with the same state in a state-option pair
availableS2Options = [1; 2; 3];
                   
%% Transitions
baseprob = .7;
mainTransition = 1-((numRealRounds*(1-baseprob)-numCrits)/(numRealRounds-numCrits)); % gotta take crit trials into account

% AM: This tells the model that, if we are in state s and take action a and get
% a high-probability transition, we should go to likelyTransition(s,a).
likelyTransition = zeros(numStates,numActions);
likelyTransition(1,[1 3]) = 2;
likelyTransition(1,[2 4]) = 3;
likelyTransition(2,1) = 5;
likelyTransition(3,1) = 6;
likelyTransition(4,1) = 7;

% AM: This tells the model that, if we're in state 1 and get a low-probability
% transition, we should go to state unlikelyTransition.
unlikelyTransition = 4;

%% subgoals
% AM: Subgoals for the two Stage 1 options & three Stage 2 options available to our goal learner
subgoals = [2 3 0; 5 6 7]; % should be numStages x numOptions

%% Initial transition prob matrix
% AM: We're just setting this now, instead of having agents learn it from
% experience.
transition_probs0 = zeros(numStates,numActions,numStates);

% Stage 1
transition_probs0(1,[1 3],2) = baseprob;
transition_probs0(1,[2 4],3) = baseprob;
transition_probs0(1,[1 2 3 4],4) = 1-baseprob;

% Stage 2
for i = S2_states
    for j = S2_actions
        if likelyTransition(i,j) ~= 0, transition_probs0(i,j,likelyTransition(i,j)) = 1; end
    end
end
%transition_probs0(4,3,likelyTransition(4,3)) = 1;

%% Save
save(path);