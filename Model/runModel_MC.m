%% DDE Project - Adam Morris, Nov. 2013 %%
% This is our model for our experiment
% Meant to show model-free learning on model-based goals
% Model combines both types of RL learners
% Much of this is drawn from Daw's 2-step task

% Our model:
% One model-based RL learner
% One dumb model-free SARSA learner (dumb because it doesn't recognize
%   trial type)
% One goal-learning model-free learner

% Version 2:
% - Model-based learner now searches through feature space
% - We now can run multiple agents

% Version 3:
% - Added dumb model-free learner
% - Fixed major bug in model-based learner
% - Added goal-learning model-free learner

% Version 4:
% - Changing model-based learner to work off goals

% Version 5:
% - Reducing # of parameters
% - Made 'params' able to be different for each agent

% Version 6:
% - Cutting out the dumb model-free learner from the decision-making (too many parameters)
% - Fixed major bug in model-based learner

% Version 7:
% - Trying to add back in dumb model-free learner (now that I have 4 cores
%   on my laptop ^^ yay parfor)
% - Making the servant/equal thing a parameter
% - Added round# to the results array

%% From 'board.mat':
% (1) trialTypes(thisBoard,thisRound) gives you the trial type of this round
% (2) options1(thisBoard,thisRound,:) gives you the actions (2 of them) available to the agent in the
%   first level at the given round
% (3) transitions(thisBoard,thisRound,choice) gives you the second-level state to which agent transitions (the actual one, not
%   the prob) by taking 'choice' in the given round
%   Note that choice is the option #
% (4) rewards(thisBoard,thisRound, trialType, featureValue) gives you the reward of the
%   feature value along the given trial type dimension
%   Technically you only get rewards in the third-level, but, since there's
%   only action you can do (i.e. click on the letter), for now we can just
%   treat it this way
% (5) numTrialTypes: this is 2 right now
% (6) features(state, trialType) gives you the feature value for the given
%   state along the given trial type dimension
% (7) numFeatureValues: this is 3 right now
% (8) goals(trialType,featureValue) gives you the corresponding goal #

%% Inputs:
% params should be [lr beta elig_trace]
%   it can be just a 1x4 vector, in which case it applies to all agents
%   or it can be an nx4, where n is numAgents
% weights should be [modelBased smartModelFree goalLearner]
% numRounds should be [numPracticeRounds numRealRounds]
% numAgents should be how many agents you want to run
% servant: set to 0 if you want the goal learner to be treated equally
%   (i.e. an independent weight parameter), or set to 1 if you want the
%   goal learner to be treated as a servant to the model-based system (i.e.
%   its weight must be <= to the model-based weight; its weight here really represents what % of the model-based weight it should have)
% boardName: should be something like 'board', or 'board_no5'
% magicBoard: this is gimmicky, but set this to anything nonzero to make
%   every agent play that same board#

%% Outputs
% earnings has the earnings for every agent
% negLL has the negLL for every agent
% results is a (numAgents*numRounds) x 8 matrix;
%   columns are id, trialType, option1, option2, choice, state2, reward,
%   and round#

%% Remarks

% - Throughout this whole thing, be VERY careful to distinguish (and
%   convert) between action space, state space, and feature space
% - MC = MonteCarlo version

function [earnings] = runModel_MC(numRounds, numAgents, twoTrialTypes)

%% Defaults
if nargin < 3
    twoTrialTypes = 1;
end
if nargin < 2
    numAgents = 10000;
end
if nargin < 1
    numRounds = 175;
end

%% Set board params
%load(['C:\Personal\School\Brown\Psychology\DDE Project\git\Model\' boardName '.mat']);

% Outputs
earnings = zeros(numAgents,1);

% Generate trial types
% if twoTrialTypes==1, trialTypes = round(rand(numAgents,numRounds))+ones(numAgents,numRounds);
% else trialTypes = 2*ones(numAgents,numRounds);
% end

% Generate options
% opt1 = round(rand(numAgents,numRounds)*3)+ones(numAgents,numRounds);
% opt2 = getOtherOption(opt1,trialTypes);

% Transition parameters
baseprob = .825;
% mainTransition = 1-((numRounds*(1-baseprob)-numCrits)/(numRounds-numCrits)); % gotta take crit trials into account

% Reward parameters
stdShift = 2;
rewardRange_hi = 5;
rewardRange_lo = -4;
numDistributions = 3+3*(twoTrialTypes==1);

rewards = rand(numDistributions,numAgents)*(rewardRange_hi+abs(rewardRange_lo))-abs(rewardRange_lo); % initial distribution

%% Let's do this!
for thisAgent = 1:numAgents
%     prevChoice = 0;
%     prevType = 0;
    
    %% Go through rounds
    for thisRound = 1:numRounds
        % What trial type is this?
%         trialType = trialTypes(thisAgent,thisRound);
        
        % Are we in a test trial? (i.e. was last trial a critical trial?
%         if any(criticalTrials(:,1)==(thisRound-1))
%             % If we are, force options & trial type
%             
%             % Are we in a congruent test trial (or in the version w/ only 1
%             % trial type)?
%             if (twoTrialTypes == 0) || (criticalTrials(find(criticalTrials(:,1)==(thisRound-1)),2) == 1), trialType = prevType;
%             else trialType = 1+1*(prevType==1); end
%             
%             opt1 = getCorrespondingAction(prevChoice,prevType,orig_simulation);
%             opt2 = getOtherOption(opt1,trialType);
%             action_options = [opt1 opt2];
%         else
%             action_options = [opt1(thisAgent,thisRound) opt2(thisAgent,thisRound)];
%         end
        
        if rand() < baseprob
            %newstate = randsample([1 2 4 5],1); % either 1 2 4 or 5
            newstate = round(rand()+1)+3*(rand()<.5)*(twoTrialTypes==1);
        else
           	newstate = 3+3*(rand()<.5)*(twoTrialTypes==1); % either 3 or 6
        end
        
        earnings(thisAgent) = earnings(thisAgent) + rewards(newstate,thisAgent);
        
        index = (1:3)+3*(newstate>3)*(twoTrialTypes==1);
        re = rewards(index,thisAgent) + round(randn(length(index),1)*stdShift);
        re(re>rewardRange_hi) = 2*rewardRange_hi-re(re>rewardRange_hi);
        re(re<rewardRange_lo) = 2*rewardRange_lo-re(re<rewardRange_lo);
        rewards(index,thisAgent) = re;
        
        % Are we in a critical trial?
%         if any(criticalTrials(:,1) == thisRound)
%             newstate = 6; % force to green triangle
%             newstate_feature = features(newstate,trialType);
%             reward = rewards(thisRound,trialType,newstate_feature,magic);
%             
%             % Polarize reward
%             d = (reward > 0)*2-1;
%             boost = 2;
%             reward = reward+boost*d;
%             if (reward > rewardRange_hi), reward = rewardRange_hi*d;
%             elseif (reward < rewardRange_lo), reward = abs(rewardRange_lo)*d;
%             end
%         else
%             newstate = transitions(thisRound,choice,magic);
%             newstate_feature = features(newstate,trialType);
%             reward = rewards(thisRound,trialType,newstate_feature,magic);
%         end
%         
        
        % Update previous choice
%         prevChoice = choice;
%         prevType = trialType;
    end
end
end