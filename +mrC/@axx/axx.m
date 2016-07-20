classdef axx
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        cndNmb
        nTrl % how many trials
    end
    
    properties (Dependent)
        nT   % how many time points
        nFr  % how many frequencies
        nCh  % how many channels
    end
    
    properties
        dTms % time resolution
        dFHz % frequency resolution
        i1F1 % 
        i1F2 %
        DataUnitStr
        Amp
        Cos
        Sin
        SpecPValue
        SpecStdErr
        Cov
        Wave
    end
    
    methods
        function obj = axx(axxStrct)
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

                % average together the following values Wave, Amp, Cos, Sin, Cov, SpecPValue, SpecStdErr
                obj.Wave = mean(cat(3,axxStrct.Wave),3);
                ampVal = mean(cat(3,axxStrct.Amp),3);
                obj.Amp = ampVal(1:obj.nFr,:);
                cosVal = mean(cat(3,axxStrct.Cos),3);
                obj.Cos = cosVal(1:obj.nFr,:);
                sinVal = mean(cat(3,axxStrct.Sin),3);
                obj.Sin = sinVal(1:obj.nFr,:);
                specpVal = mean(cat(3,axxStrct.SpecPValue),3);
                obj.SpecPValue = specpVal(1:obj.nFr,:);
                specstdVal = mean(cat(3,axxStrct.SpecStdErr),3);
                obj.SpecStdErr = specstdVal(1:obj.nFr,:);
                obj.Cov = mean(cat(3,axxStrct.Cov),3);
                else
            end
        end 
        function value = get.nT(obj)
            value = size(obj.Wave,1);
        end
        function value = get.nCh(obj)
            value = size(obj.Wave,2);
        end    
        function value = get.nFr(obj)
            value = floor(obj.nT/8);
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