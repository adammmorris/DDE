numCriticalTrials = 30;
numRealRounds = 175;
numPracticeRounds = 75;

good = true(numRealRounds,1);
templist = 1:numRealRounds;
distance_cutoff = 3;
criticalTrials = zeros(numCriticalTrials,2); % 1st column has trial #, 2nd column is whether it's congruent (1) or incongruent(0)
probCong = 1; % set this to 1 if you want all congruent crit trials

for i = 1:numCriticalTrials
    criticalTrials(i,1) = randsample(templist(good),1);
    for k = 0:distance_cutoff
        if (criticalTrials(i,1)+k) <= numRealRounds, good(criticalTrials(i,1)+k)=false; end
        if (criticalTrials(i,1)-k) > 0, good(criticalTrials(i,1)-k)=false; end
    end
    
    if rand() < probCong,criticalTrials(i,2)=1;end
end
%criticalTrials(:,1) = criticalTrials(:,1) + numPracticeRounds;