function h = PlotEEG(ASDEEG,Freq,savepath,subID, masterList,signalFF,SignalType,jcolors,Mode,EOI,FOI,A)
% This function provides a dual plot of electrode amplitude/phase spectrum and topographic
% map of amplitude/phase at a specific frequency (similar to powerDiva)

% This function is interactive: click on the head plot to select electrode
% and click on spectrum plot to select frequency bin

% PRESS ENTER: to save the current figure in the save folder path
% PRESS ESC: to exit the plot
% PRESS N to change the normalization of the head plot

% INPUT:
    % ASDEEG: nf x nelec matrix, amplitude spectrum of EEG, nf is number of
            % frequency bins and nelec is number of electrodes
    % Freq: nf x 1 vector, indicating the frequency bins
    % savepath: the string input indicating the folder to save the plots
    % master list: a cell array containing the names of ROIs
    % signalFF: fundamental frequency of the seed signals
    % SignalType: plot amplitude or phase, [Amplitude]/Phase
    % Mode: the mode of plotting, can be interactive or simple, in
            % interactive mode user can select electrodes and frequency bin
            % [Interact]/Simple
    % EOI: the electrode to plot the (initial) spectrum
    % FOI: the frequency to plot the (initial) spectrum topo map
    
    
% Written by ELham Barzegaran,3.7.2018
% Latest modification: 6.6.2018
% modified by sebastian bosse 8.8.2018

%% set parameters
if ~exist('SignalType','var')|| isempty(SignalType) % plot phase or amp
    if min(ASDEEG(:))>0
        SignalType = 'Amplitude';
    else
        SignalType = 'Phase';
    end
end

FS=14;%font size
Fmax = numel(Freq); % maximum frequency

if ~exist('EOI','var') || isempty(EOI)
    EOI = 83; % electrode used in the plot
end

load('Electrodeposition.mat'); tEpos =tEpos.xy;% electrode positions used for plots

if ~exist('FOI','var') || isempty(FOI)
    if isempty(signalFF), 
        FFI=2; 
    else 
        FFI = signalFF;
    end
else
    FFI = FOI;
end
[~,~,FFI] = intersect(FFI,round(Freq*1000)/1000);% find the index of fundamental frequencies in frequency bins and keep them for plotting purpose
FOI = FFI(1);

if ~exist('Mode','var') || isempty(Mode)
   Mode = 'Interact';
end

% allow for visualization of spatial filters
if ~exist('A','var') || isempty(Mode)
    space = 'chan';
else
    space = 'comp';
    EOI = 1 ; % start with the first component
    A = abs(A) ; % visualization in amplitude domain
end

%% Plot prepration
Probs{1} = {'facecolor','none','edgecolor','none','markersize',10,'marker','o','markerfacecolor','g' ,'MarkerEdgeColor','k','LineWidth',.5};% plotting parameters
if ~exist('jcolors','var') || isempty(jcolors)
    switch SignalType
        case 'Amplitude'
            conMap = jmaColors('hotcortex');
        case 'Phase'
            conMap = jmaColors('phasecolor');
            %conMap = hsv(64);
    end
else
    conMap = jmaColors(jcolors);
end

h=figure;
set(h,'units','centimeters')
set(h, 'Position',[1 1 35 16]);
set(h,'PaperPositionMode','manual')


subplot(2,2,2),axis off;% Show simulated signal information

nrs = max(numel(masterList),3);
text(.1,1,['' subID],'fontsize',FS+1,'fontweight','bold');
for i= 1:numel(masterList)
    if ~isempty(signalFF)
        text (.1,1-((.15)*(i)),['Source' num2str(i) ': f' num2str(i) ' = ' num2str(signalFF(i)) ' Hz,  ' strrep(masterList{i},'_','-')],'fontsize',FS-2);
    else
        text (.1,1-((.15)*(i)),['Source' num2str(i) ': ' strrep(masterList{i},'_','-')],'fontsize',FS-2);
    end
end
set(gca,'tag','info');

%% Loop over plots

