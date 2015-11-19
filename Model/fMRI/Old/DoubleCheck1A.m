%% Subject parameters

numSubjects = 100;

% Set up their parameters
params = zeros(numSubjects,5);
for thisSubj = 1:numSubjects
    % This is all very random
    lr = rand();
    elig = rand()*(1/2) + .5;
    temp = rand()*(1/2)+1;
    
    w_MFG = rand(); % model-based
    w_MB = rand(); % dumb model-free
    w_MF = rand(); % goal-learner

    weights = [w_MFG w_MB] / (w_MFG + w_MB + w_MF);
    params(thisSubj,:) = [lr elig temp weights(1) weights(2)];
end

%% Board parameters
numRounds = 250;
S2_states = 2:4;
S2_actions = 1;

% Transitions
baseprob = .7;

likelyTransition = zeros(numStates,numActions);
likelyTransition(1,[1 3]) = 2;
likelyTransition(1,[2 4]) = 3;

unlikelyTransition = 4;

% Transition prob matrix
transition_probs0 = zeros(numStates,numActions,numStates);

transition_probs0(1,[1 3],2) = baseprob;
transition_probs0(1,[2 4],3) = baseprob;
transition_probs0(1,[1 2 3 4],4) = 1-baseprob;

% Rewards
rewards = zeros(numRounds,3,numAgents);
stdShift = 2;
rewardRange_hi = 5;
rewardRange_lo = -4;

for thisAgent = 1:numAgents
    rewards(1,S2_states,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,length(S2_states),true);
    
    for thisRound = 1:(numRounds-1)
        re = squeeze(rewards(thisRound,S2_states,thisAgent))+round(randn(length(S2_states),1)'*stdShift);
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        rewards(thisRound+1,S2_states,thisAgent) = re;
    end
end

%% Run it
likelihood = zeros(numSubjects,1);
PEs = zeros(numRounds,3,numSubjects);
critTrials = [];
for thisSubj=1:numSubjects
    lr = params(thisSubj,1);
    elig = params(thisSubj,2);
    temp = params(thisSubj,3);
    w_MFG = params(thisSubj,4);
    w_MB = params(thisSubj,5);
    
    Q_MF = zeros(1,4);
    Q_MB = zeros(1,4);
    Q_MFG = zeros(1,2);
    P_H_actions = [1 0 1 0; 0 1 0 1];
    Q_bottom = zeros(3,1);
    
    crit = 0;
    
    for thisRound=1:numRounds
        if crit == 1
            critTrials(end+1) = thisRound;
            act1 = getCorrespondingAction(choice);
            act2 = getOtherAvailableAction(act1);
            availActions = [act1 act2];
            crit = 0;
        else
            availActions = availableS1Actions(thisRound,:,thisSubj);
        end
        
        Q_MB(1,availActions) = squeeze(transition_probs0(1,availActions,S2_states)) * Q_bottom;
        Q_weighted = w_MB*Q_MB(1,availActions) + w_MFG*Q_MFG(1,:)*P_H_actions(:,availActions) + (1-w_MB-w_MFG)*Q_MF(1,availActions);
        probs = exp(temp*Q_weighted) / sum(exp(temp*Q_weighted));
        choice = randsample(availActions,1,true,probs);
        
        if any(choice == [1 3]), chosenOption = 1;
        else chosenOption = 2;
        end    
        
        PEs(thisRound,1,thisSubj) = Q_bottom(S2-1) - Q_MFG(1,chosenOption);
        PEs(thisRound,2,thisSubj) = Q_bottom(S2-1) - Q_MF(1,choice);
        PEs(thisRound,3,thisSubj) = Q_bottom(S2-1) - Q_MB(1,choice);
        
        if rand() < .7, S2 = likelyTransition(1,choice);
        else
            S2 = unlikelyTransition;
            if rand() < .5, crit = 1; end
        end
        
        likelihood(thisSubj) = likelihood(thisSubj) + log(probs(availActions == choice));
        
        reward = rewards(thisRound, S2, thisSubj);
        
        % Update after first choice
        Q_MF(1,choice) = Q_MF(1,choice) + lr*(Q_bottom(S2-1) - Q_MF(1,choice));
        Q_MFG(1,chosenOption) = Q_MFG(1,chosenOption) + lr*(Q_bottom(S2-1) - Q_MFG(1,chosenOption));
        
        % Update after second choice
        delta = reward - Q_bottom(S2-1);
        Q_MF(1,choice) = Q_MF(1,choice) + lr*elig*delta;
        Q_MFG(1,chosenOption) = Q_MFG(1,chosenOption) + lr*elig*delta;
        Q_bottom(S2-1) = Q_bottom(S2-1) + lr*delta;
    end
end

subjCors = zeros(100,2);
for i=1:100
    subjCors(i,1) = corr(PEs(critTrials,1,i),PEs(critTrials,2,i));
    subjCors(i,2) = corr(PEs(critTrials,1,i),PEs(critTrials,3,i));
end

% Plot them
subplot(1,2,1)
hist(subjCors(:,1)); title(strcat(name, ' - cor w/ MF')); axis([-1 1 0 35]);
subplot(1,2,2);
hist(subjCors(:,2)); title(strcat(name, ' - cor w/ MB')); axis([-1 1 0 35]);