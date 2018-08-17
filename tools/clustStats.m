function Cluster_sstat = clustStats(inData,stats)
    % EB, 8/16/2018
    inData = cat(find(max(size(inData))),0,inData,0);
    Clusters = [find(diff(inData)==1) find(diff(inData)==-1)-1];
    Cluster_sstat = abs(arrayfun(@(x) sum(stats(Clusters(x,1):Clusters(x,2))),1:size(Clusters,1)));% summary statistics
    if isempty(Cluster_sstat)
        Cluster_sstat=0;
    end
end

