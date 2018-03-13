function [EEGData,sourceDataOrigin,masterList,subIDs] = RoiSignal(projectPath,varargin)
    % Description:	This function gets the path for a mrc project and simulate
    % EEG with activity (sourvce signal as input) in specific ROIs (input),
    % and pink and alpha noise (parameters can be set as input)
    %
    % Syntax:	[sensorData,masterList,subIDs] = mrC.RoiDemo(projectPath,varargin)
    % 
    
% INPUT:
  % projectPath - string, path to mrCurrent project folder. ELHAM: For now, I have considered a single subject folder
    %              If this is a string,subIds and dataIn will be ignored ("mrCurrent mode").??
    %              If this is false, subIds and dataIn will be used ("direct mode"). % for now I have not considered this
    %
    %
    %   note that in direct mode, dataIn and subIds are required!
    %
  %   <options>:
    %
  % (Source Signal Parameters)
    %       signalArray:    a ns x Srcnum matrix, where ns is the number of
    %                       time samples and Srcnum is the number of seed sources
    %                       [ns x 2 SSVEP sources] -> for these two, the
    %                       default ROIs of VO1L and V4R in functional
    %                       roitype is selected
    %
    %       signalsf:       sampling frequency of the input source signal
    %       
    %       signalFF:       a 1 x Srcnum vector: determines the fundamental
    %                       frequencis of sources
  
  % (ROI Parameters)
    %       roiType:        string specifying the roitype to use. 
    %                       'main' indicates that the main ROI folder
    %                       /Volumes/svndl/anatomy/SUBJ/standard/meshes/ROIs
    %                       is to be used. (['func']/'wang'/'glass','kgs','benson','main').
    %
    %       roiList:        a 1 x Srcnum cell of strings, with names of ROIs to simulate. 
    %                       [all ROIs of the specified type]
    %
    %       anatomyPath:  The folder should be for the same subject as
    %                       projectPath points to. It should have ROI forders, default
    %                       cortex file, ..
    

  % (Noise Parameters), all this parameters are defined inside "noiseParam." structure
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
    %       EEGData:        a ns x e matrix, containing simulated EEG,
    %                       where ns is number of time samples and e is the
    %                       number of the electrodes
    %
    %
    %       sourceDataOrigin: a ns x sources matrix, containing simulated
    %                           EEG in source space before converting to
    %                           sensor space EEG, where sources is the
    %                           number of source points on the cortical
    %                           meshe
    %
    %       masterList:     a 1 x Srcnum cell of strings, indicating ROI names
    %
    %       subIDs:         a 1 x s cell of strings, indicating subjects IDs     SHOULD BE UPDATED LATER
    %

 % The function was originally written by Peter Kohler, ...
 % Latest modification: Elham Barzegaran, 03.07.2018
 
 %% Prepare input variables
 
