function [opt2] = getOtherAvailableAction(opt1,trialType)
numRounds = length(opt1);
opt2 = zeros(numRounds,1);

for i = 1:numRounds
    choices = zeros(2,1);
    if any(opt1(i)==[1 3])
        choices(1) = 2;
        choices(2) = 4;
    elseif any(opt1(i)==[2 4])
        choices(1) = 1;
        choices(2) = 3;
    end
    
    opt2(i) = choices(round(rand()+1));
end

end