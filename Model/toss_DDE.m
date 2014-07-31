% Who should we toss?
% Remember, the tosslist should be ID-based, not subjMarker-based
function [tosslist] = toss_DDE(params, numTrialsCompleted)
tosslist = [];
for i = 1:size(params,1)
    % Check filter criteria
    % I'm doing: toss if lr < .1 or temp < .1 or
    %   numTrials < 150 or > 250
    if params(i,2) < .1 || params(i,3) < .1 || params(i,5) < .1 || numTrialsCompleted(i) < 150 || numTrialsCompleted(i) > 250
        tosslist(end+1) = params(i,1);
    end
    %if (params(i,2) > .1 && params(i,3) > .1 && params(i,5) > .1) || (numTrialsCompleted(i) > 250 || numTrialsCompleted(i) < 150)
    %    tosslist(end+1) = params(i,1);
    %end
end
end