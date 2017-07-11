function steadyStateWaveMovie(varargin)
    % add libraries
    if ~exist('codeFolder','var')
        codeFolder = '/Users/kohler/code';
        rcaCodePath = sprintf('%s/git/rcaBase',codeFolder);
        addpath(genpath(rcaCodePath));
        addpath(genpath(sprintf('%s/git/mrC',codeFolder)));
        addpath(genpath(sprintf('%s/git/schlegel/matlab_lib',codeFolder)));
    else
    end
    setenv('DYLD_LIBRARY_PATH','')
    
    % Description:	generate steady-state waveform movies
    % 
    % Syntax:	steadyStateWaveMovie(<options>)
    % <options>
    %   freq    - logical indicating whether to run the full ROI
    %                   analysis (true), or load prior data ([false])
    %    
    %   colors    - logical indicating whether to run the ring ROI
    %                   analysis (true), or load prior data ([false])
    %
    %   movieDur    - logical indicating whether to run the fovea ROI
    %                   analysis (true), or load prior data ([false])
    %
    %   numSamples    - logical indicating whether to run the process the ROI
    %                   analysis (true), or load prior data ([false])
    %
    %   outFormat    - logical indicating whether or not to plot 
    %                   single ROI data [false]
    %   text         - display time as text on graph ([true]/false)
    
    %% PARSE ARGS
    opt	= ParseArgs(varargin,...
            'freq', [5,6,1], ...
            'colors', [], ...
            'movieDur', 10, ...
            'numSamples', [], ...
            'outFormat', 'gif' ...
            );
    
    if isempty(opt.colors)
        cBrewer = load('colorBrewer');
        opt.colors = cBrewer.rgb10; % repeat disparity color
    else
    end
    
    if isempty(opt.numSamples)
        opt.numSamples = opt.movieDur*30; % 30 Hz
    else
    end
    
    if ~ismember(opt.outFormat,{'gif','avi'})
        error('unknown format %s',opt.outFormat);
    else
    end
        
    % compute the sine waves
    numFreq = length(opt.freq);
    amp = 1;
    deltaT = 1/opt.numSamples;
    T = 0:deltaT:1;
    T = T(1:opt.numSamples);
    sinFxn = zeros(opt.numSamples,numFreq);
    for f = 1:numFreq
        circFreq = 2*pi*opt.freq(f);
        sinFxn(:,f) = amp.*sin(circFreq.*T);
    end
    
    % draw it
    lWidth = 10;
    gcaOpts = {'tickdir','out','ticklength',[0.0,0.0],'box','off','linewidth',lWidth};
    outName = '/Users/kohler/Desktop/test';

    for f = 1:numFreq
        sinFig = figure;
        figPos = get(sinFig,'pos');
        figPos(4) = figPos(4)*1.5;
        figPos(3) = figPos(3)*1.5;
        set(sinFig,'pos',figPos);
        hold on
        for z = 1:opt.numSamples
            plot(T(1:z),sinFxn(1:z,f),'color','k','linewidth',lWidth);
            set(gca,gcaOpts{:},'xtick',[],'ytick',[], 'visible', 'off','Color',[1 1 1]);
            warning('off','all')
            xlim([-.05,1]);
            ylim([-1.05,1.05]);
            drawnow
            pause(.1);
            frame = getframe(sinFig);
            im = frame2im(frame); 
            A = rgb2ind(im,256);
            A = A(5:(end-5),5:(end-5)); % crop outer edges
            bgIdx = mode(A); 
            lineIdx = mode(A(A ~= bgIdx)); % assume that second most often value is line
            curA = uint8(zeros( size(A) ));
            curA(  A == lineIdx ) = f;
            movieFrames(:,:,f,z) = curA;
        end
        close(sinFig);
    end
        
    movieMap(1,:) = [1 1 1]; % make background white (will be transparent in gif) 
    movieMap(2:numFreq+1,:) = opt.colors(1:numFreq,:);
    movieFrames = squeeze(max(movieFrames,[],3));
    
    if strcmp(opt.outFormat,'gif')
        if exist([outName,'gif'],'file')
            delete([outName,'gif']);
        end
        for k = 1:opt.numSamples
            if k==1
                gifOpts = {'LoopCount',Inf};
            else
                gifOpts = {'WriteMode','append'};
            end
            imwrite(movieFrames(:,:,k),movieMap,[outName,'.gif'],'gif','DelayTime',opt.movieDur/opt.numSamples,gifOpts{:},'transparentColor',0);
        end
    else
        if exist([outName,'avi'],'file')
            delete([outName,'avi']);
        end
        vidObj = VideoWriter([outName,'.avi'],'Indexed AVI');
        vidObj.FrameRate = opt.numSamples/opt.movieDur; % frames per second
        vidObj.Colormap = movieMap;
        open(vidObj);
        for k = 1:size(movieFrames, 3)
           % Write each frame to the file.
           writeVideo(vidObj,movieFrames(:,:,k));
        end
        close(vidObj);
    end    
    warning('on','all')
end
