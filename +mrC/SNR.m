function [outData,anovaData] = SNR(Y,Ydim,varargin)
    % [outData,anovaData] = mrC.SNR(Y,Ydim,varargin)
    opt = ParseArgs(varargin, ...
        'ROIs',  Ydim{2}, ...
        'conds', Ydim{4}, ...
        'subs', Ydim{3}, ...
        'inverse', 1, ...
        'band', 2, ...
        'method', 'Coherent', ...
        'func_ROI',false, ...
        'multiSession',false, ...
        'log_scale', false, ...
        'makeFigure',false, ...
        'do_RMS',false ...
    );

    if ischar(opt.ROIs)
        opt.ROIs={opt.ROIs};
    else 
    end
    
    if ischar(opt.conds)
        opt.conds={opt.conds};
    else
    end
    
    % convert to opt.conds to vector of indices
    if iscell(opt.conds)
        opt.conds = cell2mat(cellfun(@(x) find(ismember(Ydim{4},x)),opt.conds,'uni',false));
    else
    end
    
    % we keep the ROIs as a cell of strings for now, conversion later
    
    if opt.multiSession
        if numel(opt.subs) ~= numel(Ydim{3})
            msg = sprintf('\n %0.0f subjects selected, all subjects must be selected when combining sesssions',numel(opt.subs));
            error(msg);
        else
        end
        Y = (Y(:,:,1:2:end,:,:,:,:)+Y(:,:,2:2:end,:,:,:,:))./2;
        Ydim{3} = Ydim{3}(1:end/2);
        opt.subs = 1:length(Ydim{3});
    else
        % convert to opt.subs to vector of indices
        if iscell(opt.subs)
            if ischar(opt.subs{1})
                opt.subs = cell2mat(cellfun(@(x) find(ismember(Ydim{3},x)),opt.subs,'uni',false));
            else
                opt.subs = cell2mat(opt.subs);
            end
        else
        end
    end
    
        
    %% GENERATE SNR (FOR ALL DATA)
    for r=1:size(Ydim{2},2)
        tInit = squeeze(Y([opt.band-1,opt.band,opt.band+1],r,:,opt.conds,opt.inverse,1,3));
        switch lower(opt.method) % make it so that case does not matter
            case 'coherent'
                tM = squeeze(mean( tInit ,2))';
                tOut1 = abs( tM );		% abs(mean) = mean(projection onto phase of mean)
                %tOut2 = ( real(tInit)*diag(real(tM)) + imag(tInit)*diag(imag(tM)) ) * diag(1./tOut1);
            case 'incoherent'
                tOut2 = abs( tInit );
                tOut1 = squeeze(mean( tOut2 ,2 ))';	% mean(abs)
        end
        %aveSNR(:,r) = tOut1(:,2)./mean(tOut1(:,[1,3]),2);
        % individual subject SNR
        tInit = reshape(abs(tInit),sort(size(tInit)));
        %for s=1:size(Y,3)
        %    subSNR(s,:,r)=tInit(2,:,s)./mean(tInit([1,3],:,s),1);
        %end
        benoitSNR(:,:,r)=compute_SNR(Y,r,opt.band,opt.conds,opt.log_scale,opt.inverse,opt.do_RMS);
    end
    
    %% PICK SELECTED DATA FEATURES and AVERAGE D/V
    if opt.func_ROI
        % note: this is not going to work with previous condition selection
        for r=1:length(opt.ROIs)
            dIdx = cellfun(@(x) strcmp(x,['func_',opt.ROIs{r},'d']),Ydim{2},'uni',false);
            vIdx = cellfun(@(x) strcmp(x,['func_',opt.ROIs{r},'v']),Ydim{2},'uni',false);
            nIdx = cellfun(@(x) strcmp(x,['func_',opt.ROIs{r}]),Ydim{2},'uni',false);
            roiIdx{r} = find(sum([cell2mat(dIdx);cell2mat(vIdx);cell2mat(nIdx)])>0);
            ready_benoitSNR(:,:,r)=mean(benoitSNR(opt.subs,opt.conds,roiIdx{r}),3);
            %ready_subSNR(:,:,r)=mean(subSNR(opt.subs,opt.conds,roiIdx{r}),3);
            %ready_aveSNR(:,r)=mean(aveSNR(opt.conds,roiIdx{r}),2);
        end
    else
        roiIdx = cell2mat(cellfun(@(x) find(ismember(Ydim{2},x)),opt.ROIs,'uni',false));
        ready_benoitSNR = benoitSNR(opt.subs,:,roiIdx);
        %ready_subSNR = subSNR(opt.subs,:,roiIdx);
        %ready_aveSNR = aveSNR(:,roiIdx);
    end
    clear benoitSNR; benoitSNR=ready_benoitSNR;
    %clear subSNR; subSNR=ready_subSNR;
    %clear aveSNR; aveSNR=ready_aveSNR;
        
    %% GENERATE AVERAGES AND SE
    %ave_subSNR = mean(subSNR,1);
    %ave_subSNR = reshape(ave_subSNR,length(opt.conds),length(opt.ROIs));
    ave_benoitSNR = squeeze(mean(benoitSNR,1));
    ave_benoitSNR = reshape(ave_benoitSNR,length(opt.conds),length(opt.ROIs));
    %if opt.multiSession
    %    benoitSNR = benoitSNR(1:2:end,:)+benoitSNR(2:2:end,:)./2; % average two session together
    %else
    %end
    se_benoitSNR = squeeze(std(benoitSNR,0,1)./sqrt(size(benoitSNR,1)));
    se_benoitSNR = reshape(se_benoitSNR,length(opt.conds),length(opt.ROIs));
 
    %% CREATE ANOVA-FRIENDLY VARIABLE, IF REQUESTED
    vectorSNR = reshape(benoitSNR,numel(benoitSNR),1);
    sIdx = repmat(1:size(benoitSNR,1),1,length(opt.conds)*length(opt.ROIs))';
    tempIdx = [];
    for c=1:length(opt.conds)
        tempIdx = [tempIdx,ones(1,size(benoitSNR,1))*(c-1)];
    end
    cIdx = repmat(tempIdx,1,length(opt.ROIs))';
    roiIdx = reshape(repmat(1:length(opt.ROIs),size(benoitSNR,1)*length(opt.conds),1),numel(sIdx),1);
    anovaData = [vectorSNR,sIdx,cIdx,roiIdx];
    
    %% MAKE FIGURE
    if opt.makeFigure
        conditions = Ydim{4}(opt.conds);
        fontSize = 12;
        gcaOpts = {'xtick',1:4,'xticklabel',conditions,'tickdir','out','box','off','fontsize',fontSize,'fontname','Calibri','linewidth',1,'ticklength',[.03,.03]};
        tempColors = colormap;
        tempIdx = round(linspace(0,length(tempColors),6));
        condColors = tempColors(tempIdx(2:end-1),:);
        tempIdx = round(linspace(0,length(tempColors),length(opt.ROIs)+1));
        roiColors = tempColors(tempIdx(2:end),:);

        figure;
        hold on;
        title(Ydim{5}(opt.inverse));
        for z = 1:length(opt.ROIs)
            plot_h(z) = plot(1:length(opt.conds),ave_benoitSNR(:,z),'color',roiColors(z,:));
            errorb(1:length(opt.conds),ave_benoitSNR(:,z),se_benoitSNR(:,z),'color',roiColors(z,:))
        end
        legend(plot_h,opt.ROIs,'location','northwest');
        set(gca,gcaOpts{:});
        hold off;
    else
    end
    outData.ave = ave_benoitSNR;
    outData.se = se_benoitSNR;
    outData.raw = benoitSNR;
