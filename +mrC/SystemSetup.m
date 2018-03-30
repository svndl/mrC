function SystemSetup(analysis)
    % mrC.SystemSetup: check if folder preferences are set, if not, set them
    
    if nargin < 1
        analysis = 'source';
    else
    end

    if ismember(lower(analysis),{'source','sourcelocalization'})
        fsDir = '/Volumes/svndl/anatomy/FREESURFER_SUBS';
        anatDir = '/Volumes/svndl/anatomy';
    elseif ismember(lower(analysis),{'headless'})
        fsDir = '/Volumes/svndl/anatomy/FREESURFER_SUBS';
        anatDir = '/Volumes/svndl/anatomy/HEADLESS';
    else
        msg = sprintf('\n unknown analysis %s provided to mrC.SystemSetup, must be ''source'' or ''headless''\n');
        error(msg)
    end
    % CHECK IF FOLDERS THAT WILL BE SET AS ENVIRONMENT VARIABLES EXIST
    % mrCurrent AnatomyFolder
    if ~exist(anatDir,'dir')
        anatDir = uigetdir(anatDir,'Anatomy directory?');
    else
    end
    % freesurfer subject directory
    fsDir = '/Volumes/svndl/anatomy/FREESURFER_SUBS';
    if ~exist(fsDir,'dir')
        fsDir = uigetdir(fsDir,'Freesurfer directory?');
    else
    end
    
    % set environment variables
    setpref('mrCurrent','AnatomyFolder',anatDir);
    fprintf('Anatomy folder set: %s\n',anatDir);
    setpref('freesurfer','SUBJECTS_DIR',fsDir)
    fprintf('Freesurfer folder set: %s\n',fsDir);
end

