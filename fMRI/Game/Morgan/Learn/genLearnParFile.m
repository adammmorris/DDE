
dummyNull = 8.000;
startNull = 6.000;
numRounds = 400;

numRuns = 1;

s1Time = 2.000;
s2Time = 2.000;
payoffTime = 2.000;


tnullmax = 6;
jitterSum = 0;


jitter = repmat([0:2:tnullmax],1,ceil(numRounds/3));
ind1   = randperm(length(jitter));
jitter1 = jitter(ind1);
jitter1= jitter1(1:numRounds);


currSec = 0.000;
currRound = 1;
i=1;

currPar = 1;
fid = fopen(fullfile('Par',['sequence_' num2str(currPar) '.par']), 'w');

for currRound = 1:numRounds
    if mod((currRound-1),50)==0
        fclose(fid);
        currPar = ((currRound-1)/50)+1;
        if currPar==8
            keyboard
        end
        fid = fopen(fullfile('Par',['sequence_' num2str(currPar) '.par']), 'w');
        currSec = 0.000;
    end
            
    
    if currSec == 0.000 
        condNum = 0;
        dur = dummyNull;
        condLabel = 'NULL';
        fprintf(fid, '%f %d %f %s\n', currSec, condNum, dur, condLabel);
        currSec = currSec + dur;
        i = i+1;
    end
    if currSec == 8.000 
        condNum = 0;
        dur = startNull;
        condLabel = 'NULL';
        fprintf(fid, '%f %d %f %s\n', currSec, condNum, dur, condLabel);
        currSec = currSec + dur;
        i = i+1;
    end
    
    
    
    % top level
    condNum = 1;
    dur = s1Time;
    condLabel = 's1';
    fprintf(fid, '%f %d %f %s\n',currSec, condNum, dur, condLabel);
    i = i+1;
    
    
    % level 2
    currSec = currSec+dur;
    condNum = 2;
    dur = s2Time;
    condLabel = 's2';
    fprintf(fid, '%f %d %f %s\n',currSec, condNum, dur, condLabel);
    i = i+1;
    
    % jitter1
    currSec = currSec + dur;
    condNum = 0;
    dur = jitter1(currRound);
    condLabel = 'NULL';
    
    
%     % force jitter to more than zero on crit trials
%     if find(criticalTrials==currRound)==1
%         index = round(1 + 2.*rand);
%         critDur = [2.000 4.000 6.000];
%         dur = critDur(index);
%     end

    if dur > 0
    fprintf(fid, '%f %d %f %s\n',currSec, condNum, dur, condLabel);
    i = i+1;
    end
    
    % payoff
    currSec = currSec + dur;
    condNum = 3;
    dur = payoffTime;
    condLabel = 'payoff';
    fprintf(fid, '%f %d %f %s\n',currSec, condNum, dur, condLabel);
    i = i+1;
    
        
     % jitter2?
    currSec = currSec + dur;
    condNum = 0;
    dur = 2.000;
    condLabel = 'NULL';
    fprintf(fid, '%f %d %f %s\n',currSec, condNum, dur, condLabel);
    i = i+1;
    
    
    currRound = currRound + 1;
    currSec = currSec + dur;
    
end
fclose(fid);


    
    