function [isIntersecting, badPoint, uaAll, ubAll] = FindMeshSelfIntersections(vertices,faces)
%function [isIntersecting badPoint uaAll ubAll] = mrC.FindMeshSelfIntersections(vertices,faces)

allLineSegs = [];

for iFace = 1:length(faces);
 
    %The following line requires stat toolbox, changed it to a silly index
%    theseLineSegs = combnk(faces(iFace,:),2);
    theseLineSegs = reshape(faces(iFace,[1 2 1 3 2 3]),2,3)';
    allLineSegs = [allLineSegs; theseLineSegs];
end

uniqueSegments = unique(sort(allLineSegs,2),'rows');

first = allLineSegs;

uaAll = zeros(size(uniqueSegments,1),size(uniqueSegments,1));

ubAll = zeros(size(uniqueSegments,1),size(uniqueSegments,1));

badPoint = zeros(size(vertices,1),1);

for i1=1:size(uniqueSegments,1),

    for i2=setdiff([1:size(uniqueSegments,1)],i1),
        p1 = allLineSegs(i1,1);
        p2 = allLineSegs(i1,2);
        p3 = allLineSegs(i2,1);
        p4 = allLineSegs(i2,2);
        
        x1 = vertices(p1,1);
        y1 = vertices(p1,2);
        
        x2 = vertices(p2,1);
        y2 = vertices(p2,2);
        
        x3 = vertices(p3,1);
        y3 = vertices(p3,2);
        
        x4 = vertices(p4,1);
        y4 = vertices(p4,2);

        denom = (y4 - y3)*(x2-x1) - (x4-x3)*(y2-y1);
        ua = (x4 -x3)*(y1-y3)-(y4-y3)*(x1-x3);
        
        ub = (x2-x1)*(y1-y3) - (y2-y1)*(x1-x3);
        
        uaAll(i1,i2) = ua/denom;
        ubAll(i1,i2) = ub/denom;
        if (ua>(0+eps*1e5) && ua<(1-eps*1e5) && ub>(0+eps*1e5) && ub<(1-eps*1e5))
            badPoint([p1 p2 p3 p4]) = 1;
        end
        
        
    end
end


 [i j] = find(uaAll>(0+eps*1e5) & uaAll<(1-eps*1e5) & ubAll>(0+eps*1e5) & ubAll<(1-eps*1e5));
 
 
 isIntersecting = false;
 
 if ~isempty(i),
     isIntersecting = true;
 end
 
