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
    