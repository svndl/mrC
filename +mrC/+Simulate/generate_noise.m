function noise = generate_noise(f_sampling, n_samples, n_nodes, mu, alpha_nodes, noise_mixing_data, spatial_normalization_type)
% GENERATE_NOISE Returns noise of unit variance as a combination of alpha
% activity (bandpass filtered white noise) and spatially coherent pink
% noise (spectrally shaped white noise)
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
% returns a matrix of size [n_samples,n_nodes]
    
    %% generate alpha noise
    %  
    alpha_noise = zeros(n_samples,n_nodes);
    alpha_noise(:,alpha_nodes)  = repmat(mrC.Simulate.get_alpha_activity(n_samples,f_sampling,[8,12]),[1,length(alpha_nodes )]); 
    
    if strcmp(spatial_normalization_type,'active_nodes')
        n_active_nodes_alpha = sum(sum(abs(alpha_noise))~=0) ;
        alpha_noise = n_active_nodes_alpha*alpha_noise/norm(alpha_noise,'fro') ;
    elseif strcmp(spatial_normalization_type,'all_nodes')
        alpha_noise = alpha_noise/norm(alpha_noise,'fro') ;
    else
        error('%s is not implemented as spatial normalization method', spatial_normalization_type)
    end
    
    
    
    %% generate pink noise
    pink_noise = mrC.Simulate.get_pink_noise(n_samples, n_nodes );

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
        error('%s is not implemented as a mixing method',mixing_type_pink_noise)
    end

    if strcmp(spatial_normalization_type,'active_nodes')
        n_active_nodes_pink = sum(sum(abs(pink_noise))~=0) ;
        pink_noise = n_active_nodes_pink * pink_noise/norm(pink_noise,'fro') ;
    elseif strcmp(spatial_normalization_type,'all_nodes')
        pink_noise = pink_noise/norm(pink_noise,'fro') ;
    else
        error('%s is not implemented as spatial normalization method', spatial_normalization_type)
    end
    %% combine different types of noise
    noise = sqrt(mu/(1+mu))*pink_noise + sqrt(1/(1+mu))*alpha_noise ;
    noise = noise/norm(noise,'fro') ;% pink noise and alpha noise are correlated randomly. dirty hack: normalize sum
    %% show resulting noise
    if true % just to take a look at the noise components
        f = [-0.5:1/n_samples:0.5-1/n_samples]*f_sampling; % frequncy range
        t = [0:n_samples-1]/f_sampling ;
        subplot(3,2,1)
        plot(t, pink_noise)
        subplot(3,2,2)
        plot(f, abs(fftshift(fft(pink_noise))))

        subplot(3,2,3)
        plot(t, alpha_noise)
        subplot(3,2,4)
        plot(f, abs(fftshift(fft(alpha_noise))))

        subplot(3,2,5)
        plot(t, noise)
        subplot(3,2,6)
        plot(f, abs(fftshift(fft(noise))))
    end
end



