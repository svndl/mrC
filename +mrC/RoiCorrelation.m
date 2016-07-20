function RoiCorrelation(subId,type)
% Description:	Generate roi correlation matrices used for doing 
%               source localization with a functional area constrained
%               estimator (FACE).
%               See: Cottereau BR, Ales JM, Norcia AM (2012) Human brain mapping 33:2694-2713.
%               This is a slightly modified version of a function by B.
%               Cottereau.
% Syntax:  mrC.RoiCorrelation(subId, type)
% In:
%   subId    - a string specifying the subject ID, without '_fs4' suffix (if given, it will be
%                 removed
%   type     - a string specifying the type (or set) of ROIs used for correlation matrix
%              (['func']/'wangatlas')

if nargin < 2
    type = 'func';
else
end

mrC.SetPrefs; % make sure preferences are set
if strfind(subId,'_fs4');
    subId = subId(1:end-4); % get rid of FS suffix, if given by user
else
end

anatDir = fullfile(getpref('mrCurrent','AnatomyFolder'),subId);
meshDir = fullfile( anatDir, 'Standard', 'meshes' );
if ~isdir( meshDir )
	error( 'Subject %s has no /Standard/meshes directory.', subId )
end
subCortex = load( fullfile( meshDir, 'defaultCortex.mat' ) );

[C, VertConn] = ...
    tess_vertices_connectivity( struct( 'faces',subCortex.msh.data.triangles' + 1, 'vertices',subCortex.msh.data.vertices' ) );
nVert = numel(VertConn);

if strcmp(type, 'func')
    ROIlist = {'V1d','V1v','V2v','V2d','V3v','V3d','V4','V3ab','LOC','MT','IPS0','VO1'};
    ROIcorrFile = fullfile( meshDir, 'ROIs_correlation.mat' );
elseif strfind(type,'wang')
    type = 'wangatlas';
    ROIlist = {'V1v' 'V1d' 'V2v' 'V2d' 'V3v' 'V3d' 'hV4' 'VO1' 'VO2' 'PHC1' 'PHC2' ...
    'TO2' 'TO1' 'LO2' 'LO1' 'V3B' 'V3A' 'IPS0' 'IPS1' 'IPS2' 'IPS3' 'IPS4' ...
    'IPS5' 'SPL1' 'FEF'};
    ROIcorrFile = fullfile( meshDir, 'WANG_correlation.mat' );
else
    error(['Unknown ROI type: ',type])
end

if exist( ROIcorrFile, 'file' )
	warning([ROIcorrFile,' exists.  Not overwriting.'])
	return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Definition of the correlation within each of the ROIs

nROIs = numel(ROIlist) * 2;
ROIs = struct( 'ndx',{cell(1,nROIs)}, 'corr',{cell(1,nROIs)}, 'name',{reshape([strcat(type,'_',ROIlist,'-L');strcat(type,'_',ROIlist,'-R')],1,nROIs)} );
max_value = 30;
cntROI = 0;
for iROI = 1:nROIs
    if exist(fullfile( meshDir, 'ROIs', [ROIs.name{iROI},'.mat'] ),'file')
        cntROI = cntROI+1; % increment counter;
		
        load( fullfile( meshDir, 'ROIs', ROIs.name{iROI} ) ); % load ROI
        ROIs.ndx{cntROI} = ROI.meshIndices;
        nInd = numel( ROI.meshIndices );

        dist = 0.5 * eye( nInd );      % Initialization of the distance matrix

        for iInd = 1:(nInd-1)

            kInd = (iInd+1):nInd;
            tmp = false( 1, nVert );
            tmp( ROI.meshIndices( iInd ) ) = true;

            distance = zeros( 1, nInd-iInd );

            i = 1;	% #dilation iterations
            j = 1;
            while any( distance == 0 )

    % 			tmp = dilatation( tmp , VertConn , i );
                for iDil = 1:i
                    k = find(tmp);
                    for iSeed = 1:numel(k)
                        tmp(VertConn{k(iSeed)}) = true;
                    end
                end
                % don't dilate outside ROI
                tmp( setdiff( find(tmp) , ROI.meshIndices ) ) = false;

                distance = distance - tmp( ROI.meshIndices(kInd) );
                j = j + 1;
                if j == 30
                    distance( distance == 0 ) = max_value;
                    break;
                end
            end
            if any(distance ~= max_value)
                [dist(iInd,kInd),dist(kInd,iInd)] = deal( distance - min(distance) + 1 );
            else
                [dist(iInd,kInd),dist(kInd,iInd)] = deal( distance );
            end
        end

        ROIs.corr{cntROI} = 0.5 ./ dist + eye(nInd);
        for iInd = 1 : nInd
            ROIs.corr{cntROI}( iInd , ROIs.corr{cntROI}(iInd,:) < 0.2 ) = 0;
        end

        [V,D] = eig( ROIs.corr{cntROI} );
        D_tmp = diag( D );
        if any( D_tmp <= 0 )
            D_tmp( D_tmp < 0 ) = 0.0001;
            ROIs.corr{cntROI} = ( V * diag( D_tmp ) * inv( V ) );
        end
        included(cntROI)={ROIs.name{iROI}};
    else
    end
end

if exist('included','var')
    not_included = find(~ismember(ROIs.name,included));
    if ~isempty(not_included)
        disp(cell2mat(['NOT INCLUDED:',cellfun(@(x) [' ',x],ROIs.name(not_included),'uni',false)]))
    else
    end
    save( ROIcorrFile, 'ROIs' )
else
    warning('No ROIs! Not creating matrix')
end



