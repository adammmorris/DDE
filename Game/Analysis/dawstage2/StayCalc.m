numStay = 0;
numSwitch = 0;
for i=1:length(Action2)
    if round1(i) >= 77
        if Re(i-1) > 2 && Action2(i-2) == Action2(i-1) && S2(i-2) ~= 5 && S2(i-1) ~= 5 && S2 (i) ~= 5
            if Action2(i) == Action2(i-1)
                numStay = numStay + 1;
            else
                numSwitch = numSwitch + 1;
            end
        end
    end
end

% .6728