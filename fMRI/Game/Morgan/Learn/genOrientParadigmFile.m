function genParadigmFile(runSequence,eventDur,condNames,condTypes,saveFolder,saveName)
% create an optseq2 style paradigm file
% 
% input
% --------------------------------------------
% runSequence:  rows=runs, cols=events
% eventDur:     how long each individual event lasts
% condNames:    leave blank to get "Item1", "Item2", etc., 
%               or a cell array with the name for each condition (e.g.,
%               "Animals-1", "Animals-2", etc.
% saveFolder:   folder where you want to save the files 
%               e.g., "paradigm files"
% saveName:     root name for saving files 
%               e.g., "EventV2-ParadigmFile" 

% output
% --------------------------------------------
% paradigm file (text file)
% rows = events
% cols = onsetTime condNum condType eventDur dummy1 condName
%   onsetTime: event onset time in seconds
%   condNum: event number (Null=0, conditions 1-N)
%   condType: which category does the cond belong to
%   eventDur: event duration in seconds
%   dummy1: always 1 (matches optseq output)
%   condName: name of condition, taken from "itemNames" variable

%% do it

[nRuns,nEvents]=size(runSequence);

for r=1:nRuns
    
    % setup for this run
    % ---------------------------------------------------------------------
    % open a file for this run
    fileName=fullfile(saveFolder,[saveName '-Run' num2str(r) '.par'])
    fid=fopen(fileName,'w');
    
    % get item order for this run
    itemOrder=runSequence(r,:);
    
    % initialize some variables
    onsetTime=0;
    dummy1=1;
    
    % loop through events for this run
    % ---------------------------------------------------------------------
    eNum=1;
    count=0;
    while eNum<=nEvents
        
        % update counter (count=number of rows in paradigm file)
        count=count+1;
        
        % get current item information
        condNum=itemOrder(eNum);
        if condNum==0
            condName='NULL';
        elseif isempty(condNames)
            condName=['Item' num2str(condNum)];
        else
            condName=condNames{condNum};
        end
        
        %get cond types and namesfor different conds
        if (condNum==1)|(condNum==9)|(condNum==17)|(condNum==25)|(condNum==33)
            condType=1;
            condTypeName=condTypes{1};
        elseif (condNum==2)|(condNum==10)|(condNum==18)|(condNum==26)|(condNum==34)
            condType=2;
            condTypeName=condTypes{2};
        elseif (condNum==3)|(condNum==11)|(condNum==19)|(condNum==27)|(condNum==35)
            condType=3;
            condTypeName=condTypes{3};
        elseif (condNum==4)|(condNum==12)|(condNum==20)|(condNum==28)|(condNum==36)
            condType=4;
            condTypeName=condTypes{4};
        elseif (condNum==5)|(condNum==13)|(condNum==21)|(condNum==29)|(condNum==37)
            condType=5;
            condTypeName=condTypes{5};
        elseif (condNum==6)|(condNum==14)|(condNum==22)|(condNum==30)|(condNum==38)
            condType=6;
            condTypeName=condTypes{6};
        elseif (condNum==7)|(condNum==15)|(condNum==23)|(condNum==31)|(condNum==39)
            condType=7;
            condTypeName=condTypes{7};
        elseif (condNum==8)|(condNum==16)|(condNum==24)|(condNum==32)|(condNum==40)
            condType=8;
            condTypeName=condTypes{8};
        else
            condType=0;
            condTypeName='NULL';
        end
       
        % figure out how many of this item in a row there are
%         if eNum==nEvents % special case, last event is always "1"
%             numInRow=1;
%         else
            numInRow=0;
            while eNum<=nEvents & condNum==itemOrder(eNum)
                eNum=eNum+1;
                numInRow=numInRow+1;
            end
%         end
        
        % variables for this row/event
        %   onsetTime: event onset time in seconds
        %   condNum: event number (NULL=0, conditions 1-N)
        %   eventDur: event duration in seconds
        %   dummy1: always 1 (matches optseq output)
        %   condName: name of condition, taken from "itemNames" variable
        currentEventDur=numInRow*eventDur;
        
        % print event information to file
       fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%s\t%s\t\n',onsetTime,condNum,condType,currentEventDur,dummy1,condName,condTypeName);
        
        % ********************************
        % update onset time for next event
        onsetTime=onsetTime+currentEventDur;
        
    end
    
    fclose(fid);
end






