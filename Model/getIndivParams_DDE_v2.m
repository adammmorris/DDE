%% getIndivParams
% This function finds the optimal individual parameters using the specified
%   model
% Uses patternsearch

%% Inputs:
% model should be a handle to a function that:
%   takes a single subject's id,option1,option2,choice,state2,re,rounds as input
%   and outputs the negLL
% practiceCutoff should be the last trial # that's still a practice round
% starts should be a k x numParams matrix, where k is the number of
%   different starts we want to do (and then take the best of)
% A is the linear constraint vector (should be [0..0 1 1] or [0..0 1 1 0])
% bounds should be a 2 x numParams matrix, where the first row has the
%   lower limit & the second row has the upper limit
% tosslist: who you want to toss (by id)
% prevOptParams: suppose you get a few more subjects, and want to test them
%   without having to redo everybody you've already done (or you want to untoss some people).  Here's what you
%   do: send in the full (id,trialType,option1,etc...), but also send in
%   the previously obtained ML parameters under the given model (WITH THE
%   FIRST ROW BEING THE UNAMBIGUOUS # ID).  Then, the function will skip
%   anybody who we've already done, and will consolidate matrices at the
%   end

%% Outputs:
% optimalParams is a numSubjects x (numParams+2) matrix
% First column is id, last is negLL

%% Versions

% v2 (May 1, 2014)
% - Added a way to not have to redo every subject if I suddenly get some
%   new data from the same study.  i.e. can incorporate previously found
%   ML params
% - Changed tosslist to be ID-based, not subjMarker-based
% - Changed the first column of optimalParams to be new id, not old id
% - Removed realPeople param

function [optimalParams] = getIndivParams_DDE_v2(model,servant,practiceCutoff,boardName,id,trialType,option1,option2,choice,state2,re,rounds,starts,A,b,bounds,tosslist,prevOptParams)
% Get the list of subjects
subjMarkers = getSubjMarkers(id);
numSubjects = length(subjMarkers);

% Get the parameter info
if (size(starts,2) ~= size(bounds,2))
    error('starts and bounds must have the same amount of columns');
end
numParams = size(starts,2);
numStarts = size(starts,1);

% Set patternsearch options
options = psoptimset('CompleteSearch','on','SearchMethod',{@searchlhs},'UseParallel','Always');    

% Set up results matrix
optimalParams = zeros(numSubjects,numParams+2); % first column will be id, last will be negLL

% Temporary variables
% Both ordered by subjMarkers, not subjIDs
max_params = zeros(numParams,numStarts,numSubjects);
lik = zeros(numStarts,numSubjects);

%% Loop through starts
for thisStart = 1:numStarts
    % Loop through subjects
    parfor thisSubj = 1:numSubjects
        subjID = id(subjMarkers(thisSubj));
        % Are we not tossing this person?  Is this person not already done?
        if ~any(tosslist == subjID) && (isempty(prevOptParams) || ~any(prevOptParams(:,1) == subjID))
            % Get the appropriate index
            if thisSubj < length(subjMarkers)
                index = subjMarkers(thisSubj):(subjMarkers(thisSubj + 1) - 1);
            else
                index = subjMarkers(thisSubj):length(id);
            end

            % Do patternsearch
            [max_params(:,thisStart,thisSubj),lik(thisStart,thisSubj),~] = patternsearch(@(params) model(params,servant,practiceCutoff,boardName,trialType(index),option1(index),option2(index),choice(index),state2(index),re(index),rounds(index)),starts(thisStart,:),A,b,[],[],bounds(1,:),bounds(2,:),options);
        end
    end
end

% Take best results & consolidate
destroy = zeros(length(tosslist),1);
i = 1;
for thisSubj = 1:numSubjects
    % Did we toss this guy?
    if any(tosslist==id(subjMarkers(thisSubj)))
        destroy(i) = thisSubj;
        i = i+1;
    % Is this person from a previous thing?
    elseif ~isempty(prevOptParams) && any(prevOptParams(:,1)==id(subjMarkers(thisSubj)))
        optimalParams(thisSubj,:) = prevOptParams(find(prevOptParams(:,1)==id(subjMarkers(thisSubj))),:);
    else
        [~,bestStart] = min(lik(:,thisSubj)); % minimum likelihood
        optimalParams(thisSubj,:) = [id(subjMarkers(thisSubj)) max_params(:,bestStart,thisSubj)' lik(bestStart,thisSubj)];
    end
end

% Get rid of tossed rows
optimalParams = removerows(optimalParams,'ind',destroy);
end