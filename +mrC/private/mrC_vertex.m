function mrC_vertex(mrCprojDir)

Hfig = figure('defaultuicontrolunits','normalized','position',round(get(0,'screensize')*[zeros(2,4);0.1 0 0.8 0;0 0.4 0 0.5]));
Hproj = uicontrol('position',[0.10 0.90 0.36 0.05],'style','text','string','');%,'enable','inactive');
Hnew  = uicontrol('position',[0.46 0.90 0.18 0.05],'style','pushbutton','string','New Project','callback',@loadNew);
Hdom  = uicontrol('position',[0.64 0.90 0.18 0.05],'style','togglebutton','string','Toggle Domain','callback',@toggleDomain);
Hcnd  = uicontrol('position',[0.10 0.85 0.18 0.05],'style','popup','string',{''},'callback',@updateCnd);
Hinv  = uicontrol('position',[0.28 0.85 0.18 0.05],'style','popup','string',{''},'callback',@updateInv);
Hsbj  = uicontrol('position',[0.46 0.85 0.18 0.05],'style','popup','string',{''},'callback',@updateSbj);
Hroi  = uicontrol('position',[0.64 0.85 0.18 0.05],'style','popup','string',{''},'callback',@updateROI);
Hf1   = uicontrol('position',[0.85 0.90 0.05 0.05],'style','edit','string','0','callback',@updateFreq);
Hf2   = uicontrol('position',[0.85 0.85 0.05 0.05],'style','edit','string','0','callback',@updateFreq);
        uicontrol('position',[0.90 0.90 0.05 0.05],'style','text','string','f1')
        uicontrol('position',[0.90 0.85 0.05 0.05],'style','text','string','f2')
Hax = axes('position',[0.1 0.1 0.85 0.65],'xgrid','on','ygrid','on','box','on',...
				'defaulttextunits','normalized','defaulttexthorizontalalignment','right','defaulttextverticalalignment','top');
Hx = xlabel('');
Hy = ylabel('');
Ht = title('');
Hmean = text('parent',Hax,'position',[0.98 0.98 0],'string','mean','color','b','fontweight','bold');
Hsvd  = text('parent',Hax,'position',[0.98 0.93 0],'string','svd1','color','r','fontweight','bold');
Hfreq = text('parent',Hax,'position',[0.98 0.98 0],'string',    '','color','b','fontweight','bold');

[t,f,EEG,InvM,roiDir,cndFiles,invFiles,sbjNames,roiList,v] = deal([]);
[iCnd,iInv,iSbj,iROI,nf1,nf2,iFreq] = deal(0);

if nargin == 0
	mrCprojDir = '';
	loadNew
else
	loadNew(mrCprojDir)
end


