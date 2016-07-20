function [seedData,roiSet] = SeedMtx(roiDir,roiType,masterList,fwdMatrix)
    % Description:	Generate Crosstalk matrix from mrCurrent folder
    %
    % Syntax:	[roiData,masterList] = mrC.SeedMtx(mrCfolders,invPaths,varargin)
    % In:
    %   roiDir - string, path to ROI directory
    %
    %   roiType:    string specifying the roitype to use (['func']/'wang'/'all').
    %   
    %   masterList: a 1 x n cell of strings, indicating the ROIs to use
    %
    %   fwdMatrix: the subject's forward matrix
    %
    % Out:
    % 	seedData:    
    %
    %	roiSet: a 1 x nROIs cell of node indices
    
    [roiChunk, tempList] = mrC.ChunkFromMesh(roiDir,size(fwdMatrix,2),roiType);
    shortList = cellfun(@(x) x(1:end-6),tempList,'uni',false);
    seedData = repmat({NaN(1,128)},2,length(masterList));
    roiSet = repmat({NaN},2,length(masterList));
    if ~isempty(roiChunk)
        %% seed ROIs
        for r=1:size(roiChunk,2)
            rIdx = find(cellfun(@(x) strcmpi(x,shortList{r}),masterList));
            if isempty(rIdx) % if this subject does not have this ROI
                if ~isempty(strfind(shortList{r},'V4v'))
                    rIdx = find(cellfun(@(x) strcmp(x,'V4'),masterList));  % consider V4v equivalent to V4
                elseif ~isempty(strfind(shortList{r},'V3a'))
                    rIdx = find(cellfun(@(x) strcmp(x,'V3ab'),masterList)); % consider V3a equivalent to V3ab
                else
                    continue
                end
            else
            end
            if strfind(upper(tempList{r}),'-L')
                lIdx = 1;
            elseif strfind(upper(tempList{r}),'-R')
                lIdx = 2;
            else
                error('unable to recover hemisphere: %s',tempList{r});
            end
            sourceTemp = zeros(size(fwdMatrix,2),1);
            sourceTemp(find(roiChunk(:,r)==1))=1;
            roiSet(lIdx,rIdx) = {find(roiChunk(:,r)==1)};
            seedData(lIdx,rIdx) = {(fwdMatrix*sourceTemp)'}; % multiply by forward to get sensor space activation                
        end
    else
    end
end