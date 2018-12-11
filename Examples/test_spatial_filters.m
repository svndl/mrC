%% Add latest mrC
clear;clc
mrCFolder = fileparts(fileparts(mfilename('fullpath')));%'/Users/kohler/code/git';
addpath(genpath(mrCFolder));
addpath('../../../BrewerMap/')
%%
DestPath = '/export/data/eeg_simulation';
AnatomyPath = fullfile(DestPath,'anatomy');
ProjectPath = fullfile(DestPath,'FwdProject2');

% Pre-select ROIs
[RoiList,subIDs] = mrC.Simulate.GetRoiClass(ProjectPath,AnatomyPath);% 13 subjects with Wang atlab 
Wangs = cellfun(@(x) {x.getAtlasROIs('wang')},RoiList);
Wangnums = cellfun(@(x) x.ROINum,Wangs)>0;

% define noise properties
Noise.mu.pink=2;
Noise.mu.alpha=2;
Noise.mu.sensor=2;

% define locations of sources
%--------------------------Cond1: V2d_R -----------------------------
Rois1 = cellfun(@(x) x.searchROIs('V2d','wang','R'),RoiList,'UniformOutput',false);% % wang ROI
do_new_data_generation = false;
% generate or read from disk
if ~exist('data_for_spatial_filter_test.mat','file') | do_new_data_generation
    n_trials = 1000 ;
    Noise.lambda = 0 ; % noise only
    [outSignal, FundFreq, SF]= mrC.Simulate.ModelSeedSignal('signalType','SSVEP','signalFreq',[2],'signalHarmonic',{[2,0,1.5,0]},'signalPhase',{[.1,0,.2,0]});
    [EEGData_noise,EEGAxx_noise,EEGData_signal,EEGAxx_signal,~,masterList,subIDs,allSubjFwdMatrices,allSubjRois] = mrC.Simulate.SimulateProject(ProjectPath,'anatomyPath',AnatomyPath,'signalArray',outSignal,'signalFF',FundFreq,'signalsf',SF,'NoiseParams',Noise,'rois',Rois1,'Save',false,'cndNum',1,'nTrials',n_trials);
    save('data_for_spatial_filter_test.mat')
else
    load('data_for_spatial_filter_test.mat')
end
%%
% mix signal and nose according to SNR and  convert to Axx
opt.signalFF=FundFreq ;
opt.signalsf=SF ;
opt.cndNum = 1;

% note that this SNR is defined over the full spectrum, while the signal is
% narrowbanded
SNR = -22;
lambda = 10^(SNR/10) ;
EEGData = {};
EEGAxx = {} ;
for subj_idx = 1:length(EEGData_signal)
    EEGData{subj_idx} = sqrt(lambda/(1+lambda))*EEGData_signal{subj_idx} + sqrt(1/(1+lambda)) * EEGData_noise{subj_idx} ;
    EEGAxx{subj_idx} = mrC.Simulate.CreateAxx(EEGData{subj_idx},opt) ;
end


%%
% test spatial filters
subj_idx = 1 ;

fund_freq_idx = 1 ;            
numTrials_list = 2.^[1,2,3,4,5,6,7];     
nDraws = 20 ;
n_comps = 1 ;
thisFundFreq = FundFreq(fund_freq_idx) ;

rois = allSubjRois{subj_idx} ;
fwdMatrix = allSubjFwdMatrices{subj_idx} ;

source_pattern = zeros(size(fwdMatrix,1),length(rois.ROIList)) ;
for roi_idx = 1:length(rois.ROIList)
    % assuming uniform activation
    source_pattern(:,roi_idx) = sum(fwdMatrix(:,rois.ROIList(roi_idx).meshIndices ),2)  ;
end

decomp_methods = {'pca','ssd','csp','rca'} ;
considered_harms=[1,2] ;

