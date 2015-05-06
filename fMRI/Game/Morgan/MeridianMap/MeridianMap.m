function MeridianMap(SID, SINIT, runNum)
%-------------------------------------------------------------------------
% 1 October 2009
% tkonkle@mit.edu

% Experiment Name:  MeridianMap
% 
% Num Conditions:   2
% 
% Blocks Per Cond:  5 
% 
% 
% Total TRs/run:    126
%
% Total Time:       4.2


% design:
% horizontal and vertical meridian markers
% alternate them within a block
% 12 seconds on, 12 seconds off, 8hz flicker

% demo
% MeridianMap('CUSH_LEARN_TEST', 'meh', 1)
% MeridianMap('CUSH_LEARN_01', 'meh', 2)

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

prefs.name                = 'MeridianMap';
prefs.sid                 = SID;
prefs.sinit               = SINIT;
prefs.runNum              = runNum;

% set up parameters
prefs.numConds            = 2;
prefs.numBlocksPerCond    = 5; 
prefs.timePerBlock        = 12; %sec
prefs.timePerImage        = .125; % sec
prefs.timeBetweenImages   = 0; % sec
prefs.numImagesPerBlock 	= prefs.timePerBlock/prefs.timePerImage; 
prefs.timePerRestBlock    = 12; % sec
prefs.imageDisplaySizePx  = 700;
prefs.quitKey             = KbName('escape');
prefs.respKeys            = [KbName('1') KbName('2') KbName('3') KbName('4') KbName('1!') KbName('2@'), KbName('3#') KbName('4$')];
prefs.triggerKey          = [KbName('=+') KbName('+')];
prefs.keyList             =zeros(1,256); % all keys ignored
prefs.keyList(prefs.respKeys)=1;
%prefs.deviceNumber        = GetKeyboardIndices(); 
%prefs.deviceNumber        = prefs.deviceNumber(1);
prefs.deviceNumber         = getDeviceNumber();


% start and stop a response Que, just to get this loaded into memory
KbQueueCreate(prefs.deviceNumber, prefs.keyList);
KbQueueStart();
KbQueueCheck();
KbQueueRelease();

% which images to use:
prefs.condLabel = {'Horizontal', 'Vertical'};


% construct block order
% alternate block order

blockOrderHelper = mod(1:prefs.numConds*prefs.numBlocksPerCond, prefs.numConds)+1;

prefs.blockOrder = zeros(1, prefs.numBlocksPerCond*prefs.numConds*2+1);
prefs.blockOrder(2:2:end) = blockOrderHelper;
prefs.numRestBlocks = sum(prefs.blockOrder == 0);
prefs.totalTime = prefs.numRestBlocks * prefs.timePerRestBlock + prefs.numBlocksPerCond * prefs.timePerBlock * prefs.numConds;
prefs.totalTRs = prefs.totalTime / 2;


%-------------------------------------------------------------------------
%% set up event timing
%-------------------------------------------------------------------------

% critical fields:
% D.eventStartTime
% D.eventCond <-- assume 0 is fixation and numConds+1 is blank
% D.eventImage#
% D.eventFixaton

disp('set up event timing')


eventNumber = 1;
D.eventStartTime(eventNumber) = 0;
D.eventEndTime(eventNumber) = prefs.timePerRestBlock;
D.eventCond(eventNumber) = prefs.blockOrder(1); % fixation
prefs.blockStartTime(1) = 0;
prefs.blockEndTime(1) = prefs.timePerRestBlock;


% set up d struct, which image when, etc
for i=2:length(prefs.blockOrder)
    
    % rest block
    if prefs.blockOrder(i) == 0
        eventNumber = eventNumber +1;
        D.eventStartTime(eventNumber)= D.eventEndTime(eventNumber-1);
        D.eventEndTime(eventNumber) = D.eventStartTime(eventNumber)+prefs.timePerRestBlock;
        D.eventCond(eventNumber) = prefs.blockOrder(i);
        D.eventImageNum(eventNumber) = 0;
        D.eventFrameTest(eventNumber) = 0;
        prefs.blockStartTime(i) = D.eventStartTime(eventNumber);
        prefs.blockEndTime(i) = D.eventEndTime(eventNumber);

    else %stimulus block
        % fill in which images are when, and blanks inbetween
        frameTest = randi(prefs.numImagesPerBlock-2)+1; % make sure it's not first or last

        % alternate image 1 and image 2
        blockIms = mod(1:prefs.numImagesPerBlock,2)+1;
               
        for j = 1:prefs.numImagesPerBlock

            % event: display image
            eventNumber = eventNumber +1;
            D.eventStartTime(eventNumber) = D.eventEndTime(eventNumber-1);
            D.eventEndTime(eventNumber) = D.eventStartTime(eventNumber) + prefs.timePerImage;
            D.eventCond(eventNumber) = prefs.blockOrder(i);
            D.eventFrameTest(eventNumber) = 0;
            D.eventImageNum(eventNumber) = blockIms(j);
            if j==1
                prefs.blockStartTime(i) = D.eventStartTime(eventNumber);
            end;
            if j==prefs.numImagesPerBlock
                prefs.blockEndTime(i) = D.eventEndTime(eventNumber);
            end
        end
    end
