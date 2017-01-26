function mrC_moveELPfile(subjid,elpPath)
% Create fake elp-file by interpolating data from an existing elp-file 
% onto another subjects low-density MNE scalp mesh.  Wrote this to make
% elp-files for NIH heads.  Try to find an elp file where the original 
% sensor cloud has similar shape to the target head, and the transformed
% fiducials end up roughly in the desired place.
%
% mrC_moveELPfile(subjid,[elpPath])
% subjid  = subject ID string, e.g. 'skeri0001'
% elpPath = optional path to elp-file to move to chosen subject
%           elpPath is expected to be part of a mrCurrent project
%

if ~exist('subjid','var') || isempty(subjid)
	help mrC_moveELPfile
	error('Specify a subject to create an elp-file for.')
end
if ~exist('elpPath','var') || isempty(elpPath)
	[elpFile,elpPath] = uigetfile('*.elp','Pick a Polhemus elp-file');
	if isnumeric(elpFile)
		return
	end
	elpPath = [elpPath,elpFile];
end
[mrCproj,elpFile] = fileparts(elpPath);
mrCproj = fileparts(mrCproj);										% drop the 'Polhemus'
regFile = fullfile(mrCproj,'_MNE_','elp2mri.tran');
[mrCproj,elpSubj] = fileparts(mrCproj);						% get the subjid for the elp-file 

FSdir = fullfile(getpref('mrCurrent','AnatomyFolder'),'FREESURFER_SUBS',[subjid,'_fs4'],'bem');
bemFile = fullfile(FSdir,[subjid,'_fs4-bem.fif']);
fidFile = fullfile(FSdir,[subjid,'_fiducials.txt']);

sortFlag = true;
xfmFlag = false;
swapDim = [-2 1 3];		% ALS to RAS
[Ps,Name,Type,Pf,kSort] = mrC_readELPfile(elpPath,sortFlag,xfmFlag,swapDim);
ns = size(Ps,1);
nf = size(Pf,1);

sensorHeight = 0.009;		% (m)

% CHECK FOR HALVED FIDUCIALS
mid = 'mrCurrent:moveELP';
if exist(fidFile,'file')
	F = load('-ascii',fidFile);
	F = F([3 1 2],:) * 1e-3;
	rat = sqrt(sum((Pf([2 3 1],:)-Pf).^2,2)) ./ sqrt(sum((F([2 3 1],:)-F).^2,2));
	fprintf('\nfiducial/sensor scale = %0.2f %0.2f %0.2f\n',rat)
else
	warning(mid,'subject %s has no fiducials file!',subjid)
	F = [];
	rat = sqrt(sum(Pf(2:3,:).^2,2)) ./ (sqrt(sum(Ps([49 113],:).^2,2))-sensorHeight);
	fprintf('\nfiducial/sensor scale = %0.2f %0.2f\n',rat)
end
if median(rat) < 0.7
	warning(mid,'halved fiducial scaling???')
	Pf = Pf*2;
	Pf(:,2) = Pf(:,2) - Pf(1,2)/2;
end

% TRANSFORM SENSORS & FIDUCIALS TO THEIR OWN HEAD
if exist(regFile,'file')
	regXfm = load('-ascii',regFile)';		% offsets in mm.  after transpose, last col = [0;0;0;1]
	Ps = [ Ps, repmat(1e-3,ns,1) ] * regXfm(:,1:3);
	Pf = [ Pf, repmat(1e-3,nf,1) ] * regXfm(:,1:3);
else
	warning(mid,'registration file %s doesn''t exist.',regFile)
end

% LOAD BEM SHELLS.  1=scalp, 2=outer skull, 3=inner skull.  brain-centered RAS coords (m)
BEM = mne_read_bem_surfaces( bemFile );
fprintf('\n')

% GROSS REGISTRATIONS TO NEW HEAD
BEMmin = min(BEM(1).rr);
BEMmax = max(BEM(1).rr);
if ~strcmp(subjid,elpSubj)
	% RIGID
	% rotate
	if ~isempty(F)
		% roll
