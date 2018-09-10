function [subRoi, subRoiDist] = SubjectROISimilarity(projectPath,varargin)
% Description:	This function gets the path for a mrc project and
% generates Resolution and Crosstalk matrices 
%
% Syntax:	[CrossTalk,CrossTalkN,ROISource,LIST,subIDs] = ResolutionMatrices(projectPath,varargin)
% 
%--------------------------------------------------------------------------    
% INPUT:
% projectPath: a cell string, indicating a  path to mrCurrent project
% folder with individual subjects in subfolders
%             
% 
%
%   <options>:
% 
%--------------------------------------------------------------------------
% Latest modification: Elham Barzegaran, 08.12.2018
%% 

opt	= ParseArgs(varargin,...
    'inverse'		, [], ...
    'rois'          , [], ...
    'roiType'       , 'wang',...
    'eccRange'      , [],...
    'figFolder'     , [],...
    'plotting'      , false,...
    'anatomyPath'   , [],...  
    'numComponents' ,5 ...
    );

% Roi Type, the names should be according to folders in (svdnl/anatomy/...)
if ~strcmp(opt.roiType,'main')% THIS SHOUDL BE CORRECTED
    switch(opt.roiType)
        case{'func','functional'} 
            opt.roiType = 'functional';
        case{'wang','wangatlas'}
            opt.roiType = 'wang';
        case{'glass','glasser'}
            opt.roiType = 'glass';
        case{'kgs','kalanit'}
            opt.roiType = 'kgs';
        case{'benson'}
            opt.roiType = 'benson';
        otherwise
            error('unknown ROI type: %s',opt.roiType);
    end
else
end

%------------------set anatomy data path if not defined ---------------------
if isempty(opt.anatomyPath)
    anatDir = getpref('mrCurrent','AnatomyFolder');
    if contains(upper(anatDir),'HEADLESS') || isempty(anatDir) %~isempty(strfind(upper(anatDir),'HEADLESS'))
        anatDir = '/Volumes/svndl/anatomy';
        setpref('mrCurrent','AnatomyFolder',anatDir);
    else
    end
else
    anatDir = opt.anatomyPath;
end

%% ===========================LOAD ROIs and FORWARDS========================
% ----------------------------GET ROIs-------------------------------------
projectPathfold = projectPath;
projectPath = subfolders(projectPath,1); % find subjects in the main folder
if isempty(opt.rois)
    Rois = mrC.Simulate.GetRoiClass(projectPathfold);
else
    Rois = opt.rois;
end

for s = 1:length(projectPath)
    %--------------------------READ FORWARD SOLUTION---------------------------  
    % Read forward
    [~,subIDs{s}] = fileparts(projectPath{s});
    disp (['Reading forwards for subject ' subIDs{s}]);
    
    fwdPath = fullfile(projectPath{s},'_MNE_',[subIDs{s}]);
    
    % remove the session number from subjec ID
    SI = strfind(subIDs{s},'ssn');
    if ~isempty(SI)
        subIDs{s} = subIDs{s}(1:SI-2);% -2 because there is a _ before session number
    end
    
    % To avoid repeatition for subjects with several sessions
    if s>1, 
        SUBEXIST = strcmpi(subIDs,subIDs{s});
        if sum(SUBEXIST(1:end-1))==1,
            disp('EEG simulation for this subject has been run before');
            continue
        end
    end
    
    if exist([fwdPath '-fwd.mat'],'file') % if the forward matrix have been generated already for this subject
        fwd =load([fwdPath '-fwd.mat']);
        fwdMatrix = fwd.fwdMatrix;
    else
        fwdStrct = mne_read_forward_solution([fwdPath '-fwd.fif']); % Read forward structure
        % Checks if freesurfer folder path exist
        if ~ispref('freesurfer','SUBJECTS_DIR') || ~exist(getpref('freesurfer','SUBJECTS_DIR'),'dir')
            %temporary set this pref for the example subject
            setpref('freesurfer','SUBJECTS_DIR',fullfile(anatDir,'FREESURFER_SUBS'));% check
        end
        srcStrct = readDefaultSourceSpace(subIDs{s}); % Read source structure from freesurfer
        fwdMatrix = makeForwardMatrixFromMne(fwdStrct ,srcStrct); % Generate Forward matrix
    end
    subRoi{s}.Fwd = fwdMatrix';
    
    %---------------------Get the ROIs for the roiType---------------------

    subInd = strcmp(cellfun(@(x) x.subID,Rois,'UniformOutput',false),subIDs{s});
    SROI = Rois{find(subInd)};
    if strcmpi(opt.roiType,'benson') && ~isempty(opt.eccRange)
        SROICent = SROI.getAtlasROIs('benson',[0 opt.eccRange(1)]);
        SROISurr = SROI.getAtlasROIs('benson',opt.eccRange);
        SROICS = SROICent.mergROIs(SROISurr);
    else
        SROICS = SROI.getAtlasROIs(opt.roiType);
    end
    [roiChunk, NameList] = SROICS.ROI2mat(size(fwdMatrix,2));
     subRoi{s}.RoiFwd = roiChunk.'*fwdMatrix';
     subRoi{s}.RoiFwdabs = roiChunk.'*abs(fwdMatrix)';
     subRoi{s}.ROIs = SROICS;
     subRoi{s}.Cancellation =1-(sum(abs(subRoi{s}.RoiFwd),2))./sum(subRoi{s}.RoiFwdabs,2);
    %-----------------Apply SVD on fwd for evaluation of LASSO-------------
   
     if ~isempty(roiChunk)
         [subRoi{s}.comp.Fwd ,~,subRoi{s}.comp.svs,subRoi{s}.comp.varexp] = arrayfun(@(x) get_principal_components(fwdMatrix(:,roiChunk(:,x)>0), opt.numComponents), 1:size(roiChunk,2),'uni', false);
     end
     
    %------------Find the ROI uniformity according to their orientation----
    % like the paper: Ahlfors et al, 2010, HBM

    % load default cortex
    load(fullfile(anatDir,subIDs{s},'Standard','meshes','defaultCortex.mat'));
    vertices = msh.data.vertices';
    faces = (msh.data.triangles+1)';
    % adjustements for visualization purpose
    vertices = vertices(:,[1 3 2]);vertices(:,3)=200-vertices(:,3);
    % Get the vertex normals 
    surfNorms = -1*get(patch('vertices',vertices,'faces',faces),'vertexnormals')';close;
    surfNorms = surfNorms./ repmat(sqrt(sum(surfNorms.^2)),3,1);
    subRoi{s}.surfNorms = surfNorms;
    if ~isempty(roiChunk)
        subRoi{s}.Norm = (surfNorms*roiChunk./repmat(sum(roiChunk),[3 1]))';
        subRoi{s}.Size = sum(roiChunk);
    end
    subRoi{s}.subIDs = subIDs{s};
    
