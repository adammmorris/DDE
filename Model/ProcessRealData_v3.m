%% ProcessRealData (May 1, 2014)
% This script does all the necessary pre-processing when receiving real
%   data
% Three critical steps..

%% 1: Add +1 to the S2 array
% This is b/c the DDE game gives it to us in 1-5, but the scripts need it
%   in 2-6
for i = 1:length(S2)
    S2(i) = S2(i)+1;
end

%% 2: Convert OptNum to separate Opt1 & Opt2
[Opt1, Opt2] = convertOptNumToOptions(OptNum);

%% 3: Generate permanent IDs for each subject
% This will change the 'id' array to the a new, stable,
%   numerical ID, and will put the old id's in an array called 'old_id'
% Note that nothing is being reordered; all the subject markers are the
%   same as in the raw excel file.
% (I gave up on the timesorting thing - not worth it.)

subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

old_id = id;
id = zeros(length(old_id),1);

% Populate array (while converting to serial date #s)
for thisSubj = 1:numSubjects
    if thisSubj < length(subjMarkers)
        index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
    else
        index = subjMarkers(thisSubj):length(id);
    end
    
    id(index) = thisSubj;
end

% Clean up
clear index; clear numSubjects; clear thisSubj;