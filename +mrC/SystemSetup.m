function [fsDir,anatDir] = SystemSetup
    % mrC.SystemSetup: check if folder preferences are set, if not, set them
    
    %% CHECK IF NECESSARY FOLDERS ARE SET AS ENVIRONMENT VARIABLES AND EXIST
    
    % mrCurrent AnatomyFolder
    
    if ~ispref('mrCurrent','AnatomyFolder')
        anatDir = '/Volumes/svndl/anatomy';
        if ~exist(anatDir,'dir')
            anatDir = uigetdir(anatDir,'Anatomy directory?');
        else
        end
        setpref('mrCurrent','AnatomyFolder',anatDir);
        fprintf('Anatomy folder set: %s\n',anatDir);
    else
         anatDir = getpref('mrCurrent','AnatomyFolder');
    end
    
    % freesurfer subject directory
    if ~ispref('freesurfer','SUBJECTS_DIR')
        fsDir = '/Volumes/svndl/anatomy/FREESURFER_SUBS';
        if ~exist(fsDir,'dir')
            fsDir = uigetdir(fsDir,'Freesurfer directory?');
        else
        end
        setpref('freesurfer','SUBJECTS_DIR',fsDir)
        fprintf('Freesurfer folder set: %s\n',fsDir);
    else
        fsDir = getpref('freesurfer','SUBJECTS_DIR');
    end
    
    
    %% CHECK IF NECESSARY DEPENDENCIES ARE INSTALLED
    % check if mrVista is installed and on path
    if exist('nearpoints') ~= 3,
        error(sprintf(strcat(2,...
            ['\n nearpoints mex-file not found. \n', ...
             'please install from http://github.com/vistalab/vistasoft. \n', ...
             'and make sure to add to vistasoft folder to path.' ])));
    else
    end
    
    %% SET DYLD
    setenv('DYLD_LIBRARY_PATH','')
end

