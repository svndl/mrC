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
    %   freq    - 1 x n array of doubles indicating the frequencies to plot
    %    
    %   colors    -  n x 3 array of doubles indicating the colors to use
    % 
    %   slowdown    - scalar indicating how much to slow down the movie
    %                   t means t x slower [10]
    %
    %   sampleRate    - scalar indicating temporal sampling rate of movie [10 Hz]
    %
    %   outFormat    - string indicating whether to output gif (['gif']) or
    %                  avi movie ('avi')
    %
    %   filename    - string indicating the output path and filename of the
    %                saved file
    
    %% PARSE ARGS
    opt	= ParseArgs(varargin,...
            'freq', [5,6,1], ...
            'colors', [], ...
            'slowdown', 10, ...
            'sampleRate', 10, ...
            'outFormat', 'gif', ...
            'filename',  '~/Desktop/test' ...
            );
    
    if isempty(opt.colors)
        cBrewer = load('colorBrewer');
        opt.colors = cBrewer.rgb10; % repeat disparity color
    else
    end
    
    % movie duration in seconds, 
    % one cycle of smallest frequency multiplied by the slowdown factor
    movieDur = 1/min(opt.freq); 
    
    % total number of samples
    numSamples = movieDur * opt.slowdown * opt.sampleRate;  
    
    if ~ismember(opt.outFormat,{'gif','avi'})
        error('unknown format %s',opt.outFormat);
    else
    end
    
    % get rid of suffix, if user added it
    if strcmp(opt.filename(end-3:end),['.',opt.outFormat])
        opt.filename = opt.filename(1:end-4);
    else
    end
    
    % compute the sine waves
    numFreq = length(opt.freq);
    amp = 1;
    deltaT = movieDur/numSamples;
    T = 0:deltaT:movieDur;
    T = T(1:numSamples);
    sinFxn = zeros(numSamples,numFreq);
    for f = 1:numFreq
        circFreq = 2*pi*opt.freq(f);
        sinFxn(:,f) = amp.*sin(circFreq.*T);
    end
    
    % draw it
    lWidth = 10;
    gcaOpts = {'tickdir','out','ticklength',[0.0,0.0],'box','off','linewidth',lWidth};

    for f = 1:numFreq
        sinFig = figure;
        figPos = get(sinFig,'pos');
        figPos(4) = figPos(4)*1.5;
        figPos(3) = figPos(3)*1.5;
        set(sinFig,'pos',figPos);
        hold on
        for z = 1:numSamples
            plotH = plot(T(1:z),sinFxn(1:z,f),'color','k','linewidth',lWidth);
            set(gca,gcaOpts{:},'xtick',[],'ytick',[], 'visible', 'off','Color',[1 1 1]);
            warning('off','all')
            xlim([-.05,movieDur+.05]);
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
            delete(plotH);
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
        for k = 1:numSamples
            if k==1
                gifOpts = {'LoopCount',Inf};
            else
                gifOpts = {'WriteMode','append'};
            end
            imwrite(movieFrames(:,:,k),movieMap,[outName,'.gif'],'gif','DelayTime',1/opt.sampleRate,gifOpts{:},'transparentColor',0);
        end
    else
        if exist([outName,'avi'],'file')
            delete([outName,'avi']);
        end
        vidObj = VideoWriter([outName,'.avi'],'Indexed AVI');
        vidObj.FrameRate = opt.sampleRate; % frames per second
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
