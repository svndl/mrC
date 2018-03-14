function EOI = FindClosestElect(x,y)
% This function find the closest electrode to x,y position


load('Electrodeposition.mat');tEpos =tEpos.xy;
Epos2= repmat([x y],[128 1]);
dis = sqrt(sum((tEpos-Epos2).^2,2));
[~,EOI] = min(dis);
end