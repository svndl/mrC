function SourceDepth(ProjectPath,overwrite)
    % Description:	Generate source depth matrix, which will be used for
    % depth weighting of MN solution.
    % written by Elham Barzegaran, April, 2019
    % 
    % Syntax:  mrC.SourceDepth(subId, type)
    % In:
    %  ProjectPath    - a string specifying the mrC project path
    %   overwrite     - a logical indicating whether to overwrite the depth
    %                  file (true/[false])              
    
if nargin <2
    overwrite = true;
else
end

mrC.SystemSetup; % make sure system is setup
anatDir = fullfile(getpref('mrCurrent','AnatomyFolder'));

if ~exist('anatDir','var') || isempty(anatDir)
    anatDir = getpref('mrCurrent','AnatomyFolder');
end

projectPaths = subfolders(ProjectPath,1); % find subjects in the main folder
subIds = subfolders(ProjectPath,0);
      
    
for sub =1:numel(subIds)    
    
    meshDir = fullfile( anatDir,subIds{sub}, 'Standard', 'meshes' );
    if ~isdir( meshDir )
        error( 'Subject %s has no /Standard/meshes directory.', subId )
    end
    figure,
    title(subIds{sub})
    
    %%subId = 
    %% Load in mesh file
    load (fullfile(meshDir,'defaultCortex.mat'),'msh');
    vertices = msh.data.vertices';
    faces = (msh.data.triangles+1)';
    % adjustements for visualization purpose
    vertices = vertices(:,[3 1 2])-128; vertices(:,2:3)=-vertices(:,2:3);
    
    Fhandler = patch('faces',faces,'vertices',vertices,'edgecolor','none','facecolor','r',... 
     'Diffusestrength',.55,'AmbientStrength',.3,'specularstrength',.1,'facelighting','gouraud','FaceAlpha',.95);
    hold on;
    clear msh;
    
    %% load in scalp data
    
    headmodelpath = fullfile(anatDir,'/FREESURFER_SUBS/',[subIds{sub} '_fs4'], 'bem');
    headSurfFile = dir(fullfile(headmodelpath,'*_fs4-head.fif'));
    headSurfFullFile = fullfile(headSurfFile.folder,headSurfFile(1).name);
    surf =  mne_read_bem_surfaces(headSurfFullFile);
    surf.rr = surf.rr*1000;

    Fhandler = patch('vertices',surf.rr,'faces',surf.tris(:,[3 2 1]),'edgecolor','none',... 
     'Diffusestrength',.55,'AmbientStrength',.3,'specularstrength',.1,'facelighting','gouraud','FaceAlpha',.2);

    lightangle(50,120)
    lightangle(50,0)
    axis equal off;
    view (90,-10)
    
    %% load in 
    load(fullfile(projectPaths{sub},'Polhemus','CoregisteredElectrodesPostion'));
    scatter3(transElectrodes(:,1),transElectrodes(:,2),transElectrodes(:,3),5,'filled')
    SR = 2; % search range
    for i = 1:size(transElectrodes)
        inds = arrayfun(@(d) (surf.rr(:,d)>(transElectrodes(i,d)-SR))&(surf.rr(:,d)<(transElectrodes(i,d)+SR)),1:3,'uni',false);
        SInd = find(sum(cat(2,inds{:}),2)>0);
        Dist = pdist2(surf.rr(SInd,:),transElectrodes(i,:));
        [~,sselect] = min(Dist);
        ElecMap(i,:) = surf.rr(SInd(sselect),:);
    end
    
    scatter3(ElecMap(:,1),ElecMap(:,2),ElecMap(:,3),[],'g','filled')
    
    %% calculate source depth
    [Dist] =pdist2(vertices,ElecMap);
    
    SourceDepths = min(Dist,[],2);
    %DepthCov = SourceDepths *SourceDepths';
    savepath = (fullfile(projectPaths{sub},'Inverses'));
    if ~exist(savepath,'dir')
        mkdir(savepath);
    else
        if ~exist(fullfile(savepath,'SourceDepth.mat'),'file') || (overwrite)
            save(fullfile(savepath,'SourceDepth.mat'),'SourceDepths');
        end
    end
end    
    
end



