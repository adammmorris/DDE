subjIDs_unique = unique(subjIDs);
numSubj = length(subjIDs_unique);
exclude = [];
for i = 1:numSubj
    if sum(critTrials==0&subjIDs==subjIDs_unique(i))==0 exclude(end+1)=subjIDs_unique(i); end
    if length(unique(choices(critTrials>=0&subjIDs==subjIDs_unique(i))))==1,exclude(end+1)=subjIDs_unique(i); end
end