% 		Ry = atan( (F(3,1)-F(2,1)) / (F(3,3)-F(2,3)) ) - atan( (Pf(3,1)-Pf(2,1)) / (Pf(3,3)-Pf(2,3)) );
% 		disp([ atan( -(F(3,3)-F(2,3)) / (F(3,1)-F(2,1)) ) , atan( -(Pf(3,3)-Pf(2,3)) / (Pf(3,1)-Pf(2,1)) ) ]*180/pi)
		Ry = atan( -(F(3,3)-F(2,3)) / (F(3,1)-F(2,1)) ) - atan( -(Pf(3,3)-Pf(2,3)) / (Pf(3,1)-Pf(2,1)) );
		fprintf('roll      = %0.1f deg\n',Ry*180/pi)
		sinRy = sin(Ry);
		cosRy = cos(Ry);
		RotRy = [ cosRy sinRy; -sinRy cosRy ];
		Ps(:,[3 1]) = Ps(:,[3 1]) * RotRy;
		Pf(:,[3 1]) = Pf(:,[3 1]) * RotRy;
		% pitch
		Rx = atan( (F(1,3)-mean(F(2:3,3))) / (F(1,2)-mean(F(2:3,2))) ) - atan( (Pf(1,3)-mean(Pf(2:3,3))) / (Pf(1,2)-mean(Pf(2:3,2))) );
		fprintf('pitch     = %0.1f deg\n',Rx*180/pi)
		sinRx = sin(Rx);
		cosRx = cos(Rx);
		RotRx = [ cosRx sinRx; -sinRx cosRx ];
		Ps(:,2:3) = Ps(:,2:3) * RotRx;
		Pf(:,2:3) = Pf(:,2:3) * RotRx;
	end
	PsMin = min(Ps);
	PsMax = max(Ps);
	% translate
	tXYZ = (PsMax+PsMin)/2 - (BEMmax+BEMmin)/2;
	tXYZ(3) = Pf(1,3)-F(1,3);								% level nasions
	fprintf('translate = [ %0.1f, %0.1f, %0.1f ] mm\n',tXYZ*1e3)
	Ps = Ps - repmat(tXYZ,ns,1);
	Pf = Pf - repmat(tXYZ,nf,1);
	PsMin = min(Ps);
	PsMax = max(Ps);
	% NON-RIGID
	Ps2 = Ps;
	Pf2 = Pf;
	% scaling
	sXYZ = (BEMmax-BEMmin+2*sensorHeight) ./ (PsMax-PsMin);
	sXYZ(3) = mean(sXYZ(1:2));
	fprintf('scale     = [ %0.2f, %0.2f, %0.2f ] x\n',sXYZ)
	sXYZ = diag(sXYZ);
	Ps2 = Ps2 * sXYZ;
	Pf2 = Pf2 * sXYZ;
	PsMin = min(Ps2);
	PsMax = max(Ps2);
	% translation
	tXYZ = (PsMax+PsMin)/2 - (BEMmax+BEMmin)/2;
	tXYZ(3) = PsMax(3)-BEMmax(3)-sensorHeight;		% align tops
	fprintf('translate = [ %0.1f, %0.1f, %0.1f ] mm\n',tXYZ*1e3)
	Ps2 = Ps2 - repmat(tXYZ,ns,1);
	Pf2 = Pf2 - repmat(tXYZ,nf,1);
% 	PsMin = min(Ps2);
% 	PsMax = max(Ps2);
else
	Ps2 = Ps;
	Pf2 = Pf;
end

% MAP SCALP RADIUS vs azimuth & elevation
[theta,phi,rho] = cart2sph( BEM(1).rr(:,1), BEM(1).rr(:,2), BEM(1).rr(:,3) );		% theta [-pi,pi], phi [-pi/2,pi/2]
Theta = linspace(-pi,pi,90);
Phi   = linspace(-pi/2,pi/2,45);
[ThetaGrid,PhiGrid] = meshgrid(Theta,Phi);
RhoGrid = griddata( theta, phi, rho, ThetaGrid, PhiGrid, 'v4' );		% linear & cubic yield NaNs, nearest & v4 don't.

% INTERPOLATE SENSOR & FIDUCIAL RADII ON SCALP MAP
% could add sensorHeight to RhoGrid for Ps2, but going to expand using sensor mesh VertexNormals instead
[Ps2(:,1),Ps2(:,2),Ps2(:,3)] = cart2sph(Ps2(:,1),Ps2(:,2),Ps2(:,3));
[Pf2(:,1),Pf2(:,2),Pf2(:,3)] = cart2sph(Pf2(:,1),Pf2(:,2),Pf2(:,3));
Ps2(:,3) = interp2( ThetaGrid, PhiGrid, RhoGrid, Ps2(:,1), Ps2(:,2), 'cubic' );		% nearest,linear,spline,cubic
Pf2(:,3) = interp2( ThetaGrid, PhiGrid, RhoGrid, Pf2(:,1), Pf2(:,2), 'cubic' );		% just for fun, not going to use this.


fig = findobj('Type','figure','Tag','mrC_moveELPfile');
if isempty(fig)
	fig = figure('tag','mrC_moveELPfile','MenuBar','none'); %,'defaultLineLineStyle','none','defaultLineMarker','.');
	colormap(summer(256))
else
	fig = fig(1);
	clf(fig)
	figure(fig)
end

ax = [ subplot(121) subplot(122) ];
Hdot = zeros(1,5);

