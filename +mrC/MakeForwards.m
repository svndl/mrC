function MakeForwards( projectDir, debugMode )
    % Description:	Prepare forwards for a source space project that can be 
    %               used with mrC.GUI and multiple other mrC functions.
    % 
    % Syntax:	mrC.MakeForwards( projectDir )
    % 
    %   projectDir - string indicating the directory of a project, 
    %                typically generated with mrC.CreateProject
    %   debugMode - show output from shell commands, to aid debugging
    %               true/[false]
    
    if nargin < 2
        debugMode = false;
    else
    end
    if nargin < 1
        projectDir = uigetdir('.','Pick your project directory');
    else
    end
    
    % make sure system is set up
    fsDir = mrC.SystemSetup;
    
    subjectList = subfolders(projectDir);

    for s = 1:length(subjectList),
        subjId = subjectList{s};
        
        if strcmp(subjId,'skeri9999')
            display('Skipping skeri9999')
            continue;
        end
        
        %% clean-up subject ID, '_' sometimes used for separate sessions
        if ~isempty(strfind(subjId,'_'))
            fsId = [subjId(1:(max(strfind(subjId,'_'))-1)),'_fs4'];
            if strcmp(fsId(1:3),'nl_')
                fsId(1:3) = 'nl-';
            else
            end
        else
            fsId=[subjId '_fs4'];
        end

        logFile = fullfile(projectDir,subjId,'_dev_',['prepInvMrc_log_' datestr(now,'yyyymmdd_HHMM_FFF') '.txt']);
        diary(logFile)

        disp(['Processing Subject: ' subjId ])
        
        %% identify files and check if they exist
        % mne cov
        mneCovFileList = subfiles(fullfile(projectDir,subjId,'_MNE_','*-cov.fif'));
        if isempty(mneCovFileList)
            error('\n Cannot find MNE files, please run mrC.PrepareProject');
        end
        mneCovFile = fullfile(projectDir,subjId,'_MNE_',mneCovFileList{1});
        
        % mne data
        mneDataFileName = [mneCovFileList{1}(1:end-8) '.fif' ];
        mneDataFile = fullfile(projectDir,subjId,'_MNE_',mneDataFileName);
        if ~exist(mneCovFile,'file')
            error( 'Cannot find an MNE covariance file %s',mneCovFile );
        end
        if ~exist(mneDataFile,'file'),
            error( 'Cannot find find measurement file: %s',mneDataFile );
        end
        
        % mne reg
        mneRegFile = fullfile(projectDir,subjId,'_MNE_','elp2mri.tran');
        if ~exist(mneRegFile,'file'),
            error( 'Cannot find find registration file: %s',mneRegFile );
        end
        
        % mne source space
        srcSpaceFile = fullfile(fsDir,fsId,'bem',[ fsId '-ico-5p-src.fif']);
        if ~exist(srcSpaceFile,'file'),
            error(['Cannot find find source space file: ' srcSpaceFile]);
        end
        
        outputDir = fullfile(projectDir,subjId,'_MNE_');
        
        %% RUN SHELL COMMANDS

        FWDOUT = fullfile(outputDir, [subjId '-fwd.fif']);
        SPHOUT = fullfile(outputDir, [subjId '-sph-fwd.fif']);
        INVOUT = fullfile(outputDir, [subjId '-inv.fif']);
                
        % add SUBJECT as environment variable
        shellCmdString{1} = sprintf('source ~/.bashrc; export SUBJECT=%s;',fsId); 
        % mne_do_forward_solution --spacing ico-5p --bem $SUBJECT --trans $REG --meas $3 --fwd $FWDOUT --overwrite --mindist 2.5
        shellCmdString{2} = ...
            sprintf('mne_do_forward_solution --spacing ico-5p --bem $SUBJECT --trans %s --meas %s --fwd %s --overwrite --mindist 2.5; ', ...
            mneRegFile,mneDataFile,FWDOUT);
        % mne_forward_solution --eeg --mricoord --eegscalp --origin 0:-20:10 --eegrad 110 --src $subjSrc --trans $REG --meas $3 --fwd $SPHOUT --eegmodel default
        shellCmdString{3} = ...
            sprintf('mne_forward_solution --eeg --mricoord --eegscalp --origin 0:-20:10 --eegrad 110 --src %s --trans %s --meas %s --fwd %s --eegmodel default; ', ...
            srcSpaceFile,mneRegFile,mneDataFile,SPHOUT);
        % mne_do_inverse_operator --eeg --fwd $FWDOUT --senscov $COV --loose .2 --eegreg .02 --inv $INVOUT
        shellCmdString{4} = ...
            sprintf('mne_do_inverse_operator --eeg --fwd %s --senscov %s --loose .2 --eegreg .02 --inv %s; ', ...
            FWDOUT,mneCovFile,INVOUT);
        
        fprintf('**************************************************************************************************\n');
        fprintf('Executing shell commands: \n');
        for z=1:length(shellCmdString)
            fprintf('%s\n',shellCmdString{z})
        end
        fprintf('**************************************************************************************************\n');

        [status,output] = system(cat(2,shellCmdString{:}));
        if debugMode
            disp(output);
        else
        end
        if status == 127
            msg = sprintf('\nCreation of forward solution failed for subject %s\n',subjId);
            error(msg);
        else
        end
    end
end