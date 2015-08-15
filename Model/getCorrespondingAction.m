%% getCorrespondingAction
% This function returns the 'corresponding' action to an inputted action,
%   for a given trial type.

function [corAction] = getCorrespondingAction(action,trialType)
if action == 1 % blue
    corAction = 3;
elseif action == 3 % blue
    corAction = 1;
elseif action == 2 % red
    corAction = 4;
elseif action == 4 % red
    corAction = 2;
elseif action == 5
    corAction = 5;
end
end