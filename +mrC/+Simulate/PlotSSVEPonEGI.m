function PlotSSVEPonEGI(EEGAxx, SignalType, SavePath,signalFF,RoiList,subIDs, subjects)


% INPUT:
    % EEGAXX: is the data that mrC.Simulate.SimulateProject returns
    % SignalType: Determines if the plots are in phase or amplitude
                % [Amplitude]/Phase
                
                
    % subjects: [Individuals]/Average            
%% set default valuse

if ~exist('SignalType','var')
    SignalType = 'Amplitude';
end

if ~exist('signalFF','var')|| isempty(signalFF)
      signalFF = 1;
end
 
if ~exist('subjects','var')
    subjects = 'Individuals';
end
%-------------------Calculate EEG spectrum---------------------------------
    sub1 = find(~cellfun(@isempty,EEGAxx),1);
    freq = 0:EEGAxx{sub1}.dFHz:EEGAxx{sub1}.dFHz*(EEGAxx{sub1}.nFr-1); % frequncy labels, based on fft

    for s = 1:length(subIDs)
        if ~isempty(EEGAxx{s})
            % --------------PLOT: interactive head and spectrum plots-----------
            SDEEG{s} = EEGAxx{s}.Cos+(EEGAxx{s}.Sin*1i);%EEGAxx{s}.Amp;% it is important which n is considered for fft
            if strcmp(subjects,'Individuals'),
                if strcmp(SignalType,'Amplitude')
                    mrC.Simulate.PlotEEG(abs(SDEEG{s}),freq,SavePath,subIDs{s},RoiList,signalFF);% Plot individuals
                elseif strcmp(SignalType,'Phase')
                    mrC.Simulate.PlotEEG(wrapTo2Pi(angle(SDEEG{s})),freq,SavePath,subIDs{s},RoiList,signalFF);% Plot individuals
                end
            end 
        end 
    end
    
    % Plot average over individuals
    MSDEEG = mean(cat(4,SDEEG{:}),4);
    if strcmp(SignalType,'Amplitude')
        mrC.Simulate.PlotEEG(abs(MSDEEG),freq,SavePath,'average over all  ',RoiList,signalFF);
    elseif strcmp(SignalType,'Phase')    
        mrC.Simulate.PlotEEG(wrapTo2Pi(angle(MSDEEG)),freq,SavePath,'average over all  ',RoiList,signalFF,'Phase');
    end
end