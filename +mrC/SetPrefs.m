function SetPrefs(varargin)
    % mrC.SetPrefs: check if folder preferences are set, if not, set them
    % <options>:
    %       manualSet: set folder preferences manually (true/[false]) 
    %       anatDir:  anatomy folder (['/Volumes/svndl/anatomy'])
    %       fsDir: freesurfer folder (['/Volumes/svndl/anatomy/FREESURFER_SUBS'])
    
    % defaults    
    opt	= ParseArgs(varargin,...
            'manualSet' , false, ...
            'anatDir'   , '/Volumes/svndl/anatomy', ...
            'fsDir'		, '/Volumes/svndl/anatomy/FREESURFER_SUBS' ...
            );
    
    if opt.manualSet
        opt.anatDir = uigetdir(opt.anatDir,'Anatomy directory?');
        opt.fsDir = uigetdir(opt.fsDir,'Freesurfer directory?');
    else
    end
    
    if ~ispref('mrCurrent','AnatomyFolder')
        setpref('mrCurrent','AnatomyFolder',opt.anatDir);
    else
    end
    if ~ispref('freesurfer','SUBJECTS_DIR')
        setpref('freesurfer','SUBJECTS_DIR',opt.fsDir)
    else
    end
    fprintf('Anatomy folder set: %s\n',opt.anatDir);
    fprintf('Freesurfer folder set: %s\n',opt.fsDir);
end