for nTrial_idx = 1:length(numTrials_list)
    nUsedTrials = numTrials_list(nTrial_idx);
    for draw_idx = 1:nDraws
        fprintf('nUsedTrials = %i, draw_idx = %i \n',nUsedTrials, draw_idx) ;
        random_numbers = randperm(EEGAxx_noise{1}.nTrl) ;
        % todo: improve indexing to avoid identical trials in different
        % draws. requires simulation of enough trials
        % for starters: just take random trials
        trial_idxs = random_numbers(1:nUsedTrials);
        
        thisAxx = EEGAxx{subj_idx};
        thisAxx.nTrl = nUsedTrials;
        thisAxx.Amp  = thisAxx.Amp(:,:,trial_idxs);
        thisAxx.Cos  = thisAxx.Cos(:,:,trial_idxs);
        thisAxx.Sin  = thisAxx.Sin(:,:,trial_idxs);
        thisAxx.Wave = thisAxx.Wave(:,:,trial_idxs);
        thisTempMean = mean(mean(thisAxx.Wave,3),1) ;
        
        % make sure the no-stimulation condition does not see the same
        % noise component
        noise_trial_idxs = random_numbers(nUsedTrials+1:2*nUsedTrials);
        thisNoiseAxx = EEGAxx_noise{subj_idx};
        thisNoiseAxx.nTrl = nUsedTrials;
        thisNoiseAxx.Amp  = thisNoiseAxx.Amp(:,:,noise_trial_idxs);
        thisNoiseAxx.Cos  = thisNoiseAxx.Cos(:,:,noise_trial_idxs);
        thisNoiseAxx.Sin  = thisNoiseAxx.Sin(:,:,noise_trial_idxs);
        thisNoiseAxx.Wave = thisNoiseAxx.Wave(:,:,noise_trial_idxs);
        
        for decomp_method_idx = 1:length(decomp_methods)
            this_decomp_method = decomp_methods{decomp_method_idx};
            
            if strcmpi(this_decomp_method,'pca')
                [thisDecompAxx,thisW,thisA,thisD] = mrC.SpatialFilters.PCA(thisAxx,'freq_range',thisFundFreq*considered_harms);
            elseif strcmpi(this_decomp_method,'pca_cart')
                [thisDecompAxx,thisW,thisA,thisD] = mrC.SpatialFilters.PCA(thisAxx,'freq_range',thisFundFreq*considered_harms,'model_type','cartesian');
            elseif strcmpi(this_decomp_method,'fullfreqPca')
                [thisDecompAxx,thisW,thisA,thisD] = mrC.SpatialFilters.PCA(thisAxx);
            elseif strcmpi(this_decomp_method,'fullfreqPca')
                [thisDecompAxx,thisW,thisA,thisD] = mrC.SpatialFilters.PCA(thisAxx,'freq_range',[1:50]);
            elseif strcmpi(this_decomp_method,'tpca')
                [thisDecompAxx,thisW,thisA,thisD] = mrC.SpatialFilters.tPCA(thisAxx);
            elseif strcmpi(this_decomp_method,'ssd')
                [thisDecompAxx,thisW,thisA,thisD]= mrC.SpatialFilters.SSD(thisAxx,thisFundFreq*considered_harms,'do_whitening',true);
            elseif strcmpi(this_decomp_method,'rca')
                [thisDecompAxx,thisW,thisA,thisD] = mrC.SpatialFilters.RCA(thisAxx,'freq_range',thisFundFreq*considered_harms,'do_whitening',true);

            elseif strcmpi(this_decomp_method,'csp')
                [theseDecompAxxs,thisW,thisA,thisD] = mrC.SpatialFilters.CSP({thisAxx,thisNoiseAxx},'freq_range',thisFundFreq*considered_harms,'do_whitening',true);
                thisDecompAxx=theseDecompAxxs{1};
            end
            for i = 1:size(thisA,2)
                if source_pattern(:,1)'*thisA(:,i)<0
                    thisA(:,i) = thisA(:,i)*-1 ;
                end
            end
            Axx_compspace.(this_decomp_method){nTrial_idx}{draw_idx} = thisDecompAxx ;
            W.(this_decomp_method){nTrial_idx}{draw_idx} = thisW ;
            A.(this_decomp_method){nTrial_idx}{draw_idx} = thisA ;
            D.(this_decomp_method){nTrial_idx}{draw_idx} = thisD ;
            
            % metrics for first 2 components
            % calculate error angles
            freqs = [0:thisDecompAxx.nFr]*thisDecompAxx.dFHz;
            signal_freq_idxs = find(ismember(freqs,thisFundFreq*considered_harms));
            noise_freq_idxs = [signal_freq_idxs-1,signal_freq_idxs+1] ;
            
            for comp_idx =1:min(n_comps,size(thisA,2))
                err_angles.(this_decomp_method)(comp_idx,nTrial_idx,draw_idx) = 180/pi* acos(abs(source_pattern(:,1)'*thisA(:,comp_idx))/sqrt(sum(source_pattern(:,1).^2)*sum(thisA(:,comp_idx).^2))) ;
                if abs(imag(err_angles.(this_decomp_method)(comp_idx,nTrial_idx,draw_idx)))>10^-10
                    error('angle should not be complex')
                else
                    err_angles.(this_decomp_method)(comp_idx,nTrial_idx,draw_idx)=...
                        real(err_angles.(this_decomp_method)(comp_idx,nTrial_idx,draw_idx));
                end
                %calculate snrs assuming ssveps, mean over all trials
                snrs.(this_decomp_method)(comp_idx,nTrial_idx,draw_idx)=mean(2*mean(thisDecompAxx.Amp(signal_freq_idxs,comp_idx,:).^2)./mean(thisDecompAxx.Amp(noise_freq_idxs,comp_idx,:).^2));
                % calculate residuals as mse over samples and trials
                % TODO: needs some sort of normalization!!

                est_signal = squeeze(thisDecompAxx.Wave(:,comp_idx,:) );
                ref_signal = squeeze(repmat(EEGAxx_signal{subj_idx}.Wave(:,1,:),1,1,size(thisDecompAxx.Wave,3))) ;
                % normalize to equal power before calculating residual
                est_signal = est_signal/sqrt(mean(est_signal(:).^2));
                ref_signal = ref_signal/sqrt(mean(ref_signal(:).^2));
                
                residuals.(this_decomp_method)(comp_idx,nTrial_idx,draw_idx) =...
                    min(...
                    mean(mean((ref_signal-est_signal).^2)),...
                    mean(mean((ref_signal+est_signal).^2)));
            end
        end
    end
end
%%
% scalp plots
FigH = figure('DefaultAxesPosition', [0.1, 0.1, 0.8, 0.8]);
nCols = 1+n_comps*length(decomp_methods) ;
nRows = length(numTrials_list) ;

rowCounter = 1 ;

subplot(nRows,nCols,1+nCols*floor(nRows/2))
mrC.Simulate.PlotScalp(source_pattern,'OP' );

for nTrial_idx = 1:length(numTrials_list)
colCounter = 1 ;

for decomp_method_idx=1:length(decomp_methods)
    this_decomp_method = decomp_methods{decomp_method_idx};
    for comp_idx = 1:min(n_comps,    size(A.(this_decomp_method){nTrial_idx}{1},2 ))
        subplot_tight(nRows,nCols,1+(colCounter-1)*n_comps+comp_idx+(rowCounter-1)*nCols,[0.04,0.005])
        if rowCounter == 1
            this_title = sprintf('%s %1i, %i trials',this_decomp_method,  comp_idx,numTrials_list(nTrial_idx)) ;
        else
            this_title = sprintf('%i trials',numTrials_list(nTrial_idx));
            
        end
        mrC.Simulate.PlotScalp(A.(this_decomp_method){nTrial_idx}{1}(:,comp_idx),this_title );
    end
    colCounter = colCounter +1 ;
end
rowCounter = rowCounter+1 ;
end

%  plots angular error of topographies
figure
colors = brewermap(4,'Set2') ;
for comp_idx = 1:1
for decomp_method_idx=1:length(decomp_methods)
    this_decomp_method = decomp_methods{decomp_method_idx};
    if comp_idx==1
        plot(numTrials_list,median(err_angles.(this_decomp_method)(comp_idx,:,:),3),'-o','LineWidth',2,'MarkerSize',10,'color',colors(decomp_method_idx,:));
    else
        plot(numTrials_list,median(err_angles.(this_decomp_method)(comp_idx,:,:),3),':o','LineWidth',2,'MarkerSize',10,'color',colors(decomp_method_idx,:));
    end
    hold on
end
end
[~, hobj, ~, ~] = legend(decomp_methods);
hl = findobj(hobj,'type','line');
set(hl,'LineWidth',1.5);
ht = findobj(hobj,'type','text');
set(ht,'FontSize',12);
title(sprintf('err ang vs num trials, comp %i',comp_idx))
xlabel('number of trials')
ylabel('err ang.')

% plot snrs
figure
comp_idx =1;
for decomp_method_idx=1:length(decomp_methods)
    this_decomp_method = decomp_methods{decomp_method_idx};
    plot(numTrials_list,median(snrs.(this_decomp_method)(comp_idx,:,:),3),'-o','LineWidth',2,'MarkerSize',10);
    hold on
end
[~, hobj, ~, ~] = legend(decomp_methods);
hl = findobj(hobj,'type','line');
set(hl,'LineWidth',1.5);
ht = findobj(hobj,'type','text');
set(ht,'FontSize',12);
xlabel('number of trials')
ylabel('snr')

% plot residual
figure
for decomp_method_idx=1:length(decomp_methods)
    this_decomp_method = decomp_methods{decomp_method_idx};
    plot(numTrials_list,median(residuals.(this_decomp_method)(comp_idx,:,:),3),'-o','LineWidth',2,'MarkerSize',10);
    hold on
end
[~, hobj, ~, ~] = legend(decomp_methods);
hl = findobj(hobj,'type','line');
set(hl,'LineWidth',1.5);
ht = findobj(hobj,'type','text');
set(ht,'FontSize',12);
xlabel('number of trials')
ylabel('residuals')
