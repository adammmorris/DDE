%% getOtherAvailableAction
% Randomly selects a second available Stage 1 action, with the constraint that it has to have a different Stage 2 goal state than action1.

function [action2] = getOtherAvailableAction(action1)
numRounds = length(action1);
action2 = zeros(numRounds,1);

for i = 1:numRounds
    choices = zeros(2,1);
    if any(action1(i)==[1 3])
        choices(1) = 2;
        choices(2) = 4;
    elseif any(action1(i)==[2 4])
        choices(1) = 1;
        choices(2) = 3;
    end
    
    action2(i) = choices(round(rand()+1));
end
end