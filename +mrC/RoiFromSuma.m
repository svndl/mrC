function RoiFromSuma(subId,varargin)
    % Description:	Convert ROIs from SUMA to mrCurrent
    % 
    % Syntax:	mrC.RoiFromSuma(subId,varargin)
    % In:
    %   subId - subject ID, without '_fs4' suffix (if given, it will be
    %           removed
    %
    %   <options>:
    %       mode:   string specifying the mode, aka the set of ROIs to convert 
    %               (['func']/'benson'/'wangatlas'/'glasser')
    %
    %       cortexfile: string specifying the full path to the mrMesh cortex file
    %
    %       ecc_range: 2 integer vector designating the minimum and maximum eccentricity
    %                  to use with Benson ROIs. Does nothing if other ROIs
    %                  are used. Default: ask which eccentricities to use
    %       plotting:  a logical variable,indicates ploting ROIs or not
    %                   [true]/false
    %       
    % Out:
    
    mrC.SystemSetup; % make sure preferences are set
    
    %% DETERMINE FREESURFER DIR
    if strfind(subId,'_fs4');
        subId = subId(1:end-4); % get rid of FS suffix, if given by user
    else
    end
    fsDir = fullfile(getpref('freesurfer','SUBJECTS_DIR'),[subId,'_fs4']);
    anatDir = fullfile(getpref('mrCurrent','AnatomyFolder'),subId);
    
    %% SET DEFAULTS
    opt	= ParseArgs(varargin,...
            'mode'		 , 'wangatlas', ...
            'cortexfile' , 	 fullfile(anatDir,'/Standard/meshes/defaultCortex.mat'), ...
            'ecc_range'  ,   [0,0], ...
            'plotting'   ,   true ...
            );
    
    if strcmp(opt.mode,'wangatlas')
        opt.mode = 'wang'; % ensure flexibility
    else
    end
    
    if strcmp(opt.mode,'glasser')
        opt.mode = 'glass'; % ensure flexibility
    else
    end
    
    %% GET ROI FILE
    if strcmp(opt.mode,'benson')
        roiNames = {'V3d','V2d','V1d','V1v','V2v','V3v'};
        %roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*h.Benson2014.all.niml.dset',fsDir),1);
        roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*Benson*.dset',fsDir),1);
        if ~roiFile{1}, roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*benson*.dset',fsDir),1); end
        
        if max(opt.ecc_range) == 0
            eccMin = input('Minimum eccentricity? [default = 0] ');
            if isempty(eccMin)
                eccMin = 0;
            else
            end
            eccMax = input('Maximum eccentricity? [default = 10, >80 = include all] ');
            if isempty(eccMax)
                eccMax = 10;
            elseif eccMax > 80 
                eccMax = 100;
            else
            end
        else
            eccMin = opt.ecc_range(1);
            eccMax = opt.ecc_range(2);
        end
    elseif strcmp(opt.mode,'wang')
        %roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*h.Wang2015_cluster.niml.dset',fsDir),1);
        roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*Wang*cluster.niml.dset',fsDir),1);
        if ~roiFile{1}, roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*wang*cluster.niml.dset',fsDir),1); end
        
        if roiFile{1} == 0
            warning('\n ... using unclustered ROI-file ...\n');
            roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*h.Wang2015.niml.dset',fsDir),1);
        else
        end
        roiNames = {'V1v' 'V1d' 'V2v' 'V2d' 'V3v' 'V3d' 'hV4' 'VO1' 'VO2',...
                    'PHC1' 'PHC2','TO2' 'TO1' 'LO2' 'LO1' 'V3B' 'V3A',...  
                    'IPS0' 'IPS1' 'IPS2' 'IPS3' 'IPS4','IPS5' 'SPL1' 'FEF'};
        eccComment = 'atlas, generated based on Wang et al., 2015';
    elseif strcmp(opt.mode,'glass')
        %roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*h.Glasser2016.niml.dset',fsDir),1);
        roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*Glasser*.dset',fsDir),1);
        if ~roiFile{1}, roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*glass*.dset',fsDir),1); end
        
        roiNames = arrayfun(@(x) sprintf('roi%03d',x),1:180,'uni',false); 
        % true names can be found on pgs. 81-85 of the supplementary material.
        eccComment = 'atlas, generated based on Glasser et al., 2016';
    elseif strcmp(opt.mode,'kgs')
        %roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*h.KGS2016.niml.dset',fsDir),1);
        roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*KGS*.dset',fsDir),1);
        if ~roiFile{1}, roiFile = subfiles(sprintf('%s/TEMPLATE_ROIs/*kgs*.dset',fsDir),1); end
        
        roiNames = {'IOG','OTS','mFUS','pFUS','PPA','VWFA1','VWFA2'};
        eccComment = 'atlas, generated based on Weiner & Grill-Spector (in press)';
    else
         % if functionally defined ROIs, users have to specify files manually
        targetFolder = ['/Volumes/Denali_4D2/kohler/localizers/',subId,'/*.niml.roi'];
        [roiFile,roiPath] = uigetfile(targetFolder,'SUMA NIML file?','MultiSelect','on');
        if isnumeric(roiFile)
            return
        end
        if iscell(roiFile)
            roiFile = cellfun(@(x) [roiPath,x],roiFile,'uni',false);
        else
            tempFile = [roiPath,roiFile];
            clear roiFile;
            roiFile{1} = tempFile;
        end
    end
    
    if roiFile{1} == 0
        msg = sprintf('\n ... %s ROI files have not been found for subject %s ... \n',opt.mode,subId);
        error(mgs);
    else
    end

    %% LOAD MRMESH CORTEX AND TRANSFORM TO MATCH FREESURFER
    load(opt.cortexfile);
    msh.nVertex = sum(msh.nVertexLR);
    % sanity check
    if any( [ size(msh.data.vertices,2), size(msh.initVertices,2) ] ~= msh.nVertex )
        error('vertex disagreement within %s',opt.cortexfile)
    end
    % get hash before doing any transforms
    meshHash = hashOld(msh.data.vertices(:),'md5');
    ctx.triangles = (msh.data.triangles+1)';
    ctx.vertices(:,1) = msh.data.vertices(3,:)-128;
    ctx.vertices(:,2) = -msh.data.vertices(1,:)+128;
    ctx.vertices(:,3) = -msh.data.vertices(2,:)+128;
    
    kL = 1:msh.nVertexLR(1);
    kR = (msh.nVertexLR(1)+1):msh.nVertex;
    
    %% READ AND RESAMPLE FREESURFER DATA
    FSvL = freesurfer_read_surf(fullfile(fsDir,'surf','lh.pial'));
    [iL,e2L] = nearpoints(ctx.vertices(kL,:)',FSvL');				% nearpoints(src,dst), indices can have duplicate entries
    FSvR = freesurfer_read_surf(fullfile(fsDir,'surf','rh.pial'));
    [iR,e2R] = nearpoints(ctx.vertices(kR,:)',FSvR');
    if any( [e2L,e2R] > (0.001^2) )
        error('chosen mrMesh Cortex doesn''t align with Freesurfer surfaces')
    end
    
    %% READ SUMA 1D ROI
    nROI = [0 0];
    iROI = 0;
    ROIs = struct('name','','coords',[],'color',[],'ViewType','','meshIndices',[],'eccData',[],'meshHash','','date','','comment','');
    creationTime = datestr(now,0);
    for z=1:length(roiFile)
        [~,tempName,ext]=fileparts(roiFile{z});
        hemi = upper(tempName(1)); % get hemisphere from roi name
        if strfind(lower(ext),'roi') % if it's a proper ROI file
            tempStrct = afni_niml_read(roiFile{z}); % get color info and potentially all info
            nimlStrct = afni_niml_readsimpleroi(roiFile{z});
            for strctIdx=1:length(nimlStrct)
                iROI =iROI + 1;
                ROIs(iROI).name = [nimlStrct{strctIdx}.Label,'-',hemi]; %% add hemisphere to name
                ROIs(iROI).coords = [];
                tempIndices = unique([nimlStrct{strctIdx}.region{1};cell2mat(nimlStrct{strctIdx}.edge')]);
                if strcmp(hemi,'L')
                    nROI(1) = nROI(1)+1;
                    label = zeros(1,length(FSvL));
                    label(tempIndices)=1;
                    ROIs(iROI).meshIndices = kL(label(iL)==1);
                elseif strcmp(hemi,'R')
                    nROI(2) = nROI(2)+1;
                    label = zeros(1,length(FSvR));
                    label(tempIndices)=1;
                    ROIs(iROI).meshIndices = kR(label(iR)==1);
                else
                    error('ERROR: Hemisphere could not be deduced from ROI name!')
                end
                ROIs(iROI).meshHash = meshHash;
                tempColor = str2num(tempStrct{strctIdx}.FillColor);
                ROIs(iROI).color = tempColor(1:3);
                ROIs(iROI).ViewType = 'Gray';
                ROIs(iROI).date = creationTime;
                ROIs(iROI).type = opt.mode;
                ROIs(iROI).comment = [opt.mode,': Converted from SUMA using mrC.ConvertROI'];
            end
        elseif strcmp(opt.mode,'benson') % if it is not a proper ROI file, this is designed specifically for Noah Benson's ROI data
            cmap = distinguishable_colors(10);
            colors = cmap(end-length(roiNames)-1:end,:);
            nimlStrct = afni_niml_readsimple(roiFile{z});
            roiData = nimlStrct.data(:,3); % roi data should be stored in 3rd sub-brick
            eccData = nimlStrct.data(:,2); % eccentricity data should be stored in 2nd sub-brick
            roiMapping = [-3,-2,-1,1,2,3]; % negative values are dorsal areas, positive values are ventral
            if max(abs(roiData)) ~= 3
                error('Expected max area idx = 3, was %.2f',max(roiData));
            elseif max(eccData) > 100
                error('Expected max eccentricity idx ~100, was %.2f',max(eccData));
            else
            end
            if eccMin == 0 && eccMax > 80 %% include everything
                eccComment = 'V1-V3 with ecc: all';
                eccIndices = ones(size(roiData,1),1);
                bensonSuffix = 'all';
            else
                eccComment = ['V1-V3 with ecc: ',num2str(eccMin),'-',num2str(eccMax)];
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %eccIndices = eccData>eccMin & eccData<eccMax;
                eccIndices = eccData>0;
                
                bensonSuffix = [num2str(eccMin),'-',num2str(eccMax)];
            end
            for z=1:length(roiMapping)
                iROI =iROI + 1;
                ROIs(iROI).name = [roiNames{z},'_',bensonSuffix,'-',hemi]; %% add hemisphere to name
                ROIs(iROI).coords = [];
                tempIndices = find(roiData==roiMapping(z) & eccIndices==1);
                if strcmp(hemi,'L')
                    nROI(1) = nROI(1)+1;
                    label = zeros(1,length(FSvL));
                    label(tempIndices)=1;
                    ROIs(iROI).meshIndices = kL(label(iL)==1);
                    %ROIs(iROI).eccData = eccData(label(iL)==1)';
                    IL = zeros(size(label));IL(iL) =  1;                   
                    ROIs(iROI).eccData =  eccData((label .*IL)==1)';
                elseif strcmp(hemi,'R')
                    nROI(2) = nROI(2)+1;
                    label = zeros(1,length(FSvR));
                    label(tempIndices)=1;
                    ROIs(iROI).meshIndices = kR(label(iR)>0);
%                     ROIs(iROI).eccData = eccData(label(iR)==1)';
                    IR = zeros(size(label));IR(iR) =  1;
                    ROIs(iROI).eccData =  eccData((label .*IR)==1)';
                else
                    error('ERROR: Hemisphere could not be deduced from ROI name!')
                end
                ROIs(iROI).meshHash = meshHash;
                ROIs(iROI).color = colors(z,:);
                ROIs(iROI).ViewType = 'Gray';
                ROIs(iROI).date = creationTime;
                ROIs(iROI).type = opt.mode;
                ROIs(iROI).comment = [opt.mode,': Converted from SUMA using mrC.ConvertROI.',eccComment];
            end
            disp(eccComment);
        else % wang, kgs or glasser
            cmap = distinguishable_colors(length(roiNames)+1);
            colors = cmap(2:end,:);
            nimlStrct = afni_niml_readsimple(roiFile{z});
            eccIndices = ones(length(nimlStrct.data),1);
            for z=1:length(roiNames)
                iROI =iROI + 1;
                ROIs(iROI).name = [roiNames{z},'-',hemi]; %% add hemisphere to name
                ROIs(iROI).coords = [];
                tempIndices = find(nimlStrct.data(:,1)==z & eccIndices==1);
                if strcmp(hemi,'L')
                    nROI(1) = nROI(1)+1;
                    label = zeros(1,length(FSvL));
                    label(tempIndices)=1;
                    ROIs(iROI).meshIndices = kL(label(iL)==1);
                elseif strcmp(hemi,'R')
                    nROI(2) = nROI(2)+1;
                    label = zeros(1,length(FSvR));
                    label(tempIndices)=1;
                    ROIs(iROI).meshIndices = kR(label(iR)==1);
                else
                    error('ERROR: Hemisphere could not be deduced from ROI name!')
                end
                ROIs(iROI).meshHash = meshHash;
                ROIs(iROI).color = colors(z,:);
                ROIs(iROI).ViewType = 'Gray';
                ROIs(iROI).date = creationTime;
                ROIs(iROI).type = opt.mode;
                ROIs(iROI).comment = [opt.mode,': Converted from SUMA using mrC.ConvertROI.',eccComment];
            end
            disp(eccComment);
        end
    end
    
    %% REMOVE OVERLAP AMONG ROIs AND PAINT ROI DATA
    cdata = ones(msh.nVertex,3)*.5;
    allIndices = cat(2,ROIs(:).meshIndices);
    overlapMesh = non_unique(allIndices);
    for iROI = 1:sum(nROI)
        tempMesh = ROIs(iROI).meshIndices(~ismember(ROIs(iROI).meshIndices,overlapMesh)); % remove overlap
        if ~isempty(ROIs(iROI).eccData)
            tempEcc = ROIs(iROI).eccData(~ismember(ROIs(iROI).meshIndices,overlapMesh)); % remove overlap
        else
            tempEcc =[];
        end
        overlapRate = length(find(ismember(ROIs(iROI).meshIndices,overlapMesh)))/length(ROIs(iROI).meshIndices)*100;
        if overlapRate > 0
            ROIs(iROI).meshIndices = tempMesh;
            ROIs(iROI).eccData = tempEcc;
            fprintf('Warning: ROI %s overlaps by %0.4g percent\n',ROIs(iROI).name,overlapRate)
        else
        end
        cdata(ROIs(iROI).meshIndices,:) = repmat(ROIs(iROI).color,numel(ROIs(iROI).meshIndices),1);
    end
    disp(['Total overlap: ',num2str(length(overlapMesh))])
    
    opt.ROIs = ROIs; % add ROIs to opt struct
    
    %% PLOT ROIs
    if opt.plotting
        kFr = find(ctx.triangles(:,1) > msh.nVertexLR(1),1,'first');		% 1st RH face index
        figH = figure('name',sprintf('%s ',opt.mode));
        subplot(121)
            patch(struct('vertices',ctx.vertices(kL,:),'faces',ctx.triangles(1:(kFr-1),:)),...
                'facevertexcdata',cdata(kL,:),'facecolor','interp','facelighting','gouraud','edgecolor','none')
            light('position',[0 0  256])
            light('position',[0 0 -256])
            light('position',[ 256 0 0])
            light('position',[-256 0 0])
            xlabel('+Right'),ylabel('+Anterior'),zlabel('+Superior'),title('LEFT')
            set(gca,'dataaspectratio',[1 1 1],'view',[0 90],'xlim',[-100 25],'ylim',[-150 100],'zlim',[-100 150])
        subplot(122)
            patch(struct('vertices',ctx.vertices(kR,:),'faces',ctx.triangles(kFr:end,:)-msh.nVertexLR(1)),...
                'facevertexcdata',cdata(kR,:),'facecolor','interp','facelighting','gouraud','edgecolor','none')
            light('position',[0 0  256])
            light('position',[0 0 -256])
            light('position',[ 256 0 0])
            light('position',[-256 0 0])
            xlabel('+Right'),ylabel('+Anterior'),zlabel('+Superior'),title('RIGHT')
            set(gca,'dataaspectratio',[1 1 1],'view',[0 90],'xlim',[-25 100],'ylim',[-150 100],'zlim',[-100 150])

        UIm = uimenu('label','HemiViews');
        uimenu(UIm,'label','dorsal','callback','set([subplot(121),subplot(122)],''view'',[0 90])')
        uimenu(UIm,'label','ventral','callback','set([subplot(121),subplot(122)],''view'',[0 -90])')
        uimenu(UIm,'label','medial','callback','set(subplot(121),''view'',[90 0]),set(subplot(122),''view'',[-90 0])')
        uimenu(UIm,'label','lateral','callback','set(subplot(121),''view'',[-90 0]),set(subplot(122),''view'',[90 0])')
        uimenu(UIm,'label','anterior','callback','set([subplot(121),subplot(122)],''view'',[180 0])')
        uimenu(UIm,'label','posterior','callback','set([subplot(121),subplot(122)],''view'',[0 0])')
        guidata(figH,opt);
        uimenu(UIm,'label','SAVE ROIs','separator','on','callback',@saveAnatROIs)
    else
        
        saveAnatROIs('data',opt)
    end
    
    
    function saveAnatROIs(varargin)
        opts	= ParseArgs(varargin,'data'	, []);
        in = [];
        if ~isempty(findobj('type','figure'))
            in = guidata(gcf);
        end
        if isempty(in)
            in = opts.data;
        end
        outDir = [fileparts(in.cortexfile),'/',in.ROIs(1).type,'_ROIs']; % default output directory 
        if ~exist(outDir,'dir')
            mkdir(outDir);
        else
        end
        
        if ~(in.plotting) && exist(outDir,'dir')
             ROIdir = outDir;
        else
            ROIdir = uigetdir(outDir,'ROI output directory');
        end
        
        if ~isnumeric(ROIdir)
            for i = 1:length(in.ROIs)
                ROI = in.ROIs(i);
                ROIfile = fullfile(ROIdir,[ROI.type,'_',ROI.name,'.mat']);
                disp(['writing ',ROIfile])
                save(ROIfile,'ROI')
            end
            set(gcbo,'visible','off')
            disp(['wrote ',int2str(i),' mesh ROI files.'])
        end
    end

    function out_array = non_unique(in_array)
        sv = sort(in_array);
        idx = sv(2:end) == sv(1:end-1);
        out_array = in_array(ismember(in_array,sv(idx)));
    end
end
