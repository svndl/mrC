function [EEGData,EEGAxx,sourceDataOrigin,masterList,subIDs] = SimulateProject(projectPath,varargin)
    
    % Description:	This function gets the path for a mrc project and simulate
    % EEG with activity (seed signal as input) in specific ROIs (input),
    % and pink and alpha noises (noise parameters can be set as input)
    %
    % Syntax:	[EEGData,EEGAxx,sourceDataOrigin,masterList,subIDs] = mrC.RoiDemo(projectPath,varargin)
    % 
%--------------------------------------------------------------------------    
% INPUT:
  % projectPath: Cell array of strings, indicating a list of paths to mrCurrent project folders of individual subjects
    %             
    % 
    %
  %   <options>:
    %
  % (Source Signal Parameters)
    %       signalArray:    a NS x seedNum matrix, where NS is the number of
    %                       time samples and seedNum is the number of seed sources
    %                       [NS x 2 SSVEP sources] -> for these two, the
    %                       random ROIs in functional
    %                       roitype is selected
    %
    %       signalsf:       sampling frequency of the input source signal
    %
    %       signalType:     type of simulated signal (visualization might differ for different signals)
    %                       
    %       
    %       signalFF:       a 1 x seedNum vector: determines the fundamental
    %                       frequencis of sources
  
  % (ROI Parameters)
    %       roiType:        string specifying the roitype to use. 
    %                       'main' indicates that the main ROI folder
    %                       /Volumes/svndl/anatomy/SUBJ/standard/meshes/ROIs
    %                       is to be used. (['func']/'wang'/'glass','kgs','benson','main').
    %
    %       roiList:        a 1 x seedNum cell of strings, with names of ROIs to simulate. 
    %                       [all ROIs of the specified type]
    %
    %       anatomyPath:  The folder should be for the same subject as
    %                       projectPath points to. It should have ROI forders, default
    %                       cortex file, ..
    
  % (Noise Parameters), all this parameters are defined inside "NoiseParam." structure
    %
    %       mu: This number determines the ratio of pink noise to alpha noise
    %
    %       lambda: This number determines the ratio of signal to noise
    %       
    %       alpha nodes: for now the only option is 'all' which means all visual areas  (maybe later a list of ROIs to put alpha in)
    %
    %       mixing_type_pink_noise: for now only 'coh' is implemented, which is default value
    %
    %       spatial_normalization_type: How to normalize noise and generated signal ['active_nodes']/ 'all_nodes'
    %
    %       distanceType: how to calculate source distances ['Euclidean']/'Geodesic', Geodesic is not implemented yet
    
  % (Plotting Parametes)
    %       sensorFig:      logical indicating whether to draw topo plots of
    %                       the simulated ROI data in sensor space. [true]/false
    %       figFolder:        string specifying folder in which to save sensor
    %                       figs. [Users' Desktop]
    
  % (Inverse Parameters) .... should be corrected
    %       inverse:        a string specifying the inverse name to use
    %                       [latest inverse]
    %       doSource:       logical indicating whether to use the inverse to push
    %                       the simulated ROI data back into source space
    %                       true/[false]
    %
    
% OUTPUT:
    %       EEGData:        a NS x e matrix, containing simulated EEG,
    %                       where NSs is number of time samples and e is the
    %                       number of the electrodes
    %
    %
    %       EEGAxx:         A cell array containing Axx structure of each
    %                       subject's simulated EEG. This output is
    %                       available if the signal type is SSVEP
    %
    %       sourceDataOrigin: a NS x srcNum matrix, containing simulated
    %                           EEG in source space before converting to
    %                           sensor space EEG, where srcNum is the
    %                           number of source points on the cortical
    %                           meshe
    %
    %       masterList:     a 1 x seedNum cell of strings, indicating ROI names
    %
    %       subIDs:         a 1 x s cell of strings, indicating subjects IDs
    %
%--------------------------------------------------------------------------
 % The function was originally written by Peter Kohler, ...
 % Latest modification: Elham Barzegaran, 03.26.2018
 % NOTE: This function is a part of mrC toolboxs

%% =====================Prepare input variables============================
 
%--------------------------set up default values---------------------------
opt	= ParseArgs(varargin,...
    'inverse'		, [], ...
    'roiType'       , 'func',...
    'roiList'		, [],...
    'signalArray'   , [],...
    'signalsf'      , 100 ,... 
    'signalType'    , 'SSVEP',...
    'signalFF'      ,[],...
    'noiseParams'   , struct,...
    'sensorFig'     , true,...
    'doSource'      , false,...
    'figFolder'     , [],...
    'anatomyPath'   ,[],...   
    'plotting'      ,1 ...
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


%----------Set folder for saving the results...default is desktop----------
if isempty(opt.figFolder)
    if ispc,home = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
    else home = getenv('HOME');end
    opt.figFolder = fullfile(home,'Desktop');
else
end

%------------------set anatomy data paths (For ROIs)-----------------------
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

% -----------------Generate default source signal if not given-------------
% Generate signal of interest
    if isempty(opt.signalArray) 
        if isempty(opt.roiList)
            [opt.signalArray, opt.signalFF, opt.signalsf]= mrC.Simulate.ModelSeedSignal('signalType',opt.signalType); % default signal (can be compatible with the number of ROIs, can be improved later)
        else 
            [opt.signalArray, opt.signalFF, opt.signalsf]= mrC.Simulate.ModelSeedSignal('signalType',opt.signalType,'signalFreq',round(rand(lengthopt.roiList)*3+3));
        end
    end  


%% ===========================GENERATE EEG signal==========================

for s = 1:length(projectPath)
%--------------------------READ FORWARD SOLUTION---------------------------  
    % Read forward
    [~,subIDs{s}] = fileparts(projectPath{s});
    
    fwdPath = fullfile(projectPath{s},'_MNE_',[subIDs{s} '-fwd.fif']);
    
    % remove the session number from subjec ID
    SI = strfind(subIDs{s},'ssn');
    if ~isempty(SI)
        subIDs{s} = subIDs{s}(1:SI-2);% -2 because there is a _ before session number
    end
    
    fwdStrct = mne_read_forward_solution(fwdPath); % Read forward structure
    % Checks if freesurfer folder path exist
    if ~ispref('freesurfer','SUBJECTS_DIR') || ~exist(getpref('freesurfer','SUBJECTS_DIR'),'dir')
        %temporary set this pref for the example subject
        setpref('freesurfer','SUBJECTS_DIR',fullfile(anatDir,'FREESURFER_SUBS'));% check
    end
    srcStrct = readDefaultSourceSpace(subIDs{s}); % Read source structure from freesurfer
    fwdMatrix = makeForwardMatrixFromMne(fwdStrct ,srcStrct); % Generate Forward matrix
    
    %-----------------------------Set ROI folder---------------------------
    if strcmp(opt.roiType,'main')
        roiDir = fullfile(anatDir,subIDs{s},'Standard','meshes','ROIs');
        roiPaths = subfiles(roiDir);
    else
        roiDir = fullfile(anatDir,subIDs{s},'Standard','meshes',[opt.roiType,'_ROIs']);
        roiPaths = subfiles(roiDir);
    end
    if ~exist(roiDir,'dir')
        EEGData{s}=[]; sourceDataOrigin{s}=[];
        warn = ['' opt.roiType ' ROIs are not defined for subject ' subIDs{s}];
        warning(warn);
        continue;
        %error('selected roi directory does not exist: %s', roiDir);
    else
    end

    %--------------------------Set inverse path--------------------------------
    % projectPath = subfolders(projectPath,1);% CHANGED FOR NOW, SHOULD CHANGE IT BACK?
    if isempty(opt.inverse)
        tempStrct = dir(fullfile(projectPath{s},'Inverses/*'));% CHANGE
        %tempStrct = dir(mrCfolders{2}); %CHANGE
        [~,tempIdx]=max(cat(3,tempStrct.datenum)); % sort by date
        opt.inverse = tempStrct(tempIdx).name;         % use latest
    else
        if iscell(opt.inverse) % unwrap if necessary
            opt.inverse = opt.inverse{1};
        else
        end
    end
    
%--------------------Display message---------------------------------------
disp (['Simulating EEG for subject ' subIDs{s}]);
% -----------------Default ROIs--------------------------
    seedNum = size(opt.signalArray,2); % Number of seed sources
    
    [roiChunk,tempList] = mrC.ChunkFromMesh(roiDir,size(fwdMatrix,2));% read the ROIs
    tempList = unique(cellfun(@(x) x(1:end-4),tempList,'uni',false));
    
    % Select Random ROIs 
    if isempty(opt.roiList) % This part should be updated. The default ROIs should be the same among subjects
        % Initialized only for the first subject, then use the same for the rest
        opt.roiList = tempList(randperm(numel(tempList),seedNum));
        
    end
    masterList = opt.roiList;
%-------------------Generate noise: from Sebastian's code------------------
    
    % -----Noise default parameters-----
    NS = size(opt.signalArray,1); % Number of time samples
    Noise = opt.noiseParams;
    Noisefield = fieldnames(Noise);
    
    if ~any(strcmp(Noisefield, 'mu')),Noise.mu = 1;end % power distribution between alpha noise and pink noise ('noise-to-noise ratio')
    if ~any(strcmp(Noisefield, 'lamda')),Noise.lambda = 1/NS;end % power distribution between signal and 'total noise' (SNR)
    if ~any(strcmp(Noisefield, 'spatial_normalization_type')),Noise.spatial_normalization_type = 'all_nodes';end% 'active_nodes'/['all_nodes']
    if ~any(strcmp(Noisefield, 'distanceType')),Noise.distanceType = 'Euclidean';end
    if ~any(strcmp(Noisefield, 'Noise.mixing_type_pink_noise')), Noise.mixing_type_pink_noise = 'coh' ;end % coherent mixing of pink noise
    if ~any(strcmp(Noisefield, 'alpha_nodes')), Noise.alpha_nodes = 'all';end % for now I set it to all visual areas, later I can define ROIs for it

    % -----Determine alpha nodes: This is temporary-----

    if strcmp(Noise.alpha_nodes,'all'), AlphaSrc = find(sum(roiChunk,2)); end % for now: all nodes will show the same alpha power over whole visual cortex  

    disp ('Generating noise signal ...');
    
    % -----Calculate source distance matrix-----
    load(fullfile(anatDir,subIDs{s},'Standard','meshes','defaultCortex.mat'));
    MDATA = msh.data; MDATA.VertexLR = msh.nVertexLR;
    clear msh;
    spat_dists = mrC.Simulate.CalculateSourceDistance(MDATA,Noise.distanceType);
    
    % -----This part calculate mixing matrix for coherent noise-----
    if strcmp(Noise.mixing_type_pink_noise,'coh')
        mixDir = fullfile(anatDir,subIDs{s},'Standard','meshes',['noise_mixing_data_' Noise.distanceType '.mat']);
        if ~exist(mixDir,'file')% if the mixing data is not calculated already
            noise_mixing_data = mrC.Simulate.GenerateMixingData(spat_dists);
            save(mixDir,'noise_mixing_data');
        else
            load(mixDir);
        end
    end
    
    % ----- Generate noise-----
    % this noise is NS x srcNum matrix, where srcNum is the number of source points on the cortical  meshe
    noiseSignal = mrC.Simulate.GenerateNoise(opt.signalsf, NS, size(spat_dists,1), Noise.mu, AlphaSrc, noise_mixing_data,Noise.spatial_normalization_type);   
    % 
%------------------------PLACE SIGNAL IN THE ROIs--------------------------
    
    disp('Generating EEG signal ...');
    % Put an option to get the ROIs either from input of function or from command line
    

    CorrectROI = cellfun(@(x) strcmpi(tempList,x), masterList,'UniformOutput',false);% compare the names of input ROIs with the ones from the filess
    
    % In the following function size(opt.signalArray,2) should be equal to size of masterList)     
    if (numel(masterList)~=seedNum) && (sum(cellfun(@(x) sum(x),CorrectROI))==seedNum)
        ROIcorr = false;
        while ROIcorr==false
            warning(['Number of ROIs does not match the number of input signals. Please select ' num2str(seedNum) ' ROIs among the list below:']);
            if strcmp(opt.roiType,'wang')
                tempList = cellfun(@(x) x(11:end),tempList,'uni',false);
            end
            List = strcat(sprintfc('%d',1:numel(tempList)),{' - '},tempList);
            display(List);
            ROIidx = unique(input(['Please enter ' num2str(seedNum) ' ROIs: (example: [1 10])\n']));
            
            % If the criteria is correct
            if (numel(ROIidx)==seedNum) && (prod(ismember(ROIidx,1:numel(tempList)))) 
                
                masterList = masterList(ROIidx); 
                opt.roiList = masterList;
                ROIcorr = true;
            end
        end     
    end
    
    [EEGData{s},sourceDataOrigin{s}] = mrC.Simulate.SrcSigMtx(roiDir,masterList,fwdMatrix,opt.signalArray,noiseSignal,Noise.lambda,'active_nodes');%Noise.spatial_normalization_type);% ROIsig % noiseParams
