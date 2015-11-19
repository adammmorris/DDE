%% ParseGridOutput
numSubjects = 100;

path_GLmodel = 'C:\Personal\Psychology\Projects\DDE\git\Model\Fitting\v6\NGLagents\SubjFits\';
path_NGLmodel = 'C:\Personal\Psychology\Projects\DDE\git\Model\Fitting\v6\NGLagents\SubjFits_null\';
% path_GLmodel = 'C:\Personal\Psychology\Projects\DDE\git\Game\Data\dawstage2\v2\Fitting\v5\SubjFits\';
% path_NGLmodel = 'C:\Personal\Psychology\Projects\DDE\git\Game\Data\dawstage2\v2\Fitting\v5\SubjFits_null\';
params_GLmodel = zeros(numSubjects,6);
params_NGLmodel = zeros(numSubjects,5);
good = false(numSubjects,1);

for i = 1:numSubjects
%     name1 = [path_GLagents_GLmodel 'Params_Subj' num2str(i) '.txt'];
%     name2 = [path_GLagents_NGLmodel 'Params_Subj' num2str(i) '.txt'];
%     name3 = [path_NGLagents_GLmodel 'Params_Subj' num2str(i) '.txt'];
%     name4 = [path_NGLagents_NGLmodel 'Params_Subj' num2str(i) '.txt'];
    name1 = [path_GLmodel 'Params_Subj' num2str(i) '.txt'];
    name2 = [path_NGLmodel 'Params_Subj' num2str(i) '.txt'];
    if exist(name1,'file') && exist(name2,'file') %&& exist(name3,'file') && exist(name4,'file')
%         params_GLagents_GLmodel(end+1,:) = csvread(name1);
%         params_GLagents_NGLmodel(end+1,:) = csvread(name2);
%         params_NGLagents_GLmodel(end+1,:) = csvread(name3);
%         params_NGLagents_NGLmodel(end+1,:) = csvread(name4);
        params_GLmodel(i,:) = csvread(name1);
        params_NGLmodel(i,:) = csvread(name2);
        good(i) = true;
    end
end

clear i; clear name1; clear name2; clear name3; clear name4; clear path_GLagents_GLmodel; clear path_GLagents_NGLmodel; clear path_NGLagents_GLmodel; clear path_NGLagents_NGLmodel;