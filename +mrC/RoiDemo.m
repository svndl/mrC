function [outMtx,ctMtx] = RoiDemo(mrCpath,varargin)
    % Description:	Stimulate ROI activity
    %
    % Syntax:	[roiData,masterList] = mrC.RoiDemo(mrCPath,invPaths,varargin)
    % In:
    %   mrCpath - string, path to mrCurrent folder.
    %              If this is a string,subIds and dataIn will be ignored ("mrCurrent mode").
    %              If this is false, subIds and dataIn will be used ("direct mode").
    %
    %
    %   note that in direct mode, dataIn and subIds are required!
    %
    %   <options>:
    %       inverse: a string specifying the inverse name to use
    %                default is using the latest inverse
    %
    %       roiList: a 1 x n cell of strings, with each cell giving the ROI name
    %
    %       roiType:    string specifying the roitype to use. 
    %                   'main' indicates that the main ROI folder
    %                   /Volumes/svndl/anatomy/SUBJ/standard/meshes/ROIs
    %                   is to be used. (['func']/'wang'/'glass','kgs','benson','main').
    %
    % Out:
    % 	roiData:    c x s cell matrix of output data, where each cell contains
    %               a 3-d matrix with time x ROIs x laterality.
    %
    %	masterList: a 1 x nROIs cell of strings, indicating ROI names

    % defaults
    opt	= ParseArgs(varargin,...
        'inverse'		, [], ...
        'roiList'		, []	, ...
        'roiType'       ,'func', ...
        'drawFig'       , true, ...
        'figFolder'     , '/Users/kohler/Desktop/',...
        'singleSubject' , 'nl-0014'...
        );
    
    if ~strcmp(opt.roiType,'main')
        switch(opt.roiType)
            case{'func','functional'}
                opt.roiType = 'func';
            case{'wang','wangatlas'}
                opt.roiType = 'wangatlas';
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
    
    anatDir = getpref('mrCurrent','AnatomyFolder');
    mrCfolders = subfolders(mrCpath,1);
    
    if isempty(opt.inverse)
        tempStrct = dir(fullfile(mrCfolders{1},'Inverses/*'));
        [~,tempIdx]=max(cat(3,tempStrct.datenum)); % sort by date
        opt.inverse = tempStrct(tempIdx).name;         % use latest
    else
        if iscell(opt.inverse) % unwrap if necessary
            opt.inverse = opt.inverse{1};
        else
        end
    end
    
    for s=1:length(mrCfolders)
        [~,subIDs{s}]=fileparts(mrCfolders{s});
        fwdPath = fullfile(mrCfolders{s},'_MNE_',[subIDs{s} '-fwd.fif']);
        fwdStrct = mne_read_forward_solution(fwdPath);
        srcStrct = readDefaultSourceSpace(subIDs{s});
        fwdMatrix = makeForwardMatrixFromMne(fwdStrct ,srcStrct);
        if strcmp(opt.roiType,'main')
            roiDir = fullfile(anatDir,subIDs{s},'Standard','meshes','ROIs');
            roiPaths = subfiles(roiDir);
        else
            roiDir = fullfile(anatDir,subIDs{s},'Standard','meshes',[opt.roiType,'_ROIs']);
            roiPaths = subfiles(roiDir);
        end
        invPath = fullfile(mrCfolders{s},'Inverses',opt.inverse);
        invMatrix = mrC_readEMSEinvFile(invPath);
        if s==1
            if isempty(opt.roiList)
                 opt.roiList = unique(cellfun(@(x) x(1:end-6),roiPaths,'uni',false));
            else
            end
            masterList = opt.roiList;
            numROI = zeros(3,length(masterList));
        else
        end
        seedData = mrC.SeedMtx(roiDir,masterList,fwdMatrix);
        sensorData(:,:,1,s) = cat(1,seedData{1,:});
        sensorData(:,:,3,s) = cat(1,seedData{2,:});
        sensorData(:,:,2,s) = sum(sensorData(:,:,[1,3],s),3); % make bilateral the center
        for r=1:size(seedData,2)
            readyData{r,s}(1,:) = sensorData(r,:,1,s);
            readyData{r,s}(2,:) = sensorData(r,:,2,s);
            readyData{r,s}(3,:) = sensorData(r,:,3,s);
        end
        readyInverse{s} = invPath;    
    end
    meanSensorData = nanmean(sensorData,4);
    subIdx = find(ismember(subIDs,opt.singleSubject));
   
    % source localized seed data
    sourceData = mrC.SourceBrain(false,readyInverse,'template','nl-0014','dataIn',readyData,'subIDs',subIDs);
    sourceDataSingle = mrC.SourceBrain(false,readyInverse(subIdx),'template',false,'dataIn',readyData(:,subIdx),'subIDs',subIDs(subIdx));
    
    tempData = arrayfun(@(x) nanmean(cat(3,sourceData{x,:}),3),1:size(sourceData,1),'uni',false); % average over subjects
    tempData = cat(3,tempData{:}); % concatenate over ROIs
    readyData = reshape(tempData,size(tempData,1),[]);
    tempData = cat(3,sourceDataSingle{:});  % concatenate over ROIs
    readySingleData = reshape(tempData,size(tempData,1),[]);
    roiLabels = repmat(masterList,1,3);
    hemiLabels = repmat({'-L','-BL','-R'},size(sourceData,1),1);
    roiLabels = cellfun(@(x,y) [x,y],roiLabels,hemiLabels,'uni',false)';
    roiLabels = roiLabels(:);
    
    mrC.WriteNiml('nl-0014',readyData,'outpath',fullfile(opt.figFolder,'roiDemoAverage.niml.dset'),'labels',roiLabels,'std_surf',false);
    mrC.WriteNiml('nl-0014',readySingleData,'outpath',fullfile(opt.figFolder,'roiDemoSingle.niml.dset'),'labels',roiLabels,'std_surf',false,'doSmooth',false);
    
    % draw figures
    colorData = meanSensorData(:);
    cRange = prctile(abs(colorData),95);
    cRange = round(cRange/1000)*1000;
    roiColorBar = [-cRange,cRange];
    hemiLabels = {'LH','BL','RH'};
    for r=1:size(sensorData,1);
        figure;
        for z=1:2
            for h = 1:3
                subplot(2,3,(z-1)*3+h);
                if z==1
                    plotH(r,h,z) = plotOnEgi(sensorData(r,:,h,subIdx),roiColorBar);
                    titleStr = sprintf('%s: %s',masterList{r},subIDs{subIdx});
                else
                    plotH(r,h,z) = plotOnEgi(meanSensorData(r,:,h),roiColorBar);
                    titleStr = sprintf('%s: average over %d subjects',masterList{r},size(subIDs,2));
                end
                if h==1
                    oldPos = get(get(plotH(r,h,z),'parent'),'position');
                    betterPos = oldPos;
                    %betterPos(3:4) = betterPos(3:4)*1.2;
                else
                end
                if z==1 && h==3
                    curPos = get(get(plotH(r,h,z),'parent'),'position');
                    colorbar('location','SouthOutside','fontsize',12,'fontname','Arial');
                    set(get(plotH(r,h,z),'parent'),'position',curPos);
                else
                end
                curPos = get(get(plotH(r,h,z),'parent'),'position');
                curPos(3:4) = betterPos(3:4);
                set(get(plotH(r,h,z),'parent'),'position',curPos)
                if h~=2
                    titleStr='';
                else
                end
                title({titleStr;hemiLabels{h}},'interpreter','none','fontsize',12,'fontname','Arial');
            end   
        end
        drawnow;
        figPos = get(gcf,'pos');
        figPos(3) = figPos(3)*1.5;
        figPos(4) = figPos(4)*1.5;
        set(gcf,'pos',figPos);
        figName =  sprintf('%s/%s_sensorDemo.pdf',opt.figFolder,masterList{r});
        export_fig(figName,'-pdf','-transparent',gcf);
    end
    close all;
    
    
end