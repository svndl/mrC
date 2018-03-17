function [scf,fidError] = CoregisterElectrodes( elpFile, fiducialFile, outputDir , display )
    % Description:	Function written by Justin Ales 
    % 
    % Syntax:       mrC.CoregisterElectrodes( elpfile, fiducialFile, outputDir )
    % 
    %   elpfile         - string indicating the electrode positions file in the .elp/.elc format
    %   fiducialFile    - string indicating the file that contains the locations of the
    %                       fiducials in the MRI reference frame.
    %   outputDir       - string indicating the location to write output
    %                       [current directory]
    %   display           - boolean indicating whether to display the electrode positions 
    %                       true/[false]. 
    
    if nargin < 4 || isempty(display)
        display = true;
    else
    end
    if nargin < 3 || isempty(outputDir)
        outputDir = pwd;
    else
    end
    if nargin < 2 || isempty(fiducialFile)
        fiducialFile = [];
        msg = sprintf('\n No fiducial file provided. \n Registration cannot be done!\n');
        error(msg);
    else
    end
    
    %% read in electrode locations (can be either elp or elc format)
    if ~isempty(strfind(elpFile,'elp')) % if elp format
        % read the elp file
        if exist('readelp')==2,
            try
                eloc = readelp(elpFile); %
                elcFormat = false;
            catch
                msg = sprintf('\n Error Reading file:  %s  This file might be the in the right file format. Use the original Locator  files. \n',elpFile);
                error(msg)
            end
        else
            msg = '\n CANNOT FIND: readelp.m  This function is from EEGLAB try running: addEEGLAB \n';
            error(msg)
        end
    else    % assume it is elc format
        % read the elc file
        if exist('readeetraklocs')==2,
            try
                eloc = readeetraklocs(elpFile); %
                elcFormat = true;
            catch
                msg = sprintf('\n Error Reading file:  %s  This file might be the in the right file format. Use the original Locator  files. \n',elpFile);
            end
        else
            error('CANNOT FIND: readlocs.m  This function is from EEGLAB try running: addEEGLAB')
        end
    end

    if ~elcFormat
        % elp format
        labels = cat(2,{eloc.labels});
        fiduIdx = [find(cellfun(@(x) strcmpi(x,'lpa'),labels)),...
                   find(cellfun(@(x) strcmpi(x,'rpa'),labels)),...
                   find(cellfun(@(x) strcmpi(x,'nz'),labels))];
        if numel(fiduIdx) < 3
            msg = '\n Not all fiducials could be found in elp file. \n';
            error(msg);
        else
        end 
            
        elp.lpa = [eloc(fiduIdx(1)).X eloc(fiduIdx(1)).Y eloc(fiduIdx(1)).Z]; 
        elp.rpa = [eloc(fiduIdx(2)).X eloc(fiduIdx(2)).Y eloc(fiduIdx(2)).Z]; 
        elp.nasion = [eloc(fiduIdx(3)).X eloc(fiduIdx(3)).Y eloc(fiduIdx(3)).Z]; 
        
        elp.x = cat(2,eloc(5:end).X);
        elp.y = cat(2,eloc(5:end).Y);
        elp.z = cat(2,eloc(5:end).Z);
        elp.sensorN = length(elp.x)+1;

        Lx = elp.lpa( 1 );
        Ly = elp.lpa( 2 );
        Nx = elp.nasion( 1 );     % distance from the ctf origin to nasion
        cs = - Lx / sqrt( Lx*Lx + Ly*Ly );
        sn =   Ly / sqrt( Lx*Lx + Ly*Ly );
        
        % convert electrodes to subject-centered
        scf = convertElp(elp.x,elp.y,cs,sn,Nx);
        scf.z = elp.z;       
        
        % convert fiducials to subject-centered
        lpa = convertElp(elp.lpa( 1 ),elp.lpa( 2 ),cs,sn,Nx);
        lpa.z = elp.lpa(3);
        
        rpa = convertElp(elp.rpa( 1 ),elp.rpa( 2 ),cs,sn,Nx);
        rpa.z = elp.rpa(3);
        
        nas = convertElp(elp.nasion( 1 ),elp.nasion( 2 ),cs,sn,Nx);
        nas.z = elp.nasion(3);
    else
        % elc format
        for i=1:length(eloc);
            scf.x(i) = eloc(i).X;
            scf.y(i) = eloc(i).Y;
            scf.z(i) = eloc(i).Z;
        end
    end
    
    % check if head shape is digitized
    pathstr = fileparts(fiducialFile);
    hspFile = subfiles(fullfile(pathstr,'*.hsp'));
    headShapeDigitized = false;
    if hspFile{1} ~= 0
        hspFullFile = fullfile(pathstr,hspFile{1});
        [headShapePoints] = readhsp(hspFullFile);
        headShapeDigitized = true;
        % convert head shape to subject-centered
        hsp = convertElp(headShapePoints(:,1),headShapePoints(:,2),cs,sn,Nx);
        hsp.z = headShapePoints(:,3);
        headShapePoints = [hsp.x,hsp.y,hsp.z];
    end
    %% Start of registration code.
    msg = '\n Coregistering fiducials ...';
    disp(msg)
    mriFiducials = load(fiducialFile);

    % Some versions of locator scale fiducials by a factor of 2.
    % This sucks, so do a kludgy check if a scaling fits the mri better
    sseCurrent = inf;
    for z = 1:2
        if z == 1
            tempFiducials = 1000*[ lpa.x, lpa.y, lpa.z; ...
                rpa.x, rpa.y, rpa.z; ...
                nas.x, nas.y, nas.z];
        else
            tempFiducials = 1000*[ 2*lpa.x, lpa.y-nas.y, lpa.z; ...
                2*rpa.x, rpa.y-nas.y, rpa.z; ...
                nas.x, nas.y, nas.z];
        end
        [tAlign, rAlign] = alignFiducials(tempFiducials,mriFiducials);
        transMat = [ rAlign, tAlign'; 0 0 0 1];
        transFid = transMat*[tempFiducials, [1; 1; 1;]]';
        transFid = transFid(1:3,:)';
        sseOrig = sum((transFid(:)-mriFiducials(:)).^2);
        if sseOrig < sseCurrent
            sseCurrent = sseOrig;
            t = tAlign;
            r = rAlign;
            elecFiducials = tempFiducials;
        else
        end
    end

    trans = [ r, t'; 0 0 0 1];
    pathstr = fileparts(fiducialFile);
    headSurfFile = dir(fullfile(pathstr,'*_fs4-head.fif'));
    headSurfFullFile = fullfile(pathstr,headSurfFile(1).name);
    surf =  mne_read_bem_surfaces(headSurfFullFile);

    transFid = trans*[elecFiducials, [1; 1; 1;]]';
    transFid = transFid(1:3,:)';
    elecCoord = [1000*scf.x', 1000*scf.y', 1000*scf.z', ones(length(scf.x),1)];
    transElec = trans*elecCoord';
    transElec = transElec(1:3,:)';
    surf.rr = surf.rr*1000;

    % map digitized head shape onto hi-res scalp
    if headShapeDigitized
        if ~isempty(hspFile)
            headShapePoints = [1000*headShapePoints, ones(size(headShapePoints,1),1)];
            transHsp = trans*headShapePoints';
            transHsp = transHsp(1:3,:)';
        else
            warning('Found headshape digitization, but cannot find hires scalp')
        end
    else
        transHsp = [];
    end
    [nT, fitHsp] = mrC.FitPointsToScalp(surf,transFid,transElec,transHsp);
    trans = nT*trans;
    transFile = fullfile(outputDir,'elp2mri.tran');
    fid = fopen(transFile,'w');
    fprintf(fid,'%d %d %d %d\n',trans');
    fclose(fid);
    
    %% DISPLAY THE ELECTRODE LOCATIONS
    if display == 1
        fig = gcf;  
        if ~elcFormat
            if ~isElpFileGood(elpFile)
                set(fig,'Color', [ 1 1 0 ] )
            end
        else
        end
        elecFiducials = [elecFiducials, [1; 1; 1;]];
        transFid = trans*elecFiducials';
        transFid = [transFid(1:3,:)/1000]';

        elecCoord = [1000*scf.x', 1000*scf.y', 1000*scf.z', ones(length(scf.x),1)];

        transElec = trans*elecCoord';
        transElec = (transElec(1:3,:)/1000)';
        
        fidMriH = scatter3( mriFiducials(:,1)/1000, mriFiducials(:,2)/1000,mriFiducials(:,3)/1000, 100, 'g', 'filled' );
        hold on;
        fidElecH = scatter3( transFid(:,1), transFid(:,2),transFid(:,3), 120, 'r', 'filled' );
        scatter3( mriFiducials(3,1)/1000,mriFiducials(3,2)/1000,mriFiducials(3,3)/1000,1200,'kx');
        elecH = scatter3( transElec(:,1), transElec(:,2),transElec(:,3), 20, 'k', 'filled' );

        if ~isempty(fitHsp)
            hspH = scatter3( fitHsp(:,1)/1000, fitHsp(:,2)/1000,fitHsp(:,3)/1000, 60, 'y', 'filled' );
            %legend([fidMriH,fidElecH,elecH,hspH],'MRI defined fiducials','Electrode Fiducials','NOSE','Electrodes','Headshape Points')
        else
            %legend([fidMriH,fidElecH,elecH],'MRI defined fiducials','Electrode Fiducials','NOSE','Electrodes','Headshape Points')
        end
        
        % compute error
        fidDiff = (1000*transFid-mriFiducials);
        fidError = (sqrt(sum(fidDiff.^2,2)));
        
        % add some gui functionality
        dcm_obj = datacursormode( fig ); % data cursor object
        set( dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on' );
        rotate3d on;
    end
end

function [trans, rot, elecPts] = alignFiducials(elecPts, volPts)
    %[trans, rot] = alignFiducials(inpts, volpts)	
    %	returns alignment matrix given elecPts and elecPts as corresponding points
    %	rot rotates elecPts into volPts coordinate frame.
    %	trans is a vector containing scalings of the x,y,and z axes 
    %		such that elecPts*trans is at the same scale as volPts
    
    % subtracting the mean, centering on zero
    orig_elecPts = elecPts;
    orig_volPts = volPts;
    volPts = volPts - (mean(volPts)'*ones(1,length(volPts)))';
    elecPts = elecPts - (mean(elecPts)'*ones(1,length(elecPts)))';
    
    H = elecPts' * volPts;
    [U,S,V] = svd(H);

    mirrorFixer = [ 1 0 0; 0 1 0; 0 0 det(U*V);];

    rot = V*mirrorFixer*(U');

    if det(rot)< 0
        disp('Warning: rotation matrix has -1 determinant, This should not have happened. Hmmm.');
    end
    
    % apply transformation to original matrices
    elecPts = (rot*(orig_elecPts'))';
    trans = mean(orig_volPts) - mean(elecPts);
end

function isGood = isElpFileGood(elpFile)
    %function isGood = isElpFileGood(elpFile)

    V = mrC_readELPfile(elpFile,true,[-2 1 3]);

    F = mrC.EGInetFaces(false);

    V(:,1:2) = mrC.FlattenZ(V);
    V(:,3) = 0;

    [isIntersect badPoint ua ub] = mrC.FindMeshSelfIntersections(V(1:128,1:2),F);

    isGood = ~isIntersect;
end

function strct = convertElp(x,y,cs,sn,Nx)
    % convert elp c.f. (CTF) to subject centered c.f. (NEUROMAG), i.e. LPA on -x, RPA on x, NAS
    % on y, origin on LPA - RPA line, but only approx between LPA and RPA.
    strct.x = x * cs - y * sn - Nx * cs;
    strct.y = x * sn + y * cs;
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


