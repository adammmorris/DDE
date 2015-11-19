%%%%% Building experiment board %%%%%

%% Versions

% Version3:
% - Changing my bounded drifting to random drifting
% - Inserting critical trials

path = 'board_scanner2b.mat';

numAgents = 200;
numRounds = [0 400];

numTotalRounds = sum(numRounds);
numPracticeRounds = numRounds(1);
numRealRounds = numRounds(2);

orig_simulation = 0;

numCrits = 0;
%not hardcoding any of these now
numOptions = 2;
numTerminalStates = 3;
actualStates = [66, 71];
numFeatureValues = 3; %colors stage 2
numTrialTypes = 1; % SET THIS TO 2 IF YOU WANT TO ACTUALLY USE BOTH TRIAL TYPES
numGoals = numFeatureValues * numTrialTypes;
numStates = 4; % ignore the bottom level for now

% Trial types
% numTotalRounds x numAgents
trialTypes = ones(numTotalRounds,numAgents); % NOTE: if we do a single trial type, it's "color" (meaning actions 1 and 3 both lead to blue, and actions 2 and 4 both lead to red)


% Top Level Options
% numTotalRounds x 3 x numAgents
options = zeros(numTotalRounds,3,numAgents);

for i = 1:numAgents
    for j = 1:numTotalRounds
     currMid = randi(actualStates(1),1,1);
     currOpt = [currMid actualStates(1)-currMid actualStates(2)-currMid];
     currRandi = randi(6,1,1);
     currPerms = perms(currOpt);
     options(j,:,i) = currPerms(currRandi,:);
    end
end

% Terminal State options
% numTotalRounds x 2 x numAgents
terminaloptions = zeros(numFeatureValues,numTerminalStates);

terminaloptions = [1 2 0;2 3 0; 1 2 3];
                    


% MORGAN: here's where I'm arbitrarily forcing all non-practice rounds to
% use option 1 instead of option 3
% If you want to get rid of this, use the above commented out code instead
%     for j = 1:numTotalRounds
%         if (j > numPracticeRounds), opt1 = 1;
%         else opt1 = round(rand()*3)+1;
%         end
%         
%         opt2 = getOtherOption(opt1,trialTypes(j));
%         options(j,:,i) = [opt1 opt2];
%     end


% Transitions
% numTotalRounds x numOptions x numAgents
baseprob = .7;
mainTransition = 1-((numRealRounds*(1-baseprob)-numCrits)/(numRealRounds-numCrits)); % gotta take crit trials into account

transitions = zeros(numTotalRounds,numOptions,numAgents);

for i = 1:numAgents
    transitions(:,:,i) = repmat((1:numOptions)+1,numTotalRounds,1);
    templist = rand(numTotalRounds,1)>mainTransition;
    transitions(templist,:,i) = repmat([4 4],sum(templist),1);
end

% Rewards
% numTotalRounds x numTrialTypes x numTerminalStates x numAgents
rewards = zeros(numTotalRounds,numTrialTypes,numTerminalStates,numAgents);
stdShift = 2;
rewardRange_hi = 5;
rewardRange_lo = -4;

for thisAgent = 1:numAgents
    rewards(numPracticeRounds+1,1,:,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,numFeatureValues,true);
    rewards(numPracticeRounds+1,2,:,thisAgent) = randsample(rewardRange_lo:rewardRange_hi,numFeatureValues,true);
    
    for thisRound = (numPracticeRounds+1):(numTotalRounds-1)
        trialType = trialTypes(thisRound,thisAgent);
        otherType = 1+1*(trialType==1);
        re = squeeze(rewards(thisRound,trialType,:,thisAgent))+round(randn(numFeatureValues,1)*stdShift);
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        rewards(thisRound+1,trialType,:,thisAgent) = re;
        rewards(thisRound+1,otherType,:,thisAgent) = rewards(thisRound,otherType,:,thisAgent);
    end
end

% % Critical trials
% % Same for each person
% good = true(numRealRounds,1);
% templist = 1:numRealRounds;
% distance_cutoff = 3;
% criticalTrials = zeros(numCrits,2); % 1st column has trial #, 2nd column is whether it's congruent (1) or incongruent(0)
% probCong = .5; % set this to 1 if you want all congruent crit trials
% 
% for i = 1:numCrits
%     criticalTrials(i,1) = randsample(templist(good),1);
%     for k = 0:distance_cutoff
%         if (criticalTrials(i,1)+k) <= numRealRounds, good(criticalTrials(i,1)+k)=false; end
%         if (criticalTrials(i,1)-k) > 0, good(criticalTrials(i,1)-k)=false; end
%     end
%     
%     if rand() < probCong,criticalTrials(i,2)=1;end
% end
% criticalTrials(:,1) = criticalTrials(:,1) + numPracticeRounds;

% Features & goals
% For trial type 1 (aka shapes): 1 = square, 2 = circle, 3 = triangle
% For trial type 2 (aka colors): 1 = blue, 2 = red, 3 = green
% Note that these are built for 2 trial types - they still work even if you're
%    only using 1 trial type

features = zeros(numStates); % features(state,dimension) gives you the feature value of a particular state along one of the trial-type dimensions

% Let's set this statically right now
% NOTE: In the original 'board.mat', this was different.  It went blue
%   square, blue circle, red square, red circle, green triangle.
%   It's fixed now, but if you use 'board.mat', be wary of this.
features(1,:) = [1]; % first-level state has no features, but it's easier to set it to 1.  This should turn to 0 when multiplied by the transition probabilities, etc.
features(2,:) = [1]; % red 
features(3,:) = [2]; % blue 
features(4,:) = [3]; % green


% For our goal-learner, we're going to need a goal numbering system based
% off these feature types
goals = zeros(numTrialTypes,numFeatureValues);
for trialType = 1:numTrialTypes
    for featureValue = 1:numFeatureValues
        goals(trialType,featureValue) = numFeatureValues*(trialType-1) + featureValue;
    end
end

%% Save
save(path,'orig_simulation','terminaloptions','numTerminalStates','numCrits','numOptions','numFeatureValues','numTrialTypes','numStates','numGoals','trialTypes','options','transitions','rewards','rewardRange_hi','rewardRange_lo','features','goals');