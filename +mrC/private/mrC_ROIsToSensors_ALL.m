function mrC_ROIsToSensors(mrCprojDir,subjID)
% Project unit ROI activations normal to cortical surface to the scalp 
% using the *-fwd.fif and *.elp files in the mrCurrent project structure.
%
% usages: mrC_ROIsToSensors
%         mrC_ROIsToSensors(mrCurrentProjectDirectory)
%         mrC_ROIsToSensors(mrCurrentProjectDirectory,subjecID)

% mrC_ROIsToSensors('X:\data\4D2\xiao\Bino_092010\MrCurrentProject','skeri0129')


if nargin < 1
	mrCprojDir = uigetdir(pwd,'Choose mrCurrent project directory');
	if isnumeric(mrCprojDir)
		return
	end
end

if nargin < 2
	subjIDs = DirCell( mrCprojDir, 'folders' );
	choice = menu('Choose subject:',subjIDs);
	if choice == 0
		return
	end
	subjID = subjIDs{choice};
end


useDefaultFlat = true;		% use digitized EGI diagram instead of flattened elp-file data
if useDefaultFlat
	EGI = load('defaultFlatNet.mat');		% 128x2 array "xy"
	pFlat = EGI.xy;
	nSensor = size(pFlat,1);
	elpFile = 'EGI Map';
	pSensor = [ pFlat, zeros(nSensor,1) ];
else
	elpDir = fullfile( mrCprojDir, subjID, 'Polhemus' );
	elpFiles = dir( fullfile( elpDir, '*.elp' ) );
	nElp = numel( elpFiles );
	if nElp == 0
		error('No elp-files in %s',elpDir)
	elseif nElp > 1
		warning('Multiple elp-files in %s.\nUsing newest.',elpDir)
		[junk,iElp] = max( [elpFiles.datenum] );
		elpFile = elpFiles(iElp).name;
	else
		elpFile = elpFiles(1).name;
	end

	nSensor = 128;
	pSensor = mrC_readELPfile(fullfile(elpDir,elpFile),true,true,[-2 1 3]);
	pFlat = mrC_flattenELPdata( pSensor(1:nSensor,:) );
end
xyzMin = min(pSensor(1:nSensor,:));
xyzMax = max(pSensor(1:nSensor,:));
xyMin = min(pFlat);
xyMax = max(pFlat);
xyzPad = [-1 1]*(0.05*max(xyzMax-xyzMin));
xyPad  = [-1 1]*(0.05*max( xyMax- xyMin));

Fwd = mrC_getFwdMatrix(fullfile(mrCprojDir,subjID,'_MNE_',[subjID,'-fwd.fif']),subjID);
dFwd = size(Fwd);
nSource = 20484;
if ~all( dFwd == [nSensor nSource] )
	warning('Unexpected forward matrix dimensions %d x %d, not %d x %d.',dFwd(1),dFwd(2),nSensor,nSource)
	[nSensor,nSource] = deal(dFwd(1),dFwd(2));
end

S = zeros(nSource,1);		% source vector

ROIlist = dir( fullfile(getpref('mrCurrent','AnatomyFolder'),subjID,'Standard','meshes','ROIs','*.mat') );
anatDir = getpref('mrCurrent','AnatomyFolder');
axView = [0 0];

