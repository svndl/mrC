function [plotH,roiH] = plotOnEgi(data,colorbarLimits,showColorbar,sensorROI,markerProps)
%plotOnEgi - Plots data on a standarized EGI net mesh
%function meshHandle = plotOnEgi(data)
%
%This function will plot data on the standardized EGI mesh with the
%arizona colormap.
%
%Data must be a 128 dimensional vector, but can have singleton dimensions,
%
%

if nargin<2
    colorbarLimits = [min(data(:)),max(data(:))];    
    newExtreme = max(abs(colorbarLimits));
    colorbarLimits = [-newExtreme,newExtreme];
end
if nargin<3
    showColorbar = false;
end
if nargin<4
    sensorROI = 0;
end
if nargin<5
    markerProps = {'facecolor','none','edgecolor','none','markersize',15,'marker','o','markerfacecolor','w','MarkerEdgeColor','k','LineWidth',.5};
else
end

data = squeeze(data);
datSz = size(data);

if datSz(1)<datSz(2)
    data = data';
end

if size(data,1) == 128
    tEpos = load('defaultFlatNet.mat');
    tEpos = [ tEpos.xy, zeros(128,1) ];
    
    tEGIfaces = mrC_EGInetFaces( false );
    
    nChan = 128;
elseif size(data,1) == 256
    
    tEpos = load('defaultFlatNet256.mat');
    tEpos = [ tEpos.xy, zeros(256,1) ];
    
    tEGIfaces = mrC_EGInetFaces256( false );
    nChan = 256;
elseif size(data,1) == 32
    tEpos = load('defaultFlatNet32.mat');
    tEpos = [ tEpos.xy, zeros(32,1) ];
    
    tEGIfaces = mrC_EGInetFaces( false );
    
    nChan = 32;
    
else
    error('Only good for 3 montages: Must input a 32, 128 or 256 vector')
end


patchList = findobj(gca,'type','patch');
netList   = findobj(patchList,'UserData','plotOnEgi');


if isempty(netList),    
    plotH = patch( 'Vertices', [ tEpos(1:nChan,1:2), zeros(nChan,1) ], ...
        'Faces', tEGIfaces,'EdgeColor', [ 0.5 0.5 0.5 ], ...
        'FaceColor', 'interp');
    axis equal;
    axis off;
else
    plotH = netList;
end

set(plotH,'facevertexCdata',data,'linewidth',0.5,'markersize',4,'marker','.');
set(plotH,'userdata','plotOnEgi');

if sensorROI ~= 0
    vertexLoc = get(plotH,'Vertices'); % vertex locations
    roiLoc = vertexLoc(sensorROI,:);
    roiH = patch(roiLoc(:,1),roiLoc(:,2),roiLoc(:,3),'o');
    set(roiH,markerProps{:});
    roiX = get(roiH,'XData');
    roiY = get(roiH,'YData');
    roiZ = get(roiH,'ZData');
    arrayfun(@(x) ...
        text(roiX(x),roiY(x),roiZ(x), num2str(x),'fontsize',8,'fontname','Arial','horizontalAlignment','center')...
        ,1:128,'uni',false);
end


colormap(jmaColors('coolhotcortex'));
%colormap coolhot
%colormap gray
if showColorbar
    colorH = colorbar;
    varargout{2} = colorH;
end
if ~isempty(colorbarLimits)
    caxis(colorbarLimits);
end
