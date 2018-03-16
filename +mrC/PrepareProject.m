function PrepareProject( projectDir )
    % Description:	Prepare source space project that can be 
    %               used with mrC.GUI and multiple other mrC functions.
    %               This function merges prepareProjectForMne and preparePowerDivaForMne
    %               both written by Justin Ales, 
    %               with some added edits by pjkohler.
    % 
    % Syntax:       mrC.PrepareProject( projectDir )
    % 
    %   projectDir - string indicating the directory of a project, 
    %                typically generated with mrC.CreateProject

    % make sure system is set up
    mrC.SystemSetup;
    
    % get freesurfer directory
    fsDir = getpref('freesurfer','SUBJECTS_DIR');
    
    % ask user to provide project directory, if not given
    if nargin ~= 1,
        projectDir = uigetdir('.','Pick your project directory');
    end
    
    % or cancel
    if projectDir == false,
        error('Canceled by user!')
    end
    
    % get list of subjects
    subjectList = subfolders(projectDir);

    % ... and step through
    for iSubj = 1:length(subjectList),
        subjId = subjectList{iSubj};

        if strcmp(subjId,'skeri9999')
            display('Skipping skeri9999')
            continue;
        end

        disp(['Processing subject: ' subjId ])
        
        % get matlab poverdiva export directory
        pdExportDir = subfolders(fullfile(projectDir,subjId,'Exp_MATL_*'),1);
        if length(pdExportDir) > 1
            error('\n More than one Exp_MATL directory in %s',fullfile(projectDir,subjId));
        elseif pdExportDir{1} == 0
            error('\n Cannot find Exp_MATL directory, please add data');
        end
        pdExportDir = pdExportDir{1};
        
        % get polhemus directory
        elpFile = subfiles(fullfile(projectDir,subjId,'Polhemus','*Edited.elp'),1);
        if elpFile{1} == 0,
            elpFile = subfiles(fullfile(projectDir,subjId,'Polhemus','*.elp'),1);
            if elpFile{1} == 0
                elpFile = subfiles(fullfile(projectDir,subjId,'Polhemus','*.elc'),1);
                if elpFile{1} == 0
                    error(['\n Subject: ' subjId ' does not have electrode location ELP file']);           
                else
                end
            else
            end
            display(['Using unedited electrode location ELP file: ' elpFile{1}]);
        else
            display(['Found edited electrode location ELP file, using file: ' elpFile{1}]);
        end
        elpFile = elpFile{1};
        
        % get MNE output directory
        outputDir = fullfile(projectDir,subjId,'_MNE_');
        if ~exist(outputDir,'dir'),
            error(['Cannot find output directory, please create: ' outputDir ]);
        else
        end

        % clean-up subject ID, '_' sometimes used for separate sessions
        if ~isempty(strfind(subjId,'_'))
            if strcmp(subjId(1:3),'nl_')
                subjId(1:3) = 'nl-';
            else
            end
            subjId = subjId(1:(max(strfind(subjId,'_'))-1));
        else
        end
        
        curFig = figure;
        clf;
        hold on;
        
        %  get subject's freesurfer directory
        subjDir = fullfile(fsDir,[subjId '_fs4']);
        if ~exist(subjDir,'dir')
            error('Subject: %s not found in directory: %s',subjId,fsDir);
        end
        
        % make list of axx export files (from PowerDiva)
        exportFileList = subfiles(fullfile(pdExportDir,'Axx_*.mat'));
        if exportFileList{1} ==0
            error('No .mat PowerDiva exports found in: %s',pdExportDir);
        end
        
        % get fiducials file
        fiducialFile = fullfile(subjDir,'bem',[subjId '_fiducials.txt']);
        if ~exist(fiducialFile,'file')
            msg = sprintf('Cannot find fiducial location file: %s\n Skipping subject: %s\n',fiducialFile, subjId);
            warning(msg);
            clf
            colordef(curFig,'none')
            whitebg(curFig,[.75 0 0 ])
            set(curFig,'name',subjId)
            text(0, .1,msg,'fontsize',24)
            axis off;
            return;
        end
        
        % loop over axx export list
        for iFile = 1:length(exportFileList),
            dataFile = fullfile(pdExportDir,exportFileList{iFile});
            fprintf('Processing file: %s\n',dataFile);
            if iFile == 1 % only register electrodes once
                doReg = true;
                % get hi-res scalp surface file
                headSurfFile = fullfile(subjDir,'bem',[subjId '_fs4-head.fif']);
                if ~exist(headSurfFile,'file')
                    msg = sprintf('Cannot find hi-res scalp surface: %s\n Not ploting subject scalp, or using hi res registration\n',fiducialFile);
                    display(msg);
                else
                    surf =  mne_read_bem_surfaces(headSurfFile);
                    patch('faces',surf.tris,'vertices',surf.rr,'linestyle','none','facecolor',[.8 .7 .6]);
                    material dull;
                    lightangle(240, 30)
                    lightangle(120, 30)
                    lightangle(0, 0)
                    axis normal
                    axis equal
                    axis vis3d
                    axis tight;
                    axis off
                    campos([    0.7712    1.6339    0.7370]);
                    camva(7);
                    set(gcf,'name',subjId)
                end  
            else
                doReg = false;
            end
            mrC.PowerDiva2Mne( elpFile, dataFile, fiducialFile, outputDir, doReg)
        end
    end
    display('Done importing data into MNE')
    display('Ready to make inverses')
end








