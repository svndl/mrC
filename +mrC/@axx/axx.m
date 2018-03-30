classdef axx
    % This class defines standard data type that is exported by xDiva. Axx
    % contains spectral and time domain representation of the multichannel
    % steady-state brain response signal.
    
    %----------------------------------------------------------------------
    % Author: Peter Kohler,
    % Last modification: Elham Barzegaran, 03/26/2018
    %======================================================================

    properties
        cndNmb
        nTrl % how many trials
    end
    
    properties (Dependent)
        nT   % how many time points: for a period of a single stimulus cycle
        nCh  % how many channels
    end
    
    properties
        dTms % time resolution in miliseconds
        dFHz % frequency resolution
        nFr  % how many frequencies
        i1F1 % fundamental frequency 1
        i1F2 % fundamental frequency 1
        DataUnitStr %like 'microVolts' 
        Amp % Amplitude spectrum of EEG: a nFr x nCh x nTrl matrix
        Cos % Cosine part of spectrum (real): a nFr x nCh x nTrl matrix
        Sin % Sine part of spectrum (imaginary): a nFr x nCh x nTrl matrix
        SpecPValue
        SpecStdErr
        Cov
        Wave % Averaged EEG in time domain: a nT x nCh x nTrl matrix: 
        %%% Note that nT might be different from the time points used for
        %%% spectrum estimation, since nT is the length of single stimulus 
        %%% cycle, while time window for spectrum is selected so that dFHz 
        %%% is about 0.5 Hz and time window lengths is an integer of stimulus cycle
    end
    
    methods
        function obj = axx(axxStrct,AVR)
            if nargin<2
                AVR=1;% average over trials?
            end
             % class constructor
            if nargin > 0
                % unchanged values, use first strct (will also work if oldStrct is just one 
                obj.dTms = axxStrct(1).dTms;
                obj.dFHz = axxStrct(1).dFHz; 
                obj.i1F1 = axxStrct(1).i1F1;
                obj.i1F2 = axxStrct(1).i1F2;
                obj.DataUnitStr = axxStrct(1).DataUnitStr;
                obj.cndNmb = axxStrct(1).cndNmb;
                obj.nTrl = axxStrct(1).nTrl;
                obj.nFr = axxStrct(1).nFr;

                % average together the following values Wave, Amp, Cos, Sin, Cov, SpecPValue, SpecStdErr
                if AVR ==1,
                    obj.Wave = mean(cat(3,axxStrct.Wave),3);
                    ampVal = mean(cat(3,axxStrct.Amp),3);
                    obj.Amp = ampVal(1:obj.nFr,:);
                    cosVal = mean(cat(3,axxStrct.Cos),3);
                    obj.Cos = cosVal(1:obj.nFr,:);
                    sinVal = mean(cat(3,axxStrct.Sin),3);
                    obj.Sin = sinVal(1:obj.nFr,:);
                    if isfield(axxStrct, 'SpecPValue')
                        specpVal = mean(cat(3,axxStrct.SpecPValue),3);
                        obj.SpecPValue = specpVal(1:obj.nFr,:);
                    else
                        obj.SpecPValue = [];
                    end
                    if isfield(axxStrct, 'SpecStdErr')
                        specstdVal = mean(cat(3,axxStrct.SpecStdErr),3);
                        obj.SpecStdErr = specstdVal(1:obj.nFr,:);
                    else
                        obj.SpecStdErr = [];
                    end
                    if isfield(axxStrct, 'Cov')
                        obj.Cov = mean(cat(3,axxStrct.Cov),3);
                    else
                        obj.SpecStdErr = [];
                    end
                elseif AVR==0,
                    obj.Wave = axxStrct.Wave;
                    obj.Amp = axxStrct.Amp(1:obj.nFr,:,:);
                    obj.Cos = axxStrct.Cos(1:obj.nFr,:,:);
                    obj.Sin = axxStrct.Sin(1:obj.nFr,:,:);
                    
                    if isfield(axxStrct, 'SpecPValue')
                       obj.SpecPValue = xxStrct.SpecPValue(1:obj.nFr,:,:);
                    else
                        obj.SpecPValue = [];
                    end
                    
                    if isfield(axxStrct, 'SpecStdErr')
                        obj.SpecStdErr = axxStrct.SpecStdErr(1:obj.nFr,:,:);
                    else
                        obj.SpecStdErr = [];
                    end
                    
                    if isfield(axxStrct, 'Cov')
                        obj.Cov = axxStrct.Cov;
                    else
                        obj.SpecStdErr = [];
                    end
                end
            end
        end 
        function value = get.nT(obj)
            value = size(obj.Wave,1);
        end
        function value = get.nCh(obj)
            value = size(obj.Wave,2);
        end
        
        function identify(thisAxx)
            if isempty(thisAxx.Wave)
                disp('I am an axx file. I am empty.');
            else
                disp('I am an axx file. I contain data.');
            end
        end
    end
    
end