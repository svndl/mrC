function [] = changeMeshColors(colorMap,range,figPosition)
%changeTopoColormap - changes all patch objects to a specified colormap
%
%function [] = changeMeshColors(colorMap,range,figPosition)
patchList = findobj('type','patch');

%  cmap = jmaColors('Arizona');


for patchHandle = patchList';
    

    thisFig = ancestor(patchHandle,'figure');
    
    setupFig = get(gcf,'WindowButtonDownFcn');
    
    if isa(setupFig,'function_handle')
        setupFig(thisFig);
    end
    
    thisAx =  ancestor(patchHandle,'axes');
    set(thisFig,'colormap',colorMap)
    
    if ischar(range)
        thisCdata = get(patchHandle,'faceVertexCData');
        thisRange = [-max(abs(thisCdata)) max(abs(thisCdata))];
    else
        thisRange = range;
    end
    
    
    if ~exist('figPosition','var') || isempty(figPosition)
       
    else
        set(thisFig,'position',figPosition);
    end
    
    set(thisAx,'CLim',thisRange)
    set(thisAx,'visible','off')
    set(patchHandle,'LineWidth',2)
    set(patchHandle,'marker','.')
    set(patchHandle,'markersize',25)
    cbarH = colorbar('peer',thisAx);
    set(cbarH,'fontname','helvetica')
    set(cbarH,'fontsize',18)
    
    
    
    
    
    
    axTitle = get(get(thisAx,'title'),'string');
    yLabel = get(get(thisAx,'ylabel'),'string');
    

    if strcmp(get(thisFig,'tag'),'PPFig_TopoWave')
        userDat = get(thisFig,'UserData');
        thisCond = userDat.gChartFs.Cnds.Sel;
        thisCond = userDat.gChartFs.Cnds.Items{thisCond};
        
        
        thisSubj = userDat.gChartFs.Sbjs.Sel;
        if length(thisSubj) >1
            thisSubj = 'All';
        else        
        thisSubj = userDat.gChartFs.Sbjs.Items{thisSubj};
        end
        
        filename = ['Topomap_Cnd_' thisCond '_Subj_' thisSubj '.eps'];
    else
    
    filename = ['Figure_' num2str(thisFig) '_' yLabel '_' axTitle '.eps'];
    end
    set(thisFig,'filename',filename);
    
        
end
