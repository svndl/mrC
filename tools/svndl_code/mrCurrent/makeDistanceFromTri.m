Dman = NaN(256);
diffList = [1 2; 1 3; 2 3];
for i=1:size(tri,1);

    for j = 1:3
    from = tri(i,diffList(j,1));
    to = tri(i,diffList(j,2));

        if from==to;
            [from to]
        end
        
        Dman(from,to) = sqrt(sum((data(from,:)-data(to,:)).^2));
        Dman(to,from) = sqrt(sum((data(from,:)-data(to,:)).^2));
    end;
end


for i=1:256;
    Dman(i,i) = 0;
end
