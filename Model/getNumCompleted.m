function [numCompleted] = getNumCompleted(id)
subjMarkers = getSubjMarkers(id);
numCompleted = zeros(length(subjMarkers),1);
for i = 1:length(subjMarkers)
    % Get position of next guy
    if i == length(subjMarkers)
        nextGuy = length(id);
    else
        nextGuy = subjMarkers(i+1); 
    end
    
    numCompleted(i) = nextGuy - subjMarkers(i);
end
end