end
% clear unnecessary variables
clear vertices fwdMatrix fwdPath fwd msh SI SROI SROICS SUBEXIST faces roi roiChunk s subInd surfNorms Rois;

%% Plot the effect of size and orientation of ROIs on their forwards and SVs
% Based on the paper : Ahlfors et al, 2010, HBM

% remove subjects with no ROI
excludes = cellfun(@(x) size(x.RoiFwd,1)==0,subRoi);
subRoi(excludes) = [];subIDs(excludes) = [];

% ROI size, uniformity, variance explained by ncomponents of svd
allvarexp = cellfun(@(x) cell2mat(x.comp.varexp),subRoi,'uni',false);  allvarexp = cat(1,allvarexp{:});  allvarexp = reshape(allvarexp,[1,numel(allvarexp)]);
allsize = cellfun(@(x) x.Size,subRoi,'uni',false);  allsize = cat(1,allsize{:});  allsize = reshape(allsize,[1,numel(allsize)]);
alluniform = cellfun(@(x) sqrt(sum(x.Norm.^2,2))',subRoi,'uni',false);  alluniform = cat(1,alluniform{:});    alluniform = reshape(alluniform,[1,numel(alluniform)]);
allcancel = cellfun(@(x) x.Cancellation,subRoi,'uni',false);  allcancel = cat(1,allcancel{:});  allcancel = reshape(allcancel,[1,numel(allcancel)]);

% Plot ROI size vs. Uniformity vs. SV variance explained
scatter3(allsize(allvarexp>0),allvarexp(allvarexp>0),alluniform(allvarexp>0),[],alluniform(allvarexp>0),'filled')
ylabel('Explained Variance');
xlabel('ROI Size');
zlabel('uniformity');

%% subject variablity of ROI norm vector

allNorm = cellfun(@(x) x.Norm,subRoi,'uni',false);
allNorm = cat(3,allNorm{:});
figure,
for roi = 1:2:size(allNorm,1)
    subplot(5,5,(roi+1)/2), hold on;
    xlim([-.8 .8]);ylim([-.8 .8]);zlim([-.8 .8]);
    title(NameList{roi}(6:end))
    arrayfun(@(x) quiver3(0,0,0,allNorm(roi,1,x),allNorm(roi,2,x),allNorm(roi,3,x)),1:size(allNorm,3));
end

%% calculate distance between ROIs using the forward model

RoiFwdStack = cellfun(@(x) x.RoiFwd,subRoi,'uni',false); RoiFwdStack = cat(3,RoiFwdStack{:});
subRoiDist = arrayfun(@(x) squareform(pdist(squeeze(RoiFwdStack(x,:,:))')),1:numel(NameList),'uni',false);
subRoiDist = cat(3, subRoiDist{:});

end