end

function ROI_SNR = compute_SNR( Y , ROI , freq , cond_ndx , db_flag ,inv_ndx,do_RMS)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Description: computes the SNR values for a given ROI from a spectrum mrCurrent export
    % (i.e. from mrCurrent: ExportData -> Go, Space = 'Source' , Domain = 'Spec')
    %
    % INPUTS =  - Y:         matrix containing the data created by mrCurrent
    % after the export
    %           - ROI:       name of the ROI (e.g.: ROI = 'V3A').
    %           - freq:      the index(es) to the frequency(ies) of interest (can be checked
    %                        by looking at Ydim{1} wich links the frequencies to their indexes).
    %           - cond_ndx:  index(es) to the condition(s) of interest (optional).
    %           - db_flag:   specifies if the computation is done in db or linear scale
    %                        (optional, default: db_flag = 1).
    %           - inv_ndx:   index specifying which inverse to use 
    %           - do_RMS:    use root mean square rather than standard mean when computing SNR   
    %         
    %   
    %
    % OUTPUT =  - ROI_SNR    the SNR vallue of the chosen ROI.
    %
    % CALL   =  - ROI_selection.m (in 'Benoit_toolbox').
    %
    % Author: Benoit Cottereau.
    % Creation: 03/05/2010.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ( nargin < 3 )
        fprintf('\n\n Error: Not enough input arguments \n See ''compute_SNR.m'' for the definition of its INPUTS/OUTPUTS \n\n\n')
        ROI_SNR = 0;
        return;
    elseif nargin == 3
        cond_nb = length( Y( 1 , 1 , 1 , : , 1 , 1 , 3 ) );
        cond_ndx = [ 1 : cond_nb ];
    else
        if cond_ndx
            cond_nb = length( cond_ndx );
        else
            cond_nb = length( Y( 1 , 1 , 1 , : , 1 , 1 , 3 ) );
            cond_ndx = [ 1 : cond_nb ];
        end
    end
    if ~( nargin >= 5 && db_flag == 0)
        db_flag = 1;
    end
    if ~( nargin >= 6 && inv_ndx == 0)
        inv_ndx = 1;
    end
    if ~( nargin >= 7 && do_RMS == 1)
        do_RMS = 0;
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Definition of the numbers of subjects and condition (to select subsets of data, ones
    % should change the Y input
    subj_nb = length( Y( 1 , 1 , : , 1 , 1 , 1 , 1 ) );

    % Definition of the parameters
    ROI_SNR = zeros( subj_nb , cond_nb );
    NUM = zeros( size( ROI_SNR ) );
    DEN = zeros( size( ROI_SNR ) );

    % Selection of the ROI
    %VA = ROI_selection( ROI );
    VA = ROI;

    if length( freq ) > 1 && ~do_RMS
        error('Use RMS when pooling multiple frequencies');
    else 
    end

    % Loop across the number of frequencies
    for k = 1 : length( freq )

        % Selection of the spectrum value at the frequency of interest
        a = reshape( Y( freq( k ) , VA , : , cond_ndx , inv_ndx , 1 , 3 ) , subj_nb , cond_nb );

        % Selection of the neighborhood spectrum values (note that for each subject, the noise
        % is averaged across all the conditions that are given to the function - not all conditions)
        a_n1_tmp = Y( freq( k ) - 1 , VA , : , cond_ndx , inv_ndx , 1 , 3 );
        %a_n1 = abs( reshape( mean( a_n1_tmp , 4 ) , subj_nb , 1 ) );
        a_n1 = reshape( mean( abs(a_n1_tmp) , 4 ) , subj_nb , 1 );

        a_n2_tmp = Y( freq( k ) + 1 , VA , : , cond_ndx , inv_ndx , 1 , 3 );
        %a_n2 = abs( reshape( mean( a_n2_tmp , 4 ) , subj_nb , 1 ) );
        a_n2 = reshape( mean( abs(a_n2_tmp) , 4 ) , subj_nb , 1 );
        % Computation of the RMS (updated at each iteration of the loop)
        if do_RMS
            NUM = NUM + abs(a) .^ 2;
            DEN = DEN + ( repmat( .5 * a_n1 + .5 * a_n2 , 1 , cond_nb ) ) .^ 2;
        else
            % no squaring if no RMS
            NUM = NUM + abs(a);
            DEN = DEN + ( repmat( .5 * a_n1 + .5 * a_n2 , 1 , cond_nb ) );
        end
    end

    % Computation of the SNR
    if do_RMS
        ROI_SNR = sqrt( NUM ) ./ sqrt( DEN );
    else
        ROI_SNR = NUM ./ DEN ;
    end

    %ROI_SNR(find(ROI_SNR<1)) = 1;
    % Go to the log scale if needed:
    if db_flag
        ROI_SNR = 20 * log10( ROI_SNR );
    end
end

