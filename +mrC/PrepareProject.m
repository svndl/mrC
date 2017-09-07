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
    
    fsDir = getpref('freesurfer','SUBJECTS_DIR');
    
    if nargin ~= 1,
        projectDir = uigetdir('.','Pick your project directory');
    end

    if projectDir == false,
        error('Canceled by user!')
    end

    subjectList = subfolders(projectDir);

    for iSubj = 1:length(subjectList),
        subjId = subjectList{iSubj};

        if strcmp(subjId,'skeri9999')
            display('Skipping skeri9999')
            continue;
        end

        disp(['Processing subject: ' subjId ])

        pdExportDir = subfolders(fullfile(projectDir,subjId,'Exp_MATL_*'),1);
        if length(pdExportDir) > 1
            error('\n More than one Exp_MATL directory in %s',fullfile(projectDir,subjId));
        elseif pdExportDir{1} == 0
            error('\n Cannot find Exp_MATL directory, please add data');
        end
        pdExportDir = pdExportDir{1};

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
        
        subjDir = fullfile(fsDir,[subjId '_fs4']);

        if ~exist(subjDir,'dir')
            error('Subject: %s not found in directory: %s',subjId,fsDir);
        end
        
        exportFileList = subfiles(fullfile(pdExportDir,'Axx_*.mat'));

        if exportFileList{1} ==0
            error('No .mat PowerDiva exports found in: %s',pdExportDir);
        end
 
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

        headSurfFile = fullfile(subjDir,'bem',[subjId '_fs4-head.fif']);
        if ~exist(headSurfFile,'file')
            msg = sprintf('Cannot find hi-res scalp surface: %s\n Not ploting subject scalp, or using hi res registration\n',fiducialFile);
            display(msg);
            plotHiResScalp = false;
        else
            plotHiResScalp = true;
        end

        for iFile = 1:length(exportFileList),

            dataFile = fullfile(pdExportDir,exportFileList{iFile});
            fprintf('Processing file: %s\n',dataFile);

            % We should make this more elegant, but this works: 
            % basically we only want to register electrodes once. But the place
            % where everything is read in correctly is buried inside
            % powerDivaExp2Mne, and I've been too lazy to extract the registration
            % code and place it somewhere else.
            % JMA

            if iFile == 1,
                doReg = true;
            else
                doReg = false;
            end

            if (plotHiResScalp == true) && doReg, 
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
            else
            end
        
            mrC.PowerDiva2Mne( elpFile, dataFile,fiducialFile,outputDir,doReg)
        end
    end
    display('Done importing data into MNE')
    display('Ready to make inverses')
end








