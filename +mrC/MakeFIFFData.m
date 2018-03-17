function MakeFIFFData(dataFile,elecPos,outputDir)
    % mrC.MakeFIFFData(dataFile,elecPos,outputDir)
    
    % read in and check the EEG data text file
    pdExport = load(dataFile);

    if ~isfield(pdExport,'Cov')
        warning('Use PD 3.30 or later for matlab exports! Cannot find Covariance field in %s!',dataFile)
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

    data.evoked.epochs = pdExport.Wave';
    epochs = data.evoked.epochs;

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

    data.info.ch_names = cell( 1, data.info.nchan ); % declare a cell array
    for ch = 1 : data.info.nchan
        data.info.chs( ch ).scanno = ch;  % in order of scanning
        data.info.chs( ch ).logno  = ch;  % in some logical order
        data.info.chs( ch ).kind   = FIFF.FIFFV_EEG_CH;
        data.info.chs( ch ).range  = 10.; % voltmeter range, only applies to raw data
        data.info.chs( ch ).cal    = 1.;  % calibration factor to bring data to Volts
        data.info.chs( ch ).coil_type = 1;
        data.info.chs( ch ).loc = [ elecPos.x( ch ); elecPos.y( ch ); elecPos.z( ch ); 1;0;0; 0;1;0; 0;0;1 ];
        data.info.chs( ch ).coil_trans = [];
        data.info.chs( ch ).eeg_loc = [ elecPos.x( ch ); elecPos.y( ch ); elecPos.z( ch ) ];
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
    [ ~, name ] = fileparts( dataFile );

    fname = fullfile(outputDir,[name '.fif']);
    covName = fullfile(outputDir,[name '-cov.fif'] );  % use datafile name as output name

    fiff_write_evoked( fname, data);
    mne_write_cov_file( covName, cov );
    fprintf( 'Wrote %s and %s\n', fname, covName);
end