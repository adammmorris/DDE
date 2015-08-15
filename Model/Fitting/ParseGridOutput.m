%% ParseGridOutput

path = '';
numSubjects = length(subjMarkers);
params = [];

for i = 1:numSubjects
    name = [path 'Params_Subj' num2str(i) '.txt'];
    if exist(name,'file')
        params(end+1,:) = csvread([path 'Params_Start' num2str(i) '.txt']);
    end
end