return

	function updateCnd(obj,event)
		iCnd = get(obj,'value');
		EEG = load(fullfile(mrCprojDir,sbjNames{iSbj},'Exp_MATL_HCN_128_Avg',cndFiles{iCnd}));
		t = (1:EEG.nT)'*EEG.dTms;
		f = (0:(EEG.nFr-1))'*EEG.dFHz;
		if nargin == 2
			toggleDomain(Hdom)
		end
	end

	function updateInv(obj,event)
		iInv = get(obj,'value');
		InvM = mrC_readEMSEinvFile(fullfile(mrCprojDir,sbjNames{iSbj},'Inverses',invFiles{iInv})) * 1e6;		% convert to pAmp/mm2
		if nargin == 2
			updatePlot
		end
	end

	function updateSbj(obj,event)
		iSbj = get(obj,'value');
		updateCnd(Hcnd)
		updateInv(Hinv)
		if ispref('mrCurrent','AnatomyFolder')
			roiDir = fullfile(getpref('mrCurrent','AnatomyFolder'),sbjNames{iSbj},'Standard','meshes','ROIs');
		elseif ispc
			roiDir = fullfile('X:','anatomy',sbjNames{iSbj},'Standard','meshes','ROIs');
		elseif ismac
			roiDir = fullfile('/Volumes/MRI','anatomy',sbjNames{iSbj},'Standard','meshes','ROIs');
		else
			roiDir = fullfile('/raid/MRI','anatomy',sbjNames{iSbj},'Standard','meshes','ROIs');
		end
		roiFiles = load(fullfile(mrCprojDir,sbjNames{iSbj},'_mrC_','SbjROIFiles.mat'));					% 1 variable: tSbjROIFiles
		curROIs = get(Hroi,'string');
		if isfield(roiFiles,'tSbjROIs')
			h = roiFiles.tSbjROIs.Hem == 3;
			if any(h)
				roiList = reshape( cat( 1, strcat(roiFiles.tSbjROIs.Name(h),'-L.mat'), strcat(roiFiles.tSbjROIs.Name(h),'-R.mat') ), 1, 2*sum(h) );
			else
				roiList = {};
			end
			h = roiFiles.tSbjROIs.Hem == 1;
			if any(h)
				roiList = cat( 2, roiList, strcat(roiFiles.tSbjROIs.Name(h),'-L.mat') );
			end
			h = roiFiles.tSbjROIs.Hem == 2;
			if any(h)
				roiList = cat( 2, roiList, strcat(roiFiles.tSbjROIs.Name(h),'-R.mat') );
			end
		else
			roiList = roiFiles.tSbjROIFiles;
		end
		match = strcmp(roiList,curROIs{get(Hroi,'value')});
		if any(match)
			iROI = find(match);
		else
			iROI = 1;
		end
		set(Hroi,'string',roiList,'value',iROI)
		updateROI(Hroi)
		toggleDomain(Hdom)
	end

	function updateROI(obj,event)
		iROI = get(obj,'value');
		v = load([roiDir,filesep,roiList{iROI}]);		% 1 variable: ROI structure
		v.ROI.meshIndices = unique(v.ROI.meshIndices);
		v.ROI.meshIndices( v.ROI.meshIndices==0 ) = [];
		set(Ht,'string',sprintf('%d vertices',numel(v.ROI.meshIndices)))
		if nargin == 2
			updatePlot
		end
	end

	function toggleDomain(obj,event)
		% sets axes limits & labels
		if get(obj,'value') == 0
			set(Hax,'xlim',[0 ceil(t(EEG.nT)/10)*10],'dataaspectratiomode','auto')
			set(Hx,'string','ms')
			set(Hy,'string','pA mm^{-2}')
			set(Hfreq,'visible','off')
			set([Hmean Hsvd],'visible','on')
		else
			set(Hax,'xlimmode','auto','dataaspectratio',[1 1 1])
			set(Hx,'string','Real')
			set(Hy,'string','Imag')
			set([Hmean Hsvd],'visible','off')
			set(Hfreq,'visible','on')
		end
		updatePlot
	end

	function updateFreq(obj,event)
		try
			nTest = eval(['[',get(Hf1,'string'),',',get(Hf2,'string'),']']);
			iTest = 1 + nTest * [ EEG.i1F1; EEG.i1F2 ];
			if (mod(iTest,1)==0) && (iTest>=1) && (iTest<=EEG.nFr)
				iFreq = iTest;
				set(Hfreq,'string',sprintf('%g Hz',f(iFreq)))
			else
				nf1 = 0;
				nf2 = 0;
				iFreq = 1;
				error('invalid frequency combination')
			end
		catch
			set(Hf1,'string',nf1)
			set(Hf2,'string',nf2)
			set(Hfreq,'string',sprintf('%g Hz',f(iFreq)))
		end
		updatePlot
	end

	function updatePlot
		% updates line objects in axes
		delete(findobj(Hax,'type','line'))
		k = 1:max(EEG.nCh,128);
		if get(Hdom,'value') == 0
			y = EEG.Wave(:,k)*InvM(:,v.ROI.meshIndices);
			[U,S,V] = svd(y,'econ');
			line(t,y,'parent',Hax,'linewidth',1,'color',[0.25 0.5 0.25])
			line(t,mean(y,2),'parent',Hax,'linewidth',2.5,'color','b')
			line(t,U(:,1)*S(1,1)*mean(abs(V(:,1)))*sign(sum(V(:,1))),'parent',Hax,'linewidth',2.5,'color','r')
		else
			% note: mrCurrent doesn't plot f=0 point, mrC_vertex includes it
			line(EEG.Cos(iFreq,k)*InvM(:,v.ROI.meshIndices),EEG.Sin(iFreq,k)*InvM(:,v.ROI.meshIndices),'linestyle','none','marker','.','markersize',16)
			line(0,0,'linestyle','none','marker','o','color','k','markerfacecolor','w','linewidth',1.5,'markersize',8)
		end
	end
	
	function loadNew(varargin)
		if (nargin == 0) || ishandle(varargin{1}(1))
			mrCprojDir = uigetdir(pwd,'mrCurrent project directory');
			if isnumeric(mrCprojDir)
				return
			end
		end
		sbjDirs = dir(fullfile(mrCprojDir,'skeri*'));
		sbjNames = {sbjDirs([sbjDirs.isdir]).name};
		nSbj = numel(sbjNames);
		if nSbj == 0
			error('no skeri#### subject directories in %s',mrCprojDir)
		end
		% assuming 1st subject defines conditions & inverses for all
		cndFiles = dir(fullfile(mrCprojDir,sbjNames{1},'Exp_MATL_HCN_128_Avg','Axx_*.mat'));
		cndFiles = {cndFiles.name};
		nCnd = numel(cndFiles);
		if nCnd == 0
			error('no Axx_*.mat files in %s',fullfile(mrCprojDir,sbjNames{1},'Exp_MATL_HCN_128_Avg'))
		end
		invFiles = dir(fullfile(mrCprojDir,sbjNames{1},'Inverses','*.inv'));
		invFiles = {invFiles.name};
		nInv = numel(invFiles);
		if nInv == 0
			error('no *.inv files in %s',fullfile(mrCprojDir,sbjNames{1},'Inverses'))
		end
		set(Hproj,'string',mrCprojDir)
		[iCnd,iInv,iSbj] = deal(1);
		set(Hcnd,'string',cndFiles,'value',iCnd)
		set(Hinv,'string',invFiles,'value',iInv)
		set(Hsbj,'string',sbjNames,'value',iSbj)
		updateSbj(Hsbj)
		updateFreq
	end


end
