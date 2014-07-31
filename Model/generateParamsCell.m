function [params, negLLs] = generateParamsCell(matrix1, matrix2, matrix3, matrix4)
numModels = nargin;
params = cell(numModels,1);
params{1} = matrix1(:,2:(end-1));
params{2} = matrix2(:,2:(end-1));
if numModels >= 3
    params{3} = matrix3(:,2:(end-1));
end
if numModels >= 4
    params{4} = matrix4(:,2:(end-1));
end

negLLs = [matrix1(:,end) matrix2(:,end)];
if numModels >= 3
    negLLs = [negLLs matrix3(:,end)];
end
if numModels >= 4
    negLLs = [negLLs matrix4(:,end)];
end

end