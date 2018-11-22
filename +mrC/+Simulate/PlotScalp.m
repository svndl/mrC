function h = PlotScalp(pattern,title_text)
    % simplifed function to just plot scalp pattern
    if ~exist('title_text','var')
        title_text = [] ;
    end
    
    load(fullfile('Electrodeposition.mat')); tEpos =tEpos.xy;% electrode positions used for plots

    h=figure;
    set(h,'units','centimeters')
    set(h, 'Position',[1 1 35 16]);
    set(h,'PaperPositionMode','manual')

    colorbarLimits = [min(pattern),max(pattern)];
    conMap = jmaColors('coolhotcortex');
    Probs{1} = {'facecolor','none','edgecolor','none','markersize',10,'marker','o','markerfacecolor','g' ,'MarkerEdgeColor','k','LineWidth',.5};% plotting parameters

    mrC.plotOnEgi(pattern,colorbarLimits,false,[],false,Probs); 

    colormap(conMap);
    colorbar;
    if ~isempty(title_text)
        title(title_text)
    end