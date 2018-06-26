function RoiCorrelation(subId,type,overwrite)
    % Description:	Generate roi correlation matrices used for doing 
    %               source localization with a functional area constrained
    %               estimator (FACE).
    %               See: Cottereau BR, Ales JM, Norcia AM (2012) Human brain mapping 33:2694-2713.
    %               This is a slightly modified version of a function by B. Cottereau.
    % 
    % Syntax:  mrC.RoiCorrelation(subId, type)
    % In:
    %   subId    - a string specifying the subject ID, without '_fs4' suffix (if given, it will be
    %                 removed
    %   type     - a string specifying the type (or set) of ROIs used for correlation matrix
    %              (['func']/'wangatlas')
    %   overwrite     - a logical indicating whether to overwrite the ROI
    %                 correlation file (true/[false])              

    if nargin < 2
        type = 'func';
    else
    end
    if nargin < 3
        overwrite = true;
    else
    end

    mrC.SystemSetup; % make sure system is setup

    if strfind(subId,'_fs4');
        subId = subId(1:end-4); % get rid of FS suffix, if given by user
    else
    end

    anatDir = fullfile(getpref('mrCurrent','AnatomyFolder'),subId);
    meshDir = fullfile( anatDir, 'Standard', 'meshes' );
    if ~isdir( meshDir )
        error( 'Subject %s has no /Standard/meshes directory.', subId )
    end

    %% GET FILE AND ROI NAMES

    if strcmp(type, 'func')
        ROIlist = {'V1d','V1v','V2v','V2d','V3v','V3d','V4','V3ab','LOC','MT','IPS0','VO1'};
        ROIcorrFile = fullfile( meshDir, 'ROIs_correlation.mat' );
    elseif strcmp(type,'wangkgs')
        ROIlist1 = {'V1v' 'V1d' 'V2v' 'V2d' 'V3v' 'V3d' 'hV4' 'VO1' 'VO2' 'PHC1' 'PHC2' ...
        'TO2' 'TO1' 'LO2' 'LO1' 'V3B' 'V3A' 'IPS0' 'IPS1' 'IPS2' 'IPS3' 'IPS4' ...
        'IPS5' 'SPL1' 'FEF'};
        ROIlist2 = {'IOG' 'mFUS' 'OTS' 'pFUS' 'PPA' 'VWFA1' 'VWFA2'};
        ROIcorrFile = fullfile( meshDir, 'WANGKGS_correlation.mat' );
    elseif strfind(type,'wang')
        type = 'wang';%'wangatlas';
        ROIlist = {'V1v' 'V1d' 'V2v' 'V2d' 'V3v' 'V3d' 'hV4' 'VO1' 'VO2' 'PHC1' 'PHC2' ...
        'TO2' 'TO1' 'LO2' 'LO1' 'V3B' 'V3A' 'IPS0' 'IPS1' 'IPS2' 'IPS3' 'IPS4' ...
        'IPS5' 'SPL1' 'FEF'};
        ROIcorrFile = fullfile( meshDir, 'WANG_correlation.mat' );
    else
        error(['Unknown ROI type: ',type])
    end

    if exist( ROIcorrFile, 'file' )
        if ~overwrite
            msg = sprintf('\n%s exists. Not overwriting.\n',ROIcorrFile);
            warning(msg);
            return
        else
            msg = sprintf('\n%s exists, renaming with ''_old'' prefix.\n',ROIcorrFile);
            disp(msg);
            movefile(ROIcorrFile,sprintf('%s_old.mat',ROIcorrFile(1:end-4)));
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Definition of the correlation within each of the ROIs
    if strcmp(type,'wangkgs')
        nROIs = (numel(ROIlist1)+numel(ROIlist2)) * 2;
        ROIs = struct( 'ndx',{cell(1,nROIs)}, 'corr',{cell(1,nROIs)}, 'name',{reshape([strcat('wang','_',ROIlist1,'-L') strcat('kgs','_',ROIlist2,'-L');strcat('wang','_',ROIlist1,'-R') strcat('kgs','_',ROIlist2,'-R')],1,nROIs)} );
        ROIname2 = reshape([strcat('wang','atlas_',ROIlist1,'-L') strcat('kgs','_',ROIlist2,'-L');strcat('wang','atlas_',ROIlist1,'-R') strcat('kgs','_',ROIlist2,'-R')],1,nROIs);
    else
        nROIs = numel(ROIlist) * 2;
        ROIs = struct( 'ndx',{cell(1,nROIs)}, 'corr',{cell(1,nROIs)}, 'name',{reshape([strcat(type,'_',ROIlist,'-L');strcat(type,'_',ROIlist,'-R')],1,nROIs)} );
        if strcmp(type,'wang')
            ROIname2 = reshape([strcat(type,'atlas_',ROIlist,'-L');strcat(type,'atlas_',ROIlist,'-R')],1,nROIs);
        end
    end
    cntROI = 0;
    for iROI = 1:nROIs
        % loop over complete set of ROIs
        roiPath = fullfile( meshDir, 'ROIs', ROIs.name{iROI} );
        E1 = exist([roiPath '.mat'],'file');
        if (strcmp(type,'wang') || strcmp(type,'wangkgs')) && ~E1
            roiPath = fullfile( meshDir, 'ROIs', ROIname2{iROI});
            E1 = exist([roiPath '.mat'],'file');
            if E1, ROIs.name = ROIname2;end
        end
        if E1
            cntROI = cntROI+1; % increment counter;
            if strcmp(split_string(ROIs.name{iROI},'-',2),'L')
                curHemi = 'left';
            else
                curHemi = 'right';
            end
            
            if strfind(ROIs.name{iROI},'kgs')
                % Get the previous ROIs vertices
                Prevndx = cat(2,ROIs.ndx{:});
                % Read the ROI
                [ ~, ROIs.ndx{cntROI} ] = mrC.MeshDist(subId,'ROI',roiPath,'hemi',curHemi);
                % Remove the reperated vertices
                Repndx = intersect(Prevndx,ROIs.ndx{cntROI});
                ROIs.ndx{cntROI} = setdiff(ROIs.ndx{cntROI},Repndx);
                % Set the corr matrix diagonal to enhance inverse results for these sources
                ROIs.corr{cntROI} = eye(numel(ROIs.ndx{cntROI}))*4.5;
            else
                [ dist, ROIs.ndx{cntROI} ] = mrC.MeshDist(subId,'ROI',roiPath,'hemi',curHemi);
                nInd = numel( ROIs.ndx{cntROI} );
                % mrC.MeshDist outputs zeroes on the diagonal, replace with 0.5
                dist( eye(nInd)==1 ) = 0.5;
                ROIs.corr{cntROI} = 0.5 ./ dist + eye(nInd);
                for iInd = 1 : nInd
                    ROIs.corr{cntROI}( iInd , ROIs.corr{cntROI}(iInd,:) < 0.2 ) = 0;
                end
                
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
end



