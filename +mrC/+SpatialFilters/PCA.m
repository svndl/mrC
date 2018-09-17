function [OutAxx,W,A,D] = PCA(InAxx,varargin)

% This function calculates finds a spatial filter based on the the PCA of
% InAxx. 

% INPUT:
    % InAxx: EEG data in Axx format
%   <options>:
    % freq_range: Frequnecies of signal considered. 
    %             Default: all, except 0 Hz
    
% OUTPUT:
    % OutAxx: Data in component space in Axx format
    % W: Spatial filter
    % A: Activation pattern
    
% Written by Sebastian Bosse, 3.8.2018

opt	= ParseArgs(varargin,...
    'freq_range', InAxx.dFHz*[1:(InAxx.nFr-1)] ...
    );


freq_idxs = 1+opt.freq_range/InAxx.dFHz ; % shift as 0Hz has idx 1

if freq_idxs(1)==1 % 0Hz is considered
    cmplx_signal = cat(1, InAxx.Cos(freq_idxs(end:-1:2),:,:),InAxx.Cos(freq_idxs,:,:)) ... % even real part 
                + 1i*cat(1, -InAxx.Sin(freq_idxs(end:-1:2),:,:),InAxx.Sin(freq_idxs,:,:)); % odd imag part
    
else
    cmplx_signal = cat(1, InAxx.Cos(freq_idxs(end:-1:1),:,:),InAxx.Cos(freq_idxs,:,:)) ... % even real part 
                + 1i*cat(1, -InAxx.Sin(freq_idxs(end:-1:1),:,:),InAxx.Sin(freq_idxs,:,:)); % odd imag part    
end



C =reshape(permute(cmplx_signal,[2,1,3]),size(cmplx_signal,2),[])*conj(reshape(permute(cmplx_signal,[2,1,3]),size(cmplx_signal,2),[]))';

if sum(abs(imag(C(:))))/sum(abs(real(C(:))))>10^-10
    error('PCA: Covariance matrix is complex')
end
C = real(C);

[W,D] = eig(C);
[D,sorted_idx] = sort(diag(D),'descend') ;
W = W(:,sorted_idx);
A = C * W * pinv(W'*C*W);


% project to pca domain
OutAxx = InAxx ;
temp = W'*reshape(permute(InAxx.Cos,[2,1,3]),size(InAxx.Cos,2),[]);
OutAxx.Cos = permute(reshape(temp,size(InAxx.Cos,2),size(InAxx.Cos,1),size(InAxx.Cos,3)),[2,1,3]);
temp = W'*reshape(permute(InAxx.Sin,[2,1,3]),size(InAxx.Sin,2),[]);
OutAxx.Sin = permute(reshape(temp,size(InAxx.Sin,2),size(InAxx.Sin,1),size(InAxx.Sin,3)),[2,1,3]);
OutAxx.Amp = abs(OutAxx.Cos +1i *OutAxx.Sin);


    
    
