function  figH = CortexPlot(topoData,templateSubj,figTitles)
    
    % take care of arguments
    if nargin < 2
        error('not enough arguments');
    else
    end
    nRows = size(topoData,2);
    nCols = size(topoData,3);
    if nargin < 3 || ~exist('figTitles','var')
        figTitles = repmat({''},nRows,nCols);
    else
    end
    % prepare figure stuff
    fSize = 12;
    figWidth = [10,10*nRows]; % centimeters
    lWidth = 2;
    gcaOpts = {'tickdir','out','ticklength',[0 0],'zticklabel',[],'xticklabel',[],'yticklabel',[],'box','off','fontsize',fSize,'fontname','Arial','linewidth',lWidth};
    
    hemiTitle = {'lh','rh'};
    for c = 1:nCols;
        figure;
        f = 0;
        for r= 1:nRows
            hold on
            if isstruct(templateSubj)
                templateCtx = templateSubj;
            else
                anatDir = getpref('mrCurrent','AnatomyFolder');
                ctxFilename=fullfile(anatDir,templateSubj,'Standard','meshes','defaultCortex');
                load(ctxFilename);
                templateCtx.faces = (msh.data.triangles+1)';
                templateCtx.vertices(:,1) = msh.data.vertices(3,:)-128;
                templateCtx.vertices(:,2) = -msh.data.vertices(1,:)+128;
                templateCtx.vertices(:,3) = -msh.data.vertices(2,:)+128;
                templateCtx.vertices = templateCtx.vertices/1000;
                
            end
            % get left & right hemisphere vertex indices
            vertIdx{1} = 1:msh.nVertexLR(1);
            vertIdx{2} = (msh.nVertexLR(1)+1):sum(msh.nVertexLR);
            kFr = find(templateCtx.faces(:,1) > msh.nVertexLR(1),1,'first');
            faceIdx{1} = 1:(kFr-1);
            faceIdx{2} = kFr:length(templateCtx.faces);
            templateCtx.faces(faceIdx{2},:) = templateCtx.faces(faceIdx{2},:)-msh.nVertexLR(1);
            for h = 1:2
                f = f + 1;
                subplot(nRows,2,f);
                dCtx = patch('vertices',templateCtx.vertices(vertIdx{h},:),'faces',templateCtx.faces(faceIdx{h},:));
                set(dCtx,'linestyle','none')
                set(dCtx,'faceVertexCData',topoData(vertIdx{h},r,c))
                set(dCtx,'facecolor','interp')
                axis equal
                axis tight
                view(10,-10)
                title([figTitles{r,c},': ',hemiTitle{h}],'interpreter','none')
                set(gca,gcaOpts{:});
                if f == 1
                    cp = campos;
                    cRange = prctile(abs(topoData(:)),99);
                    if cRange > 0
                        cRange = [-cRange cRange];
                    else
                        cRange = [-5, 5];
                    end
                    colorbar('location','West');
                else
                    campos(cp);
                end
                caxis(cRange);
                colormap(jmaColors('coolhotcortex',1.5));
                hold off
            end
        end
        drawnow;
        set(gcf, 'units', 'centimeters');
        figPos = get(gcf,'pos');
        figPos(3) = figWidth(1);
        figPos(4) = figWidth(2);
        set(gcf,'pos',figPos);
    end
end
    
    

