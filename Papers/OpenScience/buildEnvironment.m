%%------------------------------------------
% Builds the environment for the generative model in Cushman & Morris (2015). Habitual control of goal selection in humans. PNAS.
%
% Adam Morris, 2015
% 
% Note that many of the variables used here are set in "buildBoard.mat" and "board_1B.mat".
%%------------------------------------------

clear;

numAgents = 500; % Maximum # of agents
numRounds = 175; % # of rounds each agent plays

numCrits = 26; % # of critical trials
numActions = 4; % # of available actions in Stage 1
numOptions = 2; % # of available options in Stage 1
numStates = 10; % # of states

S2_states = 2:4; % Stage 2 state ID numbers
S2_actions = 1:2; % Stage 2 action ID numbers
S3_states = 5:10; % Stage 3 state ID numbers
S3_action = 1; % Stage 3 action ID number. We treat stage 3 as having only 1 action (there's no actual stage 3 choice)

%% Generative available Stage 1 actions
availableActions = zeros(numRounds,2,numAgents);

for i = 1:numAgents
    opt1 = randi(4,numRounds,1);
    opt2 = getOtherAvailableAction(opt1);
    availableActions(:,:,i) = [opt1 opt2];
end

%% Set up transitions
lowProb_uncorrected = .8; % The overall probability of transitioning to the unlikely Stage 2 state

% We have to calculate the probability of transitioning to the unlikely Stage 2 state in NON-setup trials that will make the overall probability equal to
%   lowProb_uncorrected. Basically, we're correcting for the fact that all setup trials automatically have a low probability transition.
lowProb_corrected = 1-((numRounds*(1-lowProb_uncorrected)-numCrits)/(numRounds-numCrits));

% The likely transition after taking an action from a state
likelyTransition = zeros(numStates,numActions);
likelyTransition(1,[1 3]) = 2;
likelyTransition(1,[2 4]) = 3;
likelyTransition(2:4,1) = [5 7 9];
likelyTransition(2:4,2) = [6 8 10];

% The unlikely Stage 2 state
unlikelyTransition = 4;

%% Generate rewards
rewards = zeros(numRounds,numStates,numAgents);
stdDrift = 2; % The standard deviation of the normal distribution used to drift every round
rewardRange_hi = 5; % Upper reward bound
rewardRange_lo = -4; % Lower reward bound

for thisAgent = 1:numAgents
    rewards(1,S3_states,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,length(S3_states),true); % Sample initial rewards
    
    for thisRound = 1:(numRounds-1)
        % Drift
        re = squeeze(rewards(thisRound,S3_states,thisAgent))+round(randn(length(S3_states),1)'*stdDrift);
        
        % If over boundaries, rebound (see Methods)
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        
        % Set for next round
        rewards(thisRound+1,S3_states,thisAgent) = re;
    end
end

%% Generate critical trial numbers
% Can't be within 3 rounds of each other
criticalTrials = zeros(numCrits,1);

roundList = 2:numRounds;
available = true(length(roundList),1);
distance_cutoff = 3;

for i = 1:numCrits
    criticalTrials(i,1) = randsample(roundList(available),1); % Sample from our available list
    
    % Then, make everything within three rounds of that unavailable
    for k = 0:distance_cutoff
        if (criticalTrials(i)+k) <= numRounds, available(criticalTrials(i)+k)=false; end
        if (criticalTrials(i)-k) > 0, available(criticalTrials(i)-k)=false; end
    end
end

%% Subgoals of the two Stage 1 options
subgoals = [2 3];

%% Initial transition prob matrix
transition_probs0 = zeros(numStates,numActions,numStates);
transition_probs0(1,[1 3],2) = lowProb_uncorrected;
transition_probs0(1,[2 4],3) = lowProb_uncorrected;
transition_probs0(1,[1 2 3 4],4) = 1-lowProb_uncorrected;
for i=2:4
    for j=1:2
        transition_probs0(i,j,likelyTransition(i,j)) = 1;
    end
end

%% Save
save('environment_1B.mat');