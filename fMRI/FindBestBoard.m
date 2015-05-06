corrs = zeros(size(PEs,3),1);
for i = 1:size(PEs,3)
    temp = corrcoef(PEs(:,3,i),PEs(:,4,i));
    corrs(i) = temp(2,1);
end

[a,b] = min(corrs)