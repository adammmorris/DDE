%% Simulation parameters
MFG_S2_MB = 1; % If this is 1, the model-free goal controller will act model-based-like in stage 2

%% Subject parameters
numAgents = 100;

% Set up their parameters
params = zeros(numAgents,8); % [lr1, lr2, elig, temp1, temp2, stay, weight_MFG, weight_MB]
for thisSubj = 1:numAgents
    % This is all very random
    lr1 = rand();
    lr2 = lr1;
    elig = rand()*(1/2) + .5;
    temp1 = rand()*(1/2)+1;
    temp2 = temp1;
    stay = rand();
    
    w_MFG = rand(); % model-based
    w_MB = rand(); % dumb model-free
    w_MF = rand(); % goal-learner

    weights = [w_MFG w_MB] / (w_MFG + w_MB + w_MF);
    params(thisSubj,:) = [lr1 lr2 elig temp1 temp2 stay weights(1) weights(2)];
end

%% Board parameters
numRounds = 250;
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

% Rewards
rewards = zeros(numRounds,3,numAgents);
stdShift = 2;
rewardRange_hi = 5;
rewardRange_lo = -4;

for thisAgent = 1:numAgents
    rewards(1,S3_states,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,length(S3_states),true);
    
    for thisRound = 1:(numRounds-1)
        re = squeeze(rewards(thisRound,S3_states,thisAgent))+round(randn(length(S3_states),1)'*stdShift);
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        rewards(thisRound+1,S3_states,thisAgent) = re;
    end
end

%% Run it
likelihood = zeros(numAgents,1);
PEs = zeros(numRounds,3,numAgents);
critTrials = [];

realA1 = zeros(numRounds, numAgents);
realS2 = zeros(numRounds, numAgents);
realA2 = zeros(numRounds, numAgents);
realRe = zeros(numRounds, numAgents);

for thisSubj=1:numAgents
    lr1 = params(thisSubj,1);
    lr2 = params(thisSubj,2);
    elig = params(thisSubj,3);
    temp1 = params(thisSubj,4);
    temp2 = params(thisSubj,5);
    stay = params(thisSubj,6);
    w_MFG = params(thisSubj,7);
    w_MB = params(thisSubj,8);
    
    Q_MF = zeros(4,numActions); % 4 S1/S2 states
    Q_MB = zeros(numStates,numActions);
    Q_MFG = zeros(4,numActions); % numOptions = numActions
    %P_actions_S1 = [1 0; 0 1]; % rows are options, columns are S1_actions - these are just identity matrices for our task
    %P_actions_S2 = [1 0 0; 0 1 0; 0 0 1]; % rows are options, columns are S2_actions
    
    crit = 0;
    
    lastChoice1 = 0;
    for thisRound=1:numRounds
        %% Stage 1
        
        S1_availActions = S1_actions; % availOptions = availActions

        % MB
        for a1 = S1_availActions
            Q_MB(1, a1) = 0;
            for s2 = S2_states
                Q_MB(1, a1) = Q_MB(1, a1) + transition_probs(1, a1, s2) * max(squeeze(transition_probs(s2, S2_actions(S2_avail(s2-1,:)), S3_states)) * Q_MB(S3_states,1));
            end
        end
        
        Q_weighted = w_MFG * Q_MFG(1, S1_availActions) + w_MB * Q_MB(1, S1_availActions) + (1 - w_MB - w_MFG) * Q_MF(1, S1_availActions);
        
        probs = exp(temp1 * Q_weighted + stay * (S1_availActions == lastChoice1)) / sum(exp(temp1 * Q_weighted + stay * (S1_availActions == lastChoice1)));
        choice1 = randsample(S1_availActions, 1, true, probs);
        
        if rand() < baseprob, S2 = likelyTransition(1, choice1); % Likely
        else S2 = unlikelyTransition; % Unlikely
        end
        
        if MFG_S2_MB, S2_MFG = 2;
        else S2_MFG = S2;
        end
        
        S2_availActions = S2_actions(S2_avail(S2-1,:));
        
        PEs(thisRound,1,thisSubj) = max(Q_MFG(S2_MFG,S2_availActions)) - Q_MFG(1,choice1);
        PEs(thisRound,2,thisSubj) = max(Q_MF(S2,S2_availActions)) - 0;
        PEs(thisRound,3,thisSubj) = max(Q_MB(S2,S2_availActions)) - Q_MB(1,choice1);
        
        likelihood(thisSubj) = likelihood(thisSubj) + log(probs(S1_availActions == choice1));
        
        % Update after first choice
        Q_MF(1,choice1) = 0 + lr1*(max(Q_MF(S2,S2_availActions)) - 0);
        Q_MFG(1,choice1) = Q_MFG(1,choice1) + lr1*(max(Q_MFG(S2_MFG,S2_availActions)) - Q_MFG(1,choice1));
        
        %% Stage 2
        Q_MB(S2, S2_availActions) = squeeze(transition_probs(S2, S2_availActions, S3_states)) * Q_MB(S3_states, 1);
        
        Q_weighted = w_MFG * Q_MFG(S2_MFG, S2_availActions) + w_MB * Q_MB(S2, S2_availActions) + (1 - w_MB - w_MFG) * Q_MF(S2, S2_availActions);
        
        probs = exp(temp2 * Q_weighted) / sum(exp(temp2 * Q_weighted));
        choice2 = randsample(S2_availActions,1,true,probs);
        
        S3 = likelyTransition(S2, choice2);
        reward = rewards(thisRound, S3, thisSubj);
        
        likelihood(thisSubj) = likelihood(thisSubj) + log(probs(S2_availActions == choice2));

        % Update after second choice
        Q_MF(S2, choice2) = Q_MF(S2, choice2) + lr2 * (reward - Q_MF(S2, choice2));
        
        delta = reward - Q_MFG(S2_MFG, choice2);
        Q_MFG(S2_MFG, choice2) = Q_MFG(S2_MFG, choice2)  + lr2 * delta;
        Q_MFG(1, choice1) = Q_MFG(1, choice1) + lr1 * elig * delta;
        
        Q_MB(S3,1) = Q_MB(S3,1) + lr2 * (reward - Q_MB(S3, 1));
        
        lastChoice1 = choice1;
        
        % Record results
        realA1(thisRound, thisSubj) = choice1;
        realS2(thisRound, thisSubj) = S2;
        realA2(thisRound, thisSubj) = choice2;
        realRe(thisRound, thisSubj) = reward;
    end
end

%% Correlations
subjCors = zeros(100,2);
for i=1:100
    subjCors(i,1) = corr(PEs(:,1,i),PEs(:,2,i));
    subjCors(i,2) = corr(PEs(:,1,i),PEs(:,3,i) - PEs(:,2,i));
end

% Plot them
subplot(1,2,1)
hist(subjCors(:,1)); title('Cor w/ MF'); axis([-1 1 0 35]);
subplot(1,2,2);
hist(subjCors(:,2)); title('Cor w/ MB - MF'); axis([-1 1 0 35]);

%% Save
save('simdata.mat','realA1','realS2','realA2','realRe');