N = 1;
I = 1;    
while(I)
    if strcmp(SignalType,'Amplitude')
        if strcmpi(space,'comp') 
            colorbarLimits = [-0 max(A(:,EOI)*ASDEEG(FOI,EOI)')];
        else
            if N == 1, colorbarLimits = [-0 max(ASDEEG(FOI,:))];
            else colorbarLimits = [-0 max(ASDEEG(:))];
            end
        end
    elseif strcmp(SignalType,'Phase')
        colorbarLimits = [min(ASDEEG(:)) max(ASDEEG(:))];
    end
    
    if exist('sp1','var'),delete(sp1);end % topography map plot
        sp1 = subplot(1,2,1);
    if strcmpi(Mode,'Interact') && ~strcmpi(space,'comp'),
        mrC.plotOnEgi(ASDEEG(FOI,:)',colorbarLimits,false,EOI,false,Probs); 
    else
        if strcmpi(space,'comp') 
            mrC.plotOnEgi(A(:,EOI)*ASDEEG(FOI,EOI)',colorbarLimits,false,[],false,Probs); 
        else
            mrC.plotOnEgi(ASDEEG(FOI,:)',colorbarLimits,false,[],false,Probs); 
        end
    end
    title(['Frequency = ' num2str(Freq(FOI)) 'Hz'],'fontsize',FS);
    set(sp1,'tag',num2str(1));
    colormap(conMap);
    colorbar;
    
    if exist('sp2','var'),delete(sp2);end % spectrum plot
        sp2 = subplot(2,2,4); 
    bar(Freq(1:Fmax), ASDEEG(1:Fmax,EOI),.15); 
    xlim([Freq(1) Freq(Fmax)]);
    xlabel('Frequency(Hz)','fontsize',FS-2);
    if strcmp(SignalType,'Amplitude')
        ylim([0 max(ASDEEG(1:Fmax,EOI))*1.1]);
        ylabel('ASD','fontsize',FS-2);
    elseif strcmp(SignalType,'Phase')
        ylim([min(ASDEEG(1:Fmax,EOI))*1.1 max(ASDEEG(1:Fmax,EOI))*1.1]);
        ylabel('Phase(degree)','fontsize',FS-2);
    end
    set(sp2,'tag',num2str(2));
    hold on; 
    bar(Freq(FOI), ASDEEG(FOI,EOI),.4,'FaceColor','g','EdgeColor','g'); 
    
    % draw buttons for channel selection
    if strcmpi(space,'comp')
        title(['Component ' num2str(num2str(EOI))],'fontsize',FS);
    else
        title(['Electrode ' num2str(num2str(EOI))],'fontsize',FS);
    end
    %% Reads keyboard or mouse click
    if strcmpi(Mode,'Interact')
        w = waitforbuttonpress;
        switch w 
        case 1 % keyboard 
          key = get(h,'currentcharacter'); 
          if key==27 % (Esc key) -> close the plot and return
              close;
              h=[];
              return
          elseif key==13 % (Enter key) -> save the current figure
              set(h, 'PaperPosition',[1 1 12 5]);
              print(fullfile(savepath,['SimEEG_Subject' subID 'Electrode' num2str(EOI) '_Freq' num2str(Freq(FOI)) 'Hz.tif']),'-dtiff','-r300');% Later I can update this to contain the simulation parameters
          elseif strcmp(key,'n')||strcmp(key,'N') % if n or N is pressed -> change head plot normalization
              if N==1, N=0; else N=1;end
          
          elseif key==28 && strcmpi(space,'comp')  % cursor left
              EOI = mod(EOI-1,size(A,2)+1) ;
              if EOI==0 % 0 is not valid
                  EOI = mod(EOI-1,size(A,2)+1) ;
              end
          elseif key==29 && strcmpi(space,'comp') % cursor right
              EOI = mod(EOI+1,size(A,2)+1) ;
              if EOI==0 % 0 is not valid
                  EOI = mod(EOI+1,size(A,2)+1) ;
              end
          elseif key==30 && strcmpi(space,'comp')  % cursor up
              EOI = mod(EOI+10,size(A,2)+1) ;
              if EOI==0 % 0 is not valid
                  EOI = mod(EOI+1,size(A,2)+1) ;
              end
          elseif key==31 && strcmpi(space,'comp')  % cursor down
              EOI = mod(EOI-10,size(A,2)+1) ;
              if EOI==0 % 0 is not valid
                  EOI = mod(EOI-1,size(A,2)+1) ;
              end
          elseif key=='a' 
              FOI = mod(FOI-1,Fmax+1) ;
              if FOI==0 % 0 is not valid
                  FOI = mod(FOI-1,Fmax+1) ;
              end
          elseif key=='d' 
              FOI = mod(FOI+1,Fmax+1) ;
              if FOI==0 % 0 is not valid
                  FOI = mod(FOI+1,Fmax+1) ;
              end
          elseif key=='w' 
              FOI = mod(FOI+10,Fmax+1) ;
              if FOI==0 % 0 is not valid
                  FOI = mod(FOI+1,Fmax+1) ;
              end
          elseif key=='s' 
              FOI = mod(FOI-10,Fmax+1) ;
              if FOI==0 % 0 is not valid
                  FOI = mod(FOI-1,Fmax+1) ;
              end
          end

        case 0 % mouse click 
             
            mousept = get(gca,'currentPoint');
            SPI = get(gca,'tag');
            x = mousept(1,1);
            y = mousept(1,2);
            % update location
            switch SPI
                case '1'
                    if ~strcmpi(space,'comp')
                        Epos2= repmat([x y],[128 1]);
                        dis = sqrt(sum((tEpos-Epos2).^2,2));
                        [~,EOI] = min(dis);
                    end
                case '2'
                    [~,FOI] = min(abs(repmat(x,[1 size(ASDEEG,1)])-Freq));
            end
        end
    else
        I = 0;
    end
end

%print(fullfile(savepath,['SimEEG_Subject' subID 'Electrode' num2str(EOI) '_Freq' num2str(Freq(FOI)) 'Hz_' SignalType  '.tif']),'-dtiff','-r300');% Later I can update this to contain the simulation parameters
end