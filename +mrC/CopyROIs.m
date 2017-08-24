function success = CopyROIs(subIDs,roiList,varargin)
    % Description:	Copy ROIs to the mrCurrent folder
    % 
    % Syntax:	mrC.CopyROIs(subList,roiList,varargin)
    % In:
    %   subIDs: 1 x s cell matrix, where each cell is a string
    %               specifying the subject ID
    
    %   roiList: 1 x s cell matrix, where each cell is a string
    %               specifying either an ROI or an ROI type ("folder")
    %    
    %
    %   <options>:
    %       clear: delete all existing ROIs before copying new ones (true/[false]) 
                        
    % Out:
    %   success: 1 x s cell matrix, where each cell contains a set of
    %           logicals indicating the ROIs that were successfully copied
    
    % defaults   
    
    % defaults    
    opt	= ParseArgs(varargin,...
            'clear', false ...
            );
    
    mrC.SetPrefs; % make sure preferences are set
    anatDir = getpref('mrCurrent','AnatomyFolder');
    if ischar(subIDs)
        subIDs = {subIDs}; % accept a string as well
    else
    end
    
    for s=1:length(subIDs)
        curAnat = fullfile(anatDir,subIDs{s},'Standard','meshes');
        outDir = fullfile(anatDir,subIDs{s},'Standard','meshes','ROIs');
        subDirList = subfolders(curAnat,1);
        subDirList = subDirList(~ismember(subDirList,outDir));
        rIdx = 0;
        for r=1:length(roiList)
            if ~exist(fullfile(curAnat,roiList{r}),'dir') % if not a directory
                for z = 1:length(subDirList)
                    tempPath = subfiles(fullfile(subDirList{z},[roiList{r},'*']),1);
                    if tempPath{1}
                        for t=1:length(tempPath)
                            rIdx = rIdx +1;
                            oldPath{rIdx} = tempPath{t};
                            [~,tempName,tempExt]=fileparts(tempPath{t});
                            newPath{rIdx} = fullfile(outDir,[tempName,tempExt]);
                        end
                    else
                    end
                end
            else
                tempPath = subfiles(fullfile(curAnat,roiList{r},'*'),1);
                if tempPath{1}
                    for t=1:length(tempPath)
                        rIdx = rIdx +1;
                        oldPath{rIdx} = tempPath{t};
                        [~,tempName,tempExt]=fileparts(tempPath{t});
                        newPath{rIdx} = fullfile(outDir,[tempName,tempExt]);
                    end
                else
                end          
            end
        end
        if opt.clear
            rmdir(outDir,'s')
            mkdir(outDir);
        else
        end
            
        success{s} = cellfun(@(x,y) copyfile(x,y), oldPath,newPath);
        clear oldPath;
        clear newPath;
    end
    
end

