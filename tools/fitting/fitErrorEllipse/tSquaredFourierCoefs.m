function [results] = tSquaredFourierCoefs(xyData1,xyData2,testMu,alphaVal,pdStyle)
% [results] = tSquaredFourierCoefs(xyData,testMu,alphaVal)
%
% Returns the results of running Hotelling's t-squared test that the mean
% of the 2D data in xyData is the same as the mean specified in testMu at
% the specified alphaVal (0-1).
%
% results contains the following fields:
%   alpha, tSqrdCritical, tSqrd, pVal, H (0 if can't reject null; 1 if
%       rejected the null hypothesis)
%
% If testMu is not provided, the mean is tested against the origin (0,0).
% If alphaVal is not provided, it defaults to 0.05.
%
% This function assumes that the 2D data in xyData are Fourier coefficients
% organized with the real coefficients in the 1st column and the imaginary
% coefficients in the 2nd column. Rows = samples.
%
% Based on Anderson (1984) An Introduction to Multivariate Statistical 
% Analysis, Wiley

if nargin<5 || isempty(alphaVal)
    pdStyle = false;
end

if nargin<4 || isempty(alphaVal)
    alphaVal = 0.05;
end
if nargin<3 || isempty(testMu)
    testMu = [0,0];
else
end
if nargin<2 || isempty(testMu)
    xyData2 = zeros(size(xyData1));
else
end

dims = size(xyData1);
N = dims(1);
if dims(2) ~= 2
    error('input data must be a matrix of 2D row samples');
end
if N < 2
    error('input data must contain at least 2 samples');
end

if length(testMu) ~= 2
    error('testMu should be a 2D vector');
end

xyData = xyData1 - xyData2;

try
    [sampMu,sampCovMat] = eigFourierCoefs(xyData);
catch
    fprintf('The covariance matrix of xyData could not be calculated, probably your data do not contain >1 sample.');
end

if pdStyle
    sampCovMat = eye(2);
else
end

results.alpha = alphaVal;

% Eqn. 2 in Sec. 5.3 of Anderson (1984):
t0Sqrd = ((N-1)*2)/(N-2) * finv( 1-alphaVal, 2, N - 2 ); 
results.tSqrdCritical = t0Sqrd;

try
    invSampCovMat = inv(sampCovMat);    
    % Eqn. 2 of Sec. 5.1 of Anderson (1984):
    tSqrd = N * (sampMu - testMu) * invSampCovMat * (sampMu - testMu)'; 
    
    tSqrdF = (N-2)/((N-1)*2) * tSqrd; % F approximation 
    pVal = 1 - fcdf(tSqrdF, 2, N-2);  % compute p-value
    
    results.tSqrd = tSqrd;
    results.pVal = pVal;
    results.H = tSqrd >= t0Sqrd;
catch
    fprintf('inverse of the sample covariance matrix could not be computed.')
end

