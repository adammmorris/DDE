%%%%% Building experiment board %%%%%
path = 'board_scanner1a.mat';

numAgents = 200;
numRounds = [0 400];

numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);
numRealRounds = numRounds(2);

numCrits = 0; %not hardcoding any of these now
numOptions = 3; % AM: This has to be 3 to allow for three options in S2
goalNumbers = [16 40; 32 24]; % rows are numberSet, columns are "to left state" and "to right state"
numFeatureValues = 3; %colors stage 2
numTerminalStates = 3;
numNumberSets = size(goalNumbers,1);
numStates = 7; % AM: we can't really ignore the bottom level with the new way the computations are done

% numActions is tricky
% we're doing separate things for the MF system and the other system
% the MF system has to keep track of every high-level action
% the MB system (and the intra-option policy of the MFG system) have the knowledge to abstract away from this
numActions_MF_low = max(min(goalNumbers,[],2))-1; % the highest the lower option # could be is 23
numActions_MF_high = max(max(goalNumbers,[],2))-1; % the highest the higher option # could be is 39
numActions_MF = numActions_MF_low * numActions_MF_high;
numActions = 3; % maximum number of possible actions for other systems

% AM: I made these all constants so we don't have to hardcode them in the
% model
S1_state = 1;
S1_actions = 1:2;
S1_options = 1:2;

S2_states = 2:4;
S2_actions = 1:3;
S2_options = 1:3;

S3_states = 5:7;
S3_action = 1; % We only allow one "action" in the terminal states (it never actually gets chosen, it just makes the coding easier)

%% Number sets
% Just alternate
numberSets = zeros(numTotalRounds,numAgents);
numberSets(1:2:end,:) = 1; % all odd trials are the first number set
numberSets(2:2:end,:) = 2; % all even trials are the second number set

%% Top Level Options
% numTotalRounds x numAgents
% Just compute the critical "middle" number
optNums = zeros(numTotalRounds,numAgents);

for i = 1:numAgents
    for j = 1:numTotalRounds
        low = min(goalNumbers(numberSets(j,i),:));
        optNums(j,i) = randi(low-1,1); % select a number between [1, lowerNumber - 1]
    end
end

%% Available actions from each S2 state
terminalactions = [1 2 0;2 3 0; 1 2 3];
                   
%% Transitions
baseprob = .7;
mainTransition = 1-((numRealRounds*(1-baseprob)-numCrits)/(numRealRounds-numCrits)); % gotta take crit trials into account

% AM: This tells the model that, if we are in state s and take action a and get
% a high-probability transition, we should go to likelyTransition(s,a).
likelyTransition = zeros(numStates,numActions);
likelyTransition(1,1) = 2;
likelyTransition(1,2) = 3;
likelyTransition(2,[1 2]) = [5 6];
likelyTransition(3,[2 3]) = [6 7]; % AM: There's potential ambiguity here. We could label these two actions [1 2] or [2 3]. I don't THINK it matters, but we definitely have to stay consistent.
likelyTransition(4,[1 2 3]) = [5 6 7];

% AM: This tells the model that, if we're in state 1 and get a low-probability
% transition, we should go to state unlikelyTransition.
unlikelyTransition = 4;

%% Rewards
% AM: Changed this so that it technically has rewards for all states, but
% only nonzero rewards for S3_states
rewards = zeros(numTotalRounds,numStates,numAgents);
stdShift = 2;
rewardRange_hi = 5;
rewardRange_lo = -4;

for thisAgent = 1:numAgents
    rewards(numPracticeRounds+1,S3_states,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,length(S3_states),true);
    
    for thisRound = (numPracticeRounds+1):(numTotalRounds-1)
        re = squeeze(rewards(thisRound,S3_states,thisAgent))+round(randn(length(S3_states),1)'*stdShift);
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        rewards(thisRound+1,S3_states,thisAgent) = re;
    end
end

%% subgoals
% AM: Subgoals for the two Stage 1 options & three Stage 2 options available to our goal learner
subgoals = [2 3 0; 5 6 7];

%% Initial transition prob matrix
% AM: We're just setting this now, instead of having agents learn it from
% experience.
transition_probs0 = zeros(numStates,numActions,numStates);

% Stage 1
transition_probs0(1,1,2) = baseprob;
transition_probs0(1,2,3) = baseprob;
transition_probs0(1,[1 2],4) = 1-baseprob;

% Stage 2
for i = S2_states
    for j = S2_actions
        if likelyTransition(i,j) ~= 0, transition_probs0(i,j,likelyTransition(i,j)) = 1; end
    end
end
transition_probs0(4,3,likelyTransition(4,3)) = 1;

%% Save
save(path);