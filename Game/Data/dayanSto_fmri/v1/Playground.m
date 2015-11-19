count = 0;
for i=2:length(round1)
    if round1(i) ~= round1(i-1)+1, count = count+1; end
end