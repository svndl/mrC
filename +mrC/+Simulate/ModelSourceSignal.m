function [ROIsig, FundFreq, SF] = ModelSourceSignal(varargin)
% This is a trial version, later different source signals will be added (NARMAX,...)
% For now only generates SSVEP like signal

% INPUTS:
    % <options>:
        % srcType: - the model for source signal: [Simple], SSVEP, (NARMAX... for later)
        % sf: - Sampling frequency
        % ns: Number of time samples
        % srcFreq: srcNum x 1 vector - fundamental frequencies of the sources, where srcNum is number of seed sources with different signals
        % srcHarmonic: - cell array of srcNum x 1, each of cell arrays should be a vector indicating amplitude for harmonics in one source 
        % srcPhase: - cell array of srcNum x 1, each of cell arrays should be a vector indicating phase for harmonics in one source 
    
% OUTPUTS    
    % ROIsig: - ns x srcNum maxtrix,
    % FundFreq: fundamental frequencies
    % SF: samplng frequency

% Written by Elham Barzegaran, this code uses some part from Sebastian's Bosse codes
% Last modified 3/7/2018

%% Set up default values for signal parameters

opt	= ParseArgs(varargin,...
    'srcType'		, 'SSVEP', ...
    'srcFreq'       , [],...
    'srcHarmonic'   , [],...
    'srcPhase'      , [],...
    'sf'            , 100,...
    'ns'            , 1000 ...
    );

% (THIS SHOULD BE UPDATED LATER): To allow multiple fundamental freq in one source
if isempty(opt.srcFreq), opt.srcFreq = [2,5];end % initialize fundamental frequency

srcNum = numel(opt.srcFreq);% Number of seed sources

% This part determines the number of harmonics for each source
if strcmp(opt.srcType,'Simple')% just for test, sinusoidal signal
    
   NH = ones(srcNum,1) ; 
   
elseif strcmp(opt.srcType,'SSVEP')% number of harmonics for SSVEP sources, default: 6
    
   if ~(isempty(opt.srcHarmonic)) 
       NH = cellfun('length',opt.srcHarmonic);
   elseif ~(isempty(opt.srcPhase)) 
       NH = cellfun('length',opt.srcPhase); 
   else
    NH = ones(srcNum,1)*6; 
   end
   
end

% If harmonics amplitudes and phases are not defined, they are initialized here randomly!!!
if isempty(opt.srcHarmonic)
    for s = 1:srcNum, opt.srcHarmonic{s} = (rand(1,NH(s))*5); end% random amplitude of harmonics between [0 5]
end
if isempty(opt.srcPhase)
    for s = 1:srcNum, opt.srcPhase{s} = ((rand(1,NH(s))*2-1)*pi); end % random phase of harmonics between [-pi pi]
end  

% Checks if the input parameters match
if (srcNum~=numel(opt.srcHarmonic)) || (srcNum~=numel(opt.srcPhase))
    error('Source parameters do not match');
end
for h = 1: numel(opt.srcHarmonic)
    if length(opt.srcHarmonic{h})~=length(opt.srcPhase{h})
        error('Harmonic parameters do not match')
    end
end

%% Generate SSVEP signal
ROIsig = zeros(opt.ns,srcNum);
t = (0:opt.ns-1)/opt.sf ;

% Generate signals for each source based on its harmonics
for source_idx = 1:srcNum
    for h_idx = 1:length(opt.srcHarmonic{source_idx}) % loop over harmonics                    
        ROIsig(:,source_idx) = ROIsig(:,source_idx) + ...
            opt.srcHarmonic{source_idx}(h_idx) * cos(2*pi*h_idx * opt.srcFreq(source_idx)*t+opt.srcPhase{source_idx}(h_idx))';
    end
end

FundFreq = opt.srcFreq;
SF = opt.sf;
end

