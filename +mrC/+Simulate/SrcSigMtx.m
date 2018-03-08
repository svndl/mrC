function [EEGData,sourceData,roiSet] = SrcSigMtx(roiDir,masterList,fwdMatrix,signalArray,noise,lambda,spatial_normalization_type)% ROIsig %NoiseParams
    % Description:	Generate Seed Signal within specified ROIs
    %
    % Syntax:	
    
    % INPUT:
    %   roiDir - string, path to ROI directory
    %   
    %   masterList: a 1 x n cell of strings, indicating the ROIs to use
    %
    %   ROIsig: T x n array of doubles, indicating source signal %%%% TO BE ADDED
    %
    %   NoiseParams: Parameters fo rgenerating noise, should be a structure %%%% TO BE ADDED
    %
    %   fwdMatrix: ne x nsrc matrix: The subject's forward matrix
    %   
    %   signalArray: ns x n matrix: Indicating the signals for the ROIs
    %   
    %   noise: ns x nsrc matrix: Indicating the noises signal in source space
    %   
    %   lambda: Parameter for detremination of SNR: How to add noise and signal
    %   
    %   spatial_normalization: how to nomalize the source signals...
    %
    % OUTPUT:
    % 	EEGData: ns x ne matrix: simulated EEG signal
    %   
    %   sourceData: ns x nsrc Matrix: simulated signal in source space
    %
    %	roiSet: a 1 x nROIs cell of node indices
    
    
  % Elham Barzegaran 2.27.2018
    
%%
[roiChunk, tempList] = mrC.ChunkFromMesh(roiDir,size(fwdMatrix,2));
shortList = cellfun(@(x) x(1:end-4),tempList,'uni',false);
roiSet = repmat({NaN},2,length(masterList));
if ~isempty(roiChunk)
    %% seed ROIs
    % Note: I consider here that the ROI labels in shortList are unique (L or R are considered separetly)
    [~,RoiIdx] = intersect(lower(shortList),lower(masterList));% find the ROIs, make both in lower case to avoid case sensitivity

    % V4v to V4: LATER CHANGE THIS PART
    %   indv4L = find(cellfun(@(x) ~isempty(x),strfind(lower(shortList),'v4-r')));indv4S = find(cellfun(@(x) ~isempty(x),strfind(lower(materList),'v4-r')));
    % V3a to V3ab

    if numel(RoiIdx)~= size(signalArray,2)
        error('Number of ROI is not equal to number of source signals');
    else
        % place source array in source space
        sourceTemp = zeros(size(noise));
        for s = 1: size(signalArray,2)% place the signal for each source
            sourceTemp(:,find(roiChunk(:,RoiIdx(s)))) = sourceTemp(:,find(roiChunk(:,RoiIdx(s)))) + repmat (signalArray(:,s),[1 numel(find(roiChunk(:,RoiIdx(s))))]);
        end       
        
        % Normalize the source signal
        if strcmp(spatial_normalization_type,'active_nodes')
        n_active_nodes_signal = sum(sum(abs(sourceTemp))~=0) ;
            sourceTemp = n_active_nodes_signal * sourceTemp/norm(sourceTemp,'fro') ;
        elseif strcmp(spatial_normalization_type,'all_nodes')
            sourceTemp = sourceTemp/norm(sourceTemp,'fro') ;
        else
            error('%s is not implemented as spatial normalization method', spatial_normalization_type)
        end
        
        % Adds noise to source signal
        sourceData = sqrt(lambda/(lambda+1))*sourceTemp + sqrt(1/(lambda+1)) *noise;
        sourceData = sourceData/norm(sourceData,'fro') ;% signal and noise are correlated randomly (not on average!). dirty hack: normalize sum
        
        % Generate EEG data by multiplying by forward matrix
        EEGData = sourceData*fwdMatrix';
        
        % there should be another step: add measurement noise to EEG
    end
else
end

end