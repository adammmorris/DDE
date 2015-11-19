addpath C:\Personal\Psychology\Projects\DDE\git\Model\

% opt1, opt2, action, s2, re
subjects = [2:13 15:24];
numSubj = length(subjects);
numRoundsPerSubj = 400;
Opt1 = zeros(numRoundsPerSubj, numSubj);
Opt2 = zeros(numRoundsPerSubj, numSubj);
Action = zeros(numRoundsPerSubj, numSubj);
S2 = zeros(numRoundsPerSubj, numSubj);
Re = zeros(numRoundsPerSubj, numSubj);

for i=1:numSubj
    thisSubj = subjects(i);
    if thisSubj < 10, name = strcat('0', num2str(thisSubj));
    else name = num2str(thisSubj);
    end
    
    load(strcat('data/CUSH_LEARN_', name, '_all.mat'));
    [Opt1(:,i), Opt2(:,i)] = convertOptNumToOptions(choicesAll(:,3));
    Action(:,i) = choicesAll(:,4);
    S2(:,i) = choicesAll(:,5);
    twos = S2(:,i) == 2;
    threes = S2(:,i) == 3;
    S2(twos,i) = 3;
    S2(threes,i) = 2;
    Re(:,i) = choicesAll(:,6);
end