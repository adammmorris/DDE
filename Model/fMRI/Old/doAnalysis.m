function doAnalysis(name,PEs,params,plotIndex)
% Get correlation coefficients per subject
subjCors = zeros(100,2);
for i=1:100
    subjCors(i,1) = corr(PEs(:,1,i),PEs(:,2,i));
    subjCors(i,2) = corr(PEs(:,1,i),PEs(:,3,i));
end

% Plot them
subplot(2,2,plotIndex*2-1)
hist(subjCors(:,1)); title(strcat(name, ' - cor w/ MF')); axis([-1 1 0 35]);
subplot(2,2,plotIndex*2);
hist(subjCors(:,2)); title(strcat(name, ' - cor w/ MB')); axis([-1 1 0 35]);

% What parameters predict the correlations?
disp(strcat('-------------- ', name, ' --------------'))
paramNames = {'Intercept';'LR';'Elig';'Beta';'w_MFG';'w_MB'};
corNames = {'Beta_MF' 'p_MF' 'Beta_MB' 'p_MB'};
[b1, ~, stats1] = glmfit(params,subjCors(:,1),'normal');
[b2, ~, stats2] = glmfit(params,subjCors(:,2),'normal');
array2table([b1 stats1.p b2 stats2.p],'RowNames',paramNames,'VariableNames',corNames)
end