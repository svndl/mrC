function [outData,transMtx] = SourceBrain(mrCPath,invPaths,varargin)
    % Description:	Convert EEG data to source-localized whole-brain data
    % 
    % Syntax:	[outData,transMtx] = mrC.SourceBrain(mrCPath,invPaths,varargin)
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
    %       template: string specifying the subjID to use as template, if
    %                 set to false, surface-based averaging will not de done
    %       dataIn:   c x s cell matrix, where each cell contains
    %                 a 3-d matrix with time x channels x trials. If
    %                 # channels is 128, sensor space will be assumed. If
    %                 # channels is large (>20000), source space will be assumed
    %                 (and invPaths not used).
    %       subIDs: 1 x s cell matrix, where each cell is a string
    %               specifying the subject ID  
    %       doSmooth: smooth the data after applying inverse ([true]/false) 
    %
    %       doConvert: convert the data to µAmp/mm2 by multiplying with 1e6
    %                  ([true]/false)
                        
    % Out:
    
    % defaults    
    opt	= ParseArgsOpt(varargin,...
            'template', false, ...
            'dataIn'		, [], ...
            'subIDs'		, []	, ...
            'doSmooth' , true,   ...
            'doConvert',true...
            );
    
    if ischar(mrCPath)
        % mrCurrent mode
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
        opt.doInverse = true;
    else %  direct mode
        nChannels = size(opt.dataIn{1,1},2);
        if nChannels == 128 % use inverse
            opt.doInverse = true;
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
            opt.doInverse = false;
        else
            error('unexpected number of channels, %d, check data format',nChannels);
        end
    end
    
    nSubs = size(opt.dataIn,2);
    nConds = size(opt.dataIn,1);    

    %% RUN IT

    outData = cell(nConds,nSubs);
    transMtx = cell(3,nSubs);
    for s = 1:nSubs
        if opt.template
            mapMtx = makeDefaultCortexMorphMap(opt.subIDs{s},opt.template);
        else
            mapMtx = false;
        end
        
        % Do a second order neighbor smoothing
        if opt.doSmooth
            fromCtx = readDefaultCortex(opt.subIDs{s});
            fromCtx.uniqueVertices = fromCtx.vertices;
            fromCtx.uniqueFaceIndexList = fromCtx.faces;
            [fromCtx.connectionMatrix] = findConnectionMatrix(fromCtx);
            fromCtx.connectionMatrix = fromCtx.connectionMatrix + speye(length(fromCtx.connectionMatrix));
            sumNeighbours=sum(fromCtx.connectionMatrix,2); % Although it should be symmetric, we specify row-summation
            smoothMtx=bsxfun(@rdivide,fromCtx.connectionMatrix,sumNeighbours);
            smoothMtx = smoothMtx*smoothMtx;
        else
            smoothMtx = false;
        end
        
        if opt.doInverse
            curInv = mrC_readEMSEinvFile(invPaths{s});
        else
            curInv = false;
        end

        for c = 1:nConds
            curData = opt.dataIn{c,s};
            nTrials = size(curData,3);
            for t = 1:nTrials
                curWave = curData(:,:,t);
                if opt.doInverse
                    curWave = curWave*curInv; % multiply by inverse to get into source space
                else
                end
                if opt.doConvert
                    curWave = double( curWave.*1e6 );        % make thisWave double (BRC add on 11/09/2013)
                else
                    curWave = double( curWave );
                end
                if opt.doSmooth
                    curWave = curWave*smoothMtx;        % apply smoothing matrix
                else
                end
                if opt.template
                    outData{c,s}(:,:,t) = mapMtx*curWave';  % apply between-subject morphing matrix
                else
                    outData{c,s}(:,:,t) = curWave';
                end
            end
        end
        transMtx{1,s} = curInv;
        transMtx{2,s} = smoothMtx;
        transMtx{3,s} = mapMtx;
    end
end