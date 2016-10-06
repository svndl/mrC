function [roiData,masterList] = SourceRoi(mrCPath,invPaths,varargin)
    % Description:	Convert EEG data to source-localized ROI data
    % 
    % Syntax:	[roiData,masterList] = mrC.SourceRoi(mrCPath,invPaths,<options>)
    % In:
    %   mrCPath - string, path to mrCurrent folder. 
    %              If this is a string,subIds and dataIn will be ignored ("mrCurrent mode"). 
    %              If this is false, subIds and dataIn will be used ("direct mode").
    %    
    %   invPaths - EITHER: a 1 x s cell matrix, where each cell is a string,
    %               specifying the path to the inverse for that subject. 
    %               OR: a string specifying the name of the inverse to use.
    %               This is only available in mrCurrent mode. 
    %               In direct mode, this option will be ignored if dataIn
    %               is source data, rather than sensor data.
    %
    %   note that in direct mode, dataIn and subIds are required! 
    %
    %   <options>:
    %       dataIn: c x s cell matrix, where each cell contains
    %               a 3-d matrix with time x channels x trials. If
    %               # channels is 128, sensor space will be assumed. If
    %               # channels is large (>20000), source space will be assumed
    %               (and invPaths not used).
    %       
    %       subIDs: 1 x s cell matrix, where each cell is a string
    %               specifying the subject ID
    %       
    %       roiType:    string specifying the roitype to use (['func']/'wang'/'all').
    %       
    %       blRoiOnly:  exclude non-bilateral ROIs (true/[false])
    %
    %       doConvert: convert the data to µAmp/mm2 by multiplying with 1e6
    %                  ([true]/false)
    %                        
    % Out:
    % 	roiData:    c x s cell matrix of output data, where each cell contains
    %               a 3-d matrix with time x ROIs x laterality. 
    % 
    %	masterList: a 1 x nROIs cell of strings, indicating ROI names
    
    % defaults    
    opt	= ParseArgsOpt(varargin,...
            'dataIn'		, [], ...
            'subIDs'		, []	, ...
            'roiType'       ,'func', ...
            'blRoiOnly' , false,   ...
            'doConvert',true ...
            );
    
    if ischar(mrCPath)
        % mrCurrent mode
        opt.dataIn =[]; opt.subIDs = []; % ignore these options
        if iscell(invPaths) % invPaths can be either the path to an inverse or the name only
            [~,invName,ext] = fileparts(invPaths{1});
        else
            [~,invName,ext] = fileparts(invPaths);
        end
        clear invPaths;
        invName = [invName,ext];
        mrCfolders = subfolders(mrCPath,1);
        for s = 1:length(mrCfolders)
            curFolder = mrCfolders{s};
            [~,opt.subIDs{s}]=fileparts(curFolder);
            if ~isempty(strfind(opt.subIDs{s},'_')) % if suffix
                opt.subIDs{s} = opt.subIDs{s}(1:(strfind(opt.subIDs{s},'_')-1));
            else
            end
            invPaths{s} = fullfile(curFolder,'Inverses',invName);
            axxFiles = subfiles(fullfile(curFolder,'Exp_MATL_HCN_128_Avg','Axx*'),1);
            for c=1:length(axxFiles)
                axxStrct = matfile(axxFiles{c});
                opt.dataIn{c,s} = axxStrct.Wave;
                clear axxStrct;
            end
        end
        doInverse = true;
    else %  direct mode
        % check subject IDs
        if isempty(opt.subIDs)
            error('direct mode, missing cell of subject IDs, flag "subIDs"');
        else
        end
        % check input data
        if isempty(opt.dataIn)
            error('direct mode, missing input data, flag "dataIN"');
        else
        end 
        % check inverse
        nChannels = size(opt.dataIn{1,1},2);
        if nChannels == 128 % use inverse
            doInverse = true;
            if ~isempty(invPaths)
                existIdx = logical(cellfun(@(x) exist(x,'file'),invPaths));
                if sum(existIdx) < length(invPaths)
                    error('inverse "%s" and possibly other was not found',invPaths{find(existIdx,1)});
                else
                end
            else
                error('sensor data, but no inverse given');
            end
        elseif nChannels > 20000
            doInverse = false;
        else
            error('unexpected number of channels, %d, check data format',nChannels);
        end
    end
    
    nSubs = size(opt.dataIn,2);
    nConds = size(opt.dataIn,1);    
    anatDir = getpref('mrCurrent','AnatomyFolder');
    
    %% RUN IT

    for s = 1:nSubs
        % get inverse
        curInv = mrC_readEMSEinvFile(invPaths{s});
        % get ROI chunks
        curROIdir = fullfile(anatDir,opt.subIDs{s},'Standard','meshes','ROIs');
        [roiChunk, roiList] = mrC.ChunkFromMesh(curROIdir,size(curInv,2),opt.roiType,opt.blRoiOnly);
        shortList = cellfun(@(x) x(1:end-6),roiList,'uni',false);
        if s==1
            masterList = unique(shortList);
        else
        end
        
        for c = 1:nConds
            if opt.doConvert
                curData = opt.dataIn{c,s}.*1e6;
            else
                curData = opt.dataIn{c,s};
            end
            nTrials = size(curData,3);
            for t = 1:nTrials
                if doInverse
                    srcData(:,:,t) = double(curData(:,:,t)*curInv); % multiply by inverse to get into source space
                else
                    srcData(:,:,t) = double(curData(:,:,t));
                end
            end
            srcData = nanmean(srcData,3); % average over trials (for now)
            for r=1:size(roiChunk,2)
                roiIdx = find(cellfun(@(x) strcmp(x,shortList{r}),masterList));
                if isempty(roiIdx)
                    masterList(end+1) = shortList(r);
                    roiIdx = length(masterList);
                else
                end
                clear biIdx;
                if strfind(roiList{r},'-L')
                    lIdx = 1;
                    % find index for other hemisphere
                    otherIdx = find(cell2mat(cellfun(@(x) strcmp(x,[roiList{r}(1:end-6),'-R.mat']), roiList,'uni',false)));
                    if length(otherIdx) == 1
                        biIdx = [find(roiChunk(:,r));find(roiChunk(:,otherIdx))]; % combine indices from two hemispheres
                        roiData{c,s}(:,roiIdx,3) = nanmean(srcData(:,biIdx),2); % bilateral data, average over ROI voxels
                    elseif length(otherIdx) > 1
                        error('multiple cross-hemispheres name matches');
                    else
                    end
                else
                    lIdx = 2;
                end
                roiData{c,s}(:,roiIdx,lIdx) = nanmean(srcData(:,find(roiChunk(:,r))),2); % average over ROI voxels
            end
        end
    end
end