function [exp, D, choices, PEs, critTrials] = LearningTask(SID, SINIT, seqNum, runNum)
%-------------------------------------------------------------------------
% 2 Mar 2015
% mhenry@fas.harvard.edu
%
% Experiment Name:  Learning Task
%
%
%
% Total TRs/run: 4 dummy TRs + 291 max real TRs = 295
% BE CAREFUL DON'T REGENERATE PARS WITHOUT CHECKING!
%
% Total Time: 9.7 minutes
%
% Num Runs: 8
% randperm(8)
%
% run like:  LearningTask(subID,initials,sequenceNum,runNum)
%
% LearningTask('CUSH_LEARN_01', 'meh', 4, 1)
% LearningTask('CUSH_LEARN_01', 'meh', 3, 2)
% LearningTask('CUSH_LEARN_01', 'meh', 1, 3)
% LearningTask('CUSH_LEARN_01', 'meh', 2, 4)

%-------------------------------------------------------------------------
%try

clc
commandwindow
numScreens = 0;


rng('default');
rng('shuffle');


%-------------------------------------------------------------------------
%% experiment data
%-------------------------------------------------------------------------
disp('set up experiment data')

% basic exp info
exp.name                = 'LearningTask';
exp.sid                 = SID;
exp.sinit               = SINIT;
exp.runNum              = runNum;
exp.seqNum              = seqNum;


% set up parameters
exp.dispSizeRatio       = .55;

[xres,yres] = Screen('windowsize',0);
exp.xcenter = xres/2;
exp.ycenter = yres/2;

% Number of sides for our triangle
numSides = 3;

% Angles at which our polygon vertices endpoints will be. We start at zero
% and then equally space vertex endpoints around the edge of a circle. The
% polygon is then defined by sequentially joining these end points.
anglesDeg = linspace(30, 390, numSides + 1);
anglesRad = anglesDeg * (pi / 180);
radius = 100;

% X and Y coordinates of the points defining out polygon, centred on the
% centre of the screen
yPosVector = sin(anglesRad) .* radius + exp.ycenter +150;
xPosVector = cos(anglesRad) .* radius + exp.xcenter;


% response, based on task
exp.respKeys            = [KbName('1!') KbName('2@') ]; % KbName('3') KbName('4') KbName('1!') KbName('2@'), KbName('3#') KbName('4$')];
exp.triggerKey          = [KbName('=+') KbName('+')];
exp.quitKey             = KbName('q');
exp.keyList=zeros(1,256); % all keys ignored
exp.keyList(exp.respKeys)=1;
exp.keyList(exp.triggerKey)=1;
exp.deviceNumber          = getDeviceNumber();
exp.keyleft             = [KbName('1') KbName('1!')];
exp.keyright            = [KbName('2') KbName('2@')];

% start and stop a response Que, just to get this loaded into memory
KbQueueCreate(exp.deviceNumber, exp.keyList);
KbQueueStart();
KbQueueCheck();
KbQueueRelease();



%% SETTING UP

load(fullfile('DataFiles',exp.sid,['settings_' exp.sid '.mat']));




numRounds=50;
numCrits=length(criticalTrials(exp.runNum,:));

numBeforeCrit = 3;
probBeforeCrit = 0.8;

choices = zeros(numRounds,10);

%% GET TIMING INFO

% what round are we on, globally?
runIndex = 50*(exp.runNum-1);

% read in the par file for onsets and nulls
[ons condNum dur condLabel] = textread(fullfile('Par',['sequence_' num2str(exp.seqNum) '.par']), '%f%f%f%s');


D.eventStartTime = [];
D.eventEndTime = [];
D.eventCond = [];
endTimeHelper = 0;

for i=1:length(condNum)
    
    D.eventCond = [D.eventCond condNum(i)];
    D.eventStartTime = [D.eventStartTime endTimeHelper];
    D.eventEndTime   = [D.eventEndTime   dur(i)+endTimeHelper];
    endTimeHelper = D.eventEndTime(end);
    
end

% sanity check!
for i = 1:length(ons)
    if D.eventStartTime(i) ~= ons(i)
        keyboard
    end
end

%%  CRITICAL TRIALS

critTrials = criticalTrials(exp.runNum,:);
numCrits = length(critTrials);

lastAction = 0;
lastType = 0;
inCrit = 0;


%% TRIAL TYPES (all 2 right now)

