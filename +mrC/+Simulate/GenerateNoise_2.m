function [noise, pink_noise, alpha_noise] = GenerateNoise_2(f_sampling, n_samples, n_nodes, mu, alpha_nodes, noise_mixing_data, spatial_normalization_type,nTrials)
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
    disp(['Alpha noise...']); 
    alpha_noise = zeros(n_samples,n_nodes,nTrials);
    alpha_noise(:,alpha_nodes,:)  = permute(repmat(GetAlphaActivity(n_samples,f_sampling,[8,12],nTrials),[1,1,length(alpha_nodes )]),[1 3 2]); 
    
    if strcmp(spatial_normalization_type,'active_nodes')
        alpha_noise = arrayfun(@(x) length(alpha_nodes)*alpha_noise(:,:,x)/norm(alpha_noise(:,:,x),'fro'),1:nTrials,'uni',false);
    elseif strcmp(spatial_normalization_type,'all_nodes')
        alpha_noise = arrayfun(@(x) alpha_noise(:,:,x)/norm(alpha_noise(:,:,x),'fro'),1:nTrials,'uni',false);
    else
        error('%s is not implemented as spatial normalization method', spatial_normalization_type)
    end
    alpha_noise = cat(3,alpha_noise{:});
    
%% -----------------------------generate pink noise------------------------
    disp('Pink noise...');
    [pink_noise_spec, pink_noise] = GetPinkNoise(n_samples, n_nodes,nTrials,false);

    % impose coherence on pink noise
     disp('Impose coherence...');
    if strcmp(noise_mixing_data.mixing_type,'coh') % just in case we want to add other mixing mechanisms
        % force noise to be spatially coherent within 'hard' frequency
        % ranges
        % for details see: DOI: 10.1121/1.2987429
        f = [-0.5:1/n_samples:0.5-1/n_samples]*f_sampling; % frequncy range

        % pink_noise_spec2 = fft(pink_noise,[],1);  % I directly work with pink_noise_spec
        for band_idx = 1:length(noise_mixing_data.band_freqs)
            % calc coherence for band
            C = noise_mixing_data.matrices{band_idx}; 
            freq_bin_idxs = (noise_mixing_data.band_freqs{band_idx}(1)<abs(f))&(abs(f)<noise_mixing_data.band_freqs{band_idx}(2));
            for nt = 1:nTrials
                pink_noise_spec(freq_bin_idxs,:,nt) = (C' * pink_noise_spec(freq_bin_idxs,:,nt)')';
            end
        end

        pink_noise = real(ifft(pink_noise_spec,[],1));
        else
        error('%s is not implemented as a mixing method',noise_mixing_data.mixing_type)
    end
    
    if strcmp(spatial_normalization_type,'active_nodes')
        pink_noise = arrayfun(@(x) length(alpha_nodes)*pink_noise(:,:,x)/norm(pink_noise(:,:,x),'fro'),1:nTrials,'uni',false);
    elseif strcmp(spatial_normalization_type,'all_nodes')
        pink_noise = arrayfun(@(x) pink_noise(:,:,x)/norm(pink_noise(:,:,x),'fro'),1:nTrials,'uni',false);
    else
        error('%s is not implemented as spatial normalization method', spatial_normalization_type)
    end
    pink_noise = cat(3,pink_noise{:});
%% --------------------combine different types of noise--------------------
   disp('Add two noises..')
    noise = sqrt(mu/(1+mu))*pink_noise + sqrt(1/(1+mu))*alpha_noise ;
    %noise = noise/norm(noise,'fro') ;% pink noise and alpha noise are correlated randomly. dirty hack: normalize sum
    noise = arrayfun(@(x) noise(:,:,x)/norm(noise(:,:,x),'fro'),1:nTrials,'uni',false);
%% ---------------------------show resulting noise-------------------------
    if false % just to take a look at the noise components
        f = [-0.5:1/n_samples:0.5-1/n_samples]*f_sampling; % frequncy range
        t = [0:n_samples-1]/f_sampling ;
        subplot(3,2,1)
        plot(t, pink_noise(:,1:50:end));xlim([0 2]);
        subplot(3,2,2)
        plot(f, abs(fftshift(fft(pink_noise(:,1:50:end)))));xlim([0 max(f)]);
        %ylim([0 .2]);

        subplot(3,2,3)
        plot(t, alpha_noise(:,1:50:end));xlim([0 2]);
        subplot(3,2,4)
        plot(f, abs(fftshift(fft(alpha_noise(:,1:50:end)))));xlim([0 max(f)]);
        %ylim([0 .2]);

        subplot(3,2,5)
        plot(t, noise(:,1:50:end)); xlim([0 2]);
        subplot(3,2,6)
        plot(f, abs(fftshift(fft(noise(:,1:50:end)))));xlim([0 max(f)]);
        %ylim([0 .2]);
    end
end

function Noisealpha = GetAlphaActivity(n_samples,sampling_freq,freq_band,nTrials)

    % generate alpha activity as band-pass filtered white noise
    % returns a matrix of size [n_samples,n_nodes]
    % Author: Sebastian Bosse 03/2017
    %--------------------------------------------------------------------------

    if ~exist('nTrials','var') || isempty(nTrials)
        nTrials = 1 ;
    end

    % generate white noise
    Noisew = randn(n_samples,nTrials);

    % bandpass white noise according to alpha band
    [b,a] = butter(3, freq_band/sampling_freq*2); 
    Noisealpha = arrayfun(@(x) filter(b,a, Noisew(:,x)),1:nTrials,'uni',false);

    % ensure zero mean value
    Noisealpha = cellfun(@(x) x- repmat(mean(x),[n_samples,1]),Noisealpha,'uni',false);
    Noisealpha = cat(2,Noisealpha{:});

end

function [noise_spec pink_noise] = GetPinkNoise(n_samples,n_nodes,nTrials,noise_temp)

% generate pink noise by shaping white noise
% returns a matrix of size [n_samples,n_nodes]
% Author: Sebastian Bosse 01/2018
%--------------------------------------------------------------------------
    M = n_samples + rem(n_samples,2) ;
    n = 1:M ;
    tic
    scalings = sqrt(1./n); scalings((end/2)+1:end) = flip(scalings(1:end/2));
    scalings = repmat(scalings',[1,n_nodes,nTrials]);
    noise_spec = fft(randn(M,n_nodes,nTrials),[],1).* scalings;%%%% DOES THE number of fft matters?
    if noise_temp
        pink_noise = real(ifft(noise_spec,[],1));
        pink_noise = pink_noise(1:n_samples,:,:) ;
    else
        pink_noise = [];
    end
end

