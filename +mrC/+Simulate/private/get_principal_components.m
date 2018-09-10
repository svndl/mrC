function [result, v,sv,varexp] = get_principal_components(X, numComponents)

%scal not a matlab builtin and I don't know where its from
%X = scal(X, mean(X));
%fixed to use the bsxfun which is a matlab builtin for a few years now.
% This is from LASSO toolbox
%%
if numComponents>size(X,2)
    result =[];
    v=[];sv =[]; varexp=0;
    return
end

X = bsxfun(@minus,X,mean(X));

[~, sv, v] = svd(X);
varexp = sum(diag(sv(1:numComponents,1:numComponents)))/sum(diag(sv));
v = v(:, 1:numComponents);
result = X*v;
