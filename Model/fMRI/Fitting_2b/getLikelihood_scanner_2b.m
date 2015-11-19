% params: [lr1 lr2 elig temp1 temp2 w_MFG w_MB MFG_S2_MB]

function [negLL] = getLikelihood_scanner_2b(params, boardName, realA1, realS2, realA2, realRewards)
load(boardName);
numRounds = length(realA1);

%% Run it
likelihood = 0;

lr1 = params(1);
lr2 = params(2);
elig = params(3);
temp1 = params(4);
temp2 = params(5);
stay = params(6);
w_MFG = params(7);
w_MB = params(8);
MFG_S2_MB = params(9);

Q_MF = zeros(4,numActions); % 4 S1/S2 states
Q_MB = zeros(numStates,numActions);
Q_MFG = zeros(4,numActions); % numOptions = numActions
%P_actions_S1 = [1 0; 0 1]; % rows are options, columns are S1_actions - these are just identity matrices for our task
%P_actions_S2 = [1 0 0; 0 1 0; 0 0 1]; % rows are options, columns are S2_actions

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
    choice1 = realA1(thisRound);
    
    S2 = realS2(thisRound);
    
    if MFG_S2_MB, S2_MFG = 2;
    else S2_MFG = S2;
    end
    
    S2_availActions = S2_actions(S2_avail(S2-1,:));
    
    likelihood = likelihood + log(probs(S1_availActions == choice1));
    
    % Update after first choice
    Q_MF(1,choice1) = 0 + lr1*(max(Q_MF(S2,S2_availActions)) - 0);
    Q_MFG(1,choice1) = Q_MFG(1,choice1) + lr1*(max(Q_MFG(S2_MFG,S2_availActions)) - Q_MFG(1,choice1));
    
    %% Stage 2
    Q_MB(S2, S2_availActions) = squeeze(transition_probs(S2, S2_availActions, S3_states)) * Q_MB(S3_states, 1);
    
    Q_weighted = w_MFG * Q_MFG(S2_MFG, S2_availActions) + w_MB * Q_MB(S2, S2_availActions) + (1 - w_MB - w_MFG) * Q_MF(S2, S2_availActions);
    
    probs = exp(temp2 * Q_weighted) / sum(exp(temp2 * Q_weighted));
    choice2 = realA2(thisRound);
    
    S3 = likelyTransition(S2, choice2);
    reward = realRewards(thisRound);
    
    likelihood = likelihood + log(probs(S2_availActions == choice2));
    
    % Update after second choice
    Q_MF(S2, choice2) = Q_MF(S2, choice2) + lr2 * (reward - Q_MF(S2, choice2));
    
    delta = reward - Q_MFG(S2_MFG, choice2);
    Q_MFG(S2_MFG, choice2) = Q_MFG(S2_MFG, choice2)  + lr2 * delta;
    Q_MFG(1, choice1) = Q_MFG(1, choice1) + lr1 * elig * delta;
    
    Q_MB(S3,1) = Q_MB(S3,1) + lr2 * (reward - Q_MB(S3, 1));
    
    lastChoice1 = choice1;
end

negLL = -1 * likelihood;
end
