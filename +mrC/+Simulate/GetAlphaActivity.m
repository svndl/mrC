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