end




%-------------------------------------------------------------------------
%% set up psychtoolbox windows
%-------------------------------------------------------------------------

disp('set up ptb windows')

if (Screen('WindowSize',0)~=1024)
    window.oldResolution=Screen('Resolution', 0, 1024, 768);
else
    window.oldResolution.width=1024;
    window.oldResolution.height=768;
end
pause(1);

window.bgColor = [127 127 127];
[onScreen, ScreenRect] = Screen('OpenWindow',numScreens);
Screen('FillRect', onScreen, window.bgColor);
window.ScreenX = ScreenRect(3);
window.ScreenY = ScreenRect(4);
window.ScreenDiag = sqrt(window.ScreenX.^2 + window.ScreenY.^2);
window.frameTime = Screen('GetFlipInterval', onScreen);

%-------------------------------------------------------------------------
%% load all the images into textures
%-------------------------------------------------------------------------
disp('load all images')

% note: images are stored in a tex{} cell array
% tex{categoryNumber, imageNum}
% displayRects(categoryNum, imageNum)  
% note in this experiments categoriess == conditions

for i=1:length(prefs.condLabel)
    ims = dir(fullfile('ImageFiles', prefs.condLabel{i}, '*.jpg'));
    for thisIm = 1:length(ims)
        image = imread(fullfile('ImageFiles', prefs.condLabel{i}, ims(thisIm).name));
        displayRects(i, thisIm).rect = calculateDisplayRect(size(image,1), size(image,2), prefs.imageDisplaySizePx, window.ScreenX/2, window.ScreenY/2);
        tex(i, thisIm) = Screen('MakeTexture', onScreen, image);
    end;
end;
targetRect = CenterRectOnPoint([0 0 prefs.imageDisplaySizePx prefs.imageDisplaySizePx] + [-20 -20 +20 +20], window.ScreenX/2, window.ScreenY/2);

%-------------------------------------------------------------------------
%% save the .mat file with all the planned presentations
%-------------------------------------------------------------------------
savePath = fullfile('DataFiles', SID, 'MatFiles');
if (~isdir(savePath))
    mkdir(pwd, savePath);
end
save(fullfile(savePath, [SID '-' datestr(now, 30) '.mat']), 'prefs', 'D');

% Save the PRT file
savePath = fullfile('DataFiles', SID, 'PRTFiles');
if (~isdir(savePath))
    mkdir(pwd, savePath);
end
generatePRTfile(prefs, D, fullfile(savePath, [prefs.name '_' SID '_Run' num2str(runNum) '.prt']));

%-------------------------------------------------------------------------
%% spit out experiment information:
%-------------------------------------------------------------------------
clc
disp(sprintf('\n'))
disp(sprintf('Experiment Name: %s\n', prefs.name))
disp(sprintf('Num Conditions: %d\n', prefs.numConds))
disp(sprintf('Blocks Per Cond: %d\n', prefs.numBlocksPerCond))
disp(sprintf('\n'))
disp(sprintf('Total TRs: %d\n', prefs.totalTRs))
disp(sprintf('Total Time: %1.2f\n', prefs.totalTime/60))
disp(sprintf('\n'))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-------------------------------------------------------------------------
%% run it!
%-------------------------------------------------------------------------
HideCursor

Screen('TextSize', onScreen, 32)
text = 'Checkboards will flash...';
[nr obr] = Screen('TextBounds', onScreen, text);
rect = CenterRectOnPoint(obr, window.ScreenX/2, window.ScreenY/2);
Screen('DrawText', onScreen, text, rect(1), rect(2));

text = 'PRIMARY TASK: STAY FIXATED AT THE CENTER!';
[nr obr] = Screen('TextBounds', onScreen, text);
rect = CenterRectOnPoint(obr, window.ScreenX/2, window.ScreenY/2 - 100);
Screen('DrawText', onScreen, text, rect(1), rect(2));
Screen('Flip', onScreen);

