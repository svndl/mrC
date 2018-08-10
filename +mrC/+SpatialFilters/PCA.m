function [OutAxx,W,A] = PCA(InAxx,freqs)

% This function calculates finds a spatial filter based on the the PCA of
% EEGAxx. 

% INPUT:
    % InAxx: EEG data in Axx format
    % freqs: Frequnecies considered
% OUTPUT:
    % OutAxx: Data in component space in Axx format
    % W: Spatial filter
    % A: Activation pattern
    
% Written by Sebastian Bosse, 3.8.2018

if exist('freqs','var') && ~isempty(freqs)
    freq_range = 0:InAxx.dFHz:InAxx.dFHz*(InAxx.nFr-1);
    freq_idxs = find(ismember(freq_range,freqs));
    
    real_part = InAxx.Cos(freq_idxs,:,:);
    imag_part = InAxx.Sin(freq_idxs,:,:);
    
    if ismember(0,freqs)
        cmplx_signal = cat(1, real_part,real_part) ... % even real part 
                + cat(1, -imag_part,imag_part); % odd imag part
    else    
        cmplx_signal = cat(1, real_part,InAxx.Cos(1,:,:),real_part) ... % even real part 
                + cat(1, -imag_part,InAxx.Sin(1,:,:),imag_part); % odd imag part
    end
else % just take it all
    cmplx_signal = cat(1, InAxx.Cos(2:end,:,:),InAxx.Cos) ... % even real part 
                + cat(1, -InAxx.Sin(2:end,:,:),InAxx.Sin); % odd imag part
end
% C = zeros(size(cmplx_signal,2)) ;
% for trial_idx = 1:size(cmplx_signal,3)
%     C = C+cmplx_signal(:,:,trial_idx)'*conj(cmplx_signal(:,:,trial_idx)) ;
% end
% more efficient by avoiding the loop
C =(reshape(permute(cmplx_signal,[2,1,3]),size(cmplx_signal,2),[]))*conj(reshape(permute(cmplx_signal,[2,1,3]),size(cmplx_signal,2),[])');


[W,D] = eig(C);
[D,sorted_idx] = sort(diag(D),'descend') ;
W = W(:,sorted_idx);
A = C * W / (W'*C*W);


% project to pca domain
OutAxx = InAxx ;
temp = W*reshape(permute(InAxx.Cos,[2,1,3]),size(InAxx.Cos,2),[]);
OutAxx.Cos = permute(reshape(temp,size(InAxx.Cos,2),size(InAxx.Cos,1),size(InAxx.Cos,3)),[2,1,3]);
temp = W*reshape(permute(InAxx.Sin,[2,1,3]),size(InAxx.Sin,2),[]);
OutAxx.Sin = permute(reshape(temp,size(InAxx.Sin,2),size(InAxx.Sin,1),size(InAxx.Sin,3)),[2,1,3]);
OutAxx.Amp = abs(OutAxx.Cos +i *OutAxx.Sin);


    
    
