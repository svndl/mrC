function [scaleAve,regAve] = PlusMinusAverage(inData,varargin)
    % Description:
    % 
    % Syntax:	[outData,transMtx] = mrC.SourceBrain(PlusMinusAverage,varargin)
    % In:
    %   inData - 
    %
    %   <options>:
    %       aveTime: vector of time indices to avearge over 
    %                 if set to false, no time averaging will be done
    %       scaleMode: which type of scaling to do (['std']/'rms'/'freq')
    
    % defaults    
    opt	= ParseArgs(varargin,...
            'aveTime', false, ...
            'scaleMode'		, 'std'...
            );
        
    numSubs = size(inData,2);
    numConds = size(inData,1);
    for s=1:numSubs
        noiseAve = [];
        for c=1:numConds
            curData = inData{c,s};
            if opt.aveTime
                regAve{c,s} = nanmean(mean(curData(opt.aveTime,:,:),1),3);
            else
                regAve{c,s} = nanmean(curData,3);
            end
            noiseAve = cat(3,noiseAve,curData);
        end
        if strcmp(opt.scaleMode,'freq') % frequency-based scaling
            M = size(noiseAve,1); % number of samples
            Fs = 420; % sample rate (in Hz)
            sInt = 1/Fs; % sample interval
            Y = fft(noiseAve)/M;
            % NyLimit = (1/sInt)/2;
            freq = (0:(M-1))*Fs/M; % frequency vector
            fIdx = find(freq>0,1):find(freq==30,1); % skip zero, go out to 30
            Fsub(s,:) = nanmean(mean(abs(Y(fIdx,:,:)),1),3);
        else
            numTrials = size(noiseAve,3);
            minusIdx = logical(repmat(1:2,1,numTrials/2)-1);
            noiseAve(:,:,minusIdx) = noiseAve(:,:,minusIdx)*-1;
            noiseAve = nanmean(noiseAve,3); % average over plus minus trials
            if strcmp(opt.scaleMode,'rms')
                scaleFactor = rms(noiseAve); % rms over time
            elseif strcmp(opt.scaleMode,'std')
                scaleFactor = std(noiseAve,0,1); % std over time
            else
                error('scalemode "%s" unknown',opt.scaleMode);
            end
            scaleFactor = repmat(scaleFactor,size(regAve{c,s},1),1);
            scaleAve(:,s) = cellfun(@(x) x./scaleFactor,regAve(:,s),'uni',false);  
        end
    end
    if strcmp(opt.scaleMode,'freq')
        for s=1:numSubs
            scaleFactor = repmat(mean(Fsub,1)./Fsub(s,:),size(regAve{c,s},1),1);
            scaleAve(:,s) = cellfun(@(x) x./scaleFactor,regAve(:,s),'uni',false);
        end
    else
    end
end

