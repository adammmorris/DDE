%%%%% Building experiment board %%%%%
clear;
path = 'C:\Personal\Psychology\Projects\DDE\git\Model\board_daw.mat';

numAgents = 500;
%numRounds = [75 175];
numRounds = [0 175];

numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);
numRealRounds = numRounds(2);

numCrits = 26;
numActions = 4;
numOptions = 2;
TRIAL_TYPE = 1;
numStates = 10; % remember to preserve the state # integrity

S2_states = 2:4;
S2_actions = 1:2;
S3_states = 5:10;
S3_action = 1;

%% Available actions
% numTotalRounds x 2 x numAgents
availableActions = zeros(numTotalRounds,2,numAgents);

for i = 1:numAgents
    opt1 = randi(4,numTotalRounds,1);
    opt2 = getOtherAvailableAction(opt1,TRIAL_TYPE);
    availableActions(:,:,i) = [opt1 opt2];
end

%% Transitions
% numTotalRounds x numOptions x numAgents
baseprob = .8;
mainTransition = 1-((numRealRounds*(1-baseprob)-numCrits)/(numRealRounds-numCrits)); % gotta take crit trials into account

likelyTransition = zeros(numStates,numActions);
likelyTransition(1,[1 3]) = 2;
likelyTransition(1,[2 4]) = 3;
likelyTransition(2:4,1) = [5 7 9];
likelyTransition(2:4,2) = [6 8 10];

unlikelyTransition = 4;

%% Rewards
% numTotalRounds x numStates x numAgents
rewards = zeros(numTotalRounds,numStates,numAgents);
stdShift = 2;
rewardRange_hi = 8;
rewardRange_lo = -8;

for thisAgent = 1:numAgents
    rewards(numPracticeRounds+1,S3_states,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,length(S3_states),true);
    
    for thisRound = (numPracticeRounds+1):(numTotalRounds-1)
        re = squeeze(rewards(thisRound,S3_states,thisAgent))+round(randn(length(S3_states),1)'*stdShift);
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        rewards(thisRound+1,S3_states,thisAgent) = re;
    end
end

%% Critical trials
% Same for each person
good = true(numRealRounds,1);
templist = 1:numRealRounds;
distance_cutoff = 3;
criticalTrials = zeros(numCrits,1);

for i = 1:numCrits
    criticalTrials(i,1) = randsample(templist(good),1);
    for k = 0:distance_cutoff
        if (criticalTrials(i)+k) <= numRealRounds, good(criticalTrials(i)+k)=false; end
        if (criticalTrials(i)-k) > 0, good(criticalTrials(i)-k)=false; end
    end
end
criticalTrials = criticalTrials + numPracticeRounds;

%% subgoalRewards
% The pseudo-rewards for arriving at each state (for each option)
subgoalRewards = zeros(numStates,numOptions); 
subgoalRewards(2,1) = 1;
subgoalRewards(3,2) = 1;

%% subgoals
subgoals = [2 3];

%% Initial transition prob matrix
transition_probs0 = zeros(numStates,numActions,numStates);
transition_probs0(1,[1 3],2) = baseprob;
transition_probs0(1,[2 4],3) = baseprob;
transition_probs0(1,[1 2 3 4],4) = 1-baseprob;
for i=2:4
    for j=1:2
        transition_probs0(i,j,likelyTransition(i,j)) = 1;
    end
end

%% Save
save(path);