%disp('waiting for trigger')
%[keyIsDown,secs,keyCode] = KbCheckM;
%while sum(keyCode(prefs.triggerKey))==0
%    [keyIsDown,secs,keyCode] = KbCheckM;
%end

% Wait for trigger (checks for '=' in buffer)
[triggerTime, detectTime] = waitForTrigger(prefs);
startTime=triggerTime;
startDelayMs=(detectTime-triggerTime)

disp('triggered')

% while not done
currentEvent = 1;
while (1)
    % if current time is at the clock time for the next event
    if (GetSecs-startTime)>D.eventStartTime(currentEvent)
        % play event
        if D.eventCond(currentEvent) == 0 
            % fixation
%             if D.eventFrameTest(currentEvent) == 1
%                 Screen('FillOval', onScreen, [255 0 0], CenterRectOnPoint([0 0 7 7], window.ScreenX/2, window.ScreenY/2));
%             else
%                 Screen('FillOval', onScreen, [0 0 0], CenterRectOnPoint([0 0 7 7], window.ScreenX/2, window.ScreenY/2));
%             end;
            Screen('FillOval', onScreen, [0 0 0], CenterRectOnPoint([0 0 8 8], window.ScreenX/2-1, window.ScreenY/2-1));
            D.onsetTimeStamp(currentEvent) = GetSecs();
            D.actualEventTime(currentEvent) = D.onsetTimeStamp(currentEvent)-startTime;
            disp(['condition: ' num2str(D.eventCond(currentEvent)) ' catch: ' num2str(D.eventFrameTest(currentEvent))])
            KbQueueRelease();
       
        elseif D.eventCond(currentEvent) ==(prefs.numConds + 1)
            % blank between images during a main block
            Screen('FillRect', onScreen, [255 255 255])
            D.onsetTimeStamp(currentEvent) = GetSecs();
            D.actualEventTime(currentEvent) = D.onsetTimeStamp(currentEvent)-startTime;
        else
            % main block when images are displayed
            KbQueueCreate(prefs.deviceNumber, prefs.keyList);
            KbQueueStart();
            
            Screen('DrawTexture', onScreen, tex(D.eventCond(currentEvent), D.eventImageNum(currentEvent)), [], displayRects(D.eventCond(currentEvent), D.eventImageNum(currentEvent)).rect);
            Screen('FillOval', onScreen, [0 0 0], CenterRectOnPoint([0 0 8 8], window.ScreenX/2-1, window.ScreenY/2-1));
            D.onsetTimeStamp(currentEvent) = GetSecs();
            D.actualEventTime(currentEvent) = D.onsetTimeStamp(currentEvent)-startTime;
            disp(['condition: ' prefs.condLabel{D.eventCond(currentEvent)} ' imageNum: ' num2str(D.eventImageNum(currentEvent))]);
            if D.eventFrameTest(currentEvent) == 1
                Screen('FrameRect', onScreen, [255 0 0], targetRect, 3);
            end;
        end;
        
        Screen('Flip', onScreen);
        D.actualEventTime(currentEvent) = GetSecs-startTime;
        
          % check whether a key was pressed
        % this is convoluted because we're using KbQueueCheck to check for
        % keypresses during the presentation loop.
        % Keypresses are stored, so after the presentation loop we can
        % check to see whether a key was pressed during the presentation
        % loop.
        
        if (D.eventCond(currentEvent)>0)
            [pressed, firstPress, firstRelease, lastPress, lastRelease]=KbQueueCheck();
            if (pressed==1)
                D.keyPressed2(currentEvent)=1
                whichKey=find(firstPress)
                whichKey=whichKey(1);
                D.respKey2(currentEvent)=whichKey(1);
                D.respNum2(currentEvent)=find(prefs.respKeys==D.respKey2(currentEvent));
                
                if (D.eventCond(currentEvent) ==(prefs.numConds + 1))
                    D.respRT2(currentEvent)=(firstPress(whichKey)-D.onsetTimeStamp(currentEvent-1))*1000;
                else
                    D.respRT2(currentEvent)=(firstPress(whichKey)-D.onsetTimeStamp(currentEvent))*1000;
                end
                
            else
                D.keyPressed2(currentEvent)=0;
                D.respKey2(currentEvent)=0;
                D.respNum2(currentEvent)=0;
                D.respRT2(currentEvent)=0;
            end
        else
            D.keyPressed2(currentEvent)=0;
            D.respKey2(currentEvent)=0;
            D.respNum2(currentEvent)=0;
            D.respRT2(currentEvent)=0;
        end
        
        currentEvent = currentEvent+1;
    end
    
    % if we're at the last event end, wait until the end duration
    % other wise, listen for a response until it's time for the next
    % event...
    if currentEvent > length(D.eventCond)
        while (GetSecs-startTime) < D.eventEndTime(currentEvent-1); end
        break;
    end

