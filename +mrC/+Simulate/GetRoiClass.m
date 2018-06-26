function [Roi,subIDs] = GetRoiClass(projectPath,anatDir)
% Get a project and anatomy path and roi atlas and returns the list of of
% all ROIs in that atlas, and the list of subjects with this altas ROIs in
% the project

%% Set defaults

if ~exist('anatDir','var') || isempty(anatDir),
    anatDir = getpref('mrCurrent','AnatomyFolder');
end

%% Extract the name of all ROI lists
projectPath = subfolders(projectPath,1); % find subjects in the main folder
roiList = [];

len = length(projectPath) ;

for s = 1: len
    
    [~,subIDs{s}] = fileparts(projectPath{s});
    
    display(['Loading Subject ' num2str(subIDs{s}) ' ROIs']);
    % remove the session number from subjec ID
    SI = strfind(subIDs{s},'ssn');
    if ~isempty(SI)
        subIDs{s} = subIDs{s}(1:SI-2);% -2 because there is a _ before session number
    end
    
    Roi{s} = mrC.ROIs();
    Roi{s} = Roi{s}.loadROIs(subIDs{s});
end

end