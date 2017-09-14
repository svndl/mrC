function [dist,idx] = MeshDist(subId,varargin)
    % UNTITLED Summary of this function goes here
    % Detailed explanation goes here
    
    %% SET DEFAULTS
    opt	= ParseArgs(varargin,...
            'ROI',              'wholebrain', ...
            'hemi',             'both',...
            'measure',         'Geodesic', ...
            'maxDist',          30 ...
            );
    %% SET UP SYSTEM AND GET FILES
    mrC.SystemSetup;
    % get directories
    anatDir = fullfile(getpref('mrCurrent','AnatomyFolder'),subId);
    meshDir = fullfile( anatDir, 'Standard', 'meshes' );
    if ~isdir( meshDir )
        error( 'Subject %s has no /Standard/meshes directory.', subId )
    end
    % load cortices 
    subCortex = load( fullfile( meshDir, 'defaultCortex.mat' ) );
    subCortex = subCortex.msh;
    % get hemisphere indices
    hIdx{1} = 1:subCortex.nVertexLR(1); % left idx
    hIdx{2} = (subCortex.nVertexLR(1)+1):sum(subCortex.nVertexLR); % right idx
    
    %% GET ROIs
    if strcmp(opt.ROI,'wholebrain');
        roiIdx = hIdx; % all vertices
        roiHemi = opt.hemi;
    elseif exist(opt.ROI, 'file') || exist(sprintf('%s.mat',opt.ROI),'file')
        % if ROI is a file name
        [~,roiName,roiExt] = fileparts(opt.ROI);
        tmpSplit = split_string(roiName,'-');
        tmp = load(opt.ROI);
        if strcmp(tmpSplit(end),'L');
            roiHemi = 'left';
            roiIdx{1} = tmp.ROI.meshIndices;
        elseif strcmp(tmpSplit(end),'R');
            roiHemi = 'right';
            roiIdx{2} = tmp.ROI.meshIndices;
        else
            roiHemi = opt.hemi;
            msg = sprintf( '\n Hemisphere could not be decoded, from ROI %s \n', roiName );
            error(msg);
        end
        clear tmpSplit;
        clear tmp;
    else
        % try to decode ROI type and name, assuming TYPE_NAME-HEMI convention
        tmpSplit = split_string(opt.ROI,'_',2);
        roiType = split_string(opt.ROI,'_',1);
        tmpSplit = split_string(opt.ROI,'_',2,'-');
        roiName = tmpSplit{1};
        if numel(tmpSplit) == 1
            roiHemi = 'both';
        else
            if strcmp(tmpSplit{2},'L');
                roiHemi = 'left';
            elseif strcmp(tmpSplit{2},'R');
                roiHemi = 'right';
            else
                msg = sprintf( '\n Unknown hemisphere %s for ROI %s \n', roiHemi,opt.ROI );
                error(msg);
            end
        end
        switch roiType
            case{ 'wang', 'wangatlas' }
                % if wang ROI
                roiList = {'V1v' 'V1d' 'V2v' 'V2d' 'V3v' 'V3d' 'hV4' 'VO1' 'VO2' 'PHC1' 'PHC2' ...
                       'TO2' 'TO1' 'LO2' 'LO1' 'V3B' 'V3A' 'IPS0' 'IPS1' 'IPS2' 'IPS3' 'IPS4' ...
                       'IPS5' 'SPL1' 'FEF'};
                if strcmp(roiName,'V4')
                    roiName = 'hV4';
                else
                end
                if ismember(roiName,roiList)
                    roiDir = subfolders( fullfile( meshDir, '*wang*'),1);
                    roiDir = roiDir{1};
                    roiPath = subfiles( sprintf('%s/wangatlas_%s*',roiDir,roiName) , 1);
                    if roiPath{1} == 0
                        % try just using 'wang' suffix
                        roiPath = subfiles( sprintf('%s/wang_%s*',roiDir,roiName) , 1);
                    else
                    end
                else
                    roiPath{1} = 0;
                end
            case{ 'func', 'functional' }
                % if functional ROI
                roiList = {'V1d','V1v','V2v','V2d','V3v','V3d','V4','V3ab','LOC','MT','IPS0','VO1'};
                if ismember(roiName,roiList)
                    roiDir = fullfile( meshDir, 'ROIs');
                    roiPath = subfiles( sprintf('%s/func_%s*',roiDir,roiName) , 1);
                else
                    roiPath{1} = 0;
                end
            otherwise
                roiPath{1} = 0;
        end
        % roiPath should be a two-element (left and right) cell, with paths
        if roiPath{1} == 0 
            msg = sprintf( '\n ROI %s could not be found! \n', opt.ROI );
            error(msg);
        elseif numel(roiPath) > 2
            msg = sprintf( '\n ROI %s lead to multiple ROI paths, check the files in %s! \n', opt.ROI, roiDir );
            error(msg);
        else
            tmp = load(roiPath{1});
            roiIdx{1} = tmp.ROI.meshIndices; % left
            tmp = load(roiPath{2});
            roiIdx{2} = tmp.ROI.meshIndices; % right
        end
    end
    
    % if ROI contains information about hemisphere, assume that this is to
    % be used
    if ~strcmp(roiHemi,opt.hemi)
        msg = sprintf('\n ROI %s%s is in %s hemisphere, changing hemi from ''%s'' to ''%s''\n',...
        roiName,roiExt, roiHemi,opt.hemi,roiHemi);
        warning(msg);
        opt.hemi = roiHemi;
    else
    end
    switch opt.hemi
        case 'left'
            hemiIdx = 1;
        case 'right'
            hemiIdx = 2;
        case 'both'
            hemiIdx = 3;
    end
    
    %% COMPUTE DISTANCES
    if hemiIdx == 3
        curIdx = cat(2,roiIdx{1},roiIdx{2});   
    else
        curIdx = roiIdx{hemiIdx};
    end
    if strcmp(opt.measure,'Geodesic')
        barString = {'left','right','both'};
        if ~exist('vConn','var')
            % only do this the first time
            % triangles are indices starting at zero, so add one
            [c, vConn] = ...
                tess_vertices_connectivity( struct( 'faces',subCortex.data.triangles' + 1, 'vertices',subCortex.data.vertices' ) );
            nVert = numel(vConn);
        else
        end
        nInd = numel( curIdx );
        distMat = 0.5 * eye( nInd );      % Initialization of the distance matrix

        for iInd = 1:(nInd-1) % loop over all ROI vertices except one
            if nInd > 1000
                if ~exist('waitH','var')
                    waitH = waitbar(0,sprintf('Computing distances for %s ...',barString{hemiIdx}));
                else
                end
                waitbar(iInd/(nInd-1),waitH);
            else
            end
            kInd = (iInd+1):nInd;
            tmpCortex = false( 1, nVert ); % initialize 'blank' cortical surface
            tmpCortex( curIdx( iInd ) ) = true;

            distVect = zeros( 1, nInd-iInd );

            j = 1; % counter controlling the dilation iterations
            while any( distVect == 0 )
                k = find(tmpCortex);
                for iSeed = 1:numel(k)
                    % dilate all the neighbors of the seed vertex
                    tmpCortex(vConn{k(iSeed)}) = true;
                end
                % don't dilate outside ROI
                tmpCortex( setdiff( find(tmpCortex) , curIdx ) ) = false;

                % if k indices are in dilated mask, subtrack from distance
                % indices closer to the i start index will have lower values
                distVect = distVect - tmpCortex( curIdx(kInd) );
                j = j + 1;
                if j == ( opt.maxDist + 1)
                    % assigning (maxDist - 1) to remaining values means that anything
                    % beyond the max will be given twice the values max*2 (see below)
                    distVect( distVect == 0 ) = ( opt.maxDist - 1);
                    break;
                end
            end
            %if ( -min(distVect) + 1 ) ~= j
            %        error('unepected');
            %else
            %end
            [distMat(iInd,kInd),distMat(kInd,iInd)] = deal( distVect + j );
            % old way, benoit
            % if any(distVect ~= opt.maxDist)
            %   [distMat(iInd,kInd),distMat(kInd,iInd)] = deal( distVect - min(distVect) + 1 );
            % else
            %    [distMat(iInd,kInd),distMat(kInd,iInd)] = deal( distVect ) ;
            % end
        end
        % make diagonal zero
        distMat(eye(nInd)==1) = 0;
        % check values
        allowedValues = [0:opt.maxDist,opt.maxDist*2];
        curValues = unique(distMat);
        testIdx = ~ismember(curValues,allowedValues);
        if any(testIdx)
            msg = sprintf('\nIllegal value %0.0f in matrix, something''s wrong!\n',curValues(testIdx));
            error(msg);
        else
        end
    else
        distMat =  squareform( pdist( subCortex.data.vertices(:,curIdx)' , opt.measure ) );
    end        
    if hemiIdx == 1
        dist = distMat;
        idx = roiIdx{1};
    elseif hemiIdx == 2
        dist = distMat;
        idx = roiIdx{2};
    else
        % struct-style output
        dist.left = distMat(roiIdx{1},roiIdx{1});
        dist.right = distMat(roiIdx{2},roiIdx{2});
        dist.both = distMat;
        idx.left = roiIdx{1};
        idx.right = roiIdx{2};
        idx.both = cat(2,roiIdx{1},roiIdx{2});
    end
    if exist('waitH','var')
        close(waitH);
    else
    end
end
    




%     %[C, VertConn] = tess_vertices_connectivity(fsL);
%     
%     %[D,S,Q] = perform_fast_marching_mesh(fsL.vertices(fIdx{1},:), fsL.faces(fIdx{1},:), 1)
%     
%     % compute distances
%     for h = 1:length(hemis)
%         % subtract one to get afni zero indexing
%         col2 = fIdx{h}-1;
%         afniFile = fullfile(fsDir,'SUMA','lh.pial.asc');
%         for z = 1:length(fIdx{h})
%             col1 = repmat(fIdx{h}(z)-1,1,length(fIdx{h}));
%             tic;
%             for q = 1:length(col1)
%                 distMat(q,z,h) =  getDist(col1(q),col2(q),afniFile,opt);
%             end
%             toc;
%         end
%        
%     end
% function distMat = getDist(col1,col2,afniFile,opt)
%     nameStr = randString(10);
%     nodeFile = sprintf('/Users/kohler/Desktop/tmp_%s_nodes.1D',nameStr);
%     outFile = sprintf('/Users/kohler/Desktop/tmp_%s_out.1D',nameStr);
%     fid=fopen(nodeFile,'w');
%     fprintf(fid, '%.0f %.0f \n', [col1(:) col2(:)]');
%     fclose(fid);
%     clear col*;
%     if opt.Euclidian
%         doDist = sprintf('SurfDist -i %s -input %s -Euclidian > %s',afniFile,nodeFile,outFile);
%     else
%         doDist = sprintf('SurfDist -i %s -input %s > %s',afniFile,nodeFile,outFile);
%     end
%     system(doDist);
%     [~,~,distMat]=textread(outFile,'%.0f %.0f %f','commentstyle','shell');
%     system(sprintf('rm %s',outFile));
%     system(sprintf('rm %s',nodeFile));
% end
% 
% function str = randString(stLength)
%      symbols = ['a':'z' 'A':'Z' '0':'9'];
%      nums = randi(numel(symbols),[1 stLength]);
%      str = symbols(nums);
%  end
