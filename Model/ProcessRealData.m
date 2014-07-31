%% ProcessRealData (May 1, 2014)
% This script does all the necessary pre-processing when receiving real
%   data
% Three critical steps

%% 1: Add +1 to the S2 array
% This is b/c the DDE game gives it to us in 1-5, but the scripts need it
%   in 2-6
for i = 1:length(S2)
    S2(i) = S2(i)+1;
end

%% 2: Convert OptNum to separate Opt1 & Opt2
[Opt1, Opt2] = convertOptNumToOptions(OptNum);

%% 3: Generate permanent, timesorted IDs for each subject
% This will change the 'id' array to the a new, stable, timesorted,
% numerical ID, and will put the old id's in an array called 'old_id'

subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);
temp = zeros(numSubjects,2); % this will contain subjMarker,datestamp,timestamp
idLookup = zeros(numSubjects,2); % this will contain subjMarker,new_id

% Populate array (while converting to serial date #s)
for thisSubj = 1:numSubjects
    index = subjMarkers(thisSubj);
    if iscell(datestamp) % if in cell form
        temp(thisSubj,:) = [index datenum([datestamp{index} ' ' timestamp{index}])];
    elseif isnumeric(datestamp) % if already converted
        temp(thisSubj,:) = [index datestamp(index)+timestamp(index)];
    else % if it's just a string
        temp(thisSubj,:) = [index datenum([datestamp(index) ' ' timestamp(index)])];
    end
end

% Sort by date
temp = sortrows(temp,2);

for thisSubj = 1:numSubjects
    idLookup(thisSubj,:) = [temp(thisSubj,1) thisSubj];
end

% Switcheroo
old_id = id;
new_id = zeros(length(id),1);
for thisSubj = 1:numSubjects
    i = subjMarkers(thisSubj);
    temp = idLookup(find(idLookup(:,1)==subjMarkers(thisSubj)),2);
    if thisSubj == numSubjects
        last = length(id);
    else
        last = subjMarkers(thisSubj+1)-1;
    end
    while i <= last
        new_id(i) = temp;
        i = i+1;
    end
end
clear id;
id = new_id;

%% 4: Use these new IDs to sort everything else
% We want all arrays sorted first by ID, then by round #.

massive = [id datestamp timestamp Type Goal OptNum Action S2 Re rt1 rt2 score old_id round1];
massive = sortrows(massive,[1 size(massive,2)]);
id = massive(:,1); datestamp = massive(:,2); timestamp = massive(:,3);
Type = massive(:,4); Goal = massive(:,5); OptNum = massive(:,6); Action = massive(:,7);
S2 = massive(:,8); Re = massive(:,9); rt1 = massive(:,10); rt2 = massive(:,11);
score = massive(:,12); old_id = massive(:,13); round1 = massive(:,14);