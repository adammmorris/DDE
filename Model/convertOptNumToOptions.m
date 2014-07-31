function [opt1,opt2] = convertOptNumToOptions(optNum)
numSubjects = length(optNum);
opt1 = zeros(numSubjects,1);
opt2 = zeros(numSubjects,1);
for thisRow = 1:numSubjects
    if optNum(thisRow) == 1
        opt1(thisRow) = 1;
        opt2(thisRow) = 2;
    elseif optNum(thisRow) == 2
        opt1(thisRow) = 1;
        opt2(thisRow) = 3;
    elseif optNum(thisRow) == 3
        opt1(thisRow) = 1;
        opt2(thisRow) = 4;
    elseif optNum(thisRow) == 4
        opt1(thisRow) = 1;
        opt2(thisRow) = 5;
    elseif optNum(thisRow) == 5
        opt1(thisRow) = 2;
        opt2(thisRow) = 3;
    elseif optNum(thisRow) == 6
        opt1(thisRow) = 2;
        opt2(thisRow) = 4;
    elseif optNum(thisRow) == 7
        opt1(thisRow) = 2;
        opt2(thisRow) = 5;
    elseif optNum(thisRow) == 8
        opt1(thisRow) = 3;
        opt2(thisRow) = 4;
    elseif optNum(thisRow) == 9
        opt1(thisRow) = 3;
        opt2(thisRow) = 5;
    elseif optNum(thisRow) == 10
        opt1(thisRow) = 4;
        opt2(thisRow) = 5;
    end
end
end