rewards_MB = [];
rewards_MFonMB = [];
for i=1:(size(results_MB,1)-1)
%     if results_MB(i,10)==1 && results_MB(i+1,5) ~= getCorrespondingAction(results_MB(i,5),1), rewards_MB(end+1) = results_MB(i+1,8); end
%     if results_MFonMB(i,10)==1 && results_MFonMB(i+1,5) ~= getCorrespondingAction(results_MFonMB(i,5),1), rewards_MFonMB(end+1) = results_MFonMB(i+1,8); end
     if results_MB(i,10)==1, rewards_MB(end+1) = results_MB(i,8); end
     if results_MFonMB(i,10)==1, rewards_MFonMB(end+1) = results_MFonMB(i,8); end
end