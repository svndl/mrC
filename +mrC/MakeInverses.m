function params = MakeInverses( projectDir,params )
    %function mrC.MakeInverses( projectDir,params )
    %
    % params is a structure some fields:
    % params.SNR = estimated power SNR
    % params.useROIs = boolean specifying whether to constrain
    % params.areaExp = area weighting exponent.
    % localization to fuctiona ROIs
%%   
    if nargin < 1
        projectDir = uigetdir('.','Pick your project directory');
    else
    end
    if nargin < 2 || isempty(params)
        params = get_general_params;
    else
    end
    
    % check inputs
    if ~any(ismember([1,2,3,4],params.Style))
        msg = sprintf('\nUnknown value for Inverse Style: %0.0f!\n',params.Style);
        error(msg);
    else
    end
    if ~any(ismember([0,1],params.sphereModel))
        msg = sprintf('\nUnknown value for sphere model: %0.0f!\n',params.sphereModel);
        error(msg);
    else
    end
    if params.Style == 3
        disp('GCV style, setting SNR to 1');
        params.SNR = 1;
    else
    end
    lambda2 = 1/(params.SNR);
    
    mrC.SystemSetup; % ensure system is setup
    freesurfDir = getpref('freesurfer','SUBJECTS_DIR');

    if ~exist(projectDir,'dir')
        msg = sprintf('Project directory not found: %s\n Thank You, Please Play Again.\n',projectDir);
        error(msg);
    end

    subjectList = subfolders(projectDir);

    for iSubj = 1:length(subjectList),
        subjId = subjectList{iSubj};
        
        optionString = '';
        
        if strcmp(subjId,'skeri9999')
            display('Skipping skeri9999')
            continue;
        end

        logFile = fullfile(projectDir,subjId,'_dev_',['mrC.MakeInverses_log_' datestr(now,'yyyymmdd_HHMM_FFF')  '.txt']);
        diary(logFile)
        
        disp(['Processing subject: ' subjId ])

        % clean-up subject ID, '_' sometimes used for separate sessions
        if ~isempty(strfind(subjId,'_'))
            SUBJECT = [subjId(1:(max(strfind(subjId,'_'))-1)),'_fs4'];
            if strcmp(SUBJECT(1:3),'nl_')
                SUBJECT(1:3) = 'nl-';
            else
            end
        else
            SUBJECT=[subjId '_fs4'];
        end
        
        srcSpaceFile = fullfile(freesurfDir,SUBJECT,'bem',[ SUBJECT '-ico-5p-src.fif']);
        if ~exist(srcSpaceFile,'file'),
            error(['Cannot find find source space file: ' srcSpaceFile]);
        end
        srcSpace = mne_read_source_spaces(srcSpaceFile);

        srcCov = [];

        if params.roiSize > 0
            msg = sprintf('\n You are trying to weigh the inverse by ROI size\n an experimental option that is not available at the moment');
            error(msg);
            % % FIX THIS OPTION AT SOME POINT
            anatDir = getpref('mrCurrent','AnatomyFolder');
            subjRoiDir = fullfile(anatDir,subjId,'Standard','meshes','ROIs');
            [roiList leftVerts rightVerts leftSizes rightSizes] = getRoisByType(subjRoiDir,'all');                  
            totalDx = [leftVerts rightVerts];
            srcSize = sum([srcSpace.nuse]); % <- Note tricky use of grouping
                                           %[srcSpace.nuse] -> [nuse nuse]
                                           %sum of that gives the total # of
                                           %vertices in the source space
            srcCov = sparse(srcSize,srcSize);
            for iRoi = 1:length(roiList),

                srcIdx = roiList(iRoi).meshIndices;
                srcVec = sparse(srcSize,1);
                srcVec(srcIdx) = 1;
                roiWeight = length(srcIdx).^-params.roiSize; %Inverse area weighting
                srcCov = srcCov+roiWeight*(srcVec*srcVec');

            end
            optionString = [optionString 'roiSize_weightExp_' num2str(params.roiSize) '_'];
        end
        
        if params.extendedSources
            % % WHAT DOES THIS OPTION DO?
            for iHemi = 1:2,

                src2subset = zeros(size(srcSpace(iHemi).inuse));
                src2subset(srcSpace(iHemi).vertno) = 1:10242;

                renumberedFaces = srcSpace(iHemi).use_tris;
                renumberedFaces(:) = src2subset(srcSpace(iHemi).use_tris(:));
                mesh.faces = renumberedFaces;
                mesh.vertices = srcSpace(iHemi).rr( srcSpace(iHemi).vertno,:);

                [A{iHemi}] = geometryChunk(mesh,400);
            end

            Ageom = [A{1}      zeros(size(A{1})); ...
                     zeros(size(A{2}))       A{2}];
            srcCov = Ageom;
            optionString = [optionString 'extendedSources_'];

        end

        if params.sphereModel ==true
            mneFwdFileName = [subjId '-sph-fwd.fif' ];
            optionString = [optionString 'sphere_'];
        else
            mneFwdFileName = [subjId '-fwd.fif' ];
            optionString = [optionString 'bem_'];
        end
        mneFwdFile = fullfile(projectDir,subjId,'_MNE_',mneFwdFileName);

        if params.Style == 1
            % READ MNE INVERSE
            mneInvFileName = [subjId '-inv.fif' ];
            mneInvFile = fullfile(projectDir,subjId,'_MNE_',mneInvFileName);
            
            if ~exist(mneInvFile,'file')
                error(['Cannot find an MNE inverse, please run prepareProjectForMrc' ]);
            end
            [sol] = mrC.MakeInvMne(mneInvFile,lambda2,srcSpace,srcCov);
        elseif params.Style == 2
            % DO JMA STYLE
            if params.saveFullForward
                [u s v] = mrC.MakeInvJma(mneFwdFile,lambda2,srcSpace,srcCov);
            else
                [sol] = mrC.MakeInvJma(mneFwdFile,lambda2,srcSpace,srcCov);
                optionString = [optionString 'nonorm_jma_'];
            end
        elseif (params.Style == 3) || (params.Style == 4)
            % DO GCV STYLE
            if params.Style ==4
                params.dodepthweight = true;
            end
            pdExportDir = subfolders(fullfile(projectDir,subjId,'Exp_MATL_*'),1);
            if length(pdExportDir) > 1
                error('\n More than one Exp_MATL directory in %s',fullfile(projectDir,subjId));
            elseif pdExportDir{1} == 0
                error('\n Cannot find Exp_MATL directory, please add data');
            end
            pdExportDir = pdExportDir{1};
           
            exportFileList = subfiles(fullfile(pdExportDir,'Axx_*.mat'));

            if exportFileList{1} ==0
                mgs = sprintf('No .mat PowerDiva exports found in: %s\n',pdExportDir);
                error(msg);
            end
            
            idx = 1;
            for iFile = 1:length(exportFileList)
                
                condNmbr = split_string(exportFileList{iFile},'_',2,'.',1);
                condNmbr = str2num(condNmbr(2:end));
                
                if condNmbr>900
                    continue;
                end
                
                dataFile = fullfile(pdExportDir,exportFileList{iFile});
                msg = sprintf('Processing condition %0.0f, file: %s\n',condNmbr,dataFile);
                disp(msg);
                
                Axx(idx) = orderfields(load(dataFile));
                idx = idx+1;
            end
            
            mneFwd = mne_read_forward_solution(mneFwdFile);
            [fwd] = mrC.MakeForwardMatrix(mneFwd,srcSpace);
            
            while ~isfield(params,'GCV')
                params.GCV = get_gcv_params( Axx(1) );
            end
            
            %% Add depth weighting, added by EB
            truedepth = false;
            if (params.Style ==4)%params.dodepthweight
                 %[ fwd ] = mrC.AddDepthWeight(fwd , subjId, projectDir);
                if truedepth
                    % use the true depth of sources, calculated as the
                    % distance of each source to closest electrode
                    if exist(fullfile(projectDir,subjId,'Inverses','SourceDepth.mat'),'file')
                        load(fullfile(projectDir,subjId,'Inverses','SourceDepth.mat'));
                    else
                        disp('SourceDepth file not found, Calculating dource depths for this project...');
                        mrC.SourceDepth(projectDir);
                    end
                else
                    % use the inverse of norms of forward columns as the weights
                    W = sqrt(mean(fwd.^2,1));
                    SourceDepths = 1./W;
                end
                fwd = fwd.*SourceDepths;
            end
            
            %%
            
            if params.GCV.roiCorrelation == 1
                [ fwd ] = mrC.AddCorr( fwd , subjId );
            elseif params.GCV.roiCorrelation == 2
                [ fwd ] = mrC.AddCorr( fwd , subjId ,'wang');
            elseif params.GCV.roiCorrelation == 3
                [ fwd ] = mrC.AddCorr( fwd , subjId ,'wangkgs');
            else
            end
            
            if length( params.GCV.Quadrants ) == 4
                activated_sources = [ 1 : length(fwd) ];
            else
                [ activated_sources ] = define_activated_source_space( params.Quadrants , length(fwd) , subjId );
            end
            sol = zeros( size( fwd' ) );
            [ sol_tmp , inverse_name ] = mrC.MakeInvGCV( fwd( : , find( activated_sources ) ) , Axx , params.GCV );
            sol( find( activated_sources ) , : ) = sol_tmp;
            
            
            %%
            if params.Style ==4%params.dodepthweight
                sol = sol.*SourceDepths'; 
            end
            %%
            if params.GCV.roiCorrelation == 1
                [ sol ] = mrC.AddCorr( sol , subjId );
                inverse_name = strcat(inverse_name , '_funcROIsCorr');
            elseif params.GCV.roiCorrelation == 2
                [ sol ] = mrC.AddCorr( sol , subjId ,'wang');
                inverse_name = strcat(inverse_name , '_wangROIsCorr');
            elseif params.GCV.roiCorrelation == 3
                [ sol ] = mrC.AddCorr( sol , subjId ,'wangkgs');
                inverse_name = strcat(inverse_name , '_wangkgsROIsCorr');
            else
            end
            if find( setdiff( [ 1 2 3 4 ] , params.GCV.Quadrants ) )
                inverse_name = strcat( '_' , inverse_name );
                for ndx = 1 : length( params.GCV.Quadrants )
                    inverse_name = strcat( num2str( params.GCV.Quadrants( ndx ) ) , inverse_name );
                end
                inverse_name = strcat( 'Quads_' , inverse_name );
            end
            if params.Style ==4%params.dodepthweight
                inverse_name = [inverse_name '_DepthWeight'];
            end
            
        else
            error('unknown inverse index %0.0f',params.Style)
        end


        if params.saveFullForward
            invOutFile = fullfile(projectDir,subjId,'Inverses',[optionString 'fwd' '.mat']);
            save(invOutFile, 'subjId','u','s','v');
        else
            if (params.Style == 3)||(params.Style == 4)
                % if GCV inverse
                optionString =  [optionString inverse_name];
            else
                % if JMA or MNE inverse
                optionString =  [optionString 'snr_' num2str(params.SNR)];
            end
            %invOutFile = fullfile(projectDir,subjId,'Inverses',['mneInv_' optionString '.inv']);
            invOutFile = fullfile(projectDir,subjId,'Inverses',['mneInv_' optionString '.inv']);
            mrC.WriteInverse(sol,invOutFile);
        end

        diary off

    end
end

function params = get_general_params
    % open GUI and let user choose parameters
    % Default values
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    params.Style = 3;
    params.SNR = 100;
    params.roiSize = 0;
    params.sphereModel = false;
    params.extendedSources = false;
    params.saveFullForward = false;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    f = fieldnames(params);
    % use more informative labels for a few items
    f_labels = f;
    for fIdx = 1:length(f_labels)
        if fIdx == 1
            f_labels{fIdx} = sprintf('\nInverse Style\n ( 1 = MNE, 2 = JMA, 3 = GCV, 4 = WMN  )');
        elseif fIdx == 2
            f_labels{fIdx} = sprintf('\nSNR ( if GCV, always = 1 )');
        elseif fIdx == 3
            f_labels{fIdx} = sprintf('\nROI size weighing exponent\n( if 0, do not weigh by ROI size )');
        elseif fIdx == 4
            f_labels{fIdx} = sprintf('\nUse sphere-based forward (true) \n or bem-based forward (false)');
        else
            f_labels{fIdx} = sprintf('\n%s',f{fIdx});
        end
    end
    n = numel(f);
    h = 0.8/n;
    fSize = 12;
    fig = figure('defaultuicontrolunits','normalized','Name','GENERAL OPTIONS','NumberTitle','off');
    U = zeros(2,n);
    for i = 1:n
        U(i,1) = uicontrol('style','text','position',[0.1 .95-i*h 0.4 h],'fontsize',fSize,'string',f_labels{i});
        U(i,2) = uicontrol('style','edit','position',[0.5 0.95-i*h 0.4 h],'fontsize',fSize,'string',num2str(params.(f{i})));
        align(U(i,:),'None','Middle')
    end
    uicontrol('style','pushbutton','position',[0.1 0.05 0.8 0.05],'fontname','arial','fontsize',fSize,'string','Continue','callback','uiresume(gcf)');
    uiwait(fig)
    for i = 1:n
        params.(f{i}) = str2num(get(U(i,2),'string'));
    end
    close(fig)
end

function [ gcv_params ] = get_gcv_params( Axx )
    choice = questdlg('Regularization based on?', ...
                      'GCV',...
                      'Time Inverval', ...
                      'Harmonics','Time Inverval');
    correctInput = false;
    fig = figure('defaultuicontrolunits','normalized','units','normalized','position',[0.5 ,  0.5 , 0.4 , 0.3],'Name','GCV OPTIONS','NumberTitle','off');
    while any(~correctInput)    
        % Handle response
        if strcmp(choice,'Time Inverval')
            totalInterval = Axx(1).dTms * [ 0 : size( Axx(1).Wave , 1 ) - 1 ];
            gcv_params.StartTime = ceil(min(totalInterval));
            gcv_params.EndTime = floor(max(totalInterval));
            f_labels{1} = sprintf('\nStart time (ms)');
            f_labels{2} = sprintf('\nEnd time (ms)');
        else
            % Default values
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            gcv_params.f1_Odd = true;
            gcv_params.f1_Even = false;
            f_labels{1} = sprintf('\nF1 Odd Harmonics (integers)');
            f_labels{2} = sprintf('\nF1 Even Harmonics (integers)');
            if Axx.i1F2 ~= 0
                gcv_params.f2_Odd = false;
                gcv_params.f2_Even = false;
                gcv_params.Intermodulation_order = false;
                f_labels{3} = sprintf('\nF2 Odd Harmonics (integers)');
                f_labels{4} = sprintf('\nF2 Even Harmonics (integers)');
                f_labels{5} = sprintf('\nIntermodulation terms (integers)');
            end
        end
        gcv_params.roiCorrelation = 0;
        gcv_params.Quadrants = [1 2 3 4];
        f_labels{end+1} = sprintf('\nROI correlation \n( 0 = no, 1 = func ROIs, 2 = wang ROIs, 3 = wang and kgs ROIs)');
        f_labels{end+1} = sprintf('\nActivated Quadrants\n( 1 = upL, 2 = upR, 3 = lowL, 4 = lowR )');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Display of the gui interface
        f = fieldnames(gcv_params);
        n = numel(f);
        h = 0.8/n;
        fSize = 12;
        U = zeros(1,n);
        for i = 1:n
            uicontrol('style','text','position',[0.1 .95-i*h 0.4 h],'fontsize',fSize,'string',f_labels{i});
            U(i) = uicontrol('style','edit','position',[0.5 0.95-i*h 0.4 h],'fontsize',fSize,'string',num2str(gcv_params.(f{i})));
        end
        uicontrol('style','pushbutton','position',[0.1 0.05 0.8 0.1],'fontsize',fSize,'string','OK','callback','uiresume(gcf)');
        uiwait(fig)
        for i = 1:n
            paramValue = str2num(get(U(i),'string'));
            gcv_params.(f{i}) = paramValue;
            switch f{i}
                case 'roiCorrelation'
                    correctInput(i) = any(ismember(paramValue,[0,1,2,3]));
                case 'Quadrants'
                    correctInput(i) = any(ismember(paramValue,[1,2,3,4]));
                otherwise
                    if exist('totalInterval','var')
                        % time-based
                        correctInput(i) = ( paramValue >= min(totalInterval) ) && ( paramValue < max(totalInterval) );
                    else
                        % harmonic-based
                        correctInput(i) = ~any(mod(paramValue,1) ~= 0); % check if input is integer or 0
                    end
            end
        end
    end
    close(fig)
end

function [ activated_sources ] = define_activated_source_space( Quads , source_nb , subjId )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Function to determine which sources are supposed to be activated
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    anatDir = getpref('mrCurrent','AnatomyFolder');
    tmp = fullfile(anatDir,subjId,'Standard','meshes','ROIs_correlation.mat');
    load(tmp);

    activated_sources = ones( 1 , source_nb );
    inactivated_quads = setdiff( [ 1 2 3 4 ] , Quads );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if find( inactivated_quads == 1 )  
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2v-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3v-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2V-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3V-R') ) } ) = 0;
    end
    if find( inactivated_quads == 2 )  
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2v-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3v-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2V-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3V-L') ) } ) = 0;
    end
    if find( inactivated_quads == 3 )  
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2d-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3d-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2D-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3D-R') ) } ) = 0;
    end
    if find( inactivated_quads == 4 )  
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2d-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3d-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V2D-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3D-L') ) } ) = 0;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ( find( inactivated_quads == 1 ) & find( inactivated_quads == 3 ) )
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V1-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3A-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V4-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'LOC-R') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'MT-R') ) } ) = 0;
    end
    if ( find( inactivated_quads == 2 ) & find( inactivated_quads == 4 ) )
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V1-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V3A-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'V4-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'LOC-L') ) } ) = 0;
        activated_sources( ROIs.ndx{ find( strcmp(ROIs.name,'MT-L') ) } ) = 0;
    end
end