% axes(ax(2))
imagesc(Theta*180/pi,Phi*180/pi,RhoGrid)
Hdot(4) = line(   theta*180/pi,     phi*180/pi,'Color','r','MarkerSize',12);
Hdot(5) = line(Ps2(:,1)*180/pi,Ps2(:,2)*180/pi,'Color','c','MarkerSize',16);
set(ax(2),'XLim',[-180 180],'XTick',-180:45:180,'YLim',[-90 90],'YTick',-90:45:90)
xlabel('Azimuth (deg)')
ylabel('Elevation (deg)')
title('Radius (m)')
colorbar

[Ps2(:,1),Ps2(:,2),Ps2(:,3)] = sph2cart(Ps2(:,1),Ps2(:,2),Ps2(:,3));
[Pf2(:,1),Pf2(:,2),Pf2(:,3)] = sph2cart(Pf2(:,1),Pf2(:,2),Pf2(:,3));

axes(ax(1))
HP1 = patch( 'Vertices',BEM(1).rr,'Faces',BEM(1).tris,'FaceColor',[1 0.5 0.5],'EdgeColor','r','FaceAlpha',2/3);	%,'facelighting','gouraud');
Hdot(1) = line(Pf(:,1),Pf(:,2),Pf(:,3),'Color','g','MarkerSize',32);
Hdot(2) = line(Ps(:,1),Ps(:,2),Ps(:,3),'Color','b','MarkerSize',16);
if ~isempty(F)
	Hdot(3) = line(F(:,1),F(:,2),F(:,3),'Color','m','MarkerSize',48);
end
HP2 = patch('Vertices',Ps2,'Faces',mrC_EGInetFaces(true),'FaceColor','none','EdgeColor','c','Marker','.','MarkerSize',24);
N = get(HP2,'VertexNormals');					% inward normals
N = N ./ repmat(sqrt(sum(N.^2,2)),1,3);	% make 'em unit
Ps2 = Ps2-N*sensorHeight;						% expand
set(HP2,'Vertices',Ps2)
k = [1:3,1];
line(Pf2(k,1),Pf2(k,2),Pf2(k,3),'Color','y','MarkerSize',24,'LineStyle','-','marker','.')
Pf2 = F;												% Replace transformed w/ real fiducials

pad = [-1 1]*0.030;
set(ax(1),'DataAspectRatio',[1 1 1],'View',[90 0],'YLim',[BEMmin(1),BEMmax(1)]+pad,'YLim',[BEMmin(2),BEMmax(2)]+pad,'ZLim',[BEMmin(3),BEMmax(3)]+pad)
xlabel('Right (m)')
ylabel('Anterior (m)')
zlabel('Superior (m)')
title([subjid,' <-- ',elpSubj,' (',elpFile,')'],'Interpreter','none')

set(Hdot(ishandle(Hdot)),'LineStyle','none','marker','.')

if true
	set(ax(1),'DefaultLightColor',[1 1 0.75])
	light('Position',[ 0.512 0 0.256])
	light('Position',[-0.512 0 0.256])
	set(HP1,'EdgeColor',get(HP1,'FaceColor'),'FaceLighting','gouraud','EdgeLighting','gouraud')
end

HM = [ uimenu(fig,'label','File'), uimenu(fig,'label','View') ];
uimenu(HM(2),'label','Left'  ,'callback',@SetView)
uimenu(HM(2),'label','Right' ,'callback',@SetView)
uimenu(HM(2),'label','Front' ,'callback',@SetView)
uimenu(HM(2),'label','Back'  ,'callback',@SetView)
uimenu(HM(2),'label','Top'   ,'callback',@SetView)
uimenu(HM(2),'label','Bottom','callback',@SetView)

uimenu(HM(1),'label','Save','callback',@SaveELP)

% revert to ALS coords
Ps2 = [ Ps2(:,2), -Ps2(:,1), Ps2(:,3) ];
Pf2 = [ Pf2(:,2), -Pf2(:,1), Pf2(:,3) ];

disp('done')
return

	function SetView(varargin)
		switch get(varargin{1},'label')
		case 'Left'
			set(ax(1),'view',[-90 0])
		case 'Right'
			set(ax(1),'view',[90 0])
		case 'Front'
			set(ax(1),'view',[180 0])
		case 'Back'
			set(ax(1),'view',[0 0])
		case 'Top'
			set(ax(1),'view',[0 90])
		case 'Bottom'
			set(ax(1),'view',[0 -90])
		end
	end

	function SaveELP(varargin)
		% put back in original order
		[junk,kOrig] = sort(kSort);
		mrC_saveELPfile(Pf2,Ps2(kOrig,:),Type(kOrig),Name(kOrig))
		set(varargin{1},'Enable','off')
	end

end
