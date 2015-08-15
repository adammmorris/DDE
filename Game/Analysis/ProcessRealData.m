%% ProcessRealData (May 1, 2014)
% This script does all the necessary pre-processing when receiving real
%   data

addpath('C:\Personal\Psychology\Projects\DDE\git\Model');

%% 1: Generate permanent IDs for each subject
% This will change the 'id' array to the a new, stable,
%   numerical ID, and will put the old id's in an array called 'old_id'
% Note that nothing is being reordered; all the subject markers are the
%   same as in the raw excel file.
% (I gave up on the timesorting thing - not worth it.)

id=subject; clear subject;
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

%% 2: Misc
numTrialsCompleted = getNumCompleted(id);
finalScores = getFinalScores(score,subjMarkers);
Bonuses;