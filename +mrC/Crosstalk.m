function [outMtx,ctMtx] = Crosstalk(mrCpath,varargin)
    % Description:	Generate Crosstalk matrix from mrCurrent folder
    %
    % Syntax:	[roiData,masterList] = mrC.Crosstalk(mrCPath,invPaths,varargin)
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
    %       roiType:    string specifying the roitype to use (['func']/'wang'/'all').
    %
    % Out:
    % 	roiData:    c x s cell matrix of output data, where each cell contains
    %               a 3-d matrix with time x ROIs x laterality.
    %
    %	masterList: a 1 x nROIs cell of strings, indicating ROI names

    % defaults
    opt	= ParseArgsOpt(varargin,...
        'inverse'		, [], ...
        'roiList'		, []	, ...
        'roiType'       ,'func', ...
        'drawFig'       , true ...
        );
    
    switch(opt.roiType)
        case{'func','functional'}
            opt.roiType = 'func';
        case{'wang','wangatlas'}
            opt.roiType = 'wangatlas';
        otherwise
            error('unknown ROI type: %s',opt.roiType);
    end
    
    if isempty(opt.roiList)
        if strcmp(opt.roiType,'func')
            opt.roiList = {'V1d','V1v','V2d','V2v','V3d','V3v','V4','VO1','LOC','MT','V3ab','IPS0'};
        else
            opt.roiList = {'V1d','V1v','V2d','V2v','V3d','V3v','hV4','VO1','LO1','LO2','TO1','TO2','V3A','V3B','IPS0'};
        end
    else
    end
    
    if isempty(strfind(opt.roiList{1},opt.roiType))
        % add proper prefix
        opt.roiList = cellfun(@(x) [opt.roiType,'_',x],opt.roiList,'uni',false);
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
        roiDir = fullfile(anatDir,subIDs{s},'Standard','meshes','ROIs');
        invPath = fullfile(mrCfolders{s},'Inverses',opt.inverse);
        invMatrix = mrC_readEMSEinvFile(invPath);
        if s==1
            masterList = opt.roiList;
            numROI = zeros(3,length(masterList));
        else
        end
        [seedData,roiSet] = mrC.SeedMtx(roiDir,opt.roiType,masterList,fwdMatrix);
        for sR=1:length(masterList) % seed ROI
            seedData{3,sR} = sum(cat(1,seedData{1:2,sR})); % sum the seed data
            for h = 1:3
                if ~isnan(seedData{h,sR})
                    curData = double(seedData{h,sR}*invMatrix);
                    for rR=1:length(masterList) % recipient ROI
                        if h > 2
                            roiSet{h,rR} = cat(1,roiSet{1:2,rR});          % simply concatenate the indexes
                        else
                        end
                        if sum(isnan(roiSet{h,rR}))==0
                            ctMtx(rR,sR,s,h) = nanmean(curData(:,roiSet{h,rR}),2);
                        else
                            ctMtx(rR,sR,s,h) = NaN;
                        end
                    end
                    numROI(h,sR) = numROI(h,sR)+1;
                else
                    ctMtx(:,sR,s,h) = NaN;
                end
            end
        end
    end
    
    titleOpts = {'LH','RH','BL'};
    for z=1:3
        readyMtx = -nansum(abs(ctMtx(:,:,:,z)),3);
        if z == 1 % anything missing across all subjects in one hemisphere, is missing in all hemispheres
            keepIdx = sum(readyMtx,1)~=0;
            masterList = masterList(keepIdx);
            numROI = numROI(:,keepIdx);
        else
        end
        outMtx(:,:,z) = readyMtx(keepIdx,keepIdx);
        for r=1:length(masterList)
            outMtx(:,r,z) = outMtx(:,r,z) / outMtx(r,r,z); % make each element a fraction of the diagonal'
        end
        if opt.drawFig
            fSize = 12;
            figure;
            imagesc(outMtx(:,:,z)); % resize to deal with interpolation problem
            colormap(jet); 
            hold on
            axis square
            axisLabels = cellfun(@(x) x((strfind(x,'_')+1:end)),masterList,'uni',false);
            set(gca,'xtick',1:length(masterList),'ytick',1:length(masterList),'xticklabel',axisLabels,'yticklabel',axisLabels,...
                'fontsize',fSize,'fontname','Arial');
            title([titleOpts{z},': ',opt.inverse(1:(strfind(opt.inverse,'.')-1))],...
                'fontsize',fSize,'fontname','Arial','interpreter','none');
            arrayfun(@(x) text(x,length(masterList)+1.25,x,sprintf('%d',numROI(z,x)),...
                'HorizontalAlignment','center','fontsize',fSize,'fontname','Arial'),1:length(masterList));
            xLabH = xlabel(sprintf('Seed ROI (%s)',opt.roiType),'fontsize',fSize,'fontname','Arial');
            set(xLabH,'Position',get(xLabH,'Position') + [0 .25 0]);
            ylabel(sprintf('Receiving ROI (%s)',opt.roiType),'fontsize',fSize,'fontname','Arial');
            colorbar;
            caxis([0,1]);
            drawnow;
            figPos = get(gcf,'pos');
            figPos(3:4) = figPos(3:4)*1.25;
            set(gcf,'pos',figPos);
            export_fig(['/Users/kohler/Desktop/ctMtx_',opt.roiType,titleOpts{z},'.pdf'],'-transparent',gcf)
            hold off
            close gcf;
        else
        end
    end
end