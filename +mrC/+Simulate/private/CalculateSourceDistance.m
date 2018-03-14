function spat_dists = CalculateSourceDistance(MDATA,distanceType)

% This function calculates the distances between the sources using the
% distanceType method

%--------------------------------------------------------------------------
% INPUTS
    %   MDATA:  a structure which should have the following fields:
    %           - vertices: which is  a ns x 3 matrices indicating the source coordinates in mm
    %           - triangles: indicates the faces of the cortical meshe 
    %             (Necessary only if Geodesic distance is indicated in the input)
    %
    %   distanceType: indicates how to calculate the source distaces, [Euclidean]/ Geodesic 
    %   
%OUTPUTS
    %   spat_dists:  a ns x ns matrix indicating the sources in mm
%--------------------------------------------------------------------------
% Author: Elham Barzegaran
% Latest modification: 03.13.2018
% NOTE: This function is a part of mrC toolboxs

%%
    Euc_dist = squareform(pdist(MDATA.vertices')) ;
    %---------------------EUCLIDEAN DISTANCE-------------------------------
    if strcmp(distanceType,'Euclidean') 
        spat_dists =  Euc_dist; 
        
    %---------------------GEODESIC DISTANCE--------------------------------   
    elseif strcmp(distanceType,'Geodesic')
        faces = MDATA.triangles'; vertex = MDATA.vertices';
        [c, ~] = tess_vertices_connectivity( struct( 'faces',faces + 1, 'vertices',vertex ) ); 
        % although using graph-based shortest path algorithm, we can estimate surface distances: But this will overestimate the real
        % distances...
        
        %---Using in-built matlab function:requires matlab 2015b ornewer---
        if exist('graph')==2
            G = c.*Euc_dist;
            spat_dists = distances(graph(G));
            clear G c;
        else 
        %-----------Otherwise use Dijkstra function: very slow ------------
        % There are still some problem with this part....
            spat_dists = inf(size(c));
            warning ('If the matlab version you are using is older than 2015b, calculation of Geodesic distances might take a several hours. SUGGESTION: Use Euclidean distance instead');
            
            % this input gives an option to the user to switch to Euclidean if Geodesic is taking too much time
            cond = 1;
            while cond==1 
                inp = input('Do you want to continue with Euclidean distance? \n Enter yes to continue with Euclidean distance \n Enter no to continue with Geodesic distance',s);
                if strcmp(inp,'yes') 
                    spat_dists =  Euc_dist;
                    return
                elseif strcmp(inp,'no')
                    cond = 0;    
                end
            end
            %----------------------SLOW SHORTEST PATH----------------------
            hWait = waitbar(0,'Calculating Geodesic distances ... ');
            j = 0;% counter for waitbar
            for s = 1:length(c)
                if mod(s,20)==0, waitbar(j/length(c)); end
                if s<=MDATA.VertexLR{1} % Separate left and right hemispheres
                    sidx = 1:MDATA.VertexLR{1};
                else
                    sidx = 1+MDATA.VertexLR{1}:sum(MDATA.VertexLR);
                end
                
                if sum(sidx>s) % Apply diskstra algorithm to the hemisphere
                    spat_dists(s,sidx(sidx>=s)) = dijkstra(c(sidx,sidx),Euc_dist(sidx,sidx),find(sidx==s),find(sidx>=s),0);% complexity of this algorithm is O(|V^2|), where V is number of nodes
                end
                j = j+1;
 
            end
            spat_dists = min(spat_dists,spat_dists');
            close(hWait);
        end
    end 
end