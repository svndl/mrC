function mrC_editELPfile(elpFile)
% GUI-driven attempt to fix bad elp-files
%
% SYNTAX:	mrC_editELPfile([elpFileStr])

% © 2009 Spero Nicholas
% The Smith-Kettlewell Eye Research Institute

if nargin == 0
	[elpFile,elpPath] = uigetfile('*.elp','Pick a Polhemus elp-file');
	if isnumeric(elpFile)
		return
	end
else
	elpPath = '';
end

% --------------------- read elpFile -----------------------------

[cart3D,name,type,anat3D,kSort] = mrC_readELPfile([elpPath,elpFile],true,true,[-2 1 3]);
ne = size(cart3D,1);

%--------------------------------- flatten ---------------------------------------

oSphere = fminsearch( @(o) mrC_SphereObjFcn(o,cart3D,ne), median(cart3D) );		% best-fitting sphere origin
% oSphere = fminsearch(@originFcn,median(cart3D));		% best-fitting sphere origin
% 
% 	function fval = originFcn(o)
% 		dp = cart3D - repmat(o,ne,1);
% 		u = dp ./ repmat( hypot( hypot( dp(:,1), dp(:,2) ), dp(:,3) ), 1, 3 );
% 		fval = norm(u*(u(:)\dp(:))-dp,'fro');
% 	end

polar3D = zeros(ne,3);		% [ theta, phi, radius ]
[polar3D(:,1),polar3D(:,2),polar3D(:,3)] = cart2sph( cart3D(:,1)-oSphere(1), cart3D(:,2)-oSphere(2), cart3D(:,3)-oSphere(3) );

cart2D = zeros(ne,2);
eFlat = 0.6;					% flattening exponent
[cart2D(:,1),cart2D(:,2)] = pol2cart( polar3D(:,1), (1-sin(polar3D(:,2))).^eFlat );


%------------------------------- plot --------------------------------------------
uiWHG = [ 160 20 5 ];				% width,height,gap (pixels)
axWH = [ uiWHG*[4;0;3], 640 ];	% width, height (pixels)

fig = findobj('type','figure','tag','elp-Editor');
if isempty(fig)
	fig = figure('units','pixels','position',[50 80 [axWH(1) axWH(2)+uiWHG*[0;2;2]]+10],'tag','elp-Editor','color','k','menubar','none','Resize','off');
	UI = [...
	uicontrol('position',[5               5+uiWHG*[0;1;1] uiWHG(1:2)],'style','popup','string',name,'value',1)...
	uicontrol('position',[5+uiWHG*[1;0;1] 5+uiWHG*[0;1;1] uiWHG(1:2)],'style','pushbutton','string','Edit')...
	uicontrol('position',[5+uiWHG*[2;0;2] 5+uiWHG*[0;1;1] uiWHG(1:2)],'style','pushbutton','string','Add')...
	uicontrol('position',[5+uiWHG*[3;0;3] 5+uiWHG*[0;1;1] uiWHG(1:2)],'style','pushbutton','string','Remove')...
	uicontrol('position',[5               5 uiWHG*[2;0;1] uiWHG(2)],'style','pushbutton','string','LOAD')...
	uicontrol('position',[5+uiWHG*[2;0;2] 5 uiWHG*[2;0;1] uiWHG(2)],'style','pushbutton','string','SAVE')...
	];
	set(fig,'userdata',UI)
	ax = axes('units','pixels','position',[5 5+uiWHG*[0;2;2] axWH],'dataaspectratio',[1 1 1],'visible','off','xtick',[],'ytick',[],'ztick',[]);
else
	fig = fig(1);
	UI = get(fig,'userdata');
	set(UI([1:4,6]),'enable','on')
	figure(fig)
	ax = gca;
	cla(ax)
end

[elpPath,elpFile,elpExt] = fileparts([elpPath,elpFile]);
set(fig,'name',[elpFile,elpExt])

% mesh
pMin = min(cart2D);
pMax = max(cart2D);
set(ax,'xlim',pMin(1)+(pMax(1)-pMin(1))*[-0.05 1.05],'ylim',pMin(2)+(pMax(2)-pMin(2))*[-0.05 1.05],'view',[0 90])
P = patch('vertices',[cart2D,zeros(ne,1)],'faces',EGInetFaces(ne~=128),'facecolor','none','edgecolor',[0 0 0]+0.25,'linewidth',1);

% lines
kL = { 1:7, 8:13, 14:16, 17:20, 21:24, 25:31, 32:37, 38:42, 43:47, 48:55, 56:62, 63:67,...
		68:72, 73:80, 81:87, 88:93, 94:98, 99:106, 107:112, 113:118, 119:124, 125:126, 127:128 };
nL = numel(kL);
c = hsv(nL);
c = c ./ repmat(sum(c,2)/0.6,1,3);
L = zeros(1,nL);
for i = 1:nL
	L(i) = line(cart2D(kL{i},1),cart2D(kL{i},2),'linewidth',4,'color',c(i,:));
end

% labels
rawColor = [1 1 1];
userColor = [0 1 0];
T = zeros(1,ne);
for i = 1:ne
	T(i) = text(cart2D(i,1),cart2D(i,2),name{i});
end
set(T,'horizontalalignment','center','verticalalignment','middle',...
	'fontname','Arial','fontsize',12,'fontweight','bold','color',rawColor)

set(UI(2),'callback',@elpFileEditSensor)
set(UI(3),'callback',@elpFileAddSensor)
set(UI(4),'callback',@elpFileRemoveSensor)
set(UI(5),'callback',@elpFileLoad)
set(UI(6),'callback',@elpFileSave)

