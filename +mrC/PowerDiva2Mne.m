function powerDivaExp2Mne( elpfile, datafile, fiducialFile, outputDir, doReg )
    % Description:	Function written by Justin Ales 
    % 
    % Syntax:       mrC.powerDivaExp2Mne( elpfile, datafile, fiducialFile, outputDir, doreg )
    % 
    %   datafile        - string indicating the Axx_c???.mat file from powerdiva
    %   elpfile         - string indicating the electrode positions file in the .elp/.elc format
    %   fiducialFile    - string indicating the file that contains the locations of the
    %                       fiducials in the MRI reference frame.
    %   outputDir       - string indicating the location to write output
    %                       [current directory]
    %   doReg           - boolean indicating whether to register the electrodes 
    %                       true/[false]. 
    %                       Note that registration requires fiducialFile.

    if nargin < 5 || isempty(doReg)
        doReg = false;
    else
    end
    if nargin < 4 || isempty(outputDir)
        outputDir = pwd;
    else
    end
    if nargin < 3 || isempty(fiducialFile)
        fiducialFile = [];
        if doReg == true;
            msg = sprintf('\n No fiducial file provided. \n Registration cannot be done!\n');
            warning(msg);
            doReg = false;
        else
        end
    else
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % write FIFF file in interactive mode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    try
        FIFF = fiff_define_constants();
    catch
        error('Cannot find MNE constants. You need to run: addMNE')
    end

    % write file id structure
    timezone=5;                              %   Matlab does not the timezone
    data.info.file_id.version   = bitor( bitshift( 1, 16 ) , 1 );  %   Version (1 << 16) | 1
    data.info.file_id.machid(1) = 65536 * rand( 1 );   %   Machine id is random for now
    data.info.file_id.machid(2) = 65536 * rand( 1 );   %   Machine id is random for now
    data.info.file_id.secs      = 3600 * ( 24 * ( now - datenum( 1970,1,1,0,0,0 ) ) + timezone );
    data.info.file_id.usecs     = 0;                   %   Do not know how we could get this

    % write measurement id structure
    data.info.meas_id.version  = data.info.file_id.version;
    data.info.meas_id.machid   = data.info.file_id.machid;
    data.info.meas_id.secs     = data.info.file_id.secs;
    data.info.meas_id.usecs    = data.info.file_id.usecs;
    data.info.meas_date = [];

    if ~isempty(strfind(elpfile,'elp')) % if elp format
        % read the elp file
        if exist('readelp')==2,
            try
                eloc = readelp(elpfile); %
                elcFormat = false;
            catch
                error(['Error Reading file: ' elpfile ' This file might be the in the right file format. Use the original Locator  files.']);
            end
        else
            error('CANNOT FIND: readelp.m  This function is from EEGLAB try running: addEEGLAB')
        end
    else    % assume it is elc format
        % read the elc file
        if exist('readeetraklocs')==2,
            try
                eloc = readeetraklocs(elpfile); %
                elcFormat = true;
            catch
                error(['Error Reading file: ' elpfile ' This file might be the in the right file format. Use the original Locator  files.']);
            end
        else
            error('CANNOT FIND: readlocs.m  This function is from EEGLAB try running: addEEGLAB')
        end
    end

    if ~elcFormat

        elp.lpa = [eloc(2).X eloc(2).Y eloc(2).Z]; 
        elp.rpa = [eloc(3).X eloc(3).Y eloc(3).Z]; 
        elp.nasion = [eloc(1).X eloc(1).Y eloc(1).Z]; 

        %Lx = eloc(2).X;
        %Ly = eloc(2).Y;

        %Nx = eloc(1).X; % distance from the ctf origin to nasion

        %cs = - Lx / sqrt( Lx*Lx + Ly*Ly );
        %sn =   Ly / sqrt( Lx*Lx + Ly*Ly );

        for i=5:length(eloc);

            elp.x(i-4) = eloc(i).X;
            elp.y(i-4) = eloc(i).Y;
            elp.z(i-4) = eloc(i).Z;

        end
        elp.sensorN = length(elp.x)+1;

        %elp = elec_emse2matlab( elpfile ); % read the elp file

        Lx = elp.lpa( 1 );
        Ly = elp.lpa( 2 );
        Nx = elp.nasion( 1 );     % distance from the ctf origin to nasion
        cs = - Lx / sqrt( Lx*Lx + Ly*Ly );
        sn =   Ly / sqrt( Lx*Lx + Ly*Ly );

        % convert elp c.f. (CTF) to subject centered c.f. (NEUROMAG), i.e. LPA on -x, RPA on x, NAS
        % on y, origin on LPA - RPA line, but only approx between LPA and RPA.
        scf.x = elp.x * cs - elp.y * sn - Nx * cs;
        scf.y = elp.x * sn + elp.y * cs;
        scf.z = elp.z;
    else
        for i=1:length(eloc);

            scf.x(i) = eloc(i).X;
            scf.y(i) = eloc(i).Y;
            scf.z(i) = eloc(i).Z;

        end
    end
    
    [pathstr name] = fileparts(elpfile);

    hspFile = dir(fullfile(pathstr,'*.hsp'))

    validNames = ~strncmp({hspFile(:).name},'.',1);
    hspFile=hspFile(validNames);

    headShapeDigitized = false;
    if ~isempty(hspFile),

        hspFullFile = fullfile(pathstr,hspFile(1).name);

        [headShapePoints] = readhsp(hspFullFile);
        headShapeDigitized = true;

        hsp.x = headShapePoints(:,1) * cs - headShapePoints(:,2) * sn - Nx * cs;
        hsp.y = headShapePoints(:,1) * sn + headShapePoints(:,2) * cs;
        hsp.z = headShapePoints(:,3);

        headShapePoints = [hsp.x,hsp.y,hsp.z];

    end

    % read the EEG data text file
    pdExport = load(datafile);

    if ~isfield(pdExport,'Cov')
        warning('Use PD 3.30 or later for matlab exports! Cannot find Covariance field in %s!',datafile)
        disp('But it is kinda ok. I will fake the covariance for you. But when you try to make an inverse it could get ugly');
        pdExport.Cov = eye(pdExport.nCh);
        pdExport.nTrl = 1;
    else
    end
    
    % Convert units to volts and convert covvariance to volts^2
    if ~isfield(pdExport,'DataUnitStr')
        disp('Cannot find DataUnitSt. USE PD 3.30 or later.  I will guess at units. It is your fault if it is off by 10^6!');
    elseif strcmpi(pdExport.DataUnitStr,'microVolts')
        pdExport.Wave = pdExport.Wave*10^-6;
        pdExport.Cov = pdExport.Cov*10^-12;
    end

    data.evoked.epochs = pdExport.Wave';
    epochs = data.evoked.epochs;

    signal = sqrt( var( epochs' ) );

    % get the main measurement pars with some convenient defaults
    nchan = pdExport.nCh;

    %[ a b ] = regexp( datafile, '_\d+_' ); % look for a number delimited by '_'s
    %[ a b ] = regexp( datafile, '_c\d+_' ); % look for a condition number delimited by '_'s

    sfreq = 1000*(pdExport.dTms)^-1; %Sampling frequncy in Hz
    condn = pdExport.cndNmb;

    %data.info.nchan = intInput( 'Number of channels', nchan );
    %data.info.sfreq = intInput( 'Sampling frequency (Hz)', sfreq );
    %data.info.highpass = fltInput( 'High-pass filter (Hz)', 0.1 );
    %data.info.lowpass = fltInput( 'Low-pass filter (Hz)', 50. );
    %rshift = fltInput( 'Electrode height (mm)', 0.0 );

    data.info.nchan = nchan;
    data.info.sfreq = sfreq;

    %Don't know what this is used for, hard coding it for now;
    %JMA
    data.info.highpass = .1;
    data.info.lowpass = 50;

    % rshift = fltInput( 'Electrode height (mm)', 0.0 );
    % 
    % shift electrodes inward by their height
    % [ az el r ] = cart2sph( scf.x, scf.y, scf.z );
    % r = r - 0.001 * rshift;
    % if( r <= 0 )
    %     error( me, 'Electrodes shifted too far inward!' );
    % end
    % [ scf.x scf.y scf.z ] = sph2cart( az, el, r );
    % 
    % flip coordinate sign if necessary
    % if(     flipxflag == 1 )
    %     scf.x = -scf.x;
    % elseif( flipyflag == 1 )
    %     scf.y = -scf.y;
    % elseif( flipzflag == 1 )
    %     scf.z = -scf.z;
    % end

    % convert fiducials
    if ~elcFormat
        lpa.x = elp.lpa( 1 ) * cs - elp.lpa( 2 ) * sn - Nx * cs;
        lpa.y = elp.lpa( 1 ) * sn + elp.lpa( 2 ) * cs;
        lpa.z = elp.lpa( 3 );

        rpa.x = elp.rpa( 1 ) * cs - elp.rpa( 2 ) * sn - Nx * cs;
        rpa.y = elp.rpa( 1 ) * sn + elp.rpa( 2 ) * cs;
        rpa.z = elp.rpa( 3 );

        nas.x = elp.nasion( 1 ) * cs - elp.nasion( 2 ) * sn - Nx * cs;
        nas.y = elp.nasion( 1 ) * sn + elp.nasion( 2 ) * cs;
        nas.z = elp.nasion( 3 );
    else
    end

    data.info.ch_names = cell( 1, data.info.nchan ); % declare a cell array
    for ch = 1 : data.info.nchan
        data.info.chs( ch ).scanno = ch;  % in order of scanning
        data.info.chs( ch ).logno  = ch;  % in some logical order
        data.info.chs( ch ).kind   = FIFF.FIFFV_EEG_CH;
        data.info.chs( ch ).range  = 10.; % voltmeter range, only applies to raw data
        data.info.chs( ch ).cal    = 1.;  % calibration factor to bring data to Volts
        data.info.chs( ch ).coil_type = 1;
        data.info.chs( ch ).loc = [ scf.x( ch ); scf.y( ch ); scf.z( ch ); 1;0;0; 0;1;0; 0;0;1 ];
        data.info.chs( ch ).coil_trans = [];
        data.info.chs( ch ).eeg_loc = [ scf.x( ch ); scf.y( ch ); scf.z( ch ) ];
        data.info.chs( ch ).coord_frame = FIFF.FIFFV_COORD_HEAD;

        data.info.chs( ch ).unit   = 107;  % Volts as units
        data.info.chs( ch ).unit_mul = 0;  % always 0
        data.info.chs( ch ).ch_name = [ 'EEG ' sprintf( '%0.3d', ch ) ];
    end
    
    for ch = 1 : data.info.nchan
        data.info.ch_names{ ch } = data.info.chs( ch ).ch_name; 
    end

    data.info.dev_head_t.from = FIFF.FIFFV_COORD_DEVICE;
    data.info.dev_head_t.to   = FIFF.FIFFV_COORD_HEAD;
    data.info.dev_head_t.trans = diag( [ 1 1 1 1 ] ); 

    data.info.ctf_head_t = [];
    data.info.dev_ctf_t  = [];

    % write digitizer info
    for ch = 1 : data.info.nchan
        data.info.dig( ch ).kind = FIFF.FIFFV_POINT_EEG;
        data.info.dig( ch ).ident = ch;
        data.info.dig( ch ).r = data.info.chs( ch ).eeg_loc;
        data.info.dig( ch ).coord_frame = FIFF.FIFFV_COORD_HEAD;
    end

    data.info.bads = {}; % no bad channels

    % write projections structure
    data.info.projs.kind = FIFF.FIFFV_MNE_PROJ_ITEM_EEG_AVREF; % assume average reference
    data.info.projs.active = 1;  % active
    data.info.projs.desc = 'Average EEG reference';
    data.info.projs.data.nrow = 1;
    data.info.projs.data.ncol = data.info.nchan;
    data.info.projs.data.row_names = [];
    data.info.projs.data.col_names = data.info.ch_names;
    data.info.projs.data.data = zeros( 1, data.info.nchan );

    data.info.comps = struct([]); % create a 0x0 struct

    % write evoked response structure

    data.evoked.aspect_kind = FIFF.FIFFV_ASPECT_AVERAGE;
    %ntrave = intInput( 'Number of averaged trials', 1 );
    ntrave = pdExport.nTrl;
    data.evoked.nave  = ntrave * sfreq; % number of time averages in noise cov calculation


    npretrigger = 0;
    data.evoked.first = -npretrigger;

    nsamples = pdExport.nT;

    data.evoked.last  = nsamples - npretrigger - 1;
    %comment = strInput( 'Comments', '' );
    comment = ['Condition: ' num2str(pdExport.cndNmb)];

    data.evoked.comment = comment;
    data.evoked.times = ( data.evoked.first : data.evoked.last ) / data.info.sfreq;

    % % import noise covariance matrix
    
    cov.kind = 1;     % 1 for noise cov. matrix, 2 for source covariance matrix
    cov.diag = false; % but source cov. matrices are usually diagonal
    cov.dim = data.info.nchan;

    for ch = 1 :data.info.nchan;
        cov.names{ ch } = [ 'EEG ' sprintf( '%0.3d', ch ) ];   % channel names
    end

    cov.data = pdExport.Cov;

    % write projections structure
    cov.projs.kind = FIFF.FIFFV_MNE_PROJ_ITEM_EEG_AVREF; % assume average reference
    cov.projs.active = 1;  % active
    cov.projs.desc = 'Average EEG reference';
    cov.projs.data.nrow = 1;
    cov.projs.data.ncol = cov.dim;
    cov.projs.data.row_names = [];
    cov.projs.data.col_names = cov.names;
    cov.projs.data.data = zeros( 1, cov.dim );

    cov.bads = {}; % no bad channels
    cov.nfree = ntrave * sfreq; % number of time averages in noise cov calculation

    cov.eig    = [];  % eigenvalues
    cov.eigvec = [];  % eigenvectors

    % finally, write the whole datastructure into the FIFF formated file
    [ path, name ] = fileparts( datafile );

    fname = fullfile(outputDir,[name '.fif']);
    covName = fullfile(outputDir,[name '-cov.fif'] );  % use datafile name as output name

    fiff_write_evoked( fname, data);
    mne_write_cov_file( covName, cov );
    fprintf( 'Wrote %s and %s\n', fname, covName);
    
    % Start of registration code.
  
    if (exist('fiducialFile','var'))
        if (~isempty(fiducialFile)),

            display('Coregistering fiducials')
            mriFiducials = load(fiducialFile);

            elecFiducials = 1000*[ lpa.x, lpa.y, lpa.z; ...
                rpa.x, rpa.y, rpa.z; ...
                nas.x, nas.y, nas.z];

            elecFiducials2 = 1000*[ 2*lpa.x, lpa.y-nas.y, lpa.z; ...
                2*rpa.x, rpa.y-nas.y, rpa.z; ...
                nas.x, nas.y, nas.z];

            %Reording the points to make the nasion first
            %Doing this since the coreg script locks the 1st points together
            %And we like the nasion.

            %trans = fiducial_coregister(elecFiducials([3 2 1],:),mriFiducials([3 2 1],:))';

            [tOrig rOrig] = alignFiducials(elecFiducials,mriFiducials);
            %SOme versions of locator scale fiducials by a factor of 2.
            %THis sucks, so do a kludgy check if a scaling fits the mri better
            [tScaled rScaled] = alignFiducials(elecFiducials2,mriFiducials);

            transScaled = [ rScaled, tScaled'; 0 0 0 1];
            transOrig = [ rOrig, tOrig'; 0 0 0 1];


            transFid = transScaled*[elecFiducials2, [1; 1; 1;]]';
            transFidScaled = [transFid(1:3,:)]';

            transFid = transOrig*[elecFiducials, [1; 1; 1;]]';
            transFidOrig = [transFid(1:3,:)]';

            sseScaled = sum((transFidScaled(:)-mriFiducials(:)).^2)
            sseOrig = sum((transFidOrig(:)-mriFiducials(:)).^2)


            %Check for smaller sum square error when scaled;
            if sseScaled<sseOrig 
                t = tScaled;
                r = rScaled;
                disp('Detected improper fiducial scaling, scaling fiducials up by 2');
                elecFiducials = elecFiducials2;
            else %Don't do anything if the orig fits better
                t = tOrig;
                r = rOrig;
            end


            if doReg

                trans = [ r, t'; 0 0 0 1];

                if (headShapeDigitized),

                    [pathstr name] = fileparts(fiducialFile);

                    headSurfFile = dir(fullfile(pathstr,'*_fs4-head.fif'))

                    if ~isempty(hspFile),

                        headSurfFullFile = fullfile(pathstr,headSurfFile(1).name);
                        surf =  mne_read_bem_surfaces(headSurfFullFile);

                        headShapePoints = [1000*headShapePoints, ones(size(headShapePoints,1),1)];

                        transHsp = trans*headShapePoints';
                        % headShapePoints, surf.rr

                        %Silly transposes:
                        %  [nT fitHsp] = fitScatteredPoints(1000*surf.rr,transHsp(1:3,:)');


                        %Fiducials, electrodes and Headshape points translated to
                        %initial conditions.
                        transFid = trans*[elecFiducials, [1; 1; 1;]]';
                        transFid = [transFid(1:3,:)]';
                        elecCoord = [1000*scf.x', 1000*scf.y', 1000*scf.z', ones(length(scf.x),1)];
                        transElec = trans*elecCoord';
                        transElec = [transElec(1:3,:)]';
                        surf.rr = surf.rr*1000;


                        [nT fitHsp] = fitPointsToScalp(surf,transFid,transElec,transHsp(1:3,:)');

                        trans = nT*trans;
                    else
                        warning('Found headshape digitization, but cannot find hires scalp')
                    end
                else
                    [pathstr name] = fileparts(fiducialFile);

                    headSurfFile = dir(fullfile(pathstr,'*_fs4-head.fif'))

                    headSurfFullFile = fullfile(pathstr,headSurfFile(1).name);
                    surf =  mne_read_bem_surfaces(headSurfFullFile);
                    transFid = trans*[elecFiducials, [1; 1; 1;]]';
                    %            transFid = [transFid(1:3,:)/1000]';
                    elecCoord = [1000*scf.x', 1000*scf.y', 1000*scf.z', ones(length(scf.x),1)];
                    transElec = trans*elecCoord';
                    %transElec = [transElec(1:3,:)/1000]';
                    transFid = [transFid(1:3,:)]';
                    transElec = [transElec(1:3,:)]';
                    surf.rr = surf.rr*1000;

                    [nT] = fitPointsToScalp(surf,transFid,transElec,[]);
                    trans = nT*trans;
                end

                trans
                %        [tmp transName] = fileparts(elpfile);
                transFile = fullfile(outputDir,'elp2mri.tran');
                fid = fopen(transFile,'w');
                fprintf(fid,'%d %d %d %d\n',trans');

                fclose(fid);
                % save(transFile,'trans','-ascii')
            else
                % just read in the previously made reg file

                transFile = fullfile(outputDir,'elp2mri.tran');

                if ~exist(transFile,'file')
                    error(['Cannot find file: ' transFile ' Something is weird this should have been made already'])
                end

                trans = load(fullfile(outputDir,'elp2mri.tran'));
            end

        end
    end

    % display the electrode locations
    if doReg == 1
    %    snr = 1 ./ ( signal ./ noise' );
        snr = 1 ./ ( signal);

    %     fig = figure(100);
         fig = gcf;
     %    clf;    
         set(fig, 'NumberTitle', 'off', 'Name', name, 'Position', [ 100,100, 512,512 ], 'Color', [ 0 0.75 0 ] );

         if ~elcFormat
             if ~isElpFileGood(elpfile)
                 set(fig,'Color', [ 1 1 0 ] )
             end
         else
         end

        if exist('trans','var')

            elecFiducials = [elecFiducials, [1; 1; 1;]];
            transFid = trans*elecFiducials';
            transFid = [transFid(1:3,:)/1000]';

            elecCoord = [1000*scf.x', 1000*scf.y', 1000*scf.z', ones(length(scf.x),1)];

            transElec = trans*elecCoord';
            transElec = [transElec(1:3,:)/1000]';


            scatter3( mriFiducials(:,1)/1000, mriFiducials(:,2)/1000,mriFiducials(:,3)/1000, 100, 'g', 'filled' ),
            hold on;
            scatter3( transFid(:,1), transFid(:,2),transFid(:,3), 120, 'r', 'filled' ),
            scatter3( mriFiducials(3,1)/1000,mriFiducials(3,2)/1000,mriFiducials(3,3)/1000,1200,'kx');
            scatter3( transElec(:,1), transElec(:,2),transElec(:,3), 20, 'k', 'filled' ),

    %          scatter3( mriFiducials(:,1), mriFiducials(:,2),mriFiducials(:,3), 120, 'g', 'filled' ),
    %          hold on;
    %          scatter3( transFid(:,1), transFid(:,2),transFid(:,3), 120, 'r', 'filled' ),
    %          scatter3( mriFiducials(3,1),mriFiducials(3,2),mriFiducials(3,3),1200,'kx');
    %          scatter3( transElec(:,1), transElec(:,2),transElec(:,3), 60, 'k', 'filled' ),


            if exist('fitHsp')
                scatter3( fitHsp(:,1)/1000, fitHsp(:,2)/1000,fitHsp(:,3)/1000, 60, 'y', 'filled' ),
           %     legend('MRI defined fiducials','Electrode Fiducials','NOSE','Electrodes')
            else
          %      legend('MRI defined fiducials','Electrode Fiducials','NOSE','Electrodes','Headshape Points')
            end


            fidDiff = (1000*transFid-mriFiducials);

            fidError = (sqrt(sum(fidDiff.^2,2)));

            totalError = sum(fidError);

            msg = sprintf('LEFT Ear Error: %f mm Right Ear Error: %f mm Nasion Error : %f mm\n Total Error %f mm',... 
                fidError(1),fidError(2),fidError(3),totalError);
            disp(msg)

    %        title(['Total Error: ' num2str(totalError) ' mm'])


       %         [pathstr,name] = fileparts(fiducialFile)

        else
            scatter3( 0, 0, 0, 80, 'b', 'filled' ), hold;
            scatter3( lpa.x, lpa.y, lpa.z, 120, 'g', 'filled' ),
            scatter3( rpa.x, rpa.y, rpa.z, 120, 'g', 'filled' ),
            scatter3( nas.x, nas.y, nas.z, 120, 'g', 'filled' ),
            scatter3( scf.x, scf.y, scf.z, 60, snr / max( snr ), 'filled' ),
        end


    %     axis equal,
    %     axis vis3d,
    %     axis off,
    %     grid off,
    %     view( -161, 20 );
    %     zoom( 1 );
    %     colormap( 'copper' );

        % add some gui functionality
        dcm_obj = datacursormode( fig ); % data cursor object
        set( dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on' );
        rotate3d on;
       % set( dcm_obj, 'UpdateFcn', { @myupdatefcn, scf, snr } );
    end
end

%%%%%%%%%%%%%%%%%%%%%% utility functions %%%%%%%%%%%%%%%%%%%%%%%%

% function txt = myupdatefcn( empt, event_obj, scf, snr )
%     pos = get( event_obj, 'Position' );
%     diff = ( scf.x - pos( 1 ) ).^2 + ...
%            ( scf.y - pos( 2 ) ).^2 + ...
%            ( scf.z - pos( 3 ) ).^2;
%     el_ind = find( diff < 1e-6 );
%     txt = { [ 'Chan: ', num2str( el_ind ) ], [ 'SNR: ', num2str( snr( 1, el_ind ) ) ] };
% end
% 
% function [res] = intInput( query, default )
%     res = input( [ query ' [' sprintf( '%d', default ) ']: ' ] );
%     if( isempty( res ) )
%         res = default;
%     end
% end
% 
% function [res] = fltInput( query, default )
%     res = input( [ query ' [' sprintf( '%.1f', default ) ']: ' ] );
%     if( isempty( res ) )
%         res = default;
%     end
% end
% 
% function [res] = strInput( query, default )
%     res = input( [ query ' [' default ']: ' ], 's' );
%     if( isempty( res ) )
%         res = default;
%     end
% end


