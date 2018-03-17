function PlotEEG(ASDEEG,Freq,FF,Probs,savepath,masterList,signalFF)
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
    % FF: fundamental frequency indexes
    % Probs: the plotting params
    % savepath: the string input indicating the folder to save the plots
    % master list: a cell array containing the names of ROIs
    
% Written by ELham Barzegaran,
% Last modification: 3.7.2018

%%
% set parameters
FS=14;%font size
Fmax = numel(Freq);
EOI = 83; % electrode used in the plot
FOI = FF(1); % frequency bin used in the plot
load('Electrodeposition.mat'); tEpos =tEpos.xy;% electrode poritions used for plots

h=figure;
set(h,'units','centimeters')
set(h, 'position',[1 1 25 12]);

subplot(2,2,4),axis off;% Show simulated signal information
nrs = max(numel(masterList),3);
for i= 1:numel(masterList)
    if ~isempty(signalFF)
        text (.1,.9-((1/nrs)*(i)),['Source' num2str(i) ': f' num2str(i) ' = ' num2str(signalFF(i)) ' Hz,  ' strrep(masterList{i},'_','-')],'fontsize',FS-2);
    else
        text (.1,.9-((1/nrs)*(i)),['Source' num2str(i) ': ' strrep(masterList{i},'_','-')],'fontsize',FS-2);
    end
end
N = 1;
while(1)
    if N == 1, colorbarLimits = [-0 max(ASDEEG(FOI,:))];
    else colorbarLimits = [-0 max(ASDEEG(:))];
    end
    
    if exist('sp1','var'),delete(sp1);end % topography map plot
    sp1 = subplot(1,2,1);mrC.plotOnEgi(ASDEEG(FOI,:)',colorbarLimits,false,EOI,false,Probs); 
    title(['ASD topographic map (Frequency = ' num2str(Freq(FOI)) 'Hz)'],'fontsize',FS);set(gca,'tag',num2str(1));
    colorbar;
    
    if exist('sp2','var'),delete(sp2);end % spectrum plot
    sp2 = subplot(2,2,2); bar(Freq(1:Fmax), ASDEEG(1:Fmax,EOI),.15); 
    xlim([Freq(1) Freq(Fmax)]);xlabel('Frequency(Hz)','fontsize',FS);
    ylim([0 max(ASDEEG(1:Fmax,EOI))*1]);ylabel('ASD','fontsize',FS);set(gca,'tag',num2str(2));
    hold on; bar(Freq(FOI), ASDEEG(FOI,EOI),.3,'g'); 
    %set(sp2, 'Position',get(sp2, 'Position')+[0 .4 0 -.4] );
    title(['ASD at Electrode ' num2str(num2str(EOI))],'fontsize',FS);
    
    %% Reads keyboard or mouse click
    w = waitforbuttonpress;
    switch w 
    case 1 % keyboard 
      key = get(h,'currentcharacter'); 
      if key==27 % (Esc key) -> close the plot and return
          close;
          return
      elseif key==13 % (Enter key) -> save the current figure
          print(fullfile(savepath,['SimEEG_Electrode' num2str(EOI) '_Freq' num2str(Freq(FOI)) 'Hz.tif']),'-dtiff','-r300');% Later I can update this to contain the simulation parameters
      elseif strcmp(key,'n')||strcmp(key,'N') % if n or N is pressed -> change head plot normalization
          if N==1, N=0; else N=1;end
      end
          
    case 0 % mouse click 
      mousept = get(gca,'currentPoint');
      SPI = get(gca,'tag');
      x = mousept(1,1);
      y = mousept(1,2);
    end
    
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