%%%%% Building experiment board %%%%%
path = 'C:\Personal\Psychology\Projects\DDE\git\Model\board_daw.mat';

numAgents = 200;
numRounds = [50 175];

numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);
numRealRounds = numRounds(2);

numCrits = 26;
numActions = 4;
numOptions = 2;
numFeatureValues = 3;
numTrialTypes = 1;
TRIAL_TYPE = 1;
numGoals = numFeatureValues * numTrialTypes;
numStates = 5; % remember to preserve the state # integrity

%% Trial types
% numTotalRounds x numAgents
%trialTypes = round(rand(numTotalRounds,numAgents)+1);
trialTypes = ones(numTotalRounds,numAgents)*TRIAL_TYPE;

%% Available actions
% numTotalRounds x 2 x numAgents
availableActions = zeros(numTotalRounds,2,numAgents);

for i = 1:numAgents
    opt1 = randi(4,numTotalRounds,1);
    opt2 = getOtherAvailableAction(opt1,trialTypes);
    availableActions(:,:,i) = [opt1 opt2];
end

%% Transitions
% numTotalRounds x numOptions x numAgents
baseprob = .8;
mainTransition = 1-((numRealRounds*(1-baseprob)-numCrits)/(numRealRounds-numCrits)); % gotta take crit trials into account

likelyTransition = zeros(numStates,numActions);
likelyTransition(1,[1 3]) = 2;
likelyTransition(1,[2 4]) = 3;
likelyTransition(2:4,:) = 5;

unlikelyTransition = 4;

%% Rewards
% numTotalRounds x numTrialTypes x numFeatureValues x numAgents
rewards = zeros(numTotalRounds,numTrialTypes,numFeatureValues,numAgents);
stdShift = 2;
rewardRange_hi = 5;
rewardRange_lo = -5;

for thisAgent = 1:numAgents
    rewards(numPracticeRounds+1,1,:,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,numFeatureValues,true);
    rewards(numPracticeRounds+1,2,:,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,numFeatureValues,true);
    
    for thisRound = (numPracticeRounds+1):(numTotalRounds-1)
        re = squeeze(rewards(thisRound,TRIAL_TYPE,:,thisAgent))+round(randn(numFeatureValues,1)*stdShift);
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        rewards(thisRound+1,TRIAL_TYPE,:,thisAgent) = re;
    end
end

%% Critical trials
% Same for each person
good = true(numRealRounds,1);
templist = 1:numRealRounds;
distance_cutoff = 3;
criticalTrials = zeros(numCrits,2); % 1st column has trial #, 2nd column is whether it's congruent (1) or incongruent(0)
probCong = 1; % set this to 1 if you want all congruent crit trials

for i = 1:numCrits
    criticalTrials(i,1) = randsample(templist(good),1);
    for k = 0:distance_cutoff
        if (criticalTrials(i,1)+k) <= numRealRounds, good(criticalTrials(i,1)+k)=false; end
        if (criticalTrials(i,1)-k) > 0, good(criticalTrials(i,1)-k)=false; end
    end
    
    if rand() <= probCong,criticalTrials(i,2)=1;end
end
criticalTrials(:,1) = criticalTrials(:,1) + numPracticeRounds;

%% subgoalRewards
% The pseudo-rewards for arriving at each state (for each option)
subgoalRewards = zeros(numStates,numOptions); 
subgoalRewards(2,1) = 1;
subgoalRewards(3,2) = 1;

%% features
features = zeros(numStates,1);
features(2:4) = 1:3;

%% Save
save(path);