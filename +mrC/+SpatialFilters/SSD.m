function [OutAxx,W,A] = SSD(InAxx,freqs)

% This function calculates finds a spatial filter based on the the SSD of
% EEGAxx. The signal is assumed in freqs, noise is assumed in the
% neighboring bins

% INPUT:
    % InAxx: EEG data in Axx format
    % freqs: Frequnecies of signal considered
% OUTPUT:
    % OutAxx: Data in component space in Axx format
    % W: Spatial filter
    % A: Activation pattern
    
% Written by Sebastian Bosse, 3.8.2018


    freq_range = 0:InAxx.dFHz:InAxx.dFHz*(InAxx.nFr-1);
    freq_idxs = find(ismember(freq_range,freqs));

    real_part_signal = InAxx.Cos(freq_idxs,:,:);
    imag_part_signal = InAxx.Sin(freq_idxs,:,:);
    cmplx_signal = cat(1, real_part_signal,real_part_signal) ... % even real part 
                    + cat(1, -imag_part_signal,imag_part_signal); % odd imag part

    real_part_noise = cat(1,InAxx.Cos(freq_idxs-1,:,:),InAxx.Cos(freq_idxs+1,:,:));
    imag_part_noise = cat(1,InAxx.Sin(freq_idxs-1,:,:),InAxx.Sin(freq_idxs+1,:,:));
    cmplx_noise = cat(1, real_part_noise,real_part_noise) ... % even real part 
                    + cat(1, -imag_part_noise,imag_part_noise); % odd imag part

    C_s =conj(reshape(permute(cmplx_signal,[2,1,3]),size(cmplx_signal,2),[]))*(reshape(permute(cmplx_signal,[2,1,3]),size(cmplx_signal,2),[])');
    C_n =conj(reshape(permute(cmplx_noise,[2,1,3]),size(cmplx_noise,2),[]))*(reshape(permute(cmplx_noise,[2,1,3]),size(cmplx_noise,2),[])');

    %TODO: there should be some kind of prior dimensionality reduction if the
    %covariance matrix is rank deficient

    [W,D] =eig(C_s,C_s+C_n);
    [D,sorted_idx] = sort(diag(D),'descend') ;
    W = W(:,sorted_idx);
    A = C_s * W / (W'*C_s*W);

    % project to pca domain
    OutAxx = InAxx ;
    temp = W*reshape(permute(InAxx.Cos,[2,1,3]),size(InAxx.Cos,2),[]);
    OutAxx.Cos = permute(reshape(temp,size(InAxx.Cos,2),size(InAxx.Cos,1),size(InAxx.Cos,3)),[2,1,3]);
    temp = W*reshape(permute(InAxx.Sin,[2,1,3]),size(InAxx.Sin,2),[]);
    OutAxx.Sin = permute(reshape(temp,size(InAxx.Sin,2),size(InAxx.Sin,1),size(InAxx.Sin,3)),[2,1,3]);
    OutAxx.Amp = abs(OutAxx.Cos +i *OutAxx.Sin);

end
    
    
