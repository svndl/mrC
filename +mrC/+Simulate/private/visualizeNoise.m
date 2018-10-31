function Fhander = visualizeNoise(subID,noise,spat_dists,anatDir,SR,FigPath)
    % This function is just to visuaize the noise 
    FS = 22;
    %% Surface plot of noise at a specific frequency
    Fhandler = figure;
    S1 = subplot(1,2,1);
    n = SR*2 ;
    fpnoise = fft(noise,n);
    freq = SR*(0:(n))/n;
    NoiseSig = abs(fpnoise(freq==8,:));
    mrC.Simulate.VisualizeSourceData(subID,NoiseSig,anatDir,jmaColors('hotcortex'),'ventral');
    caxis([max(NoiseSig)*-.0 max(NoiseSig)*.70]);
    view([50 20]);
    set(S1,'position',get(S1,'position')+[-0.1 -.1 .2 .15]);

    % Plot signal and ferquency 
    subplot(2,2,2), plot(noise(1:101,1:300));
    set(gca,'fontsize',FS-2,'xtick',1:100:101,'xticklabel',0:1);
    xlabel('Time (s)','fontsize',FS);
    xlim([1 101])
    
    subplot(2,2,4), plot(freq(freq<30),abs(fpnoise(freq<30,1:300)));
     set(gca,'fontsize',FS-2)
    xlabel('Frequency (Hz)','fontsize',FS);
    Sig = abs(fpnoise(freq<30,1:300));
    ylim([0 max(Sig(:))*.8])
    xlim([0 30])
    %%
    set(Fhandler,'PaperPosition',[1 1 10 6]);
    print(fullfile(FigPath,['NoiseSignal_' subID '.tif']),'-r400','-dtiff');
    %% Plot the spatial coherence decay using one source point (ROI) (Similar to figrue 4 in kellis et al., 2016)
%     [MSCOH, f]= mscohere(noise(:,ROI),noise(:,1:1000),100,[],[],100);
%     dists = spat_dists(ROI,1:1000);
%     [dists2,sortind] = sort(dists);
%     MSCOHS = MSCOH(:,sortind);
%     imagesc(MSCOHS);
%     MSCOHS_lpf =conv2(MSCOHS,ones(6,4));
%     figure,surf(MSCOHS_lpf(2:end,1:50));
%     set(gca,'xticklabel',{},'yticklabel',{},'zticklabel',{});
%     print(fullfile(SavePath,'Coherence_Spatial_Decay.tif'),'-dtiff','-r300'); close all;


end