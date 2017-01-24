function [chunks roiList roiInfo] = ChunkFromMesh(roiDir,nTotalVert,blRoiOnly)
% function [chunker] = mrC.ChunkFromMesh(roiDir,nTotalVert)
% The chunker matrix maps the full(~128 x nTotalVert) forward/inverse matrix
% onto onto a chunked 128xnMeshRois
%
% Inputs:
% roiDir is the director that contains the mesh ROI files.
% nTotalVert is the size of the forward/inverse matrix
%
% Outputs:
% chunker is a matrix nTotalVert x nMeshRois that maps
%
% Example:
% [chunker] = pkChunkFromMesh('/raid/anatomy/ales/Standard/mesh/ROIs/',length(A))
%
% Achunk = A*chunker;
%
% WARNING: NO NORMALIZATION IS DONE
% You should normalize to whichever makes most sense to you, chunk area or
% chunk projecton power.

% $Log: createChunkerFromMeshRoi.m,v $
% Revision 1.6 2016/04/10 PJK
% Renamed function mrC.ChunkFromMesh, and made a few style changes
% 
% Revision 1.5  2009/11/02 17:46:00  ales
% Many bug fixes
%
% Revision 1.4  2008/06/12 19:41:05  ales
% Added wfr2tri.m
% this function converts an emse wfr cortex into a source space file readable
% by mne
%
% Revision 1.3  2008/05/27 16:52:08  ales
% *** empty log message ***
%
% Revision 1.2  2008/05/05 19:19:10  ales
% fixed bug with not reading intput directory
%
% Revision 1.1  2008/05/05 17:26:24  ales
% Added new createChunkerFromMeshROI().

if ~exist('blRoiOnly','var') || isempty(blRoiOnly)
    blRoiOnly = false;
else
end

dirList = subfiles(fullfile(roiDir,'/*.mat'),1);
nameList = subfiles(fullfile(roiDir,'/*.mat'));

if blRoiOnly
    % take out non-bilateral ROIs
    shortList = cellfun(@(x) x(1:end-6),nameList,'uni',false);
    [~,~,numROIs] = unique(shortList);
    uniIdx = arrayfun(@(x) numel(find(numROIs==x))>1,numROIs); 
    dirList = dirList(uniIdx);
    nameList = nameList(uniIdx);
else
end

nAreas = length(dirList);

%The chunker matrix maps the full A on 128x20k to 128xnAreas
%chunker = zeros(nTotalVert,nAreas);

roiIdx = 0;
if nAreas > 0
    for r = 1:nAreas
        curROI = load(dirList{r});
        roiIdx = roiIdx+1;
        curVertices = curROI.ROI.meshIndices(curROI.ROI.meshIndices>0);
        ctxList = sparse(zeros(nTotalVert,1));
        ctxList(curVertices) = 1;
        chunks(:,roiIdx) = ctxList;
        roiInfo(roiIdx) = curROI;
        roiList(roiIdx) = nameList(r);
    end
else
    chunks = [];
    roiInfo = struct;
    roiList = cell(1);
end
