%% Builds the "board" for model fitting purposes
path = 'C:\Personal\Psychology\Projects\DDE\git\Model\Fitting\board_daw_fit.mat';

numActions = 4;
numOptions = 2;
TRIAL_TYPE = 1;
numStates = 10; % remember to preserve the state # integrity

S2_states = 2:4;
S2_actions = 1:2;
S3_states = 5:10;
S3_action = 1;

%% subgoalRewards
% The pseudo-rewards for arriving at each state (for each option)
subgoalRewards = zeros(numStates,numOptions); 
subgoalRewards(2,1) = 1;
subgoalRewards(3,2) = 1;

%% subgoals
subgoals = [2 3];

%% Initial transition prob matrix
baseprob = .8;

likelyTransition = zeros(numStates,numActions);
likelyTransition(1,[1 3]) = 2;
likelyTransition(1,[2 4]) = 3;
likelyTransition(2:4,1) = [5 7 9];
likelyTransition(2:4,2) = [6 8 10];

transition_probs0 = zeros(numStates,numActions,numStates);
transition_probs0(1,[1 3],2) = baseprob;
transition_probs0(1,[2 4],3) = baseprob;
transition_probs0(1,[1 2 3 4],4) = 1-baseprob;
for i=2:4
    for j=1:2
        transition_probs0(i,j,likelyTransition(i,j)) = 1;
    end
end

clear baseprob;

save(path);