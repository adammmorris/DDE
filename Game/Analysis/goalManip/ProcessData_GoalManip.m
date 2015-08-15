% Does extra processing for goal manipulation experiment.

numSubj = length(subjMarkers);
instructManip = zeros(numSubj,1);

INSTRUCTIONS_NOGOAL = 0;
INSTRUCTIONS_GOAL = 1;

for i=1:numSubj
    if strcmp(version1(subjMarkers(i)),'baseline_v2') == 1, instructManip(i) = INSTRUCTIONS_GOAL;
    elseif strcmp(version1(subjMarkers(i)),'noGoalInstructions_v1') == 1, instructManip(i) = INSTRUCTIONS_NOGOAL;
    else instructManip(i) = -1;
    end
end