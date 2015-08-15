bonuses = finalScores;
bonuses(bonuses<0)=0;
bonuses = bonuses / 100;

A = cell(length(subjMarkers)+1,2);
A{1,1} = 'ID';
A{1,2} = 'Bonus (dollars)';

for i=1:length(subjMarkers)
    A{i+1,1} = old_id{subjMarkers(i)};
    A{i+1,2} = bonuses(i);
end
xlswrite('Bonuses.xlsx',A);
clear A;