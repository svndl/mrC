function out = ExportAnalysis(matFile,filterName,subPrefix,condIdx,doPlot)
    if nargin<5
        doPlot = true;
    else
    end
    
    if nargin<4
        condIdx = [];
    else
    end
   
    if nargin<3
        subPrefix{1} = 'all';
    else
    end
    
    if nargin<2
        filterName = 'none';
    else
    end
    
    input = load(matFile);
    
    %% CHECK THE DATA
    
    reqFields = {'Y','Ydim','Yfilter'};
    fieldExist = isfield(input,reqFields);
    
    if any(~fieldExist)
        error('field %s and possibly others are missing from the data',reqFields{find(~fieldExist,1,'first')});
    else
    end
    
    if ~strcmp(input.Yfilter,filterName)
        error('filter "%s" was requested, but input data is filtered with "%s"',filterName,input.Yfilter);
    else
    end
    
    %% ANALYZE
    if strcmp(subPrefix{1},'all')
        subIdx = 1:size(input.Y,3);
    else
        tempIdx = [];
        for z=1:length(subPrefix)
            tempIdx = cat(1,tempIdx,cell2mat(cellfun(@(x) ~isempty(strfind(x,subPrefix{z})),input.Ydim{3},'uni',false)));
        end
        subIdx = sum(tempIdx,1) > 0;
    end
    if isempty(condIdx)
        condIdx = 1:size(input.Y,4);
    else
    end    
    
    if ndims(input.Y) == 4 
        disp('sensor mode');
        out.timeVals = input.Ydim{1};
        out.Ave = squeeze(nanmean(input.Y(:,:,subIdx,condIdx),3));
        out.numSubs = length(find(subIdx));
        out.Err = squeeze(nanstd(input.Y(:,:,subIdx,condIdx),0,3))./sqrt(out.numSubs);
    elseif ndims(input.Y) == 7
        error('source mode functionality not available yet');
    else
        error('input data have incorrect number of dimensions');
    end
    
    if doPlot 
        figure;
        plotH = plot(out.timeVals,squeeze(out.Ave(:,75,:)));
        for c=1:length(condIdx)
            ErrorBars(out.timeVals,squeeze(out.Ave(:,75,c))',squeeze(out.Err(:,75,c))','color',get(plotH(c),'color'));
        end
        xlim([0,round(input.Ydim{1}(end))]);
    else
    end
    
    
end

