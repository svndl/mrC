function PlotEEG(ASDEEG,Freq,savepath,subID, masterList,signalFF)
% This function provides a dual plot of electrode spectrum and topographic
% map of amplitude at a specific frequency (similar to powerDiva)

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
    
% Written by ELham Barzegaran,
% Last modification: 3.7.2018

%% set parameters

FS=14;%font size
Fmax = numel(Freq); % maximum frequency
EOI = 83; % electrode used in the plot
load('Electrodeposition.mat'); tEpos =tEpos.xy;% electrode poritions used for plots

if isempty(signalFF), 
    FFI=2; 
else 
    FFI = signalFF;
end

[~,~,FFI] = intersect(FFI,round(Freq*1000)/1000);% find the index of fundamental frequencies in frequency bins and keep them for plotting purpose
FOI = FFI(1);

%% Plot prepration
Probs{1} = {'facecolor','none','edgecolor','none','markersize',10,'marker','o','markerfacecolor','g' ,'MarkerEdgeColor','k','LineWidth',.5};% plotting parameters
conMap = jmaColors('hotcortex');

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
while(1)
    if N == 1, colorbarLimits = [-0 max(ASDEEG(FOI,:))];
    else colorbarLimits = [-0 max(ASDEEG(:))];
    end
    
    if exist('sp1','var'),delete(sp1);end % topography map plot
    sp1 = subplot(1,2,1);
    mrC.plotOnEgi(ASDEEG(FOI,:)',colorbarLimits,false,EOI,false,Probs); 
    title(['Frequency = ' num2str(Freq(FOI)) 'Hz'],'fontsize',FS);
    set(sp1,'tag',num2str(1));
    colormap(conMap);
    colorbar;
    
    if exist('sp2','var'),delete(sp2);end % spectrum plot
    sp2 = subplot(2,2,4); 
    bar(Freq(1:Fmax), ASDEEG(1:Fmax,EOI),.15); 
    xlim([Freq(1) Freq(Fmax)]);
    xlabel('Frequency(Hz)','fontsize',FS-2);
    ylim([0 max(ASDEEG(1:Fmax,EOI))*1.1]);
    ylabel('ASD','fontsize',FS-2);
    set(sp2,'tag',num2str(2));
    hold on; 
    bar(Freq(FOI), ASDEEG(FOI,EOI),.4,'FaceColor','g','EdgeColor','g'); 
    title(['Electrode ' num2str(num2str(EOI))],'fontsize',FS);
    
    %% Reads keyboard or mouse click
    w = waitforbuttonpress;
    switch w 
    case 1 % keyboard 
      key = get(h,'currentcharacter'); 
      if key==27 % (Esc key) -> close the plot and return
          close;
          return
      elseif key==13 % (Enter key) -> save the current figure
          set(h, 'PaperPosition',[1 1 12 5]);
          print(fullfile(savepath,['SimEEG_Subject' subID 'Electrode' num2str(EOI) '_Freq' num2str(Freq(FOI)) 'Hz.tif']),'-dtiff','-r300');% Later I can update this to contain the simulation parameters
      elseif strcmp(key,'n')||strcmp(key,'N') % if n or N is pressed -> change head plot normalization
          if N==1, N=0; else N=1;end
      end
          
    case 0 % mouse click 
      mousept = get(gca,'currentPoint');
      SPI = get(gca,'tag');
      x = mousept(1,1);
      y = mousept(1,2);
      % update location
      switch SPI
        case '1'
            Epos2= repmat([x y],[128 1]);
            dis = sqrt(sum((tEpos-Epos2).^2,2));
            [~,EOI] = min(dis);

        case '2'
            [~,FOI] = min(abs(repmat(x,[1 size(ASDEEG,1)])-Freq));
      end
    end
    
    

end
end