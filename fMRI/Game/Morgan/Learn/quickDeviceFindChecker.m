sca
buttonBoxName='Serial+Keyboard+Mouse+Joystick';
buttonBoxName='Apple Internal Keyboard / Trackpad'; % COMMENT OUT PRIOR TO SCAN!!!!


[keyboardIndices, productNames, allInfos] = GetKeyboardIndices();
whichExternal=find(strcmp(buttonBoxName,productNames));
if (isempty(whichExternal))
    sca;
    clc;
    fprintf('looking for product named ''%s''\n\n',buttonBoxName);
    disp('None of these product names match your button box name!');
    for i=1:length(productNames)
        fprintf('%s\n',productNames{i});
    end
    fprintf('\nYour button box name ''%s'' might be outdated.\n',buttonBoxName)
    fprintf('If so, find the new button box name in the list above.\n');
    fprintf('Then modify your code to use this new name.\n');
    fprintf('Search for buttonBoxName in your code, and replace\n');
    fprintf('the old button box name with the new one.\n\n');
    error('button box not found!');
end
exp.deviceNumber = keyboardIndices(whichExternal);

keyboardIndices
productNames
exp.deviceNumber