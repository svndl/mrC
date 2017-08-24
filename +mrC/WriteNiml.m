function WriteNiml(subjId,dataIn,varargin)
    
     opt = ParseArgs(varargin,...
            'outpath'   , [pwd,'/test.niml.dset'], ...
            'labels'   ,[], ...
            'stats'   ,[], ...
            'interpolate',true,...
            'std_surf', true);
    if isempty(opt.labels)
        opt.labels = arrayfun(@(x) sprintf('dset %d',x), 1:size(dataIn,2),'uni',false);
    else
    end
    
    if isempty(opt.stats)
        opt.stats =  repmat({'none'},1,size(dataIn,2));
    else
    end
    
    if opt.std_surf
        surfPre = 'std.141.';
    else
        surfPre ='';
    end
    
    anatDir = getpref('mrCurrent','AnatomyFolder');
    fsDir = fullfile(getpref('freesurfer','SUBJECTS_DIR'),[subjId,'_fs4']);
    ctxFilename=fullfile(anatDir,subjId,'Standard','meshes','defaultCortex');
    load(ctxFilename);
    ctx.faces = (msh.data.triangles+1)';
    ctx.vertices(:,1) = msh.data.vertices(3,:)-128;
    ctx.vertices(:,2) = -msh.data.vertices(1,:)+128;
    ctx.vertices(:,3) = -msh.data.vertices(2,:)+128;
    %ctx.vertices = ctx.vertices/1000;
    
    %% LOAD MRMESH CORTEX AND TRANSFORM TO MATCH FREESURFER
    msh.nVertex = sum(msh.nVertexLR);
    % sanity check
    if any( [ size(msh.data.vertices,2), size(msh.initVertices,2) ] ~= msh.nVertex )
        error('vertex disagreement within %s',mrmFile)
    end
    % get left & right hemisphere vertex indices
    kL = 1:msh.nVertexLR(1);
    kR = (msh.nVertexLR(1)+1):msh.nVertex;
    
    %% READ AND RESAMPLE FREESURFER DATA
    [vL,fL]=surfing_read_surf(fullfile(fsDir,'SUMA',[surfPre,'lh.pial.asc']));
    [vR,fR]=surfing_read_surf(fullfile(fsDir,'SUMA',[surfPre,'rh.pial.asc']));
    if opt.interpolate
        [iL,e2L] = nearpoints(vL',ctx.vertices(kL,:)');
        [iR,e2R] = nearpoints(vR',ctx.vertices(kR,:)');
        iR = iR+msh.nVertexLR(1);
    else
        [iL,e2L] = nearpoints(ctx.vertices(kL,:)',vL');
        [iR,e2R] = nearpoints(ctx.vertices(kR,:)',vR');
    end
    hemi = {'lh','rh'};
    [outPath,outName,outExt] = fileparts(opt.outpath);
    for h = 1:2
        S=struct();
        S.labels=opt.labels;
        S.stats =opt.stats;
        if opt.interpolate
            if h == 1
                S.data= dataIn(iL,:);
            else
                S.data= dataIn(iR,:);
            end
        else
            if h == 1
                S.data = zeros(size(vL,1),1);
                S.data(iL)= dataIn(kL,:);
            else
                S.data = zeros(size(vR,1),1);
                S.data(iR) = dataIn(kR,:);
            end
        end
        afni_niml_writesimple(fullfile(outPath,[surfPre,hemi{h},'.',outName,outExt]),S);
    end
%     figure;
%     subplot(121);
%     patch(struct('vertices',vL,'faces',fL),...
%             'facevertexcdata',dataIn(iL,1),'facecolor','flat','facelighting','gouraud','edgecolor','none')
%     subplot(122);
%     patch(struct('vertices',vR,'faces',fR),...
%             'facevertexcdata',dataIn(iR,1),'facecolor','flat','facelighting','gouraud','edgecolor','none')
%    
%     kFr = find(ctx.faces(:,1) > msh.nVertexLR(1),1,'first');		% 1st RH face index
%     figure;
%     subplot(121)
%         patch(struct('vertices',ctx.vertices(kL,:),'faces',ctx.faces(1:(kFr-1),:)),...
%             'facevertexcdata',dataIn(kL,1),'facecolor','flat','facelighting','gouraud','edgecolor','none')
%     subplot(122)
%         patch(struct('vertices',ctx.vertices(kR,:),'faces',ctx.faces(kFr:end,:)-msh.nVertexLR(1)),...
%             'facevertexcdata',dataIn(kR,1),'facecolor','flat','facelighting','gouraud','edgecolor','none')
end