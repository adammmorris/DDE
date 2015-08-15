differences = [];

for i=2:length(id)
    if all([~isnan(Action(i)) ~isnan(Action(i-1))]) && any(Action(i) == [Action(i-1) getCorrespondingAction(Action(i-1),1)]) && id(i) == id(i-1), differences(end+1) = Re(i) - Re(i-1); end
end