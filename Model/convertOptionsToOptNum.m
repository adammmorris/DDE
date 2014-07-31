function [optNum] = convertOptionsToOptNum(options)
numSubjects = length(options);
optNum = zeros(numSubjects,1);
for thisRow = 1:numSubjects
    if all(sort(options(thisRow,:)) == [1 2])
        optNum(thisRow) = 1;
    elseif all(sort(options(thisRow,:)) == [1 3])
        optNum(thisRow) = 2;
    elseif all(sort(options(thisRow,:)) == [1 4])
        optNum(thisRow) = 3;
    elseif all(sort(options(thisRow,:)) == [1 5])
        optNum(thisRow) = 4;
    elseif all(sort(options(thisRow,:)) == [2 3])
        optNum(thisRow) = 5;
    elseif all(sort(options(thisRow,:)) == [2 4])
        optNum(thisRow) = 6;
    elseif all(sort(options(thisRow,:)) == [2 5])
        optNum(thisRow) = 7;
    elseif all(sort(options(thisRow,:)) == [3 4])
        optNum(thisRow) = 8;
    elseif all(sort(options(thisRow,:)) == [3 5])
        optNum(thisRow) = 9;
    elseif all(sort(options(thisRow,:)) == [4 5])
        optNum(thisRow) = 10;
    end
end
end