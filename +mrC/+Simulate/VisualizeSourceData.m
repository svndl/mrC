function Fhandler = VisualizeSourceData(subID,data,anatDir,cmap,direction)
% gets the subject ID and anatomy folder and the source data and plots the
% result on the subjects default cortex...
% Elham Barzegaran, 5.22.2018
%% default variables

if ~exist('anatDir','var'),
    anatDir = getpref('mrCurrent','AnatomyFolder');
end

if ~exist('direction','var'),
    direction = 'anterior';
end
%%

% load default cortex
Path = fullfile(anatDir,subID,'Standard','meshes','defaultCortex.mat');
load(Path);
vertices = msh.data.vertices';
faces = (msh.data.triangles+1)';
% adjustements for visualization purpose
vertices = vertices(:,[1 3 2]);vertices(:,3)=200-vertices(:,3);

if ~exist('cmap','var')
    cmap = jmaColors('hotcortex');
end

%% plot brain surface

Fhandler= patch('faces',faces,'vertices',vertices,'edgecolor','none','facecolor','interp','facevertexcdata',reshape(round(data),[numel(data) 1]),...
     'Diffusestrength',.45,'AmbientStrength',.3,'specularstrength',.1,'FaceAlpha',.85);

colormap(cmap);

shading interp
lighting flat
lightangle(50,120)
lightangle(50,0)

switch direction
    case 'ventral'
        lightangle(-90,-90);
        view(90,-90)
    case 'anterior'
        view (90,-10)
end

axis  off vis3d equal
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.2, 0.24, .45, 0.65]);

end