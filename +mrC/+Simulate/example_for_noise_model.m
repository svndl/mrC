%% example script for noise model
% in order to get models for spatial decay of coherence run 
% spatial_decay_of_coherence.m at first
%% parameters for data generation
% general
f_sampling      = 100 ;            % sampling frequency [Hz]
n_samples       = 10*f_sampling ; % number of temporal samples
n_nodes         = 1300 ;

load('coordsForSB') % What is the unit of positions? Decay of spatial coherence assumes mm...
coords=coords.all;
if n_nodes < 1 % all nodes from coords
    n_nodes = size(coords,1) ;
else% reduce number of nodes for testing
    coords = coords(1:n_nodes,:) ; % reduce number of nodes for testing
end

% signal settings
% set up signal with different sources
t = [0:n_samples-1]/f_sampling ;

signal_nodes = {[1,2],... % source 1
                [5,6]};   % source 2
signal_freqs = [2,5] ;
signal_amplitudes = {   [2, 0 ,1],... % only odd harmonics for source 1
                        [0, 1, 0, 2]} ; % only even harmonics for source 2
                    
signal_phases     = {   [ 0.1,  0, 0.2],...
                        [ 0  ,0.3,   0, 0.4]} ;
                    
            
signal = zeros(n_samples,n_nodes);
for source_idx = 1:length(signal_nodes)
    if length(signal_amplitudes{source_idx})~= length(signal_phases{source_idx})
        error('definition of sources not consistent')
    end
    for h_idx = 1:length(signal_amplitudes{source_idx}) % loop over harmonics
        signal(:,signal_nodes{source_idx}) = signal(:,signal_nodes{source_idx}) +...
            signal_amplitudes{source_idx}(h_idx)*...
            cos(2*pi*h_idx*signal_freqs(source_idx)*t+signal_phases{source_idx}(h_idx))';
    end
end


%%
% noise settings
alpha_nodes = [1:200] ;     % for now: all nodes will show the same activity
mixing_type_pink_noise = 'coh' ; % coherent mixing of pink noise

mu = 1; % power distribution between alpha noise and pink noise ('noise-to-noise ratio')
spatial_normalization_type = 'all_nodes'; % ['active_nodes', 'all_nodes']

lambda = 1./n_samples ; % power distribution between signal and 'total noise' (SNR)
                        % division by n_sample to take into account the
                        % narrowband property of the ssvep
                        % this does NOT model the spatial concentration
                        % ofthe noise around f=0 and in the alpha band, but only the average power!

% preparing mixing matrices
if strcmp(mixing_type_pink_noise,'coh') % just in case we want to add other mixing mechanisms
    load('spatial_decay_models_coherence')
    
    % calcualting the distances and the coherence takes some time, better to
    % precalculate, write and read
    % mixing_matrices remain constant over all trials!
    spat_dists = squareform(pdist(coords)) ; %assuming euclidian distances
    band_names = fieldnames(best_model) ;
    mixing_data.band_freqs = band_freqs ;
    mixing_data.mixing_type = 'coh' ;
    
    for freq_band_idx = 1:length(band_freqs)
        this_spatial_decay_model = best_model.(band_names{freq_band_idx}) ;
        this_coh = this_spatial_decay_model.fun(this_spatial_decay_model.model_params,spat_dists);
        this_coh = min(max(this_coh,0),1) ;
        % see DOI: 10.1121/1.2987429
        %mixing_data.matrices{freq_band_idx} =  chol(this_coh) ;
        [V,D,W] = eig(this_coh);
        this_matrix = sqrt(D)*V';
        mixing_data.matrices{freq_band_idx} =  chol(this_coh) ; 
    end
end

noise = generate_noise(f_sampling, n_samples,n_nodes, mu, alpha_nodes, mixing_data,spatial_normalization_type); 

if strcmp(spatial_normalization_type,'active_nodes')
    n_active_nodes_signal = sum(sum(abs(signal))~=0) ;
    signal = n_active_nodes_signal * signal/norm(signal,'fro') ;
elseif strcmp(spatial_normalization_type,'all_nodes')
    signal = signal/norm(signal,'fro') ;
else
    error('%s is not implemented as spatial normalization method', spatial_normalization_type)
end


recorded_signal = sqrt(lambda/(lambda+1))*signal + sqrt(1/(lambda+1)) *noise;
recorded_signal = recorded_signal/norm(recorded_signal,'fro') ;% signal and noise are correlated randomly (not on average!). dirty hack: normalize sum
   

f = [-0.5:1/n_samples:0.5-1/n_samples]*f_sampling; % frequncy range
t = [0:n_samples-1]/f_sampling ;

figure()
subplot(3,2,1)
plot(t, noise)
subplot(3,2,2)
plot(f, abs(fftshift(fft(noise))))
xlim([0,max(f)])

subplot(3,2,3)
plot(t, signal)
subplot(3,2,4)
plot(f, abs(fftshift(fft(signal))))
xlim([0,max(f)])

subplot(3,2,5)
plot(t, recorded_signal)
subplot(3,2,6)
plot(f, abs(fftshift(fft(recorded_signal))))
xlim([0,max(f)])

    
norm(noise,'fro')