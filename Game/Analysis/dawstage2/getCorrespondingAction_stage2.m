%% getCorrespondingAction
% This function returns the 'corresponding' action to an inputted action,
%   for a given trial type.

function [corAction] = getCorrespondingAction_stage2(action1,action2)
if action1 == 1 || action1 == 3
    corAction = action2 - 4;
elseif action1 == 2 || action1 == 4
    corAction = action2 - 2;
end
end