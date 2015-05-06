function [criticalTrials] = generateCritNumbers(numRounds,numCriticalTrials,numRuns)

numRoundsPerRun= numRounds/numRuns;
numCritsPerRun = numCriticalTrials/numRuns;
criticalTrials=zeros(numRuns,numCritsPerRun);
distance_cutoff = 3;

for j = 1:numRuns
    templist = 3:(numRoundsPerRun-1);
    good = true(length(templist),1);
    for i = 1:numCritsPerRun
        criticalTrials(j,i) = randsample(templist(good),1);
        for k = 0:distance_cutoff
            if (criticalTrials(j,i)+k) <= numRoundsPerRun, good(criticalTrials(j,i)+k)=false; end
            if (criticalTrials(j,i)-k) > 0, good(criticalTrials(j,i)-k)=false; end
        end
        
    end
end