return
%============================================================================

	function elpFileEditSensor(varargin)
		ie = get(UI(1),'value');
		cart2D(ie,:) = ginput(1);
		polar3D(ie,:) = NaN;
		set(P,'vertices',[cart2D(1:ne,:),zeros(ne,1)])
		set(T(ie),'position',cart2D(ie,:),'color',userColor)
		reLine
	end

	function elpFileAddSensor(varargin)
		ie = get(UI(1),'value');
		cart2D  = [  cart2D(1:(ie-1),:);   ginput(1);  cart2D(ie:end,:) ];
		polar3D = [ polar3D(1:(ie-1),:); NaN NaN NaN; polar3D(ie:end,:) ];
		set(P,'vertices',[cart2D(1:ne,:),zeros(ne,1)])
		for ie = 1:ne
			if isnan(polar3D(ie,1))
				set(T(ie),'position',cart2D(ie,:),'color',userColor)
			else
				set(T(ie),'position',cart2D(ie,:),'color',rawColor)
			end
		end
		reLine
	end

	function elpFileRemoveSensor(varargin)
		ie = get(UI(1),'value');
		cart2D(ie,:) = [];
		polar3D(ie,:) = [];
		nv = size(cart2D,1);
		if nv < ne
			cart2D  = [  cart2D; repmat(NaN,ne-nv,2) ];
			polar3D = [ polar3D; repmat(NaN,ne-nv,3) ];
		end
		set(P,'vertices',[cart2D(1:ne,:),zeros(ne,1)])
		for ie = 1:ne
			if isnan(polar3D(ie,1))
				set(T(ie),'position',cart2D(ie,:),'color',userColor)
			else
				set(T(ie),'position',cart2D(ie,:),'color',rawColor)
			end
		end
		reLine
	end

	function reLine
		for iL = 1:nL
			set(L(iL),'xdata',cart2D(kL{iL},1),'ydata',cart2D(kL{iL},2))
		end
	end

	function elpFileLoad(varargin)
		elpEdit
	end

	function elpFileSave(varargin)
		kNaN = isnan(polar3D(1:ne,1));
		if ~any(kNaN)
			disp('You didn''t change anything')
			return
		end
		[newFile,newPath] = uiputfile('*.elp','Edited elp-file',fullfile(elpPath,[elpFile,'_Edited',elpExt]));
		if isnumeric(newFile)
			return
		end
		
		kGood = find(~kNaN);
		kEdit = find(kNaN);
		[polar3D(kEdit,1),polar3D(kEdit,2)] = cart2pol(cart2D(kEdit,1),cart2D(kEdit,2));
		polar3D(kEdit,2) = asin( 1 - polar3D(kEdit,2).^(1/eFlat) );
		
		[xi,yi,zi] = griddata(polar3D(kGood,1),polar3D(kGood,2),polar3D(kGood,3),linspace(-pi,pi,360/3+1),linspace(-pi/2,pi/2,180/2+1)','v4');
		polar3D(kEdit,3) = interp2(xi,yi,zi,polar3D(kEdit,1),polar3D(kEdit,2),'cubic');

		[cart3D(:,1),cart3D(:,2),cart3D(:,3)] = sph2cart(polar3D(1:ne,1),polar3D(1:ne,2),polar3D(1:ne,3));
		cart3D = cart3D + repmat(oSphere,ne,1);
		
		set(P,'vertices',cart3D,'facecolor','k','facealpha',0.75)
		for iL = 1:nL
			set(L(iL),'xdata',cart3D(kL{iL},1),'ydata',cart3D(kL{iL},2),'zdata',cart3D(kL{iL},3))
		end
		set(L,'visible','off')
		for ie = 1:ne
			set(T(ie),'position',cart3D(ie,:))
		end
% 		set(ax,'xlimmode','auto','ylimmode','auto','view',[0 0])
		pad = [-1 1]*0.01;	% (m)
		set(ax,'view',[0 0],...
				'xlim',[min(cart3D(:,1)),max(cart3D(:,1))]+pad,...
				'ylim',[min(cart3D(:,2)),max(cart3D(:,2))]+pad,...
				'zlim',[min(cart3D(:,3)),max(cart3D(:,3))]+pad)
% 		set(fig,'menubar','figure')

		% put back in original order
		[junk,kOrig] = sort(kSort);
		kNaN = kNaN(kOrig);
		cart3D  = cart3D(kOrig,:);
		name = name(kOrig);
		type = type(kOrig);
		% put back in ALS coordinates - quick way, keep fiducial alignment if done
		cart3D(:,1:2) = [cart3D(:,2),-cart3D(:,1)];
		anat3D(:,1:2) = [anat3D(:,2),-anat3D(:,1)];
		
		mrC_saveELPfile(anat3D,cart3D,type,name,[newPath,newFile],kNaN)

		set(UI([1:4,6]),'enable','off')
		set(fig,'KeyPressFcn',@Rotate3D)

	end

	function Rotate3D(src,evnt)
		deg = 10;						% increment (deg)
		axView = get(ax,'View');
		switch evnt.Key
		case 'rightarrow'
			axView(1) = axView(1) + deg;
		case 'leftarrow'
			axView(1) = axView(1) - deg;
		case 'uparrow'
			axView(2) = axView(2) + deg;
		case 'downarrow'
			axView(2) = axView(2) - deg;
		end
		if axView(1) > 180
			axView(1) = axView(1) - 360;
		elseif axView(1) < -180
			axView(1) = axView(1) + 360;
		end
		if axView(2) > 90
			axView(2) = 90;
		elseif axView(2) < -90
			axView(2) = -90;
		end
		set(ax,'View',axView)
	end
end

