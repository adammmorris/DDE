%% Script to set global structure for each participant%%
function [] = generateSettings(subID)
%% SETTING UP

numRounds=400;
numCrits=56;
numRuns = 8;

[criticalTrials] = generateCritNumbers(numRounds,numCrits,numRuns);
criticalTrials = sort(criticalTrials,2);

evenCrit = zeros(numRuns,numCrits/numRuns);
for i =1:numRuns
    for j = 1:numCrits/numRuns
        if (mod(i,2)==0 || mod(j,2)==0) && ~(mod(i,2)==0 && mod(j,2)==0)
            evenCrit(i,j)=1;
        end
    end
end

numBeforeCrit = 3;
probBeforeCrit = 0.8;


Type = 1;
Goal = 2;
optNum = 3;
Action = 4;
S2 = 5;
R = 6;
rt1 = 7;
rt2 = 8;
scr = 9;
roundNum = 10;

numOptionScreens = 10;
numActions = 5;
numLetterStates = 5;
numFeatures = 3;
numTrialTypes = 2;
currentOptionScreen = 0;
currentTrialType = 2;
currentGoal = 0;
TrialType_shape = 1;
TrialType_color = 2;





%% NUMBER/OPTION MAPPING

numToOptions = zeros(numOptionScreens,2);
for i = 1:numOptionScreens
    if i < 5
        numToOptions(i,1) = 1;
        switch i
            case 1
                numToOptions(i,2) = 2;
                
            case 2
                numToOptions(i,2) = 3;
                
            case 3
                numToOptions(i,2) = 4;
                
            case 4
                numToOptions(i,2) = 5; 
        end
    elseif i < 8
        numToOptions(i,1) = 2;
        switch i
            case 5
                numToOptions(i,2) = 3;
                
            case 6
                numToOptions(i,2) = 4;
                
            case 7
                numToOptions(i,2) = 5;
                
        end
    elseif i < 10
        numToOptions(i,1) = 3;
        switch i
            case 8
                numToOptions(i,2) = 4;
                
            case 9
                numToOptions(i,2) = 5;
                
        end
    else
        numToOptions(i,1) = 4;
        numToOptions(i,2) = 5;
    end
end



optionsToNum = zeros(4,5);

optionsToNum(1,2) = 1;
optionsToNum(1,3) = 2;
optionsToNum(1,4) = 3;
optionsToNum(1,5) = 4;
optionsToNum(2,3) = 5;
optionsToNum(2,4) = 6;
optionsToNum(2,5) = 7;
optionsToNum(3,4) = 8;
optionsToNum(3,5) = 9;
optionsToNum(4,5) = 10;


%% TRANSITIONS


baseprob = .7;

transitionsMatrix = zeros(numActions,numLetterStates);
mainTransition = 1-((numRounds*(1-baseprob)-numCrits)/(numRounds - numCrits));
otherTransition = 1 - mainTransition;

for i = 1:numActions
    for j = 1:numLetterStates
        if i == j
            transitionsMatrix(i,j) = mainTransition;
        elseif j == 5
            transitionsMatrix(i,j) = otherTransition;
        else
            transitionsMatrix(i,j) = 0;
        end
    end
end


transitions = zeros(numActions,numRounds);
for thisAction = 1:numActions
    for thisRound = 1:numRounds
        randVal = rand;
        if randVal < transitionsMatrix(thisAction,1)
            transitions(thisAction,thisRound) =1;
        elseif randVal < (transitionsMatrix(thisAction,1) + transitionsMatrix(thisAction,2))
            transitions(thisAction,thisRound) = 2;
        elseif randVal < (transitionsMatrix(thisAction,1) + transitionsMatrix(thisAction,2) + transitionsMatrix(thisAction,3))
            transitions(thisAction,thisRound) = 3;
        elseif randVal < (transitionsMatrix(thisAction,1) + transitionsMatrix(thisAction,2) + transitionsMatrix(thisAction,3) + transitionsMatrix(thisAction,4))
            transitions(thisAction,thisRound) = 4;
        else
            transitions(thisAction,thisRound) = 5;
        end
    end
end

%% TRIAL TYPES (all 2 right now)

trialTypes = zeros(1,numRounds);
for i = 1:numRounds
    trialTypes(i) = TrialType_color;
end

%% OPTION NUMBERS

optionNumbers = zeros(1,numRounds);
for i = 1:numRounds
    opt1 = round(rand*3)+1;
    opt2 = getOtherOption(opt1,trialTypes(i));
    optionNumbers(i) = optionsToNum(min(opt1,opt2),max(opt1,opt2));
end


%% REWARDS

winsArray = zeros(numFeatures,numTrialTypes,numRounds);
rewardRange_hi = 10;
rewardRange_lo = -10;
stdShift = 4;

for currFeature=1:numFeatures
    for currTrialType=1:numTrialTypes
        winsArray(currFeature,currTrialType,1)= round(rand*(rewardRange_hi+abs(rewardRange_lo)) - abs(rewardRange_lo));
        for currRound = 1:numRounds
            if currTrialType == trialTypes(currRound)
                u1 = rand;
                u2 = rand;
                standardNormal = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
                re = winsArray(currFeature,currTrialType,currRound) + round(standardNormal*stdShift);
                
                if re > rewardRange_hi
                    re = 2*rewardRange_hi - re;
                end
                if re < rewardRange_lo
                    re = 2*rewardRange_lo - re;
                end
                
                winsArray(currFeature,currTrialType,currRound+1) = re;
            else
                winsArray(currFeature,currTrialType,currRound+1) = winsArray(currFeature,currTrialType,currRound);
            end
        end
    end
end



%% Q STUFF
lr = .2;
elig = 1;
startScore = 40;


%% save
savePath = fullfile('DataFiles', subID);
mkdir(pwd, savePath);
save(fullfile(savePath,['settings_' subID '.mat']));