end

sca;
ActualScanTime=GetSecs()-startTime;
fprintf('\nActual Scan Time = %4.1f\n', ActualScanTime);
fprintf('\nExpected Scan Time = %4.1f\n\n', prefs.totalTime);

%-------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-------------------------------------------------------------------------
%% save data file
%-------------------------------------------------------------------------

save temp.mat
savePath = fullfile('DataFiles', SID, 'MatFiles');
if (~isdir(savePath))
    mkdir(pwd, savePath);
end
save(fullfile(savePath, [SID '-' datestr(now, 30) '.mat']), 'prefs', 'D');

%-------------------------------------------------------------------------
%% plot response data:
%-------------------------------------------------------------------------

savePath = fullfile('DataFiles', SID, 'Timing');
if (~isdir(savePath))
    mkdir(pwd, savePath);
end

figure
plot(D.eventFrameTest==1), hold on, plot(D.respRT2>0, 'r')
xlabel('run time')
saveas(gcf, fullfile(savePath, ['responseData_' num2str(runNum) '.eps']),'epsc');


% plot timing
figure
plot(D.eventStartTime-D.actualEventTime)
ylim([-2*window.frameTime 2*window.frameTime]);
xlabel('event number')
ylabel('seconds')
title('difference between expected and actual time');
title('difference between expected and actual time')
saveas(gcf, fullfile(savePath, ['timing_' num2str(runNum) '.eps']),'epsc');

%-------------------------------------------------------------------------
%% close psychtoolbox windows
%-------------------------------------------------------------------------

% close window, wait a second
sca;
t=GetSecs; while(GetSecs-t)<1; end

% then change resolution back
try
    if (window.oldResolution.width~=1024)
        Screen('Resolution', 0, window.oldResolution.width, window.oldResolution.height);
    end
end

% catch
%     sca;
%     psychrethrow(lasterror);
%     keyboard;
% end

%-------------------------------------------------------------------------
% HELPER FUNCTIONS
%-------------------------------------------------------------------------
function generatePRTfile(prefs, D, filename)
% generate PRT File

% 4 conds

condColor = ...
   {[255 16 0],
    [0 249 0],
    [0 73 255],
    [152 0 183]};

TRdur         = 2;

% open file
fid = fopen(filename, 'w');


% header information
fprintf(fid,'\n');
fprintf(fid,'FileVersion:        1\n');
fprintf(fid,'ResolutionOfTime:   Volumes\n');
fprintf(fid,'Experiment:         %s\n', prefs.name);
fprintf(fid,'BackgroundColor:    0 0 0\n');
fprintf(fid,'TextColor:          255 255 255\n');
fprintf(fid,'TimeCourseColor:    255 255 255\n');
fprintf(fid,'TimeCourseThick:    3\n');
fprintf(fid,'ReferenceFuncColor: 0 0 80\n');
fprintf(fid,'ReferenceFuncThick: 3\n');
fprintf(fid,'NrOfConditions:     %d\n',prefs.numConds);
fprintf(fid,'\n');


% condition information
for thisCond = 1:prefs.numConds

    % condition name
    fprintf(fid, '%s\n', prefs.condLabel{thisCond});

    % number of events
    fprintf(fid, '%d\n', sum(prefs.blockOrder==thisCond));

    % onsets and offsets in TRs
    onsets = prefs.blockStartTime(prefs.blockOrder==thisCond)/TRdur + 1;
    offsets = prefs.blockEndTime(prefs.blockOrder==thisCond)/TRdur; % don't add 1! + 1;
    for thisTR = 1:length(onsets)
        fprintf(fid, '  %2.0f %2.0f\n', onsets(thisTR), offsets(thisTR));
    end;

    % color
    fprintf(fid,'Color: %d %d %d\n\n', condColor{thisCond});

end;
fclose(fid);


%-------------------------------------------------------------------------
function displayRect = calculateDisplayRect(imH, imW, dispSize, centerX, centerY)
% given an arbitrary image size
% generate a rect size, centered on the Screen, that makes the maximum
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
displayRect = CenterRectOnPoint(rect, centerX, centerY);



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
% =========================================================================
function [triggerTime, detectTime] = waitForTrigger(prefs)

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
% quickDeviceFindChecker

KbQueueCreate(prefs.deviceNumber, keyList);

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


