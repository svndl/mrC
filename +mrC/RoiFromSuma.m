function RoiFromSuma(subId,varargin)
    % Description:	Convert ROIs from SUMA to mrCurrent
    % 
    % Syntax:	mrC.RoiFromSuma(subId,varargin)
    % In:
    %   subId - subject ID, without '_fs4' suffix (if given, it will be
    %           removed
    %
    %   <options>:
    %       Mode:   string specifying the mode, aka the set of ROIs to convert 
    %               (['func']/'benson'/'wangatlas')
    %
    %       CortexFile: string specifying the full path to the mrMesh cortex file
    %                        
    % Out:
    
    mrC.SetPrefs; % make sure preferences are set
    
    %% DETERMINE FREESURFER DIR
    if strfind(subId,'_fs4');
        subId = subId(1:end-4); % get rid of FS suffix, if given by user
    else
    end
    fsDir = fullfile(getpref('freesurfer','SUBJECTS_DIR'),[subId,'_fs4']);
    anatDir = fullfile(getpref('mrCurrent','AnatomyFolder'),subId);
    
    %% SET DEFAULTS
    opt	= ParseArgsOpt(varargin,...
            'Mode'		 , 'wangatlas', ...
            'CortexFile' , 	 fullfile(anatDir,'/Standard/meshes/defaultCortex.mat') ...
            );
    
    if strcmp(opt.Mode,'wang')
        opt.Mode = 'wangatlas'; % ensure flexibility
    else
    end
    
    if strcmp(opt.Mode,'glasser')
        opt.Mode = 'glass'; % ensure flexibility
    else
    end
    
    %% GET ROI FILE
    if strcmp(opt.Mode,'benson')
        roiNames = {'V1','V2','V3'};
        targetFolder = [fsDir,'/benson_atlas/*.niml.dset'];
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
    elseif strcmp(opt.Mode,'wangatlas')
        targetFolder = [fsDir,'/wang_atlas/*cluster.niml.dset'];
        roiNames = {'V1v' 'V1d' 'V2v' 'V2d' 'V3v' 'V3d' 'hV4' 'VO1' 'VO2',...
                    'PHC1' 'PHC2','TO2' 'TO1' 'LO2' 'LO1' 'V3B' 'V3A',...  
                    'IPS0' 'IPS1' 'IPS2' 'IPS3' 'IPS4''IPS5' 'SPL1' 'FEF'};
        eccComment = 'atlas, generated based on Wang et al., 2014';
    elseif strcmp(opt.Mode,'glass')
        targetFolder = [fsDir,'/glass_atlas/*glass_atlas.niml.dset'];
        roiNames = arrayfun(@(x) sprintf('roi%03d',x),1:180,'uni',false); 
        % true names can be found on pgs. 81-85 of the supplementary material.
        eccComment = 'atlas, generated based on Glasser et al., 2016';
    elseif strcmp(opt.Mode,'kgs')
        targetFolder = [fsDir,'/kgs_atlas/*kgs_atlas.niml.dset'];
        roiNames = {'IOG','OTS','mFUS','pFUS','PPA','VWFA1','VWFA2'};
        eccComment = 'atlas, generated based on Weiner & Grill-Spector (in press)';
    else
        targetFolder = ['/Volumes/Denali_4D2/kohler/localizers/',subId,'/*.niml.roi'];
    end
    
    % currently users have to specify files manually - perhaps get rid of
    % this, but on the other hand a good check that you know what you are
    % doing ...
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
    
    %% LOAD MRMESH CORTEX AND TRANSFORM TO MATCH FREESURFER
    load(opt.CortexFile);
    msh.nVertex = sum(msh.nVertexLR);
    % sanity check
    if any( [ size(msh.data.vertices,2), size(msh.initVertices,2) ] ~= msh.nVertex )
        error('vertex disagreement within %s',opt.CortexFile)
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
    ROIs = struct('name','','coords',[],'color',[],'ViewType','','meshIndices',[],'meshHash','','date','','comment','');
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
                ROIs(iROI).type = opt.Mode;
                ROIs(iROI).comment = [opt.Mode,': Converted from SUMA using mrC.ConvertROI'];
            end
        elseif strcmp(opt.Mode,'benson') % if it is not a proper ROI file, this is designed specifically for Noah Benson's ROI data
            cmap = distinguishable_colors(10);
            colors = cmap(end-length(roiNames)-1:end,:);
            nimlStrct = afni_niml_readsimple(roiFile{z});
            if eccMin == 0 && eccMax > 80 %% include everything
                eccComment = 'V1-V3 with ecc: all';
                eccIndices = ones(length(nimlStrct.data),1);
                eccMode = [opt.Mode,'_all'];
            else
                eccFile{z} = roiFile{z};
                eccFile{z}(strfind(roiFile{z},'areas'):strfind(roiFile{z},'areas')+4)='eccen';
                eccStrct = afni_niml_readsimple(eccFile{z});
                eccIndices = eccStrct.data>eccMin & eccStrct.data<eccMax;
                eccComment = ['V1-V3 with ecc: ',num2str(eccMin),'-',num2str(eccMax)];
                eccMode = [opt.Mode,num2str(eccMin),'-',num2str(eccMax)];
            end
            for z=1:length(roiNames)
                iROI =iROI + 1;
                ROIs(iROI).name = [roiNames{z},'-',hemi]; %% add hemisphere to name
                ROIs(iROI).coords = [];
                tempIndices = find(nimlStrct.data==z & eccIndices==1);
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
                ROIs(iROI).type = eccMode;
                ROIs(iROI).comment = [opt.Mode,': Converted from SUMA using mrC.ConvertROI.',eccComment];
            end
            disp(eccComment);
        else % wang, kgs or glasser
            cmap = distinguishable_colors(length(roiNames)+1);
            colors = cmap(2:end,:);
            nimlStrct = afni_niml_readsimple(roiFile{z});
            eccIndices = ones(length(nimlStrct.data),1);
            eccMode = opt.Mode;
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
                ROIs(iROI).type = eccMode;
                ROIs(iROI).comment = [opt.Mode,': Converted from SUMA using mrC.ConvertROI.',eccComment];
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
        overlapRate = length(find(ismember(ROIs(iROI).meshIndices,overlapMesh)))/length(ROIs(iROI).meshIndices)*100;
        if overlapRate > 0
            ROIs(iROI).meshIndices = tempMesh;
            fprintf('Warning: ROI %s overlaps by %0.4g percent\n',ROIs(iROI).name,overlapRate)
        else
        end
        cdata(ROIs(iROI).meshIndices,:) = repmat(ROIs(iROI).color,numel(ROIs(iROI).meshIndices),1);
    end
    disp(['Total overlap: ',num2str(length(overlapMesh))])
    
    opt.ROIs = ROIs; % add ROIs to opt struct
    
    %% PLOT ROIs
    kFr = find(ctx.triangles(:,1) > msh.nVertexLR(1),1,'first');		% 1st RH face index
    figH = figure('name',sprintf('%s ',opt.Mode));
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

    function saveAnatROIs(varargin)
        in = guidata(gcf);
        outDir = [fileparts(in.CortexFile),'/',in.ROIs(1).type,'_ROIs']; % default output directory 
        if ~exist(outDir,'dir')
            mkdir(outDir);
        else
        end
        ROIdir = uigetdir(outDir,'ROI output directory');
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