trialTypes = zeros(1,numRounds);
for i = 1:numRounds
    trialTypes(i) = TrialType_color;
end


%% Q VALUES

PEs = zeros(numRounds,4);
Q_MF = zeros(numRounds,numActions);
Q_States = zeros(numRounds,numLetterStates);
Q_Goal = zeros(numRounds,numFeatures);

%-------------------------------------------------------------------------
%% set up psychtoolbox windows
%-------------------------------------------------------------------------

disp('set up ptb windows')

Screen('Preference','SkipSyncTests', 1)
w = Screen('OpenWindow',0,[225 225 225],[]);

%-------------------------------------------------------------------------
%% save the .mat file with all the planned presentations
%-------------------------------------------------------------------------
savePath = fullfile('DataFiles', SID);
mkdir(pwd, savePath);
save(fullfile(savePath, [SID '-' datestr(now, 30) '.mat']), 'exp', 'D');

%-------------------------------------------------------------------------
%% print out experiment information:
%-------------------------------------------------------------------------
clc
disp(sprintf('\n'))
disp(sprintf('Experiment Name: %s\n', exp.name))
disp(sprintf('Num Rounds: %d\n', numRounds))
disp(sprintf('\n'))
disp(sprintf('Total TRs: %d\n', D.eventEndTime(end)/2))
disp(sprintf('Total Time: %1.2f\n', D.eventEndTime(end)/60))
disp(sprintf('\n'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RUN IT!
HideCursor
Screen('TextSize', w, 30);


% -----------------
% TASK INSTRUCTIONS:
% -------------------
Screen('FillRect', w, [255 255 255]);
text = 'Press ''1'' to choose the number on the left,';
[nr obr] = Screen('TextBounds', w, text);
rect = CenterRectOnPoint(obr, exp.xcenter, exp.ycenter - 100);
Screen('DrawText', w, text, rect(1), rect(2));

text = 'or to click on the colored square.';
[nr obr] = Screen('TextBounds', w, text);
rect = CenterRectOnPoint(obr, exp.xcenter, exp.ycenter);
Screen('DrawText', w, text, rect(1), rect(2));

text = 'Press ''2'' to choose the number on the right.';
[nr obr] = Screen('TextBounds', w, text);
rect = CenterRectOnPoint(obr, exp.xcenter, exp.ycenter+100);
Screen('DrawText', w, text, rect(1), rect(2));
Screen('Flip', w, [], 1);

% --------
% TRIGGER
% --------



% Wait for trigger (checks for '=' in buffer)
%[triggerTime, detectTime] = waitForTrigger(exp);
startTime=GetSecs();
%startDelayMs=(detectTime-triggerTime);


%% MAIN LOOP

score = zeros(numRounds+1,1);
score(1) = startScore;
spoiled = zeros(numRounds+1,1);



KbQueueCreate(exp.deviceNumber, exp.keyList);
KbQueueStart();
current = 1;
actualEvent = 1;
currRand = rand;
timeThruCounter = 1;

while(1)
    
    if((GetSecs-startTime) > D.eventStartTime(actualEvent))
        
        Screen('FillRect', w, [255 255 255]);
        Screen('FillOval', w, [255 255 255], CenterRectOnPoint([0 0 10 10], exp.xcenter, exp.ycenter));
        Screen('FrameOval', w, [0 0 0], CenterRectOnPoint([0 0 10 10], exp.xcenter, exp.ycenter),2);
        
        
        while (GetSecs-startTime)<D.eventEndTime(actualEvent)
            
            if spoiled(current) == 0
                
                keyPressThisEvent=0;
                
                %NULL
                if D.eventCond(actualEvent) == 0
                    
                    % graying out the background for "calculating reward"
                    if (actualEvent > 1 && D.eventCond(actualEvent-1)==2)
                        Screen('FillRect', w, [200 200 200]);
                        Screen('FrameOval', w, [0 0 0], CenterRectOnPoint([0 0 10 10], exp.xcenter, exp.ycenter),2);
                        
                        if lastWasCrit == 1
                            % show gray square for imagery decoding
                            Screen('FillOval', w, [150 150 150], CenterRectOnPoint([0 0 100 100], exp.xcenter, exp.ycenter),2);
                        else
                            switch choices(current,S2)
                                case 1
                                    Screen('FillRect', w, [0 0 255], CenterRectOnPoint([0 0 100 100], exp.xcenter-150, exp.ycenter-150),2);
                                case 2
                                    Screen('FillOval', w, [255 0 0], CenterRectOnPoint([0 0 100 100], exp.xcenter+150, exp.ycenter-150),100);
                                case 3
                                    Screen('FillRect', w, [0 0 255], CenterRectOnPoint([0 0 100 100], exp.xcenter-150, exp.ycenter-150),2);
                                case 4
                                    Screen('FillOval', w, [255 0 0], CenterRectOnPoint([0 0 100 100], exp.xcenter+150, exp.ycenter-150),100);
                                case 5
                                    Screen('FillPoly', w, [0 255 0], [xPosVector;yPosVector]',1);
                            end
                        end
                        
                        if timeThruCounter == 1
                        Screen('TextSize', w, 42);
                        text2 = 'Calculating your reward...';
                        [nr obr] = Screen('TextBounds', w, text2);
                        rect = CenterRectOnPoint(obr, exp.xcenter, exp.ycenter + 250);
                        end
                        
                        Screen('DrawText', w, text2, rect(1), rect(2));
                        Screen('Flip', w,[],1);
                        
                        if timeThruCounter ==1
                            D.onsetTimeStamp(actualEvent) = GetSecs();
                            D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                        end
                        
                    else
                        % this is the null between rounds
                        Screen('FillRect', w, [255 255 255]);
                        Screen('FrameOval', w, [0 0 0], CenterRectOnPoint([0 0 10 10], exp.xcenter, exp.ycenter),2);
                        Screen('Flip', w,[],1);
                        
                        if timeThruCounter ==1
                            D.onsetTimeStamp(actualEvent) = GetSecs();
                            D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                        end
                    end
                    timeThruCounter = timeThruCounter + 1;
                    
                elseif D.eventCond(actualEvent) == 1
                    
                    % LEVEL ONE
                    if timeThruCounter==1
                        
                        currentOptionScreen = optionNumbers(current);
                        currentTrialType = trialTypes(current);
                        currentOption1 = numToOptions(currentOptionScreen,1);
                        currentOption2 = numToOptions(currentOptionScreen,2);
                        
                        %  critical trails
                        inCrit = 0;
                        lastWasCrit = 0;
                        for i = 1:length(critTrials)
                            if current == critTrials(i) %%|| current == critTrials_incog(i)
                                inCrit = 1;
                            elseif (current - 1) == critTrials(i) %%|| (current - 1) == critTrials_incog(i)
                                currentTrialType = trialTypes(current-1);
                                currentOption1 = getCorrespondingAction(lastAction,trialTypes(current-1));
                                currentOption2 = getOtherOption(currentOption1,currentTrialType);
                                currentOptionScreen = optionsToNum(min(currentOption1,currentOption2),max(currentOption1,currentOption2));
                                lastWasCrit = 1;
                            end
                        end
                        
                        % fMRI crit switch
                        for i = 1:numBeforeCrit
                            for j = 1:length(critTrials)
                                if (current+i) == critTrials(j)
                                    if currRand<probBeforeCrit
                                        currentOption1 = getCorrespondingAction(numToOptions(optionNumbers(current+i),1),trialTypes(current+i));
                                        currentOption2 = getCorrespondingAction(numToOptions(optionNumbers(current+i),2),trialTypes(current+i));
                                    end
                                end
                            end
                        end
                        
                        choices(current,Type) = currentTrialType;
                        
                        if currRand < 0.5
                            text1 = num2str(currentOption1);
                            text2 = num2str(currentOption2);
                            switched = 0;
                        else
                            text1 = num2str(currentOption2);
                            text2 = num2str(currentOption1);
                            switched = 1;
                        end
                        
                        choices(current,optNum) = currentOptionScreen;
                        
                    end
                    
                    % display the two choices
                    Screen('TextSize', w, 100);
                    [nr, obr] = Screen('TextBounds', w, text1);
                    rect = CenterRectOnPoint(obr, exp.xcenter-100, exp.ycenter);
                    Screen('DrawText', w, text1, rect(1), rect(2));
                    
                    [nr, obr] = Screen('TextBounds', w, text2);
                    rect = CenterRectOnPoint(obr, exp.xcenter+100, exp.ycenter);
                    Screen('DrawText', w, text2, rect(1), rect(2));
                    
                    
                    Screen('FrameOval', w, [0 0 0], CenterRectOnPoint([0 0 10 10], exp.xcenter, exp.ycenter),2);
                    Screen('Flip', w,[],1);
                    
                    if timeThruCounter == 1
                        D.onsetTimeStamp(actualEvent) = GetSecs();
                        D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                    end
                    
                    timeThruCounter = timeThruCounter + 1;
                elseif  D.eventCond(actualEvent)==2
                    
                    % if spoiled trial, yell at ppt, and wait until next trial
                    % begins
                    if D.keyPressed2(actualEvent-1)==0
                        spoiled(current) = 1;
                        Screen('TextSize', w, 64);
                        text = 'TOO SLOW!!';
                        [nr obr] = Screen('TextBounds', w, text);
                        rect = CenterRectOnPoint(obr, exp.xcenter, exp.ycenter - 100);
                        Screen('DrawText', w, text, rect(1), rect(2));
                        Screen('Flip', w,[],1);
                    else
                        % LEVEL TWO
                        
                        %set everything only once, to be safe
                        if timeThruCounter ==1
                            
                            choices(current,rt1) = D.respRT2(actualEvent-1);
                            
                            if D.respNum2(actualEvent-1) == 1
                                if switched == 0
                                    choices(current,Action) = currentOption1;
                                    unchosen = currentOption2;
                                else
                                    choices(current,Action) = currentOption2;
                                    unchosen = currentOption1;
                                end
                            elseif D.respNum2(actualEvent-1) == 2
                                if switched == 0
                                    choices(current,Action) = currentOption2;
                                    unchosen = currentOption1;
                                else
                                    choices(current,Action) = currentOption1;
                                    unchosen = currentOption2;
                                end
                            end
                            
                            % if in crit trial, force the transition
                            if (inCrit ==1)
                                choices(current,S2) = 5;
                            else
                                choices(current,S2) = transitions(choices(current,Action),current+runIndex);
                            end
                        end
                        
                        %  DISPLAY LEVEL TWO
                        
                        if lastWasCrit == 1
                            % show gray square for imagery decoding
                            Screen('FillOval', w, [150 150 150], CenterRectOnPoint([0 0 100 100], exp.xcenter, exp.ycenter),2);
                            Screen('Flip', w,[],1);
                            
                            if timeThruCounter ==1
                                D.onsetTimeStamp(actualEvent) = GetSecs();
                                D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                            end
                        else
                            switch choices(current,S2)
                                case 1
                                    % TO DO : show blue square
                                    currFeature = 1;
                                    Screen('FillRect', w, [0 0 255], CenterRectOnPoint([0 0 100 100], exp.xcenter-150, exp.ycenter-150),2);
                                    Screen('Flip', w,[],1);
                                    
                                    if timeThruCounter ==1
                                        D.onsetTimeStamp(actualEvent) = GetSecs();
                                        D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                                    end
                                    
                                case 2
                                    % TO DO: show red circle
                                    currFeature = 2;
                                    Screen('FillOval', w, [255 0 0], CenterRectOnPoint([0 0 100 100], exp.xcenter+150, exp.ycenter-150),100);
                                    Screen('Flip', w,[],1);
                                    
                                    if timeThruCounter ==1
                                        D.onsetTimeStamp(actualEvent) = GetSecs();
                                        D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                                    end
                                    
                                case 3
                                    % TO DO: show blue square
                                    if (currentTrialType == TrialType_shape)
                                        currFeature = 2;
                                    else
                                        currFeature = 1;
                                    end
                                    Screen('FillRect', w, [0 0 255], CenterRectOnPoint([0 0 100 100], exp.xcenter-150, exp.ycenter-150),100);
                                    Screen('Flip', w,[],1);
                                    
                                    if timeThruCounter ==1
                                        D.onsetTimeStamp(actualEvent) = GetSecs();
                                        D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                                    end
                                    
                                case 4
                                    % TO DO: show red circle
                                    currFeature = 2;
                                    Screen('FillOval', w, [255 0 0], CenterRectOnPoint([0 0 100 100], exp.xcenter+150, exp.ycenter-150),100);
                                    Screen('Flip', w,[],1);
                                    
                                    if timeThruCounter ==1
                                        D.onsetTimeStamp(actualEvent) = GetSecs();
                                        D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                                    end
                                    
                                case 5
                                    % TO DO: show green triangle
                                    currFeature = 3;
                                    Screen('FillPoly', w, [0 255 0], [xPosVector;yPosVector]',1);
                                    Screen('Flip', w,[],1);
                                    
                                    if timeThruCounter ==1
                                        D.onsetTimeStamp(actualEvent) = GetSecs();
                                        D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                                    end
                                    
                            end
                        end
                    end
                    timeThruCounter = timeThruCounter + 1;
                    
                elseif  D.eventCond(actualEvent)==3
                    
                    % set everything only once, to be safe
                    if timeThruCounter ==1
                        %get 2nd level rt
                        if D.eventCond(actualEvent-1)==0
                            % if last was null, get RT from 2 events ago
                            choices(current,rt2) = D.respRT2(actualEvent-2);
                        else
                            % else get RT from last event
                            choices(current,rt2) = D.respRT2(actualEvent-1);
                        end
                        
                        % get reward
                        choices(current,R) = winsArray(currFeature,currentTrialType,current+runIndex);
                        
                        %set crit trial reward
                        if inCrit == 1
                            if evenCrit(i) == 1
                                choices(current,R) = (Q_MF(choices(current,Action)) + Q_Goal(currFeature))/2;
                            else
                                choices(current,R) = Q_States(choices(current,S2));
                            end
                            choices(current,R) = round(choices(current,R));
                        end
                        
                        %update score
                        score(current+1) = score(current) + choices(current,R);
                    end
                    
                    % display current total score also
                    Screen('TextSize', w, 64);
                    
                    text1 = num2str(choices(current,R));
                    [nr obr] = Screen('TextBounds', w, text1);
                    rect = CenterRectOnPoint(obr, exp.xcenter, exp.ycenter - 100);
                    Screen('DrawText', w, text1, rect(1), rect(2));
                    
                    
                    text1 = 'Total Score:';
                    [nr obr] = Screen('TextBounds', w, text1);
                    rect = CenterRectOnPoint(obr, exp.xcenter-150, exp.ycenter + 100);
                    Screen('DrawText', w, text1, rect(1), rect(2));
                    
                    text2 = num2str(score(current+1));
                    [nr obr] = Screen('TextBounds', w, text2);
                    rect = CenterRectOnPoint(obr, exp.xcenter+150, exp.ycenter + 100);
                    Screen('DrawText', w, text2, rect(1), rect(2));
                    Screen('Flip', w,[],1);
                    
                    if timeThruCounter == 1
                        D.onsetTimeStamp(actualEvent) = GetSecs();
                        D.actualEventTime(actualEvent) = D.onsetTimeStamp(actualEvent)-startTime;
                        
                        
                        choices(current,roundNum) = current;
                        choices(current,scr) = score(current+1);
                        
                        lastAction = choices(current,Action);
                        
                        
                        % replicate last trial's Q vals
                        if current > 1
                            Q_MF(current,:) = Q_MF(current-1,:);
                            Q_States(current,:) = Q_States(current-1,:);
                            Q_Goal(current,:) = Q_Goal(current-1,:);
                        end
                        
                        % write down prediction errors
                        PEs(current,1) = Q_States(current,choices(current,S2)) - Q_MF(current,choices(current,Action));%deltaB
                        PEs(current,2) = choices(current, R) - Q_States(current,choices(current,S2)); %deltaA
                        PEs(current,3) = choices(current, R) - Q_MF(current,choices(current,Action)); %??
                        PEs(current,4) = choices(current, R) - Q_Goal(currFeature); %deltaC
                        
                        
                        
                        % update only those states we reached this trial
                        Q_MF(current,choices(current,Action)) = Q_MF(current,choices(current,Action)) + lr*(Q_States(current,choices(current,S2)) - Q_MF(current,choices(current,Action)));
                        del = choices(current, R) - Q_States(current,choices(current,S2));
                        Q_States(current,choices(current,S2)) = Q_States(current,choices(current,S2)) + lr*del;
                        Q_MF(current,choices(current,Action)) = Q_MF(current,choices(current,Action)) + lr*elig*del;
                        Q_Goal(current,currFeature) = Q_Goal(current,currFeature) + lr*(choices(current,R) - Q_Goal(current,currFeature));
                    end
                    
                    timeThruCounter = timeThruCounter + 1;
                end
            else
                % if it is a spoiled round, make sure you update the score
                % for the next round so it's not zero
                score(current+1) = score(current);
            end
        end
    end
    
    % check for response
    
    [pressed, firstPress, firstRelease, lastPress, lastRelease]=KbQueueCheck();
    if (pressed==1)
        keyPressThisEvent=1;
        
        try
            D.keyPressed2(actualEvent)=1;
            whichKey=find(firstPress);
            whichKey=whichKey(1);
            D.respKey2(actualEvent)=whichKey(1);
            D.respNum2(actualEvent)=find(exp.respKeys==D.respKey2(actualEvent));
            D.respRT2(actualEvent)=(firstPress(whichKey)-D.onsetTimeStamp(actualEvent))*1000;
            
            
        catch
            D.keyPressed2(actualEvent)=0;
            D.respKey2(actualEvent)=0;
            D.respNum2(actualEvent)=0;
            D.respRT2(actualEvent)=0;
            
            
        end
        
        KbQueueRelease();
        KbQueueCreate(exp.deviceNumber, exp.keyList);
        KbQueueStart();
        
    elseif keyPressThisEvent==0
        D.keyPressed2(actualEvent)=0;
        D.respKey2(actualEvent)=0;
        D.respNum2(actualEvent)=0;
        D.respRT2(actualEvent)=0;
        
        
    end
    
    startScore = score(current);
    
    % resave behavioral file each time, just in case
    save(fullfile('DataFiles',SID, [SID '.MFMB.Seq' num2str(exp.seqNum) '.Run' num2str(exp.runNum) '.mat']), 'exp', 'D','choices','PEs','critTrials','Q_MF','Q_States','Q_Goal','actualEvent');
    
    % update the score, so that the score carries over between runs
    save(fullfile('DataFiles',exp.sid,['settings_' exp.sid '.mat']), 'startScore','-append');
    
    % increment event
    actualEvent = actualEvent+1;
    
    % reset this
    timeThruCounter = 1;
    
    
    % if we're at the last event end, wait until the end duration
    % other wise, listen for a response until it's time for the next
    % event...
    if actualEvent > length(D.eventCond)
        while (GetSecs-startTime) < D.eventEndTime(actualEvent-1); end
        break;
    end
    
    % if its time to start a new round, increment round number
    if (actualEvent>6 && D.eventCond(actualEvent) == 1)
        current = current + 1;
        % and change the rand for display order on event 1 of round, which
        % was getting messed up in the while loop
        currRand = rand;
        
        %build in a fail safe for quitting the task
        if current > numRounds
            while (GetSecs-startTime) < D.eventEndTime(actualEvent-1); end
        break;
        end
            
    end
    
end

sca;
%ActualScanTime=GetSecs()-triggerTime;
%fprintf('\nActual Scan Time = %4.1f\n', ActualScanTime);


%-------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayRect = calculateDisplayRect(imH, imW, dispSize, CenterX, CenterY)
% given an arbitrary image size
% generate a rect size, Centered on the Screen, that makes the maximum
% dimension equal to N pixels


aspectRatio = imH/imW;

if aspectRatio == 1
    % square
    newHeight = dispSize;
    newWidth = dispSize;
    
elseif aspectRatio > 1
    % tall
    newHeight = dispSize;
    newWidth = dispSize/aspectRatio;
    
else aspectRatio < 1
    % fat
    newWidth = dispSize;
    newHeight = dispSize * aspectRatio;
    
end

rect = round([0 0 newWidth newHeight]);
displayRect = CenterRectOnPoint(rect, CenterX, CenterY);




%-------------------------------------------------------------------------
function displayRect = calculateDisplayRect_rectScaling(imH, imW, dispSize, CenterX, CenterY)

aspectRatio = imW/imH;
if aspectRatio == 1
    % square
    newHeight = sqrt((dispSize^2)/2);
    newWidth = newHeight;
else
    newHeight = sqrt(dispSize^2 / (aspectRatio^2+1));
    newWidth = aspectRatio * newHeight;
    
end
rect = round([0 0 newWidth newHeight]);
displayRect = CenterRectOnPoint(rect, CenterX, CenterY);






%-------------------------------------------------------------------------
function [keyIsDown,secs,keyCode] = KbCheckM(deviceNumber)
% [keyIsDown,secs,keyCode] = KbCheckM(deviceNumber)
% check all attached keyboards for keys that are down
%
% Tim Brady and Oliver Hinds
% 2007-07-18

if(~IsOSX)
    if exist('deviceNumber', 'var')
        [keyIsDown, secs, keyCode] = KbCheck(deviceNumber);
    else
        [keyIsDown, secs, keyCode] = KbCheck();
    end
    return
    %error('only call this function on mac OS X!');
end

if nargin==1
    [keyIsDown,secs,keyCode]= PsychHID('KbCheck', deviceNumber);
elseif nargin == 0
    keyIsDown = 0;
    keyCode = logical(zeros(1,256));
    
    invalidProducts = {'USB Trackball'};
    devices = PsychHID('devices');
    for i = 1:length(devices)
        if(strcmp(devices(i).usageName, 'Keyboard') )
            for j = 1:length(invalidProducts)
                if(~(strcmp(invalidProducts{j}, devices(i).product)))
                    [down,secs,codes]= PsychHID('KbCheck', i);
                    codes(83) = 0;
                    
                    keyIsDown = keyIsDown | down;
                    keyCode = codes | keyCode;
                end
            end
        end
    end
elseif nargin > 1
    error('Too many arguments supplied to KbCheckM');
end

return

%---------------------------------------------
% wait for key to start initiate trial
%---------------------------------------------
function waitForKey
make sure no key is currently pressed
[keyIsDown,secs,keyCode]=KbCheck();
while(keyIsDown)
    [keyIsDown,secs,keyCode]=KbCheck();
end
get keyquit
while(1)
    [keyIsDown,secs,keyCode]=KbCheck();
    if keyIsDown
        break;
    end
end

% =========================================================================
% =========================================================================
function [triggerTime, detectTime] = waitForTrigger(exp)

% alvarez@wjh.harvard.edu
% 3/1/11
% wait for trigger using PTB3 function KbQueueCheck
%
% returns
%   triggerTime: clock time when first trigger event was entered in key buffer
%   detectTime: click time when first trigger event was registered
%
% I suspect that detectTime-triggerTime is sometimes greater than the
% amount of time the button box sends "button press response"
%
% Using KbQueueCheck enables you can "capture" that missed event by storing
% it in an Queue...

% specify which keys you want to create a cue for
keyList=zeros(1,256); % all keys ignored
keyList([KbName('=+') KbName('+')])=1; % listen to trigger keys

% % create a cue
% deviceNumber=GetKeyboardIndices; % see if you have multiple keyboards connected
% deviceNumber=deviceNumber(1); % MATLAB lists peripheral keyboards first (i.e, things plugged into USB)
%quickDeviceFindChecker

KbQueueCreate(exp.deviceNumber, keyList);

% inform user that we're now waiting for the trigger
disp('waiting for trigger');

% start queueing responses
KbQueueStart();

% initial check for key
[pressed, firstPress, firstRelease, lastPress, lastRelease]=KbQueueCheck();

% wait for the keypress
while ~pressed % wait for keypresses for this many seconds
    [pressed, firstPress, firstRelease, lastPress, lastRelease]=KbQueueCheck();
end
detectTime=GetSecs(); % time when the keypress was registered by this for loop

whichKey=find(firstPress); % check which key was pressed
whichKey=whichKey(1); % if multiple keys pressed, only use first
triggerTime=firstPress(whichKey); % time when the keypress was registered in the buffer...

% release the KbQueue
KbQueueRelease();
disp('triggered');

% =========================================================================
% =========================================================================
function deviceNumber=getDeviceNumber

% first check for the scanner buttonBox
buttonBoxName='Serial+Keyboard+Mouse+Joystick';
[keyboardIndices, productNames, allInfos] = GetKeyboardIndices();
whichExternal=find(strcmp(buttonBoxName,productNames));

% if not connected to the scanner, look for apple internal
if (isempty(whichExternal))
    buttonBoxName='Apple Internal Keyboard / Trackpad';
    [keyboardIndices, productNames, allInfos] = GetKeyboardIndices();
    whichExternal=find(strcmp(buttonBoxName,productNames));
end


if (isempty(whichExternal))
    sca;
    clc;
    fprintf('looking for product named ''%s''\n\n',buttonBoxName);
    disp('None of these product names match your button box name!');
    for i=1:length(productNames)
        fprintf('%s\n',productNames{i});
    end
    fprintf('\nYour button box name ''%s'' might be outdated.\n',buttonBoxName)
    fprintf('If so, find the new button box name in the list above.\n');
    fprintf('Then modify your code to use this new name.\n');
    fprintf('Search for buttonBoxName in your code, and replace\n');
    fprintf('the old button box name with the new one.\n\n');
    error('button box not found!');
end
deviceNumber = keyboardIndices(whichExternal);

keyboardIndices
productNames
deviceNumber

