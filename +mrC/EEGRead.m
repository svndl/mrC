function [outData,FreqFeatures,subIDs] = EEGRead(mrCPath,varargin)
    % Description:	Reads EEG data, gives output similar to SourceBrain 
    % 
    % Syntax:	[outData,transMtx] = mrC.SourceBrain(mrCPath,invPaths,varargin)
    % In:
    %   mrCPath - string, path to mrCurrent folder. 
    %              If this is a string,subIds and dataIn will be ignored ("mrCurrent mode"). 
    %              If this is false, subIds and dataIn will be used ("direct mode").
    %    
    
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
    %       domain: calculate the inverse in time or frequency domain. if
    %               in frequency domain, it will return the inverse data in
    %               complex matrices. ([time]/frequency)
                        
    % Out:
    
    % defaults    
    opt	= ParseArgs(varargin,...
            'template', false, ...
            'dataIn'		, [], ...
            'subIDs'		, []	, ...
            'domain', 'time'...
            );
    
    if ischar(mrCPath)
        % mrCurrent mode

        mrCfolders = subfolders(mrCPath,1);
        for s = 1:length(mrCfolders)
            curFolder = mrCfolders{s};
            [~,opt.subIDs{s}]=fileparts(curFolder);
            if ~isempty(strfind(opt.subIDs{s},'_')) % if suffix
                opt.subIDs{s} = opt.subIDs{s}(1:(strfind(opt.subIDs{s},'_')-1));
            else
            end
            axxFiles = subfiles(fullfile(curFolder,'Exp_MATL_HCN_128_Avg','Axx*'),1);
            for c=1:length(axxFiles)
                axxStrct = matfile(axxFiles{c});
                if strcmp(opt.domain,'time'),
                    opt.dataIn{c,s} = (axxStrct.Wave)';
                    FreqFeatures = [];
                elseif strcmp(opt.domain,'frequency'),
                    opt.dataIn{c,s} = ((axxStrct.Cos)+((axxStrct.Sin)*1j)).';
                    FreqFeatures.dFHz = axxStrct.dFHz;
                    FreqFeatures.i1F1 = axxStrct.i1F1;
                    FreqFeatures.i1F2 = axxStrct.i1F2;
                else
                    error(['Input domain " ' opt.domain ' "is not defined']);
                end
                clear axxStrct;
            end
        end
    end
    
    nSubs = size(opt.dataIn,2);
    nConds = size(opt.dataIn,1);    
    subIDs = opt.subIDs;
    outData = opt.dataIn;

end