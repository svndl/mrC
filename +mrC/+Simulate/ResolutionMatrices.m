function [CrossTalk CrossTalkN] = ResolutionMatrices(projectPath,varargin)
    
    % Description:	This function gets the path for a mrc project and simulate
    % EEG with activity (seed signal as input) in specific ROIs (input),
    % and pink and alpha noises (noise parameters can be set as input)
    %
    % Syntax:	[EEGData,EEGAxx,sourceDataOrigin,masterList,subIDs] = mrC.RoiDemo(projectPath,varargin)
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
    %       signalFF:       a seedNum x 1 vector: determines the fundamental
    %                       frequencis of sources
  
  % (ROI Parameters)

    %       roiType:        THIS IS NOT NEEDED IF YOU GIVE THE rois INPUT.  
    %                       string specifying the roitype to use. 
    %                       'main' indicates that the main ROI folder
    %                       /Volumes/svndl/anatomy/SUBJ/standard/meshes/ROIs
    %                       is to be used. ('func'/'wang'/'glass'/'kgs'/'benson'/'wangkgs').
    %
    %
    %       roiSpatfunc     a string indicating which spatial function
    %                       will be used to put the seed signal in ROI
    %                       [uniform]/gaussian
    %       roiSize         number of vertices in each ROI
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
    

  % (Save Parameters)
    %       SavePath:       The folder to save simulated data in axx format
    %
    %       cndNum:         The condition number for simulated EEG
  
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
    'rois'          , [], ...
    'roiType'       , 'wang',...
    'figFolder'     , [],...
    'anatomyPath'   , []...   
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


%-------Set folder for saving the results if not defined (default is desktop)----------
if isempty(opt.figFolder)
    if ispc,home = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
    else home = getenv('HOME');end
    opt.figFolder = fullfile(home,'Desktop');
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



%% ===========================GENERATE EEG signal==========================
projectPathfold = projectPath;
projectPath = subfolders(projectPath,1); % find subjects in the main folder

for s = 1:length(projectPath)
    %--------------------------READ FORWARD SOLUTION---------------------------  
    % Read forward
    [~,subIDs{s}] = fileparts(projectPath{s});
    disp (['Simulating EEG for subject ' subIDs{s}]);
    
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
        load([fwdPath '-fwd.mat']);
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
    

    
    %% Read Inverses
    if ~isempty(opt.inverse)
        invPaths{s} = fullfile(projectPath{s},'Inverses',opt.inverse);
        if exist(invPaths{s},'file')
            curInv = mrC_readEMSEinvFile(invPaths{s});
        else
            error(['Inverse ' opt.inverse ' is not found']);
        end
    else
        warning('Please indicate the inverse name...');
    end

    %% Make the resolution matrix

    Resolution = fwdMatrix'*curInv;

    %% Get the ROIs
    %%%%%%%%%%%%%%%%%%%%% add other atlases later...%%%%%%%%%%%%%%%%%%%%%%%
    
    RoiDir = fullfile(anatDir,subIDs{s},'Standard','meshes',['wang_ROIs']);%
    [roiChunk , list] = mrC.ChunkFromMesh(RoiDir,size(fwdMatrix,2));% read the ROIs 

    RoiDir2 = fullfile(anatDir,subIDs{s},'Standard','meshes','kgs_ROIs');%
    [roiChunk2 , list2] = mrC.ChunkFromMesh(RoiDir2,size(fwdMatrix,2));% read the ROIs 
    roiChunk = cat(2,roiChunk,roiChunk2);
   
    %RoiDir2 = fullfile(anatDir,subIDs{s},'Standard','meshes','glass_ROIs');%
    if exist(RoiDir2,'dir'),
        [roiChunk , list2] = mrC.ChunkFromMesh(RoiDir2,size(fwdMatrix,2));% read the ROIs    
        
        % cross talk matrix
        ROISource{s} = roiChunk.'*Resolution;
        CrossTalk{s} = ROISource{s}*roiChunk;
        CrossTalkN{s} = CrossTalk{s}./repmat(max(CrossTalk{s},[],2),[1 length(CrossTalk{s})]);

    end
end
end


function Inv = mrC_readEMSEinvFile(filename)
% Inv = mrC_readEMSEinvFile(filename)
% returns nChannels x nVertices matrix
% 
% based on emseReadInverse, modified to fread nRows x nCols bytes
% beginning at (assumed) end of header rather than by fseeking back from EOF.
% Thus, this implementation should read .inv files with or without the xml-ish footer.

% $Log: mrC_readEMSEinvFile.m,v $
% Revision 1.3  2009/11/18 01:55:03  nicholas
% merged into main branch
%
% Revision 1.2.2.2  2009/11/12 20:45:18  nicholas
% changed 128 channel check from error to warning
%
% Revision 1.2.2.1  2009/07/21 18:17:31  nicholas
% *** empty log message ***
%
% Revision 1.2  2008/11/07 00:03:00  ales
% Further squashed the emse style inverse binary/text reading bug
%
	fid = fopen(filename,'rb','ieee-le');
	if fid == -1
		error('Error opening %s',filename)
	end
	% Get the magic number
	magicNum = upper(fscanf(fid,'%c',8));
	if strcmp(magicNum,'454D5345') % Magic number is OK, we're reading a real inverse file
		% Next read in the major and minor revs, and other header fields.
		% Based on the file format description in Appendix A of EMSE's help file,
		% we expect exactly ten elements in Header, with the dimensions of the inverse
		% matrix in the 9th and 10th position.  Here's what can go wrong:
		% 1) SSI might revise inverse file header field structure without warning us.
		% 2) There will be two extra fields if "cortical thinning was used", whatever that means.
		% For now, this implementation simply checks whether fscanf returns less than expected number of
		% Header elements, otherwise throwing an error.  It falls to you, dear reader,
		% to implement handling of the remaining possibilities listed above should they ever occur.
		[Header,nHeader] = fscanf(fid,'%d',10);
		% fscanf is not robust to bytes following the last header field that have degenerate ASCII values;
		% so we use fgetl, which seems to behave correctly;
                % These lines did not completely fix the bug. Changed to an explicit fseek,
		% see line below if block: fseek(fid,1,0)
		% nHeader = nHeader + 1;
		% Header(nHeader) = str2num(fgetl(fid));

		if nHeader ~= 10
			error('Expecting 10 header elements, found %d in %s',nHeader,filename)
        	end	
		
		%This line explicity sets the file read position to what we think is the begining of good data.
	        fseek(fid,1,0);
        
		nRows = Header(9);
		nCols = Header(10);
		if nCols ~= 128
% 			error('Expecting 128 columns in inverse, found %d in %s',nCols,filename);
			warning('Expecting 128 columns in inverse, found %d in %s',nCols,filename);
		end
		[Inv,nInv] = fread(fid,nCols*nRows,'float64',0,'ieee-le');
		fclose(fid);
		if nInv ~= nCols*nRows
			error( 'Size of inverse (%d) does not match dimensions in file header (%d*%d=%d)',nInv,nRows,nCols,nRows*nCols)
		end
		Inv = reshape( Inv, nCols, nRows );		% nChannels x nVertices
	else
		error('Magic# in %s = %s, expecting 454D5345',filename,magicNum)
	end
end