% set up default values
opt	= ParseArgs(varargin,...
    'inverse'		, [], ...
    'roiType'       , 'func',...
    'roiList'		, [],...
    'signalArray'   , [],...
    'signalsf'      , 100 ,... %?????? Check what is the best
    'noiseParams'   , struct,...
    'sensorFig'     , true,...
    'doSource'      , false,...
    'figFolder'     , [],...
    'anatomyPath'   ,[],...
    'signalFF'      ,[]...
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

% set inverse path
 %projectPath = subfolders(projectPath,1);% CHANGED FOR NOW, SHOULD CHANGE IT BACK?
if isempty(opt.inverse)
    tempStrct = dir(fullfile(projectPath{1},'Inverses/*'));% CHANGE
    %tempStrct = dir(mrCfolders{2}); %CHANGE
    [~,tempIdx]=max(cat(3,tempStrct.datenum)); % sort by date
    opt.inverse = tempStrct(tempIdx).name;         % use latest
else
    if iscell(opt.inverse) % unwrap if necessary
        opt.inverse = opt.inverse{1};
    else
    end
end

% Set folder for saving the results...default is desktop
if isempty(opt.figFolder)
    if ispc,home = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
    else home = getenv('HOME');end
    opt.figFolder = fullfile(home,'Desktop');
else
end

% set anatomy data paths (For ROIs)
if isempty(opt.anatomyPath)
    anatDir = getpref('mrCurrent','AnatomyFolder');
    if ~isempty(strfind(upper(anatDir),'HEADLESS')) || isempty(anatDir)
        anatDir = '/Volumes/svndl/anatomy';
        setpref('mrCurrent','AnatomyFolder',anatDir);
    else
    end
else
    anatDir = opt.anatomyPath;
end

%% READ FORWARD SOLUTION AND ROIs
for s=1:length(projectPath)
    % Read forward
    [~,subIDs{s}]=fileparts(projectPath{s});
    fwdPath = fullfile(projectPath{s},'_MNE_',[subIDs{s} '-fwd.fif']);
    fwdStrct = mne_read_forward_solution(fwdPath); % Read forward structure
    % Checks if freesurfer folder path exist
    if ~ispref('freesurfer','SUBJECTS_DIR')
        %temporary set this pref for the example subject
        setpref('freesurfer','SUBJECTS_DIR',fullfile(anatDir,'FREESURFER_SUBS'));% check
    end
    srcStrct = readDefaultSourceSpace(subIDs{s}(1:7)); % Read source structure from freesurfer
    fwdMatrix = makeForwardMatrixFromMne(fwdStrct ,srcStrct); % Generate Forward matrix
    % Set ROI folder
    if strcmp(opt.roiType,'main')
        roiDir = fullfile(anatDir,subIDs{s},'Standard','meshes','ROIs');
        roiPaths = subfiles(roiDir);
    else
        roiDir = fullfile(anatDir,subIDs{s}(1:7),'Standard','meshes',[opt.roiType,'_ROIs']);
        roiPaths = subfiles(roiDir);
    end
    if ~exist(roiDir,'dir')
        error('selected roi directory does not exist: %s', roiDir);
    else
    end
    
    % Read the list of ROIs
    if s==1
        if isempty(opt.roiList)
             %opt.roiList = unique(cellfun(@(x) x(1:end-6),roiPaths,'uni',false));
             opt.roiList = unique(cellfun(@(x) x(1:end-4),roiPaths,'uni',false));%roiPaths; % I CONSIDER THE LEFT AND RIGHT ROIS SEPARATELY
        else
        end
        masterList = opt.roiList;
    else
    end
    
%% Generate default source signal
    [roiChunk,tempList] = mrC.ChunkFromMesh(roiDir,size(fwdMatrix,2));
    tempList = unique(cellfun(@(x) x(1:end-4),tempList,'uni',false));
    % Generate signal of interest
    if isempty(opt.signalArray) 
        [opt.signalArray, opt.signalFF, opt.signalsf]= mrC.Simulate.ModelSourceSignal(); % default signal (can be compatible with the number of ROIs, can be improved later )
        opt.roiList = tempList([33 34]);
        masterList = opt.roiList;
    end   
 
%% Generate noise: from Sebastian's code   
    % Generate noise with parameters 
    
    % Noise default values
    NS = size(opt.signalArray,1); % number of time samples
    srcNum = size(opt.signalArray,2); % number of seed sources
    Noise = opt.noiseParams;
    Noisefield = fieldnames(Noise);
    
    if ~any(strcmp(Noisefield,'mu')),Noise.mu = 1;end % power distribution between alpha noise and pink noise ('noise-to-noise ratio')
    if ~any(strcmp(Noisefield,'lamda')),Noise.lambda = 1/NS;end % power distribution between signal and 'total noise' (SNR)
    if ~any(strcmp(Noisefield,'spatial_normalization_type')),Noise.spatial_normalization_type = 'all_nodes';end% ['active_nodes', 'all_nodes']
    if ~any(strcmp(Noisefield, 'distanceType')),Noise.distanceType = 'Geodesic';end %'Euclidean' 
    if ~any(strcmp(Noisefield, 'Noise.mixing_type_pink_noise')), Noise.mixing_type_pink_noise = 'coh' ;end % coherent mixing of pink noise
    if ~any(strcmp(Noisefield, 'alpha_nodes')), Noise.alpha_nodes = 'all';end % for now I set it to all visual areas, later I can define ROIs for it

    % Determine alpha nodes: This is temporary

    if strcmp(Noise.alpha_nodes,'all'), AlphaSrc = find(sum(roiChunk,2)); end % for now: all nodes will show the same alpha power over whole visual cortex  

    disp ('Generating noise signal ...');
    
    % Calculate source distance matrix
    load(fullfile(anatDir,subIDs{s}(1:7),'Standard','meshes','defaultCortex.mat'));
    MDATA = msh.data; clear msh;
    Euc_dist = squareform(pdist(MDATA.vertices')) ;
    if strcmp(Noise.distanceType,'Euclidean')
        spat_dists =  Euc_dist;%assuming euclidian distances (can be changed later)
    elseif strcmp(Noise.distanceType,'Geodesic')
        faces = MDATA.triangles'; vertex = MDATA.vertices';
        [c, ~] = tess_vertices_connectivity( struct( 'faces',faces + 1, 'vertices',vertex ) ); 
        % although using graph-based shortest path algorithm, we can estimate surface distances: But this will overestimate the real
        % distances...
        if exist('graph')~=2
            G = c.*Euc_dist;
            spat_dists = distances(graph(G));
            clear G c;
        else 
            % I recieve memory error... think what can be done...
            %error ('Geodesic distance is not implemented yet... Please use Eudlidean distance for now'); %%%%%%% SHOULD BE IMPLEMENTED
            spat_dists = inf(size(c));
            hWait = waitbar(0,'Calculating Geodesic distances ... ');
            for s = 1:length(c)
                if mod(s,10)==0
                    waitbar(s/length(c));
                    disp(['calculating distance...' num2str(sound((s/length(c))*100)) ' %']);
                end
                spat_dists(s,s:length(c)) = dijkstra(c,Euc_dist,s,s:length(c),0);% complexity of this algorithm is O(|V^2|), where V is number of nodes
            end
            close hWait;
            spat_dists = min(spat_dists,spat_dists');
        end
    end   
    
    % This part calculate mixing matrix for coherent noise
    if strcmp(Noise.mixing_type_pink_noise,'coh')
        mixDir = fullfile(anatDir,subIDs{s}(1:7),'Standard','meshes',['noise_mixing_data_' Noise.distanceType '.mat']);
        if ~exist(mixDir,'file')% if the mixing data is not calculated already
            noise_mixing_data = mrC.Simulate.Generate_mixing_data(spat_dists);
            save(mixDir,'noise_mixing_data');
        else
            load(mixDir);
        end
    end
    
    noiseSignal = mrC.Simulate.generate_noise(opt.signalsf, NS, size(spat_dists,1), Noise.mu, AlphaSrc, noise_mixing_data,Noise.spatial_normalization_type);   
    
    %% PLACE SIGNAL IN THE ROIs (for now with a uniform distribution) AND ADD THE NOISE    
    warning('on');
    display('Generating EEG signal ...')
    % put an option to get the ROIs either from input of function or from command line
    
    
    % in the following function size(opt.signalArray,2) should be equal to size of masterList) 
    if numel(masterList)~=srcNum
        ROIcorr = false;
        while ROIcorr==false
            warning(['Number of ROIs does not match the number of input signals. Please select ' num2str(srcNum) ' ROIs among the list below:']);
            if strcmp(opt.roiType,'wang'), tempList = cellfun(@(x) x(11:end),tempList,'uni',false);end
            List = strcat(sprintfc('%d',1:numel(tempList)),{' - '},tempList);
            display(List);
            ROIidx = unique(input(['Please enter ' num2str(srcNum) ' ROIs: (example: [1 10])\n']));
            
            % if the criteria is correct
            if (numel(ROIidx)==srcNum) && (prod(ismember(ROIidx,1:numel(tempList)))) 
                masterList = masterList(ROIidx); 
                ROIcorr = true;
            end
        end     
    end
    
    [EEGData,sourceDataOrigin] = mrC.Simulate.SrcSigMtx(roiDir,masterList,fwdMatrix,opt.signalArray,noiseSignal,Noise.lambda,'active_nodes');%Noise.spatial_normalization_type);% ROIsig % NoiseParams
    
    %% Adjust structure for output and plots
    invPath = fullfile(projectPath{s},'Inverses',opt.inverse);
    %invMatrix = mrC_readEMSEinvFile(invPath);
    readyInverse{s} = invPath;    
end

%% DRAW FIGURES
%The length of fft should be indicated (This is similar to axx file from PowerDiva)
if ~isempty(opt.signalFF)
    WL = (opt.signalFF.^-1)*opt.signalsf*2;%window length for each fundamental frequency: half resolution of fundamentals
    WL = lcms(WL);% least common multiple
    if WL<(opt.signalsf*2)% find a time window for resolution less than .5 Hz
        WL = WL*(WL\(opt.signalsf*2));
    end
else
    WL = opt.signalsf*2;
end

% FIRST PLOT: EEG and source spectrum
freq = (-0.5:1/(WL*4):0.5-1/(WL*4))*opt.signalsf;
figure,
subplot(3,1,1);
plot(freq,abs(fftshift(fft(opt.signalArray,WL*4),1)));
xlim([0,max(freq)]);xlabel('Frequency(Hz)');
ylabel('Source signal','Fontsize',14);

subplot(3,1,2);
plot(freq,abs(fftshift(fft(noiseSignal(:,1:500:end),WL*4),1)));
xlim([0,max(freq)]);xlabel('Frequency(Hz)');
ylabel('Noise signal','Fontsize',14);

subplot(3,1,3);
plot(freq,abs(fftshift(fft(EEGData,WL*4),1)));
xlim([0,max(freq)]);xlabel('Frequency(Hz)');
ylabel('EEG signal','Fontsize',14);


% SECOND PLOT: interactive head and spectrum plots
ASDEEG = abs(fftshift(fft(EEGData,WL),1));% it is important which n is considered for fft
freq = (-0.5:1/WL:0.5-1/WL)*opt.signalsf; % frequncy labels, based on fft
fidx = find(freq>=0); freq = freq(fidx);
ASDEEG = ASDEEG(fidx,:);

if ~isempty(opt.signalFF)
    FOI = opt.signalFF;
else
    %ASDSIG = abs(fftshift(fft(opt.signalArray,WL)));% if the fundamental frequencies are not given as an input to the function
    FOI = 2;% for now just 2Hz
end
[~,~,FOIidx] = intersect(FOI,round(freq*1000)/1000);% find the index of fundamental frequencies in freq

Probs{1} = {'facecolor','none','edgecolor','none','markersize',10,'marker','o','markerfacecolor','g' ,'MarkerEdgeColor','k','LineWidth',.5};% plotting parameters
conMap = jmaColors('hotcortex');
mrC.Simulate.PlotEEG(ASDEEG,freq,FOIidx,Probs,opt.figFolder,masterList,opt.signalFF);

%% APPLY INVERSE: I will update this part later
%     if opt.doSource
%         % source localized seed data
%         sourceData = mrC.SourceBrain(false,readyInverse,'template','nl-0014','dataIn',readyData,'subIDs',subIDs);
%         sourceDataSingle = mrC.SourceBrain(false,readyInverse(subIdx),'template',false,'dataIn',readyData(:,subIdx),'subIDs',subIDs(subIdx));
% 
%         tempData = arrayfun(@(x) nanmean(cat(3,sourceData{x,:}),3),1:size(sourceData,1),'uni',false); % average over subjects
%         tempData = cat(3,tempData{:}); % concatenate over ROIs
%         readyData = reshape(tempData,size(tempData,1),[]);
%         tempData = cat(3,sourceDataSingle{:});  % concatenate over ROIs
%         readySingleData = reshape(tempData,size(tempData,1),[]);
%         roiLabels = repmat(masterList,1,3);
%         hemiLabels = repmat({'-L','-BL','-R'},size(sourceData,1),1);
%         roiLabels = cellfun(@(x,y) [x,y],roiLabels,hemiLabels,'uni',false)';
%         roiLabels = roiLabels(:);
% 
%         mrC.WriteNiml('nl-0014',readyData,'outpath',fullfile(opt.figFolder,'roiDemoAverage.niml.dset'),'labels',roiLabels,'std_surf',false);
%         mrC.WriteNiml('nl-0014',readySingleData,'outpath',fullfile(opt.figFolder,'roiDemoSingle.niml.dset'),'labels',roiLabels,'std_surf',false,'doSmooth',false);
%     else
%     end


end
