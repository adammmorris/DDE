%% Board parameters
S1_actions = 1:2;
S2_states = 2:4;
S2_actions = 1:3;
S2_avail = logical([1 1 0; 0 1 1; 1 1 1]); % rows are S2 states (- 1), columns are actions, values are 0/1 for not available/available
S3_states = 5:7;
numStates = 7;
numActions = 3;

% Transitions
baseprob = .7;

likelyTransition = zeros(numStates,numActions);
likelyTransition(1,[1 3]) = 2;
likelyTransition(1,[2 4]) = 3;
likelyTransition(2,[1 2]) = [5 6];
likelyTransition(3,[2 3]) = [6 7];
likelyTransition(4,[1 2 3]) = [5 6 7];

unlikelyTransition = 4;

% Transition prob matrix
transition_probs = zeros(numStates,numActions,numStates);

transition_probs(1,[1 3],2) = baseprob;
transition_probs(1,[2 4],3) = baseprob;
transition_probs(1,[1 2 3 4],4) = 1-baseprob;
for i = S2_states
    for j = S2_actions
        if likelyTransition(i,j) ~= 0
            transition_probs(i,j,likelyTransition(i,j)) = 1;
        end
    end
end

save('scanner_2b.mat');