Hfig   = figure('Name',mrCprojDir,'MenuBar','none');
Hax    = axes('DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'ZTick',[],'Box','on');
Hpatch = patch('Vertices',[pFlat,zeros(nSensor,1)],'Faces',EGInetFaces(false),'FaceVertexCData',Fwd*S,'FaceColor','interp','EdgeColor','k','MarkerSize',16);
Htitle = title('');
ylabel(elpFile,'Interpreter','none')
xlabel(subjID)
colorbar

uimenu(Hfig,'Label','Select ROI(s)','Callback',@ROIcallback)
Hopts = uimenu(Hfig,'Label','Options');
Hcmaps = uimenu(Hopts,'Label','ColorMaps');
Hcmap = [ ...
	uimenu(Hcmaps,'Label','Jet','Checked','on','Callback',@CmapCallback) ...
	uimenu(Hcmaps,'Label','FlippedNegJet','Callback',@CmapCallback) ...
	uimenu(Hcmaps,'Label','BlueWhiteRed','Callback',@CmapCallback) ...
	];
Hshows = uimenu(Hopts,'Label','Show');
	uimenu(Hshows,'Label','Lines','Checked','on','Callback',@ShowCallback)
	uimenu(Hshows,'Label','Dots','Callback',@ShowCallback)
Hviews = uimenu(Hopts,'Label','View');
Hview = [ ...
	uimenu(Hviews,'Label','Flat','Checked','on','Callback',@DimCallback) ...
	uimenu(Hviews,'Label','3D','Callback',@DimCallback) ...
	uimenu(Hviews,'Label','Top','Callback',@ViewCallback,'Separator','on') ...
	uimenu(Hviews,'Label','Left','Callback',@ViewCallback) ...
	uimenu(Hviews,'Label','Right','Callback',@ViewCallback) ...
	uimenu(Hviews,'Label','Front','Callback',@ViewCallback) ...
	uimenu(Hviews,'Label','Back','Checked','on','Callback',@ViewCallback) ...
	];

CmapCallback(Hcmap(1))
DimCallback(Hview(1))




return

	function ROIcallback(varargin)
% 		iSel = buttondlg('Pick ROIs',{ROIlist.name});		% iSel = double of zeros & ones, empty if cancelled, error if dialog closed
% 		if isempty(iSel)
% 			return
% 		else
% 			iSel = find(iSel);
% 		end
		[iSel,OK] = listdlg('PromptString','Pick ROIs','ListString',{ROIlist.name},'Name','mrC_ROIsToSensors');		% iSel,OK both type double
		if OK == 0
			return
		end
		nROI = numel(iSel);
		ROIs = {ROIlist(iSel).name};
		S(:) = 0;
		for i = 1:nROI
			roi = load( fullfile(anatDir,subjID,'Standard','meshes','ROIs',ROIs{i}) );
			S(roi.ROI.meshIndices) = 1;
		end
		[junk,ROIs] = cellfun(@fileparts,ROIs,'UniformOutput',false);
		set(Hpatch,'FaceVertexCData',Fwd*S)
		set(Hax,'CLim',[-1 1]*max(abs(get(Hpatch,'FaceVertexCData'))))
		set(Htitle,'String',[sprintf('%s, ',ROIs{1:nROI-1}),ROIs{nROI}])
	end

	function CmapCallback(Hcaller,varargin)
		nCmap = 256;
		switch get(Hcaller,'Label')
		case 'Jet'
			set(Hfig,'Colormap',jet(nCmap))
		case 'FlippedNegJet'
			set(Hfig,'Colormap',flipdim(1-jet(nCmap),1))
		case 'BlueWhiteRed'
			x = [0;0.5;1];
			xi = linspace(0,1,nCmap)';
			set(Hfig,'Colormap',[interp1(x,[0;1;1],xi),interp1(x,[0;1;0],xi),interp1(x,[1;1;0],xi)])
		end
		set(Hcaller,'Checked','on')
		set(setdiff(Hcmap,Hcaller),'Checked','off')
	end

	function ShowCallback(Hcaller,varargin)
		isChecked = strcmp(get(Hcaller,'Checked'),'on');
		switch get(Hcaller,'Label')
		case 'Lines'
			if isChecked
				set(Hpatch,'LineStyle','none')
				set(Hcaller,'Checked','off')
			else
				set(Hpatch,'LineStyle','-')
				set(Hcaller,'Checked','on')
			end
		case 'Dots'
			if isChecked
				set(Hpatch,'Marker','none')
				set(Hcaller,'Checked','off')
			else
				set(Hpatch,'Marker','.')
				set(Hcaller,'Checked','on')
			end
		end
	end

	function DimCallback(Hcaller,varargin)
		switch get(Hcaller,'Label')
		case 'Flat'
			set(Hpatch,'Vertices',[pFlat,zeros(nSensor,1)])
			set(Hax,'XLim',[xyMin(1) xyMax(1)]+xyPad,'YLim',[xyMin(2) xyMax(2)]+xyPad,'ZLim',[-1 1],'View',[0 90])
			set(Hview(3:7),'enable','off')
		case '3D'
			set(Hpatch,'Vertices',pSensor(1:nSensor,:))
			set(Hax,'XLim',[xyzMin(1) xyzMax(1)]+xyzPad,'YLim',[xyzMin(2) xyzMax(2)]+xyzPad,'ZLim',[xyzMin(3) xyzMax(3)]+xyzPad,'View',axView)
			set(Hview(3:7),'enable','on')
		end
		set(Hcaller,'Checked','on')
		set(setdiff(Hview(1:2),Hcaller),'Checked','off')
	end

	function ViewCallback(Hcaller,varargin)
		switch get(Hcaller,'Label')
		case 'Top'
			axView = [0 90];
		case 'Left'
			axView = [-90 0];
		case 'Right'
			axView = [90 0];
		case 'Front'
			axView = [180 0];
		case 'Back'
			axView = [0 0];
		end
		set(Hax,'View',axView)
		set(Hcaller,'Checked','on')
		set(setdiff(Hview(3:7),Hcaller),'Checked','off')
	end

end





