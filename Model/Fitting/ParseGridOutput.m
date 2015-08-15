%% ParseGridOutput

path = 'C:\Personal\Psychology\Projects\DDE\git\Model\Fitting\v2\SubjFits\';
numSubjects = length(subjMarkers);
optParams = [];
good = false(numSubjects,1);

for i = 1:numSubjects
    name = [path 'Params_Subj' num2str(i) '.txt'];
    if exist(name,'file')
        good(i) = true;
        optParams(end+1,:) = csvread(name);
    end
end