function [noise, pink_noise, pink_noise_uncoh, alpha_noise] = GenerateNoise(f_sampling, n_samples, n_nodes, mu, alpha_nodes, noise_mixing_data, spatial_normalization_type)
% Syntax: [noise, pink_noise, pink_noise_uncoh, alpha_noise] = GenerateNoise(f_sampling, n_samples, n_nodes, mu, alpha_nodes, noise_mixing_data, spatial_normalization_type)
% Desciption: GENERATE_NOISE Returns noise of unit variance as a combination of alpha
%               activity (bandpass filtered white noise) and spatially coherent pink
%               noise (spectrally shaped white noise)
% INPUT:
    % f_sampling:                   sampling frequency
    % n_samples:                    number of temporal samples to be generated
    % n_nodes:                      number of nodes/vertices to be generated
    % mu:                           power of pink noise/power of alpha activity ('noise-to-noise' ratio)
    % alpha_nodes:                  indices of nodes/vertices carrying alpha activity
    % noise_mixing_data:            data necessary to impose a statistical spatial
    %                               relation on the poink noise
    % spatial_normalization_type:   spatial reference to normalize the
    %                               different noises to
    %                               'all_nodes': normalize to total number of nodes
    %                               'active_nodes': normalize only to nodes where a specific noise has any activity
% OUTPUT:
    % noise: returns a matrix of size [n_samples,n_nodes]
    % pink_noise
    % ..

% Author: Sebastian Bosse
% Latest Modification: EB, 07/17/2018

%% ---------------------------- generate alpha noise------------------------
    %  
    alpha_noise = zeros(n_samples,n_nodes);
    alpha_noise(:,alpha_nodes)  = repmat(GetAlphaActivity(n_samples,f_sampling,[8,12]),[1,length(alpha_nodes )]); 
    
    if strcmp(spatial_normalization_type,'active_nodes')
        n_active_nodes_alpha = size(alpha_noise,2);%sum(sum(abs(alpha_noise))~=0) ;
        alpha_noise = n_active_nodes_alpha*alpha_noise/norm(alpha_noise,'fro') ;
    elseif strcmp(spatial_normalization_type,'all_nodes')
        alpha_noise = alpha_noise/norm(alpha_noise,'fro') ;
    else
        error('%s is not implemented as spatial normalization method', spatial_normalization_type)
    end
    
    
    
%% -----------------------------generate pink noise------------------------
    pink_noise = GetPinkNoise(n_samples, n_nodes );pink_noise_uncoh = pink_noise;

    % impose coherence on pink noise
    if strcmp(noise_mixing_data.mixing_type,'coh') % just in case we want to add other mixing mechanisms
        % force noise to be spatially coherent within 'hard' frequency
        % ranges
        % for details see: DOI: 10.1121/1.2987429
        f = [-0.5:1/n_samples:0.5-1/n_samples]*f_sampling; % frequncy range

        pink_noise_spec = fft(pink_noise,[],1);  
        for band_idx = 1:length(noise_mixing_data.band_freqs)
            % calc coherence for band
            C = noise_mixing_data.matrices{band_idx}; 
            freq_bin_idxs = (noise_mixing_data.band_freqs{band_idx}(1)<abs(f))&(abs(f)<noise_mixing_data.band_freqs{band_idx}(2));
            pink_noise_spec(freq_bin_idxs,:) = (C' * pink_noise_spec(freq_bin_idxs,:)')'; 
        end

        pink_noise = real(ifft(pink_noise_spec,[],1));
        else
        error('%s is not implemented as a mixing method',noise_mixing_data.mixing_type)
    end

    if strcmp(spatial_normalization_type,'active_nodes')
        n_active_nodes_pink = sum(sum(abs(pink_noise))~=0) ;
        pink_noise = n_active_nodes_pink * pink_noise/norm(pink_noise,'fro') ;
    elseif strcmp(spatial_normalization_type,'all_nodes')
        pink_noise = pink_noise/norm(pink_noise,'fro') ;
    else
        error('%s is not implemented as spatial normalization method', spatial_normalization_type)
    end
%% --------------------combine different types of noise--------------------
    pow =1;
    noise = ((mu/(1+mu)).^pow)*pink_noise + ((1/(1+mu)).^pow)*alpha_noise ;
    noise = n_active_nodes_pink*noise/norm(noise,'fro') ;% pink noise and alpha noise are correlated randomly. dirty hack: normalize sum

end

function y = GetAlphaActivity(n_samples,sampling_freq,freq_band)

% generate alpha activity as band-pass filtered white noise
% returns a matrix of size [n_samples,n_nodes]
% Author: Sebastian Bosse 03/2017
%--------------------------------------------------------------------------

if nargin <3
    n_trials = 1 ;
end

% generate white noise
x = randn(n_samples,1);

% bandpass white noise according to alpha band
[b,a] = butter(3, freq_band/sampling_freq*2); 
y = filter(b,a, x); 

% ensure zero mean value
y = y - repmat(mean(y),[n_samples,1]) ;

end

function pink_noise = GetPinkNoise(n_samples,n_nodes)

% generate pink noise by shaping white noise
% returns a matrix of size [n_samples,n_nodes]
% Author: Sebastian Bosse 01/2018
%--------------------------------------------------------------------------

    M = n_samples + rem(n_samples,2) ;
    n = 1:M ;
    scalings = sqrt(1./n);
    scalings = repmat(scalings,[n_nodes,1])';
        
    noise_spec = fft(randn(M,n_nodes)).*scalings ;
    pink_noise = real(ifft(noise_spec))  ;
    pink_noise = pink_noise(1:n_samples,:) ;
end

