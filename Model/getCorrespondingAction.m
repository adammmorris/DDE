%% getCorrespondingAction
% This function returns the 'corresponding' action to an inputted action,
%   for a given trial type.

% Set orig_simulation to 1 if this data is from a simulation from board 1
function [corAction] = getCorrespondingAction(action,trialType,orig_simulation)
if nargin < 3
    orig_simulation = 0;
end

if orig_simulation == 1
    if trialType == 1 % shape trial
        if action == 1 % square
            corAction = 3;
        elseif action == 3 % square
            corAction = 1;
        elseif action == 2 % circle
            corAction = 4;
        elseif action == 4 % circle
            corAction = 2;
        elseif action == 5
            corAction = 5;
        end
    else % color trial
        if action == 1 % blue
            corAction = 2;
        elseif action == 2 % blue
            corAction = 1;
        elseif action == 3 % red
            corAction = 4;
        elseif action == 4 % red
            corAction = 3;
        elseif action == 5
            corAction = 5;
        end
    end
else
    if trialType == 1 % shape trial
        if action == 1 % square
            corAction = 2;
        elseif action == 2 % square
            corAction = 1;
        elseif action == 3 % circle
            corAction = 4;
        elseif action == 4 % circle
            corAction = 3;
        elseif action == 5
            corAction = 5;
        end
    else % color trial
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
end
end