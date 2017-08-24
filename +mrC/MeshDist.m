function [dist,coords] = MeshDist(subId,varargin)
    % Description:	Get distances between mesh indices
    % 
    % Syntax:	mrC.MeshDist(subId,varargin)
    % In:
    %   subId - subject ID, without '_fs4' suffix (if given, it will be
    %           removed
    %
    %   <options>:
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
     opt	= ParseArgs(varargin,...
             'CortexFile' ,fullfile(anatDir,'/Standard/meshes/defaultCortex.mat') ...
             );
         
    %% LOAD MRMESH CORTEX AND TRANSFORM TO MATCH FREESURFER
    load(opt.CortexFile);
    msh.nVertex = sum(msh.nVertexLR);
    % sanity check
    if any( [ size(msh.data.vertices,2), size(msh.initVertices,2) ] ~= msh.nVertex )
        error('vertex disagreement within %s',opt.CortexFile)
    end
    
    kL = 1:msh.nVertexLR(1);
    kR = (msh.nVertexLR(1)+1):msh.nVertex;
    coords.all = msh.data.vertices';
    coords.left = coords.all(kL,:);
    coords.right = coords.all(kR,:);
    dist.all = squareform(pdist(coords.all));
    dist.left = squareform(pdist(coords.left));
    dist.right = squareform(pdist(coords.right));
end 
