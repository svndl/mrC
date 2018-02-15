function [wave,harmonics] = FrequencyFilter(Axx,DrawFigure,SpecCutOff,DoNoHarm)
    %% sort out arguments
    if nargin < 4 || isempty(DoNoHarm)
        DoNoHarm = false;
    else
    end
    if nargin < 3 || isempty(SpecCutOff)
        SpecCutOff = 40;
    else
    end
    if nargin < 2
        DrawFigure = false;
    else
    end
    if nargin < 1
        error('No AXX file given!');
    else
    end
    if (SpecCutOff*Axx.i1F1)>size(Axx.Cos,1)-1
        error('SpecCutOff is higher than the highest frequency included in Axx!');
    else
    end
    %% create time-line
    trialTime = 1/(Axx.dFHz*Axx.i1F1); % sample length
    Fs = 1/(trialTime/Axx.nT); % samples per second
    dt = 1/Fs;                 % seconds per sample
    t = (0:dt:trialTime-dt)';   % seconds
    
    %% filters
    filter{1} = Axx.i1F1*(1:2:SpecCutOff); % odd
    filter{2}= Axx.i1F1*(2:2:SpecCutOff);  % even
    filter{3} = Axx.i1F1*(1:SpecCutOff);   % all
    
    
    %% mrCURRENT METHOD
    % Axx.nT is the number of samples per total stimulus cycle
    tRC = gcd( Axx.i1F1, Axx.i1F2 ); % number of total stimulus cycles per Axx epoch 
    tNT = tRC*Axx.nT; % the number of time points must be multiplied to match the Axx epoch.
    
    for z=1:size(Axx.Wave,3)
        tFB = 2*pi/tNT*(0:tNT-1)';     % Fourier base
        curCos = Axx.Cos(2:end,:,z);    % eliminate first element of Axx.Cos & Axx.Sin, which is the DC component
        curSin = Axx.Sin(2:end,:,z);
        for f = 1:length(filter)
            tFBCos{f} = cos( tFB *(filter{f})); % tested faster than old way of doing trig on 1 column & building matrices w/ indexing
            tFBSin{f} = sin( tFB *(filter{f}));
            filteredWave{f} = tFBCos{f} * curCos(filter{f},:) + tFBSin{f} * curSin(filter{f},:);
            if tRC > 1
                filteredWave{f} = filteredWave{f}(1:Axx.nT,:); 
                % if length of FB mats are more than one repeat cycle, there will tRC identical cycles, so just use the first
            else
            end
            if DoNoHarm
                harmonics = [];
            else
                % make bar values
                filteredHarm{f} = curCos(filter{f},:) + curSin(filter{f},:) * i;
            end
            
        end
        % Plot the signal versus time:
        if DrawFigure
            gcaOpts = {'tickdir','out','box','off','fontsize',12,'fontname','Calibri','linewidth',1,'ticklength',[.015,.015]};
            figure(z);
            plot(t,filteredWave{1}(:,75),'b','linewidth',2);hold on; 
            plot(t,filteredWave{2}(:,75),'r','linewidth',2);
            plot(t,filteredWave{3}(:,75),'c','linewidth',2);
            xlim([0,trialTime]);
            set(gca,gcaOpts{:});
            xlabel('time (in seconds)');
            title('Signal versus Time');
            legend('Odd','Even','All');
            zoom xon;
            hold off;
        else
        end
        wave.odd(:,:,z) = filteredWave{1};
        wave.even(:,:,z) = filteredWave{2};
        wave.all(:,:,z) = filteredWave{3};
        harmonics.odd(:,:,z) = filteredHarm{1};
        harmonics.even(:,:,z) = filteredHarm{2};
        harmonics.all(:,:,z) = filteredHarm{3};
    end
end