%% convert EEG to axx format
% if signalType=='SSVEP'
    EEGAxx{s}= mrC.Simulate.CreateAxx(EEGData{s},opt);% Converts the simulated signal to Axx format  
% end
end


%% =======================PLOT FIGURES=====================================
if opt.plotting==1
    %-------------------Calculate EEG spectrum---------------------------------
    freq = 0:EEGAxx{1}.dFHz:EEGAxx{1}.dFHz*(EEGAxx{1}.nFr-1); % frequncy labels, based on fft

    for s = 1: length(projectPath)
        if ~isempty(EEGData{s})
            ASDEEG{s} = EEGAxx{s}.Amp;% it is important which n is considered for fft
        end
    end
    MASDEEG = mean(cat(4,ASDEEG{:}),4);

    % ------------------------FIRST PLOT: EEG and source spectra---------------
    WL = 1000/(EEGAxx{1}.dTms*EEGAxx{1}.dFHz); % window length for FFT, based on AXX file
    freq2 = (-0.5:1/(WL*4):0.5-1/(WL*4))*opt.signalsf;
    figure,
    subplot(3,1,1); % Plot signal ASD
    plot(freq2,abs(fftshift(fft(opt.signalArray,WL*4),1)));
    xlim([0,max(freq2)]);xlabel('Frequency(Hz)');
    ylabel('Source signal','Fontsize',14);

    subplot(3,1,2); % Plot noise ASD
    plot(freq2,abs(fftshift(fft(noiseSignal(:,1:500:end),WL*4),1)));
    xlim([0,max(freq2)]);xlabel('Frequency(Hz)');
    ylabel('Noise signal','Fontsize',14);

    subplot(3,1,3); % plot EEG ASD
    %plot(freq2,abs(fftshift(fft(EEGData,WL*4),1)));
    plot(freq,MASDEEG);
    xlim([0,max(freq2)]);xlabel('Frequency(Hz)');
    ylabel('EEG signal','Fontsize',14);

    input('Press enter to continue....');
    close all;
    % --------------SECOND PLOT: interactive head and spectrum plots-----------
    if isempty(opt.signalFF)
        opt.signalFF = 1;
    end
     % Plot average over individuals
    mrC.Simulate.PlotEEG(MASDEEG,freq,opt.figFolder,'average over all  ',masterList,opt.signalFF);

     % Plot individuals
    for s = 1: length(projectPath)
        if ~isempty(EEGData{s})
            mrC.Simulate.PlotEEG(ASDEEG{s},freq,opt.figFolder,subIDs{s},masterList,opt.signalFF);
        end
    end
end
end
