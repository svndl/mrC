function [Fhandler,RoiList] = VisualizeSourceRoi(subID,anatDir,RoiType,RoiIdx,direction)
% gets the subject ID and anatomy folder and plots the
% ROIs on the subjects default cortex...
% Elham Barzegaran, 5.25.2018
%% default variables

if ~exist('anatDir','var')||isempty(anatDir),
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

%% plot brain surface

Fhandler= figure,

patch('faces',faces,'vertices',vertices,'edgecolor','none','facecolor','interp','facevertexcdata',repmat([.7,.7,.7],size(vertices,1),1),...
     'Diffusestrength',.45,'AmbientStrength',.3,'specularstrength',.1,'FaceAlpha',.65);

%colormap(cmap);

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

%% plot ROIs on the brain
RoiDir = fullfile(anatDir,subID,'Standard','meshes',[RoiType '_ROIs']); 
[chunks,RoiList] = mrC.ChunkFromMesh(RoiDir,size(vertices,1),1);

if ~exist('RoiIdx','var')||isempty(RoiIdx),
    RoiIdx = 1:size(chunks,2);
end


cmap = colormap(lines(256));
for i = 1:numel(RoiIdx)
    [RoiV, RoiF] = SurfSubsample(vertices, faces,find(chunks(:,RoiIdx(i))),'union');  
    C=cmap(i*floor(255/numel(RoiIdx)),:);
    if ~isempty(RoiF),
        hold on; patch('faces',RoiF,'vertices',RoiV,'edgecolor','k','facecolor','interp','facevertexcdata',repmat(C,size(RoiV,1),1),...
            'Diffusestrength',.55,'AmbientStrength',.7,'specularstrength',.2,'FaceAlpha',1);
        scatter3(RoiV(:,1),RoiV(:,2),RoiV(:,3),30,C,'filled');
    end
end

end

function [nvertices, nfaces,vertIdx2] = SurfSubsample(vertices, faces,vertIdx,type)

% This function selects a subset of vertices and their corresponding faces indicated by vertIdx 
% INPUT: 
    % type: can be 'union' or 'intersect', the criteria for including faces
%-------------------------------------------------------------------------
if ~exist('type','var'),type = 'intersect';end
%-------------------------------------------------------------------------
vertIdx = sort(vertIdx);
I1 = find(ismember(faces(:,1),vertIdx));
I2 = find(ismember(faces(:,2),vertIdx));
I3 = find(ismember(faces(:,3),vertIdx));

if strcmp(type,'intersect')
    FI  = intersect(intersect(I1,I2),I3);
    nfaces = faces(FI,:);
    vertIdx2 = unique(nfaces(:));
    nvertices = vertices(vertIdx,:);
    fnew = zeros(size(nfaces));
    for i = 1:numel(vertIdx)
        fnew(nfaces==vertIdx(i)) = i;
    end
    nfaces=fnew;
    [~,vertIdx2] = intersect(vertIdx2,vertIdx);

elseif strcmp(type,'union')
    FI = union(union(I1,I2),I3);
    nfaces = faces(FI,:);
    vertIdx2 = unique(nfaces(:));
    nvertices = vertices(vertIdx2,:);
    fnew = zeros(size(nfaces));
    for i = 1:numel(vertIdx2)
        fnew(nfaces==vertIdx2(i)) = i;
    end
    nfaces=fnew;
    [~,vertIdx2] = intersect(vertIdx2,vertIdx);

else
    error('Criteria is not defined');
end

end