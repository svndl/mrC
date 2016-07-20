function GUI(initPath)
    % mrC.GUI
    % 
    % Description:	mrCurrent GUI
    %% General initialization 
	disp( 'MrCurrent Version 10.1' );
	% Version commentary managed by CVS
	% Preceding version commentary available in X:\projects\pettet\mrPrototypes\mrCurrent\mrCurrent.m.

% 	error('Fix ishandle(empty) calls that don''t return false')

	% Initialize these variables here first to force outer scope
	gH = [];			% GUI handles
	gProjPN = '';	% project path name
	gProjVer = 0;
	gInvDir = '';
	gD = [];			% root of the main data structure
	gVEPInfo = []; % VEP metadata from Axx files
	gCndFiles = [];
	gSbjROIFiles = [];
% 	gCortex = [];
	gCortex = struct( 'Open', false, 'Name', '', 'InvM', [], 'InvName', '', 'sensorData', [], 'origin', [], 'FOV', [-125 125], 'dCam', 1e3 ); % ,'colors', []
	gIsPivotOn = false;	% flag for pivoting
	gChartFs = [];			% structure of chart fields
	gChartL = [];
	gOptFs = [];			% structure of option fields
	gOptL = [];
	gCompFieldNms = [];	% since readable harmonic component expressions don't make good struct field names.
	gSPHs = [];
	gCurs = [];
	gCalcItems = [];
	gCalcItemOrder = [];
	gGroups = [];

	mrC_Init
% 	mrC_InitPivotFieldStructs;
	if nargin >= 1
		mrC_ProjectNew_CB(initPath)
	end

	function mrC_Task_DumpGlobals
		tGlobals = { 'gProjPN', 'gVEPInfo', 'gD', 'gChartFs', 'gChartL', 'gOptFs', 'gOptL', 'gCurs', 'gSbjROIFiles', 'gCortex', 'gCalcItems', 'gCalcItemOrder', 'gGroups', 'gH' };
		for i = 1:numel( tGlobals )
			assignin( 'base', tGlobals{i}, eval( tGlobals{i} ) )
		end
	end
	
	function mrC_Init
		ghMrCurrentGUI = findtag( 'mrC_GUI' );	% look for existing GUI;
		if ~isempty( ghMrCurrentGUI )		% if it already exists...
			figure( ghMrCurrentGUI );		% use it...
			return;							% and stop here.
		end
		% if we get here, start building new GUI
		gH = mrC_BuildGUI;
	
		set( gH.Figure, 'ResizeFcn', @ResizeMrCG, 'CloseRequestFcn', @mrC_CloseGUI_CB )
		set( gH.ChartList, 'Callback', @mrC_ChartList_CB )
		set( gH.ChartPivot,'Callback', @mrC_ChartPivot_CB )
		set( gH.ItemsList, 'Callback', @mrC_ItemsList_CB )
		set( [ gH.ItemsUp, gH.ItemsDown, gH.ItemsTop, gH.ItemsFlip ], 'Callback', @mrC_ItemsArrange_CB )
		set( gH.ItemsUserEdit, 'Callback', @mrC_ItemsUserEdit_CB )
		set( gH.OptionsPivot,  'Callback', @mrC_OptionsPivot_CB )
		set( gH.OptionsList,   'Callback', @mrC_OptionsList_CB )
		set( [ gH.PlotNew, gH.PlotRevise ], 'Callback', @mrC_Plot_CB )
		set( gH.ProjectNew, 'Callback', @mrC_ProjectNew_CB )
		set( [ gH.FrameEdit, gH.MovieStartEdit, gH.MovieStopEdit ], 'Callback', @mrC_CursorEdit_CB )
		set( [ gH.FramePick, gH.MovieStartPick, gH.MovieStopPick ], 'Callback', @mrC_CursorPick_CB )
		set( [ gH.FrameDown, gH.FrameUp ], 'Callback', @mrC_CursorStep_CB )
		set( gH.MoviePlay,   'Callback', @mrC_CursorPlay_CB )
		set( gH.CursorClear, 'Callback', @mrC_CursorClear_CB )
		set( gH.CursorStep,  'Callback', @mrC_CursorStepBy_CB )
		set( [ gH.ViewP, gH.ViewA, gH.ViewL, gH.ViewR, gH.ViewD, gH.ViewV ], 'Callback', @mrC_CortexView_CB )
		set( [ gH.RotateL, gH.RotateR, gH.RotateD, gH.RotateV ], 'Callback', @mrC_CortexRotate_CB )
		set( gH.CortexPaint,   'Callback', @mrC_CortexPaint_CB )
		set( gH.CortexScalp,   'Callback', @mrC_CortexScalp_CB )
		set( gH.CortexContour, 'Callback', @mrC_CortexContour_CB )

		ConfigureTaskControls
		function ConfigureTaskControls
			tTask.ExportData    = @mrC_ExportData;
% 			tTask.ExportChartData = @mrC_ExportChartData;
			tTask.CalcItem      = @SetCalcItem;
			tTask.CalcItemOrder = @SetCalcItemOrder;
			tTask.GroupSbjs     = @GroupSbjCreate;
			tTask.PaintROIs     = @PaintROIsOnCortex;
			tTask.CortexMosaic  = @makeCortexMosaic;
% 			tTask.SpecToXL      = @SpecToXL;				%@mrC_Task_SpecToXL;
			tTask.SpecToTXT     = @SpecToTXT;			%@mrC_Task_SpecToTXT;
% 			tTask.ExportToODBC  = @ExportToODBC;		%@mrC_Task_ExportToODBC;		% get these from Mark's code
			tTask.SpoofMAxxFig  = @SpoofMAxxFig;		%@mrC_Task_SpoofMAxxFig;
			tTask.DumpGlobals   = @mrC_Task_DumpGlobals;
			tTask.TopoGUI       = @MakeTopoGUI;
			tTask.SetAnatFold   = @mrC_Task_SetAnatFold;
			set( gH.TaskPopup, 'String', fieldnames( tTask ) )
			set( gH.TaskGO, 'Callback', @mrC_Task_Go )
			function mrC_Task_Go( varargin )
				tList = get( gH.TaskPopup, 'String' );
				tVal  = get( gH.TaskPopup, 'Value' );
				if iscell( tList )
					tTask.( tList{tVal} )();
				else
					tTask.( strtok( tList(tVal,:) ) )();		% unnecessary, but why not
				end
			end
		end

		SetMessage( 'Click Project New button...', 'status' )
		drawnow
		
		[ gChartFs, gOptFs, gChartL, gOptL ] = mrC_InitPivotFieldStructs;
		UpdateChartListBox
		UpdateOptionsListBox
	end

	function mrC_CloseGUI_CB( tH, varargin )
		if ishandle( gH.CortexFigure )
			set( gH.CortexFigure, 'CloseRequestFcn', 'closereq' )
		end
		tHFigs = findobj( 'type','Figure', 'WindowButtonDownFcn', @mrC_SetPlotFocus_CB ); 
		if ~isempty( tHFigs )
			set( tHFigs, 'WindowButtonDownFcn', '' )
		end
		delete( tH )
	end

%% Pivot Functions

	function mrC_ChartList_CB( varargin )
		% set Items listbox to reflect Chart listbox status
		gIsPivotOn = false;
		gChartL.Sel = get( gH.ChartList, 'Value' );
		if isempty( gChartFs.( gChartL.Items{ gChartL.Sel } ).Items )
			set( gH.ItemsList, 'String', {}, 'Value', [], 'Max', 1, 'ListboxTop', 1, 'UserData', 'Chart' );
		else
			tFNm = gChartL.Items{ gChartL.Sel };
			tMax = 2 - ( ( gChartFs.(tFNm).Dim > 3 ) && ~gChartFs.(tFNm).pageVector );
			set( gH.ItemsList, 'ListboxTop', 1 )
			set( gH.ItemsList, 'String', gChartFs.(tFNm).Items, 'Value', gChartFs.(tFNm).Sel, 'Max', tMax, 'UserData', 'Chart' );
			set( gH.ItemsList, 'ListboxTop', min( gChartFs.(tFNm).Sel ) )
		end
		set( gH.ItemsUserEdit, 'String', '', 'enable', 'off' );
	end

	function mrC_OptionsList_CB( varargin )
		% set Items listbox to reflect Options listbox status
		gIsPivotOn = false;
		gOptL.Sel = get( gH.OptionsList, 'Value' );
		if isempty( gOptL.Sel )
			set( gH.ItemsList, 'Value', [], 'String', {}, 'Max', 1, 'ListboxTop', 1, 'UserData', 'Options' );
		else
			tFNm = gOptL.Items{ gOptL.Sel };
			set( gH.ItemsList, 'ListboxTop', 1 )
			set( gH.ItemsList, 'String', gOptFs.(tFNm).Items, 'Value', gOptFs.(tFNm).Sel, 'Max', gOptFs.(tFNm).Max, 'UserData', 'Options' );
			set( gH.ItemsList, 'ListboxTop', min( gOptFs.(tFNm).Sel ) )
			if IsOptSelUserDefined( tFNm )
				set( gH.ItemsUserEdit, 'String', GetOptSelx( tFNm, 1 ), 'enable', 'on' );
			else
				set( gH.ItemsUserEdit, 'String', '', 'enable', 'off' );
			end
		end
	end

	function mrC_ChartPivot_CB( varargin )
		% set Items listbox to pivot Chart listbox items
		gIsPivotOn = true;
		set( gH.ItemsList, 'ListboxTop', 1 )
		set( gH.ItemsList, 'Value', gChartL.Sel, 'String', gChartL.Items, 'Max', 2, 'UserData', 'Chart' )
		set( gH.ItemsList, 'ListboxTop', min( gChartL.Sel ) )
		set( gH.ItemsUserEdit, 'String', '', 'enable', 'off' );
	end

	function mrC_OptionsPivot_CB( varargin )
		% set Items listbox to pivot Options listbox items
		gIsPivotOn = true;
		set( gH.ItemsList, 'ListboxTop', 1 )
		set( gH.ItemsList, 'String', gOptL.Items, 'Value', gOptL.Sel, 'Max', 2, 'UserData', 'Options' )
		set( gH.ItemsList, 'ListboxTop', min( gOptL.Sel ) )
		set( gH.ItemsUserEdit, 'String', '', 'enable', 'off' );
	end

	function UpdateChartListBox
		tNList = numel( gChartL.Items );
		tChartList = cell(1,tNList);
		tDimNms = { 'row' 'col' 'cmp' 'page' };
		for iF = 1:tNList
			tFNm = gChartL.Items{ iF }; % get each chart field name
			gChartFs.(tFNm).Dim = iF;
			if ( gChartFs.(tFNm).Dim > 3 ) && ~gChartFs.(tFNm).pageVector && ~isempty( gChartFs.(tFNm).Sel )
				gChartFs.(tFNm).Sel = gChartFs.(tFNm).Sel( 1 ); % when when changing to page field, take first item.
			end
% 			if isempty( gChartFs.(tFNm).Items )
% 				tChartList{ iF } = [ tDimNms{ min( gChartFs.(tFNm).Dim, 4 ) } ': ' tFNm ': ' ];	% ???
% 			else
				tItemSel = gChartFs.(tFNm).Items( gChartFs.(tFNm).Sel );
				if gChartFs.(tFNm).pageVector
					if numel( tItemSel ) == numel( gChartFs.(tFNm).Items )
						tItemSel = { 'All' };
					end
				end
				tChartList{ iF } = [ tDimNms{ min( gChartFs.(tFNm).Dim, 4 ) } ': ' tFNm ': ' sprintf( '%s,', tItemSel{:} ) ];
				tChartList{ iF } = tChartList{ iF }( 1:(end-1) );
% 			end
		end
		set( gH.ChartList, 'String', tChartList );
	end

	function UpdateOptionsListBox
		% updates whole options list.  make it just do selected option?
% 		gOptFs.Colors.Sel = 1:numel( gChartFs.(gChartL.Items{3}).Sel );		% don't automatically adjust to #cmps
		tNList = numel( gOptL.Items );
		tOptionsList = cell(1,tNList);
		for iF = 1:tNList
			tFNm = gOptL.Items{ iF }; % get each chart field name
			tItemSel = GetOptSelx( tFNm );
			tOptionsList{ iF } = [ tFNm ': ' sprintf( '%s,', tItemSel{:} ) ];
			tOptionsList{ iF } = tOptionsList{ iF }( 1:(end-1) );
		end
		set( gH.OptionsList, 'String', tOptionsList )
		ConfigureCortex
% 		if gCortex.Open		% causes error with UsrDef cutoff
% 			SetCortexFigColorMap;
% 		end
	end

	function mrC_ItemsList_CB( varargin )
		switch get( gH.ItemsList, 'UserData' )
		case 'Chart'
% 			tNCmps = numel( gChartFs.(gChartL.Items{3}).Sel );
			if gIsPivotOn
				gChartL.Items = get( gH.ItemsList, 'String' );		% this is only for calls external to uicontrol CB?
			else
				tFNm = gChartL.Items{ gChartL.Sel };
				gChartFs.(tFNm).Items = get( gH.ItemsList, 'String' )';
				gChartFs.(tFNm).Sel   = get( gH.ItemsList, 'Value' );
				if strcmp( tFNm, 'Sbjs' )
					ResolveSbjROIs
				end
			end
			UpdateChartListBox
% 			if tNCmps ~= numel( gChartFs.(gChartL.Items{3}).Sel )
% 				UpdateOptionsListBox			% for color management
% 			end
		case 'Options'
			if gIsPivotOn
				gOptL.Items = get( gH.ItemsList, 'String' );
% 				UpdateOptionsListBox
			else
				tFNm = gOptL.Items{ gOptL.Sel };
				gOptFs.(tFNm).Items = get( gH.ItemsList, 'String' )';
				gOptFs.(tFNm).Sel   = get( gH.ItemsList, 'Value' );
% 				UpdateOptionsListBox
				if IsOptSelUserDefined( tFNm )
					set( gH.ItemsUserEdit, 'String', GetOptSelx( tFNm, 1 ), 'enable', 'on' );
				else
					set(gH.ItemsUserEdit, 'String', '', 'enable', 'off' );
				end
			end
			UpdateOptionsListBox
		end
	end

	function mrC_ItemsUserEdit_CB( varargin )
		tList = get( gH.ItemsList, 'String' );
		tList{ strmatch( 'UsrDef: ', tList ) } = [ 'UsrDef: ' get( gH.ItemsUserEdit, 'String' ) ];
		set( gH.ItemsList, 'String', tList );
		mrC_ItemsList_CB
	end

	function mrC_ItemsArrange_CB( tH, varargin )
		tList = get( gH.ItemsList, 'String' );
		tNAll = numel( tList );
		tiAll = ( 1:tNAll )'; % subscript of full list
		tiSel = get( gH.ItemsList, 'Value' )'; % subscripts of currently selected items
		tNSel = numel( tiSel );
		tiUnSel = setxor( tiAll, tiSel ); % subscripts of unselected items
		tiNewSel = tiSel;
		switch tH
		case gH.ItemsTop
			tiNewSel = ( 1:tNSel )';
		case gH.ItemsUp
			if any( diff( tiSel ) > 1 )	% non-contiguous, squeeze up
				tiNewSel = ( tiSel(1) : ( tiSel(1) + tNSel - 1 ) )';
			elseif min( tiSel ) > 1			% contiguous, promote by one
				tiNewSel = tiSel - 1;
			end
		case gH.ItemsDown
			if any( diff( tiSel ) > 1 )	% non-contiguous, squeeze down
				tiNewSel =  ( ( tiSel(end) - tNSel + 1 ) : -1 : tiSel(end) )';
			elseif max( tiSel ) < tNAll	% contiguous, demote by one
				tiNewSel = tiSel + 1;
			end
		case gH.ItemsFlip
			tiNewSel = flipud( tiSel(:) );
		end
		if any( tiNewSel ~= tiSel )
			tiNewUnSel = setxor( tiAll, tiNewSel );
			tNewList( tiNewSel ) = tList( tiSel );
			tNewList( tiNewUnSel ) = tList( tiUnSel );
			if tH == gH.ItemsFlip
				tiNewSel = flipud( tiNewSel );
			end
			set( gH.ItemsList, 'String', tNewList, 'Value', tiNewSel, 'listboxtop', 1 );
		end
		mrC_ItemsList_CB
	end





	function ResolveSbjROIs
		% find the intersection of ROIs wrt sbjs
		tSbjNms  = GetChartSelx( 'Sbjs', 2, true );
        tSbjNmsStr = cellfun(@(x) replaceChar(x,'-','_'),tSbjNms,'uni',false);
		tOldROIItems = gChartFs.ROIs.Items;						% any ROI CalcItems will be in this list
		tNewROIItems = gSbjROIFiles.( tSbjNmsStr { 1 } ).Name; % ROI names shared in common; start with 1st sbj.
		for iSbj = 2:numel( tSbjNms )
			tNewROIItems = intersect( tNewROIItems, gSbjROIFiles.( tSbjNmsStr { iSbj }).Name );
		end
		% Now handle CalcItems
		if isfield( gCalcItems, 'ROIs' )
			tCINms = fieldnames( gCalcItems.ROIs );
			for iCI = 1:numel( tCINms )
				tCITs = GetCalcItemTerms( [ 'ROIs:', tCINms{ iCI } ] );
				iCITs = ismember( tCITs, tCINms );
				while any( iCITs )
					kCIT = find( iCITs );
					for iCIT = kCIT
						tCITs = cat( 2, tCITs, GetCalcItemTerms( [ 'ROIs:', tCITs{ iCIT } ] ) );		% append CalcItem terms
					end
					tCITs( kCIT ) = [];		% remove current batch of CalcItems
					iCITs = ismember( tCITs, tCINms );
				end
				if all( ismember( tCITs, tNewROIItems ) )
					tNewROIItems = cat( 2, tNewROIItems, tCINms( iCI ) );
				end
			end
		end
		% determine new selection by identifing which of the old ROIs occur in the new set.
		gChartFs.ROIs.Items = [ tOldROIItems(ismember(tOldROIItems,tNewROIItems)), tNewROIItems(~ismember(tNewROIItems,tOldROIItems)) ];		% = tNewROIItems;
		[ tJunk, gChartFs.ROIs.Sel ] = intersect( gChartFs.ROIs.Items, tOldROIItems( gChartFs.ROIs.Sel ) );
		if numel(gChartFs.ROIs.Sel) ~= 0
			gChartFs.ROIs.Sel = sort( gChartFs.ROIs.Sel );
		end
	end

	function tIsSbjPage = IsSbjPage
		tIsSbjPage = gChartFs.Sbjs.Dim > 3;
	end


	function tChartSel = GetChartSelx( aChartDim, scalarFlag, dataFlag )
		% scalarFlag == 1 returns 1st selected item in string
		% scalarFlag ~= 1 returns cell array of selection(s)
		% dataFlag == true returns non-CalcItem selections only, CalcItems are converted to their dependent "real data" parts
		switch nargin
		case 2
			dataFlag = false;
		case 1
			scalarFlag = 2;
			dataFlag = false;
		end
		if scalarFlag == 1		% String
			tChartSel = gChartFs.( aChartDim ).Items{ gChartFs.( aChartDim ).Sel };	% note: if multiple selections, only 1st is returned!
			if dataFlag
				tSelNm = [ aChartDim, ':', tChartSel ];
				while IsCalcItem( tSelNm )									% drill down until you encounter 1st non-CalcItem
					tCalcItemTerms = GetCalcItemTerms( tSelNm );
					tChartSel = tCalcItemTerms{1};
					tSelNm = [ aChartDim, ':', tChartSel ];
				end
				if strcmp( aChartDim, 'Sbjs' )
					tIsGroup = strncmp( tChartSel, 'GROUP_', 6 );
					while tIsGroup
						% just get the first member
						tChartSel = gGroups( strcmp( { gGroups.name }, tChartSel(7:end) ) ).members{1};
						tIsGroup = strncmp( tChartSel, 'GROUP_', 6 );		
					end
				end
			end
		else							% Cell
			tChartSel = gChartFs.( aChartDim ).Items( gChartFs.( aChartDim ).Sel );
			if dataFlag
				tChartSel = GetUsedRealItems( aChartDim, tChartSel );
				if strcmp( aChartDim, 'Sbjs' )
					tChartSel = Groups2Members( tChartSel );
				end
				tChartSel = unique( tChartSel );		% remove redundancies
			end
		end
	end

	function [ tF, tN, tNms ] = checkValidity( iDim, tValidFields )
		tNms = GetChartSelx( gChartL.Items{iDim} );
		if ismember( gChartL.Items{iDim}, tValidFields )
			tF = gChartL.Items{iDim};
			tN = numel( tNms );
		else
			tF = '';
			tN = 1;
			tNms = { tF };		% avoid inappropriate labels
		end
	end

	function tOptSel = GetOptSelx( aOptName, scalarFlag, numericFlag )
		% scalarFlag == 1 returns 1st selected item in string
		% scalarFlag ~= 1 returns cell array of selection(s)
		% numericFlag == true returns numeric value not string ( scalarFlag==1 only )
		switch nargin
		case 2
			numericFlag = false;
		case 1
			scalarFlag = 2;
			numericFlag = false;
		end
		if scalarFlag == 1
			tOptSel = gOptFs.(aOptName).Items{ gOptFs.(aOptName).Sel };	% this syntax only returns 1st string if multiple RHS items
			if IsOptSelUserDefined( aOptName ),
				if numel( tOptSel > 8 )
					tOptSel = tOptSel(9:end);		% drop 'UsrDef: '
				else
					tOptSel = '';
				end
			end
			if numericFlag
				tOptSel = str2double( tOptSel );		% str2double('') = NaN
			end
		else
			tOptSel = gOptFs.(aOptName).Items( gOptFs.(aOptName).Sel );
		end
	end


	function tIsOptSelUserDefined = IsOptSelUserDefined( aOptName )
		tIsOptSelUserDefined = any( strncmp( GetOptSelx( aOptName ), 'UsrDef:', 7 ) );
	end
	function tIsOptSel = IsOptSel( aOptName, aOptValue )
% 		if isnumeric( aOptValue )
% 			tIsOptSel = GetOptSelx( aOptName, 1, true ) == aOptValue;
% 		else
			tIsOptSel = strcmp( GetOptSelx( aOptName, 1 ), aOptValue );
% 		end
	end
	function tIsOptSel = IsAnyOptSel( aOptName, aOptValue )
		tIsOptSel = ~isempty( strmatch( aOptValue, GetOptSelx( aOptName ) ) );
% 		tIsOptSel = AnyStrMatch( aOptValue, GetOptSelx( aOptName ) );
% 		function tIsAnyStrMatch = AnyStrMatch( tStr, tCAS )
% 			% loop through strings in cell array tCAS and return whether any of
% 			% them match the leading characters of tStr.  In other words, is
% 			% the string tStr prefixed by any of the strings in tCAS?  Good for
% 			% finding structure field names that begin with a particular
% 			% string, e.g., when subsetting a tCCD structure without needing to
% 			% know all the fields exactly, eg, "Spec"...
% 			tIsAnyStrMatch = false;
% 			for i = 1:numel( tCAS )
% 				tIsAnyStrMatch = ~isempty( strmatch( tCAS{ i }, tStr ) );
% 				if tIsAnyStrMatch
% 					return;
% 				end
% 			end
% 		end
	end

	function SetOptSel( aOptName, aOptValue )
		tSel = mrC_GetCellSub( { aOptValue }, gOptFs.( aOptName ).Items );
		% option is in items listbox = (items listbox displaying option) & (option already selected) & (pivot off)
		if strcmp( get( gH.ItemsList, 'UserData' ), 'Options' ) && strcmp( gOptL.Items{ gOptL.Sel }, aOptName ) && ~gIsPivotOn
			set( gH.ItemsList, 'Value', tSel );
			mrC_ItemsList_CB
		else
			gOptFs.( aOptName ).Sel = tSel;
			UpdateOptionsListBox
		end
	end


	function [ tDomain, tCursDomain ] = GetDomain
		tDomain = GetOptSelx( 'Domain', 1 );
		if nargout > 1
			if strcmp( tDomain, 'SpecPhase' )
				tCursDomain = 'Spec';
			else
				tCursDomain = tDomain;
			end
		end
	end

	function tSpace = GetSpace
		tSpace = GetOptSelx( 'Space', 1 );
	end

	function tIsPlot = IsPlot( tPlotType )
		switch tPlotType
		case {'Wave','Spec','SpecPhase','2DPhase','Bar','BarTriplet'}
			tIsPlot = strcmp( GetDomain, tPlotType );
		case 'Offset'
			tDomain = GetDomain;
			tIsPlot = strcmp( tDomain, 'Wave' ) || strcmp( tDomain, 'Spec' ) || strcmp( tDomain, 'SpecPhase' );
		case 'Component'
			tDomain = GetDomain;
			tIsPlot = strcmp( tDomain, '2DPhase' ) || strncmp( tDomain, 'Bar', 3 );
		case 'Source'
			tIsPlot = IsOptSel( 'Space', 'Source' );
		case 'Sensor'
			tIsPlot = ~IsOptSel( 'Space', 'Source' );
		case 'Cursor'
			tIsPlot = ~IsOptSel( 'Space', 'Topo' ) && IsPlot( 'Offset' );
% 		case 'Time'
% 			tIsPlot = strcmp( GetDomain, 'Wave' );
% 		case 'Freq'
% 			tIsPlot = strcmp( GetDomain, 'Spec' );
		otherwise
			error('unknown plot type %s',tPlotType)
		end
	end



%% NewProject
	function mrC_ProjectNew_CB( tH, varargin )
	
		if ishandle( tH )
			SetMessage( 'Browse to new project folder...', 'status' )
			if ischar( gProjPN ) && ~isempty( dir( gProjPN ) )
				tNewProjPN = uigetdir( gProjPN );
			else
				tNewProjPN = uigetdir;
			end
			if tNewProjPN == 0
				return
			end
			gProjPN = tNewProjPN;
		else
			gProjPN = tH;
			if ~isdir( gProjPN )
				error( 'bad project directory name: %s', gProjPN )
			end
		end

		tDlm = filesep;
		if ispc
			tDlm = '\\';		% needs escape character for textscan
		end
		tTok = textscan( gProjPN, '%s', 'delimiter', tDlm );
		set( gH.ProjectText, 'String', tTok{ 1 }{ end } );

		% reinitialize all these...
		[ gD, gVEPInfo, gCndFiles, gSbjROIFiles, gCurs ] = deal([]);		% *** check gCortex for handle & delete cortex window?
		gCortex.Open = false;
		[ gCortex.Name, gCortex.InvName ] = deal('');
		[ gCortex.InvM, gCortex.sensorData ] = deal([]);
		[ gH.CortexFigure, gH.CortexAxis, gH.CortexPatch, gH.CortexLights, gH.CortexText ] = deal([]);
		
		tGroupFile = fullfile( gProjPN, 'SbjGroups.mat' );
		if exist( tGroupFile, 'file' )
% 			load( tGroupFile )
			tGroupData = load( tGroupFile );
			gGroups = tGroupData.gGroups;
		else
% 			gGroups = struct( 'name', {}, 'members', {} );								% 0x0 structure
			gGroups = struct( 'name', {'uninitialized'}, 'members', {{}} );
		end

		% Need to rebuild everything to get rid of old CalcItems
		% Clear isn't necessary but playing it safe
		tFNms = fieldnames( gChartFs );
		for iFNm = 1:numel(tFNms)
			gChartFs.(tFNms{iFNm}).Items = {};
			gChartFs.(tFNms{iFNm}).Sel   = [];
		end

		% start drilling...
		gChartFs.Sbjs.Items = DirCell( gProjPN, 'folders' );
		
        tNSbjs = numel( gChartFs.Sbjs.Items );
		if tNSbjs == 0
			SetMessage( [ 'No subject folders in ', gProjPN], 'error' )
		end
		t1stSbjPN = fullfile( gProjPN, gChartFs.Sbjs.Items{1} ); % also used in nested ManageCndNames below.
		recompute = false;		% flag for RE-computing ROI montages if they already exist
 		if isdir( fullfile( t1stSbjPN, '_mrC_' ) ) && isdir( fullfile( t1stSbjPN, 'Inverses' ) )
			gProjVer = 3;
			gInvDir = 'Inverses';
			SetMessage( 'Loading project type 2 or 3...', 'status' )
			% check for inverse ROI montage directories under 1st subject
			% if found, allow for override of default behavior to use them
			if ~isempty( DirCell( fullfile( t1stSbjPN, '_mrC_' ), 'folders' ) )
				recompute = strcmp(questdlg('Recompute ROI montages?','mrCurrent','No','Yes','No'),'Yes');
			end
		else
			gProjVer = 1;
			gInvDir = 'ROI';
			SetMessage( 'Loading original project type...', 'status' )
			if ~isempty( DirCell( fullfile( t1stSbjPN, 'ROI' ), 'folders' ) )
				recompute = strcmp(questdlg('Recompute ROI montages?','mrCurrent','No','Yes','No'),'Yes');
			end
		end

		GetSbjROIFiles; % do this here so we can later add error catch.

% 		if gProjVer==1
% 			tMtgNms = DirCell( t1stSbjPN, 'folders' ); % also used below in ManageCndNames.
% 		else
% 			tMtgNms = DirCell( fullfile( t1stSbjPN, 'Exp_MATL*' ), 'folders' );
% 			tMtgNms{ end + 1 } = 'ROI';
% 		end

		gChartFs.Mtgs.Items = DirCell( fullfile( t1stSbjPN, 'Exp_MATL*' ), 'folders' );
		ManageCndNames;		% sets gChartFs.Cnds.Items and gCndFiles.
		gChartFs.Invs.Items = DirCell( fullfile( t1stSbjPN, gInvDir, '*.inv' ), 'filenames' );
		gChartFs.Hems.Items = mrC_DefaultChartVals( 'Hems', true );
		gChartFs.ROItypes.Items = mrC_DefaultChartVals( 'ROItypes', true );
		
		gChartFs.Sbjs.Sel = 1:tNSbjs;
		gChartFs.Cnds.Sel = 1;
		gChartFs.Mtgs.Sel = 1;
		gChartFs.Invs.Sel = 1;
		gChartFs.Hems.Sel = mrC_DefaultChartVals( 'Hems', false );
		gChartFs.ROItypes.Sel = mrC_DefaultChartVals( 'ROItypes', false );

		gOptFs.Cortex.Items = cat( 2, { 'none' }, gChartFs.Sbjs.Items );
		gOptFs.Cortex.Sel = 1;

		SetMessage( 'New project opened; configure pivot controls and click NewPlot to load data', 'status' )
		LoadData				% Sets gChartFs: Flts,Comps,Chans
		LoadInverses		% Create new mtg data if not already created by LoadData.
			ResolveSbjROIs
			gChartFs.ROIs.Sel = 1;
		ConfigureCalcItems

		% LoadData,LoadInverses use numel(gChartFs.Sbjs.Items), so doing this after.  could switch to tNSbjs like GetSbjROIFiles & move it up?
		if ( numel( gGroups ) == 1 ) && strcmp( gGroups(1).name, 'uninitialized' ) && isempty( gGroups(1).members )
			if gProjVer == 3
				tSsnLabels = cell( 1, tNSbjs );
				for iSsn = 1:tNSbjs
                    curNameStr = replaceChar(gChartFs.Sbjs.Items{iSsn},'-','_');
					tSsnLabels{iSsn} = gD.(curNameStr).SsnHeader.SsnLabel;
				end
				tSsnUnique = unique( tSsnLabels );	% sorted
				for iSsn = 1:numel(tSsnUnique)
					gGroups(iSsn).name = tSsnUnique{iSsn};
					gGroups(iSsn).members = gChartFs.Sbjs.Items( strcmp( tSsnLabels, gGroups(iSsn).name ) );
				end
			else
				gGroups = gGroups( [] );		% 0x0 struct
			end
		end
		if numel( gGroups ) > 0
			gChartFs.Sbjs.Items = [ gChartFs.Sbjs.Items, strcat( 'GROUP_', { gGroups.name } ) ];
		end
		
		mrC_ChartList_CB
		mrC_ItemsList_CB
		UpdateOptionsListBox
	
%% -- GetSbjROIFiles
		function GetSbjROIFiles
			tSbjROIs = struct( 'Name', [], 'Hem', [] );
			for iSbj = 1:tNSbjs
				tSbjNm = gChartFs.Sbjs.Items{ iSbj };
                tSbjNmStr = tSbjNm;
                if ~isempty(strfind(tSbjNm,'-'))
                    tSbjNmStr(strfind(tSbjNm,'-'))='_';
                else
                end 
				if gProjVer == 1
					tSbjROIFilesPFN = fullfile( gProjPN, tSbjNm, 'ROI', 'SbjROIFiles.mat' );
				else
					tSbjROIFilesPFN = fullfile( gProjPN, tSbjNm, '_mrC_', 'SbjROIFiles.mat' );
				end
				if isempty( dir( tSbjROIFilesPFN ) ) || recompute		% faster than exist( tSbjROIFilesPFN, 'file' )
					tSbjROIsPN = GetSbjROIsPN( tSbjNm );
					if ~isdir( tSbjROIsPN )
						SetMessage( [ tSbjROIsPN ' does not exist.' ], 'error' )
					end
					tSbjROIFiles = DirCell( fullfile( tSbjROIsPN, '*.mat' ), 'files' );
					tNROIs = numel( tSbjROIFiles );
					if tNROIs == 0
						SetMessage( [ tSbjROIsPN ' has no mat-files.' ], 'error' )
					else
						tLHroi = cellfun( @(c) strcmp( upper( c(end-5:end) ), '-L.MAT' ), tSbjROIFiles );
						tLHroiNm = tSbjROIFiles( tLHroi );
						for iROI = 1:numel(tLHroiNm)
							tLHroiNm{ iROI } = tLHroiNm{ iROI }( 1:end-6 );
						end
						tRHroi = cellfun( @(c) strcmp( upper( c(end-5:end) ), '-R.MAT' ), tSbjROIFiles );
						tRHroiNm = tSbjROIFiles( tRHroi );
						for iROI = 1:numel(tRHroiNm)
							tRHroiNm{ iROI } = tRHroiNm{ iROI }( 1:end-6 );
						end
						tBILATroiNm = intersect( tLHroiNm, tRHroiNm );
						tLHonly = setdiff( tLHroiNm, tBILATroiNm );
						tRHonly = setdiff( tRHroiNm, tBILATroiNm );
						tUNKNOWNroiNm = tSbjROIFiles( ~(tLHroi | tRHroi) );
						tSbjROIs.Name = [ tBILATroiNm, tLHonly, tRHonly, tUNKNOWNroiNm];
						tSbjROIs.Hem  = [ repmat(3,1,numel(tBILATroiNm)), ones(1,numel(tLHonly)), repmat(2,1,numel(tRHonly)), zeros(1,numel(tUNKNOWNroiNm)) ];
						save( tSbjROIFilesPFN, 'tSbjROIs' );
					end
				else
					load( tSbjROIFilesPFN );		% loads variable 'tSbjROIFiles'
                end
				gSbjROIFiles.(tSbjNmStr) = tSbjROIs;
			end
		end

%% -- ManageCndNames
		function ManageCndNames
			% this should only be called for first sbj and first mtg
			tIsCndNamesChanged = false;
			if gProjVer == 1
				tCndNamesFileNm = fullfile( gProjPN, 'CndFiles.mat' );
			else
				% t1stSbjPN defined by enclosing function mrC_ProjectNew_CB.
				tCndNamesFileNm = fullfile( t1stSbjPN, '_mrC_', 'CndFiles.mat' );		% or just stick it in outer folder like v1?
			end
			if isempty( dir( tCndNamesFileNm ) ) || recompute
				% use names of .mat files from first non-ROI mtg from 1st sbj as default cnd name
				% we must strip extensions to make valid field name strings, so
				% it must be re-appended when using the name for file loading/saving.
				tCndFiles = DirCell( fullfile( t1stSbjPN, gChartFs.Mtgs.Items{ 1 }, 'Axx*.mat' ), 'filenames' );
				tCndFileNames = struct;
				for iCndFile = 1:numel( tCndFiles )
					tCndFileNames.( tCndFiles{ iCndFile } ) = tCndFiles{ iCndFile };
				end
				tIsCndNamesChanged = true; % to ensure this new info is saved below
			else
				load( tCndNamesFileNm, 'tCndFileNames' ); % initialize tCndFileNames from file
			end
			% prompt for any changes
			tOldCndNames = fieldnames( tCndFileNames );
			if numel( tOldCndNames ) <= 30
				tNewCndNames = inputdlg( tOldCndNames, 'Enter new Cnd names', 1, tOldCndNames );		% returns column cell array even w/ row input
			else
				disp('too many conditions, no rename option.')
				tNewCndNames = {};
			end
			if ~isempty( tNewCndNames )
				for iCnd = 1:numel( tOldCndNames )
					if ~strcmp( tNewCndNames{ iCnd }, tOldCndNames{ iCnd } )
						% reassign the file name for this cnd item from the old cnd field name to the new
						tCndFileNames.( tNewCndNames{ iCnd } ) = tCndFileNames.( tOldCndNames{ iCnd } );
						tCndFileNames = rmfield( tCndFileNames, tOldCndNames{ iCnd } );
					end
				end
				tIsCndNamesChanged = true; % to ensure this new info is saved below
			else
				tNewCndNames = tOldCndNames;
			end
			% if changes (including new) save it
			if tIsCndNamesChanged
				save( tCndNamesFileNm, 'tCndFileNames' );
			end
			gChartFs.Cnds.Items = tNewCndNames';
			gCndFiles = tCndFileNames; % (re)initialize global variable
			% Now LoadData may use gCndFiles to obtain correct data from each file.
		end

%% -- LoadData
		function LoadData
			disp([ 'Condition info from ', gChartFs.Sbjs.Items{1} ])
			for iCnd = 1:numel( gChartFs.Cnds.Items )
				% Start by getting VEPinfo and harmonic component item subscripts
				tCndNm = gChartFs.Cnds.Items{ iCnd };
				SetMessage( [ 'Loading file data for ' tCndNm '...' ], 'status' )
				% to construct path to sens mtg cnd data file for 1st sbj
				% and get VEP info to construct subscripts for harmonic components.
				tPFN = fullfile( gProjPN, gChartFs.Sbjs.Items{1}, gChartFs.Mtgs.Items{1}, [ gCndFiles.(tCndNm) '.mat' ] );
				gVEPInfo.(tCndNm) = load( tPFN, 'dFHz', 'dTms', 'i1F1', 'i1F2', 'nFr', 'nT', 'nCh' ); % VEP info data
				gVEPInfo.(tCndNm).nFr = gVEPInfo.(tCndNm).nFr - 1;
% 				gVEPInfo.(tCndNm).AxxFile = gCndFiles.(tCndNm);
				gVEPInfo.(tCndNm).AxxNum = str2double( strrep( gCndFiles.(tCndNm), 'Axx_c', '' ) );
				if iCnd == 1
					gChartFs.Comps.Items = GetComp( 'getcomplist' );
					gChartFs.Comps.Sel = 1;
					gCompFieldNms = TranslateCompName( gChartFs.Comps.Items );
					gChartFs.Flts.Items = GetFilter( 'getfilterlist' );
					gChartFs.Flts.Sel = 1;
					gChartFs.Chans.Items = strtrim( cellstr( int2str( ( 1:gVEPInfo.(tCndNm).nCh )' ) ) )';
					gChartFs.Chans.Sel = 1:gVEPInfo.(tCndNm).nCh;
				end
				tNComp = numel( gChartFs.Comps.Items );
				tiComp = zeros( 1, tNComp );
				for iComp = 1:tNComp
					tiComp( iComp ) = GetComp( gChartFs.Comps.Items{ iComp }, gVEPInfo.(tCndNm) );
				end
				fprintf( '%s: dT = %0.4gms, nT = %d, dF = %gHz, nF = %d, iF1 = %d, iF2 = %d\n', tCndNm,...
					gVEPInfo.(tCndNm).dTms, gVEPInfo.(tCndNm).nT, gVEPInfo.(tCndNm).dFHz, gVEPInfo.(tCndNm).nFr+1, gVEPInfo.(tCndNm).i1F1, gVEPInfo.(tCndNm).i1F2 )
				% set up data structures for sbjs and mtgs in project folders
				for iSbj = 1:numel( gChartFs.Sbjs.Items )
					tSbjNm = gChartFs.Sbjs.Items{ iSbj };
                    tSbjNmStr = replaceChar(tSbjNm,'-','_'); 
					for iMtg = 1:numel( gChartFs.Mtgs.Items )
						tMtg = gChartFs.Mtgs.Items{ iMtg };
						tPFN = fullfile( gProjPN, tSbjNm, tMtg, [ gCndFiles.(tCndNm) '.mat' ] );
						tVEP = load( tPFN, 'Wave', 'Sin', 'Cos' ); % VEP data
						tNCh = size( tVEP.Wave, 2 );
						if tNCh > 128									% *** why is this check in here?  do we need it?
							disp(['nCh = ',int2str(gVEPInfo.(tCndNm).nCh),', size(Wave,2) = ',int2str(tNCh)])
							tNCh = 128;
						end
						gD.(tSbjNmStr).(tCndNm).(tMtg).Wave.( 'none' ) = tVEP.Wave( :, 1:tNCh );
						gD.(tSbjNmStr).(tCndNm).(tMtg).Spec = tVEP.Cos( 2:end, 1:tNCh ) + tVEP.Sin( 2:end, 1:tNCh ) * i;
						for iComp = 1:tNComp
% 							gD.(tSbjNmStr).(tCndNm).(tMtg).Harm.( gCompFieldNms{ iComp } ) = gD.(tSbjNmStr).(tCndNm).(tMtg).Spec( tiComp( iComp ), : );
							gD.(tSbjNmStr).(tCndNm).(tMtg).Harm.( gCompFieldNms{ iComp } ) = tiComp( iComp );
						end
					end
				end
			end
			for iSbj = 1:numel( gChartFs.Sbjs.Items )
				tSbjNm = gChartFs.Sbjs.Items{ iSbj };
                tSbjNmStr = replaceChar(tSbjNm,'-','_');
				tSsnHeaderFile = fullfile( gProjPN, tSbjNm, gChartFs.Mtgs.Items{1}, 'SsnHeader_ssn.mat'  );
				if exist( tSsnHeaderFile, 'file' )
					gD.(tSbjNmStr).SsnHeader = load( tSsnHeaderFile );
					gD.(tSbjNmStr).SsnHeader.SsnLabel = strrep( gD.(tSbjNmStr).SsnHeader.SsnLabel, 'Ssn ', '' );
				elseif gProjVer == 3
					gProjVer = 2;
					SetMessage( sprintf('%s has no SsnHeader_ssn.mat file.  Only ID groups will be enabled.',tSbjNm) , 'warning' )
				end
			end
			if ~recompute
				for iSbj = 1:numel( gChartFs.Sbjs.Items )
					tSbjNm = gChartFs.Sbjs.Items{ iSbj };
                    tSbjNmStr = replaceChar(tSbjNm,'-','_');
					for iInv = 1:numel( gChartFs.Invs.Items )
						tInvNm = gChartFs.Invs.Items{ iInv };
						if gProjVer == 1
							tPFN = fullfile( gProjPN, tSbjNm, 'ROI', tInvNm, 'Inv.mat' );
						else
							tPFN = fullfile( gProjPN, tSbjNm, '_mrC_', tInvNm, 'Inv.mat' );
						end
						if ~isempty( dir( tPFN ) )		% Newbie sbjs might not have ROI mtgs yet...
							tVEP = load( tPFN );			% InvMean & InvSVD
							gD.(tSbjNmStr).ROI.(tInvNm).Mean = tVEP.InvMean;
							gD.(tSbjNmStr).ROI.(tInvNm).SVD  = tVEP.InvSVD;
						end
					end
				end
			end
			gCurs = struct(	'Wave', struct( 'StepX', gVEPInfo.(tCndNm).dTms ),...
									'Spec', struct( 'StepX', gVEPInfo.(tCndNm).dFHz ) );
			SetMessage( 'Done loading file data', 'status' )
		end

%% -- LoadInverses
		function LoadInverses
			% Check for ROI mtgs for each Inv and Sbj.  If it doesn't exist, create it,
			% and save it out for posterity.  Should test each sbj, in case of a newbie.
			% If all ROI data folders have already been created, nothing happens.
			% We don't follow exact order of tD data heirarchy, because we only
			% want to load the inverse once per sbj.
			for iSbj = 1:numel( gChartFs.Sbjs.Items )
				tSbjNm = gChartFs.Sbjs.Items{ iSbj };
                tSbjNmStr = tSbjNm;
                if ~isempty(strfind(tSbjNm,'-'))
                    tSbjNmStr(strfind(tSbjNm,'-'))='_';
                else
                end 
				tSbjROIsPN = GetSbjROIsPN( tSbjNm );
				tBilat = gSbjROIFiles.(tSbjNmStr).Hem == 3;
				for iInv = 1:numel( gChartFs.Invs.Items )
					tInvNm = gChartFs.Invs.Items{ iInv };
					if isfield( gD.(tSbjNmStr), 'ROI' ) && isfield( gD.(tSbjNmStr).ROI, tInvNm )
						continue;
					else % create ROI Mtg data for this sbj and inv
						% Load sbj's inverse
						SetMessage( [ 'Loading inverse ', tInvNm, ' for ', tSbjNm  ], 'status' )
						tMtgPN = fullfile( gProjPN, tSbjNm, gInvDir );
						tInvM = mrC_readEMSEinvFile( fullfile( tMtgPN, [ tInvNm '.inv' ] ) ) * 1e6;		% #channels x #vertices.  convert to pAmp/mm2
						if gProjVer == 1
							tInvPN = fullfile( tMtgPN, tInvNm );			% montage pathname = inverse file,  inverse pathname = ROI montage file???
						else
							tInvPN = fullfile( gProjPN, tSbjNm, '_mrC_', tInvNm );
						end
						if ~exist( tInvPN, 'dir' )
							mkdir( tInvPN )
						end						
						% Build an inverver matrix using variables set by GetSbjROIFiles.
						[ gD.(tSbjNmStr).ROI.(tInvNm).Mean, gD.(tSbjNmStr).ROI.(tInvNm).SVD ] = mrC_GetROIinv( tSbjROIsPN, gSbjROIFiles.(tSbjNmStr).Name(tBilat), tInvM, fullfile( tInvPN, 'Inv.mat' ) );
					end
				end
			end
			SetMessage( 'Done Loading Inverses', 'status' )
		end

%% -- ConfigureCalcItems
		function ConfigureCalcItems
			% load previously saved gCalcItems from file, if it exists in project
			gCalcItems = [];
			gCalcItemOrder = [];
			tCalcItemsFileNm = fullfile( gProjPN, 'CalcItems.mat' );
			if ~isempty( dir( tCalcItemsFileNm ) )
				tCI = load( tCalcItemsFileNm, 'gCalcItems', 'gCalcItemOrder' );
				gCalcItems = tCI.gCalcItems;
				gCalcItemOrder = tCI.gCalcItemOrder;
				tCIFNms = fieldnames( gCalcItems );
				if ~isempty( tCIFNms )
					for iCIFN = 1:numel( tCIFNms )
						gChartFs.( tCIFNms{ iCIFN } ).Items = cat( 2, gChartFs.( tCIFNms{ iCIFN } ).Items, ...
							fieldnames( gCalcItems.( tCIFNms{ iCIFN } ) )' );
					end
				end
			end
		end

	end

%% Plotting
%% -- New & Replace
	function mrC_Plot_CB( tH, varargin )
		tDomain = GetDomain; % sets outer scope for nested functions that handle plot domain
		tFigTag = [ 'mrC_Plot_', GetSpace, tDomain ];
		tFigH = findtag( tFigTag );
		tIsNoFigYet = isempty( tFigH ); % figure doesn't yet exist
		tOldYLim = []; % sets outer scope for nested functions that handle ScaleBy:Reuse
		tOldXLim = [];
		
		PrepareToReuseScales
		function PrepareToReuseScales
			if ~IsOptSel( 'ScaleBy', 'Reuse' )
				return
			end
			if tIsNoFigYet
				SetWarning( 'ScaleBy:Reuse can''t find previous plot; using ScaleBy:All' )
				return
			end
			% check to see that subplot rows and cols are compatibile
			tSPSize = [ numel( GetChartSel( gChartL.Items{1}, 2 ) ), numel( GetChartSel( gChartL.Items{2}, 2 ) ) ];
			if IsPlot( 'Offset' )
				tSPSize( 1 ) = 1;
			end
			if all( tSPSize == size( gSPHs ) )
				tOldYLim = get( gSPHs, 'YLim' );
				tOldXLim = get( gSPHs, 'XLim' );
			else
				SetMessage( 'If ScaleBy is "Reuse", the number of rows and columns must not change', 'error' )
			end
		end
		
		if tIsNoFigYet
			tFigH = figure( 'Tag', tFigTag );
		else 
			if tH == gH.PlotNew
				tPos = get( tFigH, 'Position' );
				set( tFigH, 'Tag', '' );					% neuter existing fig
				tFigH = figure( 'Tag', tFigTag, 'Position', tPos + [ 20 -20 0 0 ] );
			else		% RevisePlot button
				clf( tFigH );
				figure( tFigH );
			end
		end
		
		% store GUI state info
		tUD = struct( 'gChartFs', gChartFs, 'gChartL', gChartL, 'gOptFs', gOptFs, 'gOptL', gOptL, 'gIsPivotOn', gIsPivotOn,...
			'Pivot_Items_listbox_userdata', get( gH.ItemsList, 'UserData' ) );

		% everything else
% 		tSbjNms = GetChartSelx( 'Sbjs' );
% 		tNSbjs = numel( tSbjNms );
		
		tFltRC = [];	% structure for filter repeat cycles
							% external scope here, set by nested function SetFilterRepeatCycles.
		tNT = [];
% 		tX = [];
		if IsPlot( 'Wave' )
			SetFilteredWaveforms
			SetFilterRepeatCycles
		end

		tColorOrderMat = GetColorOrderRGB; % this gets set to figure, and reused extensively below.
		% set colormap, buttondownfcn
		set( tFigH, 'DefaultAxesColorOrder', tColorOrderMat, 'WindowButtonDownFcn', @mrC_SetPlotFocus_CB, 'Name', GetFigName )
		
% 		[iCol,iCmp,tOffset] = deal([]);		% fix this.  for offset format

		if IsPlot('Source')
			Data_Graph
		else		% sensor domain
			switch GetSpace
			case 'Sensor'
				Data_Graph
			case 'Topo'
				Data_Topograph
			end
			if ~ishandle( tFigH )
				return		% catches figure closures from bad domain calls
			end
		end

		if IsPlot( 'Cursor' )
% 			tUD.Cursor = gCurs.( strrep( GetDomain, 'Phase', '' ) );
			[ tDomain, tCursDomain ] = GetDomain;
			tUD.Cursor = gCurs.(tCursDomain);
		end
		set( tFigH, 'UserData', tUD );
		UpdateCursorEditBoxes
		SetMessage( 'Done Plotting', 'status' )
		return

		% Nested functions ----------


		function SetFilterRepeatCycles
			tFltNms = GetChartSelx( 'Flts', 2, true );
			tNFlts = numel( tFltNms );
			tCnd = GetChartSelx( 'Cnds', 1, true );
			tMtg = GetChartSelx( 'Mtgs', 1 );
			tSbj = GetChartSelx( 'Sbjs', 1, true );
            tSbjStr = replaceChar(tSbj,'-','_');
			if tNFlts > 1
				tWL = zeros(1,tNFlts);	% wavelength
				for iFlt = 1:tNFlts
					tWL( iFlt ) = size( gD.(tSbjStr).(tCnd).(tMtg).Wave.(tFltNms{iFlt}), 1 );
				end
				tNT = tWL(1);
				if any( tWL(2:tNFlts) ~= tNT )				% if filters don't match
					for iFlt = 2:tNFlts
						tNT = lcm( tNT, tWL( iFlt ) );		% cumulative wavelength least common multiple.
					end
					for iFlt = 1:tNFlts
						tFltRC.(tFltNms{ iFlt }) = tNT / tWL( iFlt );		% repeat cycles for each filter.
					end
				else
					for iFlt = 1:tNFlts
						tFltRC.(tFltNms{ iFlt }) = 1;
					end
				end
			else
				tNT = size( gD.(tSbjStr).(tCnd).(tMtg).Wave.(tFltNms{1}), 1 );
				tFltRC.(tFltNms{1}) = 1;
			end
		end
		
		function tFigNm = GetFigName
			tNPages = numel( gChartL.Items ) - 3;
			tPageItems = cell( 1, tNPages );
			for iPage = 1:tNPages
				tItemSel = GetChartSelx( gChartL.Items{ iPage + 3 } );
				switch gChartL.Items{iPage + 3}
				case {'Sbjs','Chans'}
% 					GetMultiPageStr( gChartL.Items{iPage + 3} )
					tNItemSel = numel( tItemSel );
					switch tNItemSel
					case 1
						tPageItems{iPage} = tItemSel{1};
					case numel( gChartFs.( gChartL.Items{iPage + 3} ).Items )
						tPageItems{iPage} = [ 'All ', gChartL.Items{iPage + 3} ];
					otherwise
% 						tPageItems{iPage} = [ int2str( tNItemSel ), ' ', gChartL.Items{iPage + 3} ];
						tPageItems{iPage} = sprintf( '%s[%d]', gChartL.Items{iPage + 3}, tNItemSel );
					end
				otherwise
					tPageItems{ iPage } = tItemSel{1};
				end % For 'All' Sbjs.
			end
			tFigNm = [ sprintf( '%s,', tPageItems{1:tNPages-1} ), tPageItems{tNPages} ];
% 			function GetMultiPageStr( tItemNm )
% 				tNItemSel = numel( tItemSel );
% 				switch tNItemSel
% 				case 1
% 					tPageItems{iPage} = tItemSel{1};
% 				case numel( gChartFs.(tItemNm).Items )
% 					tPageItems{iPage} = [ 'All ', tItemNm ];
% 				otherwise
% 					tPageItems{iPage} = [ int2str( tNItemSel ), ' ', tItemNm ];
% 				end
% 			end
		end
	
%% -- Data Graph
		function Data_Graph

			[ tDomain, tCursDomain ] = GetDomain;
			tCndInfo = GetVEP1Cnd(1);			% assuming same VEP info for all conditions for CalcItems
			tSliceFlags = false(1,3);			% [ SourceSpace, AvgChans, GFP ]
			switch tDomain
			case 'Wave'
				tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
				tSliceFlags(3)  = IsOptSel( 'SensorWaves', 'GFP' );
				tIsOffset = true;
				tX = tCndInfo.dTms * ( 1:tNT );
			case {'Spec','SpecPhase'}
				tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
				tIsOffset = true;
				tX = tCndInfo.dFHz * ( 1:tCndInfo.nFr );
			case {'2DPhase','Bar','BarTriplet'}
				tValidFields = { 'Sbjs', 'Cnds', 'Comps', 'Chans' };
				tIsOffset = false;
			otherwise
				error( 'Invalid plot domain %s', tDomain )
			end
			tSliceFlags(1) = IsOptSel( 'Space', 'Source' );
			if tSliceFlags(1)
				tValidFields = cat( 2, tValidFields, { 'Invs', 'Hems', 'ROIs', 'ROItypes' } );
			elseif tIsOffset
				tSliceFlags(2) = IsOptSel( 'SensorWaves', 'average' );	% only applies to sensor space, force true for bar,2DPhase???
			else
				tSliceFlags(2) = true;
			end

			[ tRowF, tNRows, tRowNms ] = checkValidity( 1, tValidFields );
			[ tColF, tNCols, tColNms ] = checkValidity( 2, tValidFields );
			[ tCmpF, tNCmps, tCmpNms ] = checkValidity( 3, tValidFields );
			tValidDims = ~[ isempty( tRowF ), isempty( tColF ), isempty( tCmpF ) ];

% 			tColorOrderMat = GetColorOrderRGB;
% 			set( tFigH, 'DefaultAxesColorOrder', tColorOrderMat )
			tNColors = size( tColorOrderMat, 1 );

			if tIsOffset
				[ tSPRows, iRowSP ] = deal( 1 );
				if tNRows == 1
					tOffset = 0;
				elseif strcmp( tDomain, 'SpecPhase' )
					tOffset = 360 * (( tNRows - 1 ):-1:0);
				else
% 					tOffset = GetOptSelx( [tCursDomain,'Spacing'], 1, true ) * ( tNRows - 1 ) / 2;
% 					tOffset = linspace( tOffset, -tOffset, tNRows );
					tOffset = GetOptSelx( [tCursDomain,'Spacing'], 1, true ) * (( tNRows - 1 ):-1:0);
				end
			else
				tSPRows = tNRows;
			end			
			gSPHs = zeros(tSPRows,tNCols);

			SD = InitSliceDescription( tValidFields, true );
			if any( strcmp( { tRowF, tColF, tCmpF }, 'Chans' ) ) || ( numel( SD.Chans.Sel ) == 1 )		% tRowF etc. will be '' if field not valid.  Chans always valid anyhow.
				tSliceFlags(2:3) = false;		% AvgChans & GFP
			end
			
			tReqDispersion = IsAnyOptSel( 'Stats', 'Dispersion' );
			tReqScatter = IsAnyOptSel( 'Stats', 'Scatter' );
			
			for iCol = 1:tNCols				% columns are definitely subplots
				if tIsOffset
					gSPHs(iCol) = subplot(1,tNCols,iCol);
				end
				if tValidDims(2)
					SD.( tColF ).Sel = iCol;
				end
				for iRow = 1:tNRows			% rows may or may not be separate subplots
					if ~tIsOffset
						iRowSP = iRow;
						gSPHs(iRowSP,iCol) = subplot(tNRows,tNCols,sub2ind([tNCols tNRows],iCol,iRow));
					end
					if tValidDims(1)
						SD.( tRowF ).Sel = iRow;
					end
					for iCmp = 1:tNCmps		% stack
						if tValidDims(3)
							SD.( tCmpF ).Sel = iCmp;
						end

						tAvgSbjs = ( numel( SD.Sbjs.Sel ) > 1 ) || strncmp( SD.Sbjs.Items{ SD.Sbjs.Sel(1) }, 'GROUP_', 6 );
						if tAvgSbjs
							% don't do any stats for sensor-space butterfly plot
							tPlotDispersion = any( tSliceFlags ) && tReqDispersion;			% && ~strcmp( tDomain, 'Spec' );		% get SE across subjects.  won't do channels.
							tPlotScatter = tReqScatter;
						else
							[ tPlotDispersion, tPlotScatter ] = deal( false );
						end
						tAvgFlags = [ tAvgSbjs, tPlotDispersion ];

						iColor = mod( iCmp-1, tNColors ) + 1;
						switch tDomain
						case 'Wave'
							if iCmp == 1
								line( tX([1 end]), tOffset([iRow iRow]), 'Color', [0 0 0] )
							end
							[ tY, tSE, tNSbjs ] = getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags, 0, tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );
							line(	tX, tY + tOffset(iRow), 'LineWidth', 2, 'Color', tColorOrderMat( iColor, : ) )
							if tPlotDispersion
								if IsOptSel( 'Patches', 'on' )
									patch( tX([ 1:tNT, tNT:-1:1 ]), tY([ 1:tNT, tNT:-1:1 ]) + [ tSE(1:tNT); -tSE(tNT:-1:1) ] + tOffset(iRow), tColorOrderMat( iColor, : ), 'FaceAlpha', 0.25, 'LineStyle', 'none' );
								else
									line( tX([ 1:tNT, tNT:-1:1 ]), tY([ 1:tNT, tNT:-1:1 ]) + [ tSE(1:tNT); -tSE(tNT:-1:1) ] + tOffset(iRow), 'Color', tColorOrderMat( iColor, : ), 'LineStyle', ':' );
								end
							end
						case 'Spec'
							if iCmp == 1
								line( tX([1 end]), tOffset([iRow iRow]), 'Color', [0 0 0] )
							end
% 							tY = abs( getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags ) );
							[ tY, tJunk, tNSbjs ] = getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags );
							tY = abs( tY );
							if IsOptSel( 'SpecPlotCmp', 'UpDown' ) && ( mod(iCmp,2) == 0 )
								tY = -tY;
							end
							if any(tSliceFlags(1:2))	% SourceSpace or AvgChans
								line(	[ tX; tX ], [ repmat( tOffset(iRow), 1, tCndInfo.nFr ); tY' + tOffset(iRow) ], 'LineWidth', 2, 'Color', tColorOrderMat( iColor, : ) )
							else
								line(	tX, tY + tOffset(iRow), 'LineWidth', 2, 'Color', tColorOrderMat( iColor, : )  )
							end
						case 'SpecPhase'
							if iCmp == 1
								line( tX([1 end]), tOffset([iRow iRow]), 'Color', [0 0 0] )
							end
% 							tY = angle( getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags ) ) * (180/pi);
							[ tY, tJunk, tNSbjs ] = getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags );
							tY = angle( tY ) * (180/pi);
							if any(tSliceFlags(1:2))	% SourceSpace or AvgChans
								line(	[ tX; tX ], [ repmat( tOffset(iRow), 1, tCndInfo.nFr ); tY' + tOffset(iRow) ], 'LineWidth', 2, 'Color', tColorOrderMat( iColor, : ) )
							else
								line(	tX, tY + tOffset(iRow), 'LineWidth', 2, 'Color', tColorOrderMat( iColor, : )  )
							end
						case '2DPhase'
							if iCmp == 1
								line( 0,0, 'LineStyle','none', 'Marker','+', 'MarkerSize',20, 'Color','k' )
							end
							[ tY, tYSubj, tNSbjs ] = getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags );
							tX = real( tY );
							tY = imag( tY );
							if ~tAvgSbjs || IsAnyOptSel( 'Stats', 'Mean' )
%								line(	tX, tY, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 15, ...
%												'MarkerEdgeColor', tColorOrderMat( iColor, : ), 'MarkerFaceColor', tColorOrderMat( iColor, : ) )
								line(	[0 tX], [0 tY], 'Color', tColorOrderMat( iColor, : ), 'LineWidth', 2) %, 'Marker', '.', 'MarkerSize', 20 )
							end
							if tPlotDispersion
								tNellip = 30;
								tTh = linspace( 0, 2*pi, tNellip )';
								if IsOptSel( 'DisperScale', 'SEM' )
									tNormK = 1 / (tNSbjs-2);
								else % 95% CI
									tNormK = (tNSbjs-1)/tNSbjs/(tNSbjs-2) * finv( 0.95, 2, tNSbjs - 2 );
								end
								[ tEVec, tEVal ] = eig( cov( [ real( tYSubj ), imag( tYSubj ) ] ) );	% Compute eigen-stuff
								tXY = [ cos(tTh), sin(tTh) ] * sqrt( tNormK * tEVal ) * tEVec';		% Error/confidence ellipse
								tXY = tXY + repmat( [tX tY], tNellip, 1 );
								if IsOptSel( 'Patches', 'on' )
									% patches with transparent fills look great, but Matlab throws an error when trying to save them as AI files.
									patch( tXY(:,1), tXY(:,2), tColorOrderMat( iColor, : ), 'FaceAlpha', .25, 'EdgeColor', tColorOrderMat( iColor, : ), 'LineWidth', 2 );
								else
									% use the following when making AI files.
									line( tXY(:,1), tXY(:,2), 'Color', tColorOrderMat( iColor, : ), 'LineWidth', 2 );
								end
							end
							if tPlotScatter
								line( real(tYSubj), imag(tYSubj), 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 15, ...
									'MarkerEdgeColor', tColorOrderMat( iColor, : ), 'MarkerFaceColor', tColorOrderMat( iColor, : ) );
							end
						case 'Bar'
							[ tYM, tYA, tNSbjs ] = getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags );
							patch( iCmp + [-1 -1 1 1]*0.45, [0 1 1 0]*tYM, tColorOrderMat( iColor, : ), 'EdgeColor', [ 0 0 0 ] )
							if tPlotDispersion
								tYSE = Std2ErrBar( std( tYA ), tNSbjs );
								line( [ iCmp, iCmp ], [ tYM - tYSE, tYM + tYSE ], 'Color', [ 0 0 0 ], 'LineWidth', 2 );
							end
							if tPlotScatter
								line( repmat( iCmp, tNSbjs, 1 ), tYA, 'Color', [ 0 0 0 ], 'LineStyle', 'none', 'Marker', 'o' );
							end
						case 'BarTriplet'
							[ tYM, tYA, tNSbjs ] = getAvgSliceData( tAvgFlags, SD, tDomain, tValidFields, tSliceFlags );
							patch( iCmp + [-0.45 -0.45 -0.15 -0.15], [0 1 1 0]*tYM(1), tColorOrderMat( iColor, : ), 'EdgeColor', [ 0 0 0 ] )
							patch( iCmp + [-0.15 -0.15  0.15  0.15], [0 1 1 0]*tYM(2), tColorOrderMat( iColor, : ), 'EdgeColor', [ 0 0 0 ] )
							patch( iCmp + [ 0.15  0.15  0.45  0.45], [0 1 1 0]*tYM(3), tColorOrderMat( iColor, : ), 'EdgeColor', [ 0 0 0 ] )
							if tPlotDispersion
								tYSE = Std2ErrBar( std( tYA ), tNSbjs );
								line( repmat( iCmp + [ -0.3 0 0.3 ], 2, 1 ), [ tYM - tYSE; tYM + tYSE ], 'Color', [ 0 0 0 ], 'LineWidth', 2 );	
							end
							if tPlotScatter
								line( repmat( iCmp, tNSbjs, 1 ), tYA(:,2), 'Color', [ 0 0 0 ], 'LineStyle', 'none', 'Marker', 'o' );
							end
						end
					end
					if ~tIsOffset
						Component_Format
					end
				end
				if tIsOffset
					Offset_Format
				end
			end
			if tIsOffset		% IsPlot( 'Cursor' ) ?
				gCurs.(tCursDomain).XData = tX;
			end

		
			function Offset_Format
				title( tColNms{ iCol }, 'Interpreter', 'none' );
				if iCol == tNCols && iCmp == tNCmps
					All_Format;
% 					tXLim = tX( [ 1 end ] );
					tXLim = [0 ceil(tX(end)/10)*10];
					if strcmp( tCursDomain, 'Spec' )
% 						tXLim( 1 ) = 0;
						if ~IsOptSel( 'SpecXLim', 'Max' )
							tXLim( 2 ) = GetOptSelx( 'SpecXLim', 1, true );
						end
					end
					set( gSPHs( 1, : ), 'XLim', tXLim );
					tLabelFS = 12;
					axes( gSPHs( 1, end ) );
					% data units, messes up if you change xlim
					text( 1.025 * tXLim( 2 ) * ones( tNRows, 1 ), tOffset', tRowNms, 'Interpreter', 'none', 'FontSize', tLabelFS, 'Tag', 'rowLabel' );
					% normalized units, messes up if you change ylim
					if tNCmps <= 10
						for iiCmp = 1:tNCmps
							text( 'Units','normalized', 'HorizontalAlignment','center', 'VerticalAlignment','top', 'Interpreter','none', 'FontWeight','bold', 'FontSize',tLabelFS,...
								'Position',[(iiCmp-0.5)/tNCmps 0.99], 'String',tCmpNms{iiCmp}, 'Color',tColorOrderMat( mod(iiCmp-1,tNColors)+1, : ) )
						end
					else
% 						text( 'Units','normalized', 'HorizontalAlignment','center', 'VerticalAlignment','top', 'Interpreter','none', 'FontWeight','bold', 'FontSize',tLabelFS,...
% 							'Position',[2.5/7 0.99], 'String',tCmpNms{1}, 'Color',tColorOrderMat(1,:) )
% 						text( 'Units','normalized', 'HorizontalAlignment','center', 'VerticalAlignment','top', 'Interpreter','none', 'FontWeight','bold', 'FontSize',tLabelFS,...
% 							'Position',[3.5/7 0.99], 'String','...', 'Color','k' )
% 						text( 'Units','normalized', 'HorizontalAlignment','center', 'VerticalAlignment','top', 'Interpreter','none', 'FontWeight','bold', 'FontSize',tLabelFS,...
% 							'Position',[4.5/7 0.99], 'String',tCmpNms{tNCmps}, 'Color',tColorOrderMat(tNCmps,:) )
						text( 'Units','normalized', 'HorizontalAlignment','center', 'VerticalAlignment','top', 'Interpreter','none', 'FontWeight','bold', 'FontSize',tLabelFS,...
							'Position',[0.5 0.99], 'String',[tCmpNms{1},' ... ',tCmpNms{tNCmps},' (',int2str(tNCmps),')'], 'Color','k' )
					end
					ReplaceCursors;
				end
			end

			function Component_Format
				tLabelFS = 12;
				if strcmp( tDomain, '2DPhase' )
					tL = max( abs( [ xlim ylim ] ) );
					xlim( [ -tL tL ] );
					ylim( [ -tL tL ] );
				else
					xlim( [ 0 tNCmps + 1 ] );
					if iRow == tNRows && iCol == 1		% lower left
						set( gSPHs( iRowSP, iCol ), 'XTick', 1:tNCmps, 'XTickLabel', tCmpNms );
					else
						set( gSPHs( iRowSP, iCol ), 'XTick', [], 'XTickLabel', [] );
					end
				end
				if iRow == 1
					title( tColNms{ iCol }, 'Interpreter', 'none', 'FontSize', tLabelFS );
				end
				if iRow == tNRows && iCol == tNCols
					All_Format;
					for iRowL = 1:tNRows
						axes( gSPHs( iRowL, end ) );
						tXLRight = xlim;
						tXLRight = 1.025 * tXLRight( end );
						tYLCenter = mean( ylim );
						text( tXLRight, tYLCenter, tRowNms{ iRowL }, 'Interpreter', 'none', 'FontSize', tLabelFS )	%,...
%								'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'rotation', 90 )
%								'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'rotation', -90 )
					end
					if strcmp( tDomain, '2DPhase' ) %~IsOptSel( 'Domain', 'Bar' )		% *** avoid this for cmp=Chans in source space!
						axes( gSPHs( end, 1 ) );
						tXLim = xlim;
						tLegX = linspace( tXLim( 1 ), tXLim( end ), 2 + 8 * tNCmps );
						tLegX = tLegX( 2:(end-1) );
						tYLim = ylim;
						tLegLineX = [ tLegX( 1:8:end ); tLegX( 2:8:end ) ];
						tLegLineY = 0.95 * diff(tYLim) + tYLim(1) * ones( size( tLegLineX ) );
						line( tLegLineX, tLegLineY );
						tLegTextX = tLegX( 3:8:end );
						tLegTextY = 0.95 * diff(tYLim) + tYLim(1) * ones( size( tLegTextX ) );
						text( tLegTextX, tLegTextY, tCmpNms, 'Interpreter', 'none', 'FontSize', tLabelFS );
					end
				end
			end

			function All_Format
				% Handle ylim
				if numel( gSPHs ) > 1
					tYLAll = reshape( get( gSPHs, 'YLim' ), size( gSPHs ) ); % All the ylims, in cell array shaped like plot.
					tScaleBy = GetOptSelx( 'ScaleBy', 1 );
					% Default to 'All' if user tries to 'Reuse' from non-existant figure.
					if strcmp( tScaleBy, 'Reuse' ) && isempty( tOldYLim )
						tScaleBy = 'All';
					end
					switch tScaleBy
						case 'Rows'
							if tNCols > 1
								for iRowL =1:tSPRows
% 									if strncmp( tDomain, 'Bar', 3 )		% IsOptSel( 'Domain', 'Bar' ) || IsOptSel( 'Domain', 'BarTriplet' )		% use smarter logic
										tYLMx = cat( 1, tYLAll{ iRowL, : } );
										tYLm = [ min(tYLMx(:,1)), max(tYLMx(:,2)) ];
% 									else
% 										% global ylim max for this row
% 										tYLMx = max( max( abs( cat( 1, tYLAll{ iRowL, : } ) ) ) );
% 										% determine ylim modified by this scaling option
% 										tYLm = [ -tYLMx tYLMx ];
% 									end
									set( gSPHs( iRowL, : ), 'YLim', tYLm );
									if strcmp( tDomain, '2DPhase' )
										set( gSPHs( iRowL, : ), 'XLim', tYLm )
									end
								end
							end
						case 'Cols'
							if tSPRows > 1
								for iColL =1:tNCols
% 									if strncmp( tDomain, 'Bar', 3 )
										tYLMx = cat( 1, tYLAll{ :, iColL } );
										tYLm = [ min(tYLMx(:,1)), max(tYLMx(:,2)) ];
% 									else
% 										tYLMx = max( max( abs( cat( 1, tYLAll{ :, iColL } ) ) ) );
% 										tYLm = [ -tYLMx tYLMx ];
% 									end
									set( gSPHs( :, iColL ), 'YLim', tYLm );
									if strcmp( tDomain, '2DPhase' )
										set( gSPHs( :, iColL ), 'XLim', tYLm )
									end
								end
							end
						case 'All'
% 							if strncmp( tDomain, 'Bar', 3 )
								tYLMx = cat( 1, tYLAll{:} );
								tYLm = [ min(tYLMx(:,1)), max(tYLMx(:,2)) ];
% 							else
% 								tYLMx = max( max( abs( cat( 1, tYLAll{:} ) ) ) );
% 								tYLm = [ -tYLMx tYLMx ];
% 							end
							set( gSPHs, 'YLim', tYLm );
							if strcmp( tDomain, '2DPhase' )
								set( gSPHs, 'XLim', tYLm )
							end
						case 'Reuse'
							if numel( gSPHs ) == 1
								tOldYLim = { tOldYLim }; tOldXLim = { tOldXLim };
							else
								for iSPH = 1:numel( gSPHs )
									set( gSPHs( iSPH ), 'YLim', tOldYLim{ iSPH } );
									set( gSPHs( iSPH ), 'XLim', tOldXLim{ iSPH } );
								end
							end
					end
				end
			end
		
		end

%% -- Data Topograph
		function Data_Topograph

			if gProjVer == 1
				close( tFigH )
				SetMessage( 'Topo plots only work for V2 projects', 'error'  )
			end			
			if IsPlot( 'Component' )
				close( tFigH )
				SetMessage( 'Attempt to call Data_Topograph on component data', 'error' )
			end

			[ tDomain, tCursDomain ] = GetDomain;
			if ~IsCursor( tCursDomain, 'Frame' )
% 				close( tFigH )
				SetMessage( ['Need to set a ',tCursDomain,' cursor before creating Topo',tDomain,' plot.'], 'error' )
			end

			tCndNms = GetChartSelx( 'Cnds' );
			tNCnds = numel( tCndNms );
			tEGIfaces = mrC_EGInetFaces( false );
			if IsOptSel( 'TopoMap', 'Standard' )
				tEpos = load('defaultFlatNet.mat');
				tEpos = [ tEpos.xy, zeros(128,1) ];
				tXLim = [ min(tEpos(1:128,1))-0.05 max(tEpos(1:128,1))+0.05 ];
				tYLim = [ min(tEpos(1:128,2))-0.05 max(tEpos(1:128,2))+0.05 ];
            end
            
            if IsOptSel( 'TopoMap', 'Sphere' )
				tEpos = load('defaultSphereNet.mat');
				tEpos = tEpos.xyz;
				tXLim = [ min(tEpos(1:128,1))-0.05 max(tEpos(1:128,1))+0.05 ];
				tYLim = [ min(tEpos(1:128,2))-0.05 max(tEpos(1:128,2))+0.05 ];
            end
            
            
% 			tEGIfaces = tEGIfaces(1:end-2,:);		% exclude last 2 triangles
	
			% plot Sbjs x Cnds (or Cnds x Sbjs) regardless of pivot chart
			tIsWave = strcmp( tDomain, 'Wave' );
			if tIsWave
% 				set( tFigH, 'ColorMap', jet(256) )
				tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
			else
% 				set( tFigH, 'ColorMap', hot(256) )
				tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
			end
			
			SD = InitSliceDescription( tValidFields, true );
% 			if any( strncmp( SD.Sbjs.Items, 'GROUP_', 6 ) )
% 				SetMessage( 'Sorry, no Topo space support for subject groups yet.', 'error' )
% 			end
			
			% force selection of all channels
			[ SD.Chans.Items, SD.Chans.Sel ] = deal( 1:numel(gChartFs.Chans.Items) );
			tMultiFlt = numel( SD.Flts.Sel ) > 1;
			if tMultiFlt
				SetMessage( 'Topo plot only showing 1st of multiple selected filters.', 'warning' )
				SD.Flts.Sel = 1;
			end

			tIsSbjPage = IsSbjPage;
			if tIsSbjPage
				SD.Sbjs.Items = Groups2Members( SD.Sbjs.Items );
				tNSbjs = numel( SD.Sbjs.Items );
				tNSbjSP = 1;									% # subject subplots
				tAvgSbjs = tNSbjs > 1;
				SD.Sbjs.Sel = 1:tNSbjs;
			else
% 				[tNSbjs,tNSbjSP] = deal( numel( SD.Sbjs.Items ) );
				tNSbjSP = numel( SD.Sbjs.Items );
				tAvgSbjs = strncmp( SD.Sbjs.Items, 'GROUP_', 6 );
			end

			tZmax = zeros( 1, tNSbjSP );
			tCmax = GetOptSelx( 'ColorMapMax', 1 );
			if strcmp( tCmax, 'All' )		% get most extreme Sbj sensor value across all chosen conditions
				for iSbj = 1:tNSbjSP
					if ~tIsSbjPage
						SD.Sbjs.Sel = iSbj;
					end
					for iCnd = 1:tNCnds
						SD.Cnds.Sel = iCnd;
						if tIsWave
							tZ = getAvgSliceData( [ tAvgSbjs(iSbj), false ], SD, tDomain, tValidFields, false(1,3), 0, tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );
						else		% component domains already excluded, this should be Spec
						%	tZ = getAvgSliceData( [ tAvgSbjs(iSbj), false ], SD, tDomain, tValidFields, false(1,3), 2:gVEPInfo.( SD.Cnds.Items{ SD.Cnds.Sel } ).nFr );
                        	tZ = getAvgSliceData( [ tAvgSbjs(iSbj), false ], SD, tDomain, tValidFields, false(1,3), 2:gVEPInfo.( SD.Cnds.Items{ 1 } ).nFr );
					
							if strcmp( tDomain, 'SpecPhase' )
								tZ = angle( tZ ) * (180/pi);
							end
						end
						tZmax(iSbj) = max( tZmax(iSbj), max( abs( tZ(:) ) ) );
					end
				end
			end

			% Figure will be either Cnds x Sbjs or Sbjs x Cnds regardless of pivot dimensions
			tCndRows = strcmp( gChartL.Items{1}, 'Cnds' ) || strcmp( gChartL.Items{2}, 'Sbjs' )  || ( strcmp( gChartL.Items{3}, 'Cnds' ) && tIsSbjPage );
			if tCndRows
				tNRows = tNCnds;
				tNCols = tNSbjSP;
			else
				tNRows = tNSbjSP;
				tNCols = tNCnds;
			end
			gSPHs = zeros( tNRows, tNCols );
			tH = zeros( tNSbjSP, tNCnds );
			for iSbj = 1:tNSbjSP
				if ~tIsSbjPage
					SD.Sbjs.Sel = iSbj;
				end
				if tAvgSbjs(iSbj) && ~tIsSbjPage
					tSbjNms = Groups2Members( SD.Sbjs.Items(SD.Sbjs.Sel) );
				end
				if IsOptSel( 'TopoMap', 'elp-File' )		% pick 1st elp-File in selection
					if tAvgSbjs(iSbj) && ~tIsSbjPage
						tEpos = GetSensorPos( tSbjNms{1}, false );
					else
						tEpos = GetSensorPos( SD.Sbjs.Items{SD.Sbjs.Sel(1)}, false );
					end
					tNE = size(tEpos,1);
					tEpos = tEpos - repmat( fminsearch( @(tO) mrC_SphereObjFcn(tO,tEpos,tNE), median(tEpos) ), tNE, 1 );		% subtract origin of best fitting sphere
					[ tEpos(:,1), tEpos(:,2), tEpos(:,3) ] = cart2sph( tEpos(:,1), tEpos(:,2), tEpos(:,3) );					% convert to spherical coords [theta,phi,radius]
					% if you're going to rotate, transform tEpos.  CameraUpVector tilts axes lines.  after flattening?
	% 				i = [17 15 16 11 6 55 62 72 75 81];				% midline electrodes
	% 				thetaNose = sum((tEpos(i,1)+pi*(tEpos(i,1)<0)).*tEpos(i,3))/sum(tEpos(i,3));
					[ tEpos(:,1), tEpos(:,2) ] = pol2cart( tEpos(:,1), ( 1 - sin( tEpos(:,2) ) ).^0.6 );			% flatten to [x,y] coords
					tXLim = [ min(tEpos(1:128,1))-0.05 max(tEpos(1:128,1))+0.05 ];
					tYLim = [ min(tEpos(1:128,2))-0.05 max(tEpos(1:128,2))+0.05 ];
                    [ tEpos(1:128,1:2), zeros(128,1) ];
				end
				for iCnd = 1:tNCnds
					SD.Cnds.Sel = iCnd;

					if tIsWave
						[ tZ, tJunk, tNSbjs ] = getAvgSliceData( [ tAvgSbjs(iSbj), false ], SD, tDomain, tValidFields, false(1,3), gCurs.(tCursDomain).Frame.iX, tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );		% 1x128
					else		% component domains already excluded, this should be Spec
						[ tZ, tJunk, tNSbjs ] = getAvgSliceData( [ tAvgSbjs(iSbj), false ], SD, tDomain, tValidFields, false(1,3), gCurs.(tCursDomain).Frame.iX );
						if strcmp( tDomain, 'Spec' )
							tZ = abs( tZ );
						else
							tZ = angle( tZ ) * (180/pi);
						end
					end
					
					if tCndRows
						gSPHs(iCnd,iSbj) = subplot( tNRows, tNCols, sub2ind( [ tNCols tNRows ], iSbj, iCnd ), 'XLim', tXLim, 'YLim', tYLim );
					else
						gSPHs(iSbj,iCnd) = subplot( tNRows, tNCols, sub2ind( [ tNCols tNRows ], iCnd, iSbj ), 'XLim', tXLim, 'YLim', tYLim );
					end
					% always Sbjs x Cnds, might be transpose of subplots
					tH(iSbj,iCnd) = patch( 'Vertices', tEpos(1:128,:), 'Faces', tEGIfaces,...
						'EdgeColor', [ 0.25 0.25 0.25 ],'FaceColor', 'interp', 'FaceVertexCData', tZ(:), 'CDataMapping', 'scaled' );	% 'Marker', '.', 'MarkerEdgeColor', 'k',
					switch tCmax
					case 'All'
                        
					case 'Cursor'
						tZmax(iSbj) = max( abs(tZ) );
					otherwise
						tZmax(iSbj) = eval( tCmax );
					end
					if tIsWave
						set( get( tH(iSbj,iCnd), 'Parent' ), 'CLim', [ -tZmax(iSbj), tZmax(iSbj) ] )
					elseif strcmp( tDomain, 'SpecPhase' )
						set( get( tH(iSbj,iCnd), 'Parent' ), 'CLim', [ -180, 180 ] )
					else
						set( get( tH(iSbj,iCnd), 'Parent' ), 'CLim', [ 0, tZmax(iSbj) ] )
					end
					if tCndRows
						if iCnd == tNRows
							if tAvgSbjs(iSbj)
								if tNSbjs <= 3									
									if tIsSbjPage
										xlabel( [ SD.Sbjs.Items{1}, sprintf(', %s',SD.Sbjs.Items{2:tNSbjs}) ] )
									else
										xlabel( [ tSbjNms{1}, sprintf(', %s',tSbjNms{2:tNSbjs}) ] )
									end
								else
									xlabel( 'average' )
								end
							else
								xlabel( SD.Sbjs.Items{iSbj} )
							end
						end
						if iSbj == 1
							ylabel( tCndNms{iCnd}, 'Interpreter', 'none' )
						end
					else
						if iSbj == tNRows
							xlabel( tCndNms{iCnd}, 'Interpreter', 'none' )
						end
						if iCnd == 1
							if tAvgSbjs(iSbj)
								if tNSbjs <= 3
									if tIsSbjPage
										ylabel( [ SD.Sbjs.Items{1}, sprintf(', %s',SD.Sbjs.Items{2:tNSbjs}) ] )
									else
										ylabel( [ tSbjNms{1}, sprintf(', %s',tSbjNms{2:tNSbjs}) ] )
									end
								else
									ylabel( 'average' )
								end
							else
								ylabel( SD.Sbjs.Items{iSbj} )
							end
						end
					end
					if ( iSbj == 1 ) && ( iCnd == 1 )
						if tIsWave
							if tMultiFlt
								title( sprintf( '%0.1f ms ( Flt = %s )', gCurs.(tCursDomain).Frame.iX * GetDTms(1), SD.Flts.Items{ SD.Flts.Sel } ), 'Interpreter', 'none' )
							else
								title( sprintf( '%0.1f ms', gCurs.(tCursDomain).Frame.iX * GetDTms(1) ) )
							end
						else
							title( sprintf( '%0.1f Hz', gCurs.(tCursDomain).Frame.iX * GetDFHz(1) ) )
						end
					end

				end
			end

			% match cortex colormaps
			tCutFrac = min( GetOptSelx( 'ColorCutoff', 1, true ) / max( tZmax ), 1 );
			if tIsWave
				set( tFigH, 'ColorMap', flow( 256, tCutFrac ) )
			elseif strcmp( tDomain, 'SpecPhase' )
				set( tFigH, 'ColorMap', hsv( 256 ) )
			else
				tCM = hot(356);
				tCM = tCM(1:256,:);
				tCM( 1:round(tCutFrac*256), : ) = 0.5;
				set( tFigH, 'ColorMap', tCM )
			end

% 			tFigColor = get( tFigH, 'Color' );
			set( gSPHs, 'dataaspectratio', [ 1 1 1 ], 'XTick', [], 'YTick', [] ) %, 'Color', 'none', 'Box', 'on' )
			%, 'XColor', tFigColor, 'YColor', tFigColor, 'XColor', tFigColor ) %'XLim', [ -1.6 1.6 ], 'YLim', [ -1.6 1.6 ] )
			
			tHuicm = uicontextmenu( 'Parent', tFigH );		% note: has to have same parent figure as objects it gets assigned to
			uimenu( tHuicm, 'Label', 'ID Vertices', 'Callback', 'mrC_IDpatchVertices' )
			set( tH, 'UIContextMenu', tHuicm )


		end

	end

	function tSD = InitSliceDescription( tValidFields, tMultiFlag )
		tSD = gChartFs;		% field names not in order
		for iFNm = 1:numel( tValidFields )
% 			tSD.( tValidFields{iFNm} ) = gChartFs.( tValidFields{iFNm} );		% *** why?  do we need non-valid fields assigned above?
			if strcmp( tValidFields{iFNm}, 'Chans' )
				tSD.( tValidFields{iFNm} ).Items = gChartFs.Chans.Sel;
				tSD.( tValidFields{iFNm} ).Sel = 1:numel(gChartFs.Chans.Sel);
			else
				tSD.( tValidFields{iFNm} ).Items = GetChartSelx( tValidFields{iFNm} );
				if tMultiFlag
					tSD.( tValidFields{iFNm} ).Sel = 1:numel( tSD.( tValidFields{iFNm} ).Items );
				else
					tSD.( tValidFields{iFNm} ).Sel = 1;
				end
			end
		end
% 		tNonValid = setdiff( fieldnames(gChartFs), tValidFields );
	end

	function tYbar = Std2ErrBar( tStd, tNSbjs )
		switch GetOptSelx( 'DisperScale', 1 )
		case 'SEM'
			tYbar = tStd / sqrt( tNSbjs - 1 );
		case '95%CI'			% note how this differs from 2D-phase version, since we project into 1-D.
			tYbar = tStd * sqrt( finv( 0.95, 1, tNSbjs - 1 ) / tNSbjs );
		otherwise
			error('Unknown DisperScale.')
		end
	end

	function tSbjItems = Groups2Members( tSbjItems )
		tIsGroup = strncmp( tSbjItems, 'GROUP_', 6 );
		while any( tIsGroup )
			iGroup = find( tIsGroup, 1 );
			tGroupName = tSbjItems{iGroup}(7:end);
			tSbjItems(iGroup) = [];																								% delete current group from list
			tSbjItems = cat( 2, tSbjItems, gGroups( strcmp( { gGroups.name }, tGroupName ) ).members );	% append it's members
			tIsGroup = strncmp( tSbjItems, 'GROUP_', 6 );		
		end
	end

	function [tOut1,tOut2,tNSbjs] = getAvgSliceData( tAvgFlags, tSD, varargin )
		% getAvgSliceData( tAvgFlags, tSD, tDomain, tValidFields, tFlags, tIndex, tRC )
		% Average across subjects
		% tAvgFlags = [ AverageSubjectsFlag, CalculateStandardErrorFlag (Wave only) ]
		% tIndex = Sample Index (Wave or Spec)

		if tAvgFlags(1)
			tSD.Sbjs.Items = Groups2Members( tSD.Sbjs.Items( tSD.Sbjs.Sel ) );		% note: subjects could be counted multiple times	
			tSD.Sbjs.Sel = 1;
			tNSbjs = numel( tSD.Sbjs.Items );
			if tNSbjs == 1
				tAvgFlags(1) = false;
			end
		else
			tNSbjs = 1;
		end
		switch varargin{1}	% Domain
		case 'Wave'
            tOut1 = getSliceData( tSD, varargin{:} );
			if all( tAvgFlags )
				tOut2 = tOut1.^2;
			else
				tOut2 = [];
			end
			if tAvgFlags(1)
				for iSbj = 2:tNSbjs
					tSD.Sbjs.Sel = iSbj;
					if tAvgFlags(2)
						tYi = getSliceData( tSD, varargin{:} );			% [nT x 1]
						tOut1 = tOut1 + tYi;
						tOut2 = tOut2 + tYi.^2;
					else
						tOut1 = tOut1 + getSliceData( tSD, varargin{:} );
					end
				end
				tOut1 = tOut1 / tNSbjs;																% mean across subjects
				if tAvgFlags(2)
					tOut2 = sqrt( ( tOut2 - tNSbjs * tOut1.^2 ) / (tNSbjs - 1 ) );		%  std across subjects
					tOut2 = Std2ErrBar( tOut2, tNSbjs );
				end
			end
%             missingSbjs = 0;
%             tOut1 = 0;
%             tOut2 = 0;
%             for iSbj = 1:tNSbjs
%                 tSD.Sbjs.Sel = iSbj;				
%                 if isempty(find(isnan(getSliceData( tSD, varargin{:} )), 1))
%                     if all( tAvgFlags )
%                         tOut2 = tOut1.^2;
%                     else
%                     end	
%                     if tAvgFlags(2)
%                         tYi = getSliceData( tSD, varargin{:} );			% [nT x 1]
%                         tOut1 = tOut1 + tYi;
%                         tOut2 = tOut2 + tYi.^2;
%                     else
%                         tOut1 = tOut1 + getSliceData( tSD, varargin{:} );
%                     end
%                 else
%                     missingSbjs = missingSbjs +1;
%                 end
%             end
%             tOut1 = tOut1 / (tNSbjs - missingSbjs);																% mean across subjects
%             if tAvgFlags(2)
%                 tOut2 = sqrt( ( tOut2 - tNSbjs * tOut1.^2 ) / ((tNSbjs - missingSbjs) - 1 ) );		%  std across subjects
%                 tOut2 = Std2ErrBar( tOut2, tNSbjs );
%             else
%             end
		case {'Spec','SpecPhase'}
			tOut1 = getSliceData( tSD, varargin{:} );			% [nFr x 1]
			if tAvgFlags(1)
				for iSbj = 2:tNSbjs
					tSD.Sbjs.Sel = iSbj;
					tOut1 = tOut1 + getSliceData( tSD, varargin{:} );
				end
				tOut1 = tOut1 / tNSbjs;
			end
% 			tOut1 = abs( tOut1 );
			tOut2 = [];
		case '2DPhase'
			if tAvgFlags(1)
				tOut2 = zeros( tNSbjs, 1 );
				for iSbj = 1:tNSbjs
					tSD.Sbjs.Sel = iSbj;
					tOut2(iSbj) = getSliceData( tSD, varargin{:} );
				end
				tOut1 = mean( tOut2 );		% complex mean - scalar
			else
				tOut1 = getSliceData( tSD, varargin{:} );
				tOut2 = [];
			end
		case 'Bar'
			if tAvgFlags(1)
				tOut2 = zeros( tNSbjs, 1 );
				for iSbj = 1:tNSbjs
					tSD.Sbjs.Sel = iSbj;
					tOut2(iSbj) = getSliceData( tSD, varargin{:} );
				end
				switch GetOptSelx( 'BarMean', 1 )
				case 'Coherent'
					tM = mean( tOut2 );
					tOut1 = abs( tM );		% abs(mean) = mean(projection onto phase of mean)
					tOut2 = [ real(tOut2), imag(tOut2) ]*[ real(tM); imag(tM) ] / tOut1;
				case 'Incoherent'
					tOut2 = abs( tOut2 );
					tOut1 = mean( tOut2 );	% mean(abs)
				otherwise
					error('Unknown BarMean.')
				end
			else
				tOut1 = abs( getSliceData( tSD, varargin{:} ) );
				tOut2 = [];
			end
		case 'BarTriplet'
			if tAvgFlags(1)
				tOut2 = zeros( tNSbjs, 3 );
				for iSbj = 1:tNSbjs
					tSD.Sbjs.Sel = iSbj;
					tOut2(iSbj,:) = getSliceData( tSD, varargin{:} )';
				end
				switch GetOptSelx( 'BarMean', 1 )
				case 'Coherent'
					tM = mean( tOut2 );
					tOut1 = abs( tM );		% abs(mean) = mean(projection onto phase of mean)
					tOut2 = ( real(tOut2)*diag(real(tM)) + imag(tOut2)*diag(imag(tM)) ) * diag(1./tOut1);
				case 'Incoherent'
					tOut2 = abs( tOut2 );
					tOut1 = mean( tOut2 );	% mean(abs)
				otherwise
					error('Unknown BarMean.')
				end
			else
				tOut1 = abs( getSliceData( tSD, varargin{:} ) );		% 3x1 vector
				tOut2 = [];
			end
		end
	end



	function tYj = getSliceData( tSD, tDomain, tValidFields, tFlags, tIndex, tRC )
		switch nargin
		case 5
			tRC = 1;
		case 4
			tIndex = 0;
			tRC = 1;
		case 3
			tFlags = false(1,3);
			tIndex = 0;
			tRC = 1;
		end
		if IsSliceCalcItem
			tYj = ConvertCalcItemSlice( tSD, @getSliceData );
		else
			tSbjField = tSD.Sbjs.Items{ tSD.Sbjs.Sel };
            tSbjFieldStr = replaceChar(tSbjField,'-','_');
			tCndField = tSD.Cnds.Items{ tSD.Cnds.Sel };
			tChans    = tSD.Chans.Items( tSD.Chans.Sel );
			tMtg      = tSD.Mtgs.Items{ 1 };
			switch tDomain
			case 'Wave'
				if isscalar(tIndex) && ( tIndex == 0 )
					tEEG = gD.(tSbjFieldStr).(tCndField).(tMtg).Wave.( tSD.Flts.Items{ tSD.Flts.Sel } )( :, tChans );
				else
					tIndex = mod( tIndex-1, size( gD.(tSbjFieldStr).(tCndField).(tMtg).Wave.( tSD.Flts.Items{ tSD.Flts.Sel } ), 1 ) ) + 1;		% filtering might shorten waveform
					tEEG = gD.(tSbjFieldStr).(tCndField).(tMtg).Wave.( tSD.Flts.Items{ tSD.Flts.Sel } )( tIndex, tChans );
				end
			case {'Spec','SpecPhase'}
				if isscalar(tIndex) && ( tIndex == 0 )
					tEEG = gD.(tSbjFieldStr).(tCndField).(tMtg).Spec( :, tChans );
				else
					tEEG = gD.(tSbjFieldStr).(tCndField).(tMtg).Spec( tIndex, tChans );
				end
% 				tFlags(3) = false;		% GFP on components doesn't make sense
%				tRC = 1;
			case {'2DPhase','Bar'}
% 				tEEG = gD.(tSbjFieldStr).(tCndField).(tMtg).Harm.( TranslateCompName( tSD.Comps.Items{ tSD.Comps.Sel } ) )( tChans );
				tEEG = gD.(tSbjFieldStr).(tCndField).(tMtg).Spec( gD.(tSbjFieldStr).(tCndField).(tMtg).Harm.( TranslateCompName( tSD.Comps.Items{ tSD.Comps.Sel } ) ), tChans );
% 				tFlags(3) = false;
%				tRC = 1;
			case 'BarTriplet'
				iSpec = gD.(tSbjFieldStr).(tCndField).(tMtg).Harm.( TranslateCompName( tSD.Comps.Items{ tSD.Comps.Sel } ) );
				if iSpec == 1
					tEEG = [ repmat(NaN,1,numel(tChans)); gD.(tSbjFieldStr).(tCndField).(tMtg).Spec( iSpec+[0,1], tChans ) ];
				elseif iSpec == size( gD.(tSbjFieldStr).(tCndField).(tMtg).Spec, 1 )
					tEEG = [ gD.(tSbjFieldStr).(tCndField).(tMtg).Spec( iSpec+[-1,0], tChans ); repmat(NaN,1,numel(tChans)) ];
				else
					tEEG = gD.(tSbjFieldStr).(tCndField).(tMtg).Spec( iSpec+[-1,0,1], tChans );
				end
% 				tFlags(3) = false;
%				tRC = 1;
			end
			if tFlags(1)			% tIsSourceSpace
				tYj = tEEG * GetReqInv;
			elseif tFlags(2)		% tAvgChans
				tYj = mean( tEEG, 2 );
			elseif tFlags(3)		% tGFP					% Wave Only
				% from Darren Weber's eeg_gfp.m
				% Global Field Power is the root mean squared differences
				% between all possible source locations; note here that we only
				% divide by #Channels because of the above progressive difference
				% calculations, wheras Lehmann & Skrandies use 2*#Channels because they
				% calculate all pairwise differences.
% 				[tNt,tNChan] = size( tEEG );
% 				tYj = zeros(tNt,1);
% 				for i = 1:tNChan
% 					tYj = tYj + sum( ( tEEG(:,repmat(i,1,tNChan-i)) - tEEG(:,(i+1):tNChan) ).^2, 2);
% 				end
% 				tYj = sqrt( tYj / tNChan);

				% from Vladimir, PowerDiva
				tYj = std(tEEG,1,2);
			elseif false
				tYj = tEEG;
				[tSVDu,tSVDs,tSVDv] = svd( tYj, 'econ' );
				if mean( tSVDv(:,1) ) < 0
					for i = 1:size( tYj, 2 )
						if tSVDv(i,1) > 0
							tYj(:,i) = -tYj(:,i);
						end
					end
				else
					for i = 1:size( tYj, 2 )
						if tSVDv(i,1) < 0
							tYj(:,i) = -tYj(:,i);
						end
					end
				end
			else
				tYj = tEEG;
			end
			if tRC > 1
				tYj = repmat( tYj, tRC, 1 );
			end
		end
		return
		%-------------------------
		function tInvM = GetReqInv
			tInvField  = tSD.Invs.Items{ tSD.Invs.Sel };
			tTypeField = tSD.ROItypes.Items{ tSD.ROItypes.Sel };
			tROINm     = tSD.ROIs.Items{ tSD.ROIs.Sel };
			switch tSD.Hems.Items{ tSD.Hems.Sel }
			case 'Left'
				tInvM = gD.(tSbjFieldStr).ROI.(tInvField).(tTypeField)( tChans, strcmp( gSbjROIFiles.(tSbjFieldStr).Name, tROINm ), 1 );
			case 'Right'
				tInvM = gD.(tSbjFieldStr).ROI.(tInvField).(tTypeField)( tChans, strcmp( gSbjROIFiles.(tSbjFieldStr).Name, tROINm ), 2 );
			case 'Bilat'
				tInvM = gD.(tSbjFieldStr).ROI.(tInvField).(tTypeField)( tChans, strcmp( gSbjROIFiles.(tSbjFieldStr).Name, tROINm ), 3 );
			otherwise
				error( 'unknown hemisphere %s', tSD.Hems.Items{ tSD.Hems.Sel } )
			end
		end
		
		function rIsSliceCalcItem = IsSliceCalcItem
			rIsSliceCalcItem = false;
			for iFNm = 1:numel( tValidFields )
				if strcmp( tValidFields{iFNm}, 'Chans' )
				else
					rIsSliceCalcItem = IsCalcItem( [ tValidFields{iFNm}, ':', tSD.(tValidFields{iFNm}).Items{ tSD.(tValidFields{iFNm}).Sel } ] );
				end
				if rIsSliceCalcItem
					return
				end
			end
		end
		
		function rSM = ConvertCalcItemSlice( aSD, tCaller )				% recursive!
			tOCINm = GetOuterCalcItemName( aSD );								% Outer CalcItem Name e.g. 'Cnds:Avg12'
			tOCITs = GetCalcItemTerms( tOCINm );								% Outer CalcItem Terms e.g. { 'Axx_c001', 'Axx_C002' }
			tOCITv = genvarname( tOCITs );										% Outer CalcItem Term legal variable names
			tOCITSM = cell2struct( cell(numel(tOCITv),1), tOCITv );		% struct with empty fields tOCITv 
			[ tOCIFNm, tOCIINm ] = GetCalcItemPartNames( tOCINm );		% Outer CalcItem Field and Item Names
			tExpr = strrep( gCalcItems.(tOCIFNm).(tOCIINm), [ tOCIINm, ' = ' ], '' );		% extract RHS of equation
			for iOCIT = 1:numel( tOCITs )
				aSD.(tOCIFNm).Items{ aSD.(tOCIFNm).Sel } = tOCITs{iOCIT};			% modify slice descr struct to use this Calc Item Term
				tOCITSM.( tOCITv{iOCIT} ) = feval( tCaller, aSD, tDomain, tValidFields, tFlags, tIndex, tRC );		% recursively drills from outer to inner CalcItems
				tExpr = strrep( tExpr, tOCITs{iOCIT}, [ 'tOCITSM.', tOCITv{iOCIT} ] );
% 				tExpr = strrep( tExpr, [ tOCITs{iOCIT}, ' ' ], [ 'tOCITSM.', tOCITv{iOCIT}, ' ' ] );
			end
			tExpr = ReplaceWithArrayOps( tExpr );
			try
	% 			eval( [ tExpr ';' ] ); % now rSM is a slice correspoding to the CalcItem
				rSM = eval( tExpr );
			catch
				SetMessage( 'Error in CalcItem formula', 'warning' )
				rethrow( lasterror );
			end
			return
			
			function rOuterCalcItemName = GetOuterCalcItemName( aSD )
				for iCI = 1:numel( gCalcItemOrder )
					[ tFNm, tINm ] = GetCalcItemPartNames( gCalcItemOrder(iCI) );
					if strcmp( tINm, aSD.(tFNm).Items{ aSD.(tFNm).Sel } )
						rOuterCalcItemName = gCalcItemOrder{ iCI };
						return
					end
				end
				error( 'No CalcItems found.' )	% you should've checked before calling ConvertCalcItemSlice 
			end
			function tStr = ReplaceWithArrayOps( tStr )
				tStr = strrep( tStr, '*', '.*' );
				tStr = strrep( tStr, '/', './' );
				tStr = strrep( tStr, '^', '.^' );
			end
		end
	end


	function mrC_SetPlotFocus_CB( tH, varargin )
		% mrC_Plot_CB sets the ButtonDownFcn of each plot figure to this callback.
		% If caller was out of focus w/ an empty tag, steal it from fig that does (if any).
		% Then, restore GUI state from the calling fig's userdata.
		if isempty( findobj( 'Tag', 'mrC_GUI' ) );
			return
		end
	
		% Recall GUI state from figure userdata
		tUD = get( tH, 'UserData' );
		% current state of cortex window should override that stored in Plot figure,
		% to prevent unwanted switching of cortex window.
		tUD.gOptFs.( 'Cortex' ).Sel = gOptFs.( 'Cortex' ).Sel;
		% handle possible changes in CalcItems
		for tChartF = fieldnames( tUD.gChartFs )'
			% remove dead CalcItems
			tAlive = ismember( tUD.gChartFs.(tChartF{1}).Items, gChartFs.(tChartF{1}).Items );
			if ~all( tAlive )
				disp('WARNING: Dead Item(s) in figure userdata')	% not necessarily CalcItem could be dead ROI from increasing subject pool
				disp( tUD.gChartFs.(tChartF{1}).Items( ~tAlive ) )
				tSelItems = tUD.gChartFs.(tChartF{1}).Items( tUD.gChartFs.(tChartF{1}).Sel );		% original selection(s)
				tUD.gChartFs.(tChartF{1}).Items = tUD.gChartFs.(tChartF{1}).Items( tAlive );
				tSelOK = ismember( tSelItems, tUD.gChartFs.(tChartF{1}).Items );						% flag for still valid selections
				if ~any(tSelOK)
					disp('Chart selection reset to 1st remaining item.')
					tSelItems = tUD.gChartFs.(tChartF{1}).Items(1);
				elseif ~all(tSelOK)
					disp('Chart selections reduced.')
					tSelItems = tSelItems(tSelOK);
				end
				tUD.gChartFs.(tChartF{1}).Sel = find( ismember( tUD.gChartFs.(tChartF{1}).Items, tSelItems ) );
			end
			% add new CalcItems
			tNewCI = setdiff( gChartFs.(tChartF{1}).Items, tUD.gChartFs.(tChartF{1}).Items );
			if ~isempty( tNewCI )
				tUD.gChartFs.(tChartF{1}).Items = [ tUD.gChartFs.(tChartF{1}).Items, tNewCI ];
			end
		end

		gChartFs = tUD.gChartFs; % structure of chart fields
		gChartL = tUD.gChartL;
		gOptFs = tUD.gOptFs; % structure of option fields
		gOptL = tUD.gOptL;
		gIsPivotOn = tUD.gIsPivotOn;
		tCallingLB = tUD.Pivot_Items_listbox_userdata;
		set( gH.ItemsList, 'UserData', tCallingLB );
		if strcmpi( tCallingLB, 'Options' )
			mrC_OptionsList_CB
			UpdateChartListBox
		else
			mrC_ChartList_CB
			UpdateOptionsListBox
		end
		mrC_ItemsList_CB

		[ tDomain, tCursDomain ] = GetDomain;
		if IsPlot( 'Cursor' )
			gCurs.(tCursDomain) = tUD.Cursor;
		end
		UpdateCursorEditBoxes
		% Now determine if calling figure is the last pivot plot made...
		tFigTag = [ 'mrC_Plot_', GetSpace, tDomain ];
		tFigH = findtag( tFigTag );
		if isempty( tFigH ) || ( tH ~= tFigH )		% ( # ~= [] ) doesn't return true???
			set( tFigH, 'Tag', '' )						% set doesn't complain if tFigH is empty
			set( tH, 'Tag', tFigTag )
		end

		if IsOptSel( 'AutoPaint', 'on' ) && gCortex.Open && IsPlot( 'Offset' ) && IsCursor( tCursDomain, 'Frame' )
			mrC_CortexPaint_CB
		end
	end

%% Cursor
% Cursors are entities that allow data from a particular slice of a VEP
% pivot plot to be selected and painted onto a cortical mesh.  Cursor data
% are stored in gCurs.( PPDomain ).( CursType ), where PPDomain is
% the pivot plot domain, i.e., Wave, and/or Spec, etc.; and CursType is
% MovieStart, MovieStop, and/or Frame.

%% -- Cursor GUI callbacks
	function mrC_CursorPick_CB( tH, varargin )
		[ tDomain, tCursDomain ] = GetDomain;
		if ~IsPlot( 'Offset' )
			SetMessage( [ tDomain ' domain does not allow cursors' ], 'error' )
		end
		tFigH = findtag( [ 'mrC_Plot_', GetSpace, tDomain ] );
		if isempty( tFigH )
			SetMessage( 'You are attempting to place a cursor in a non-existant plot', 'error' )
		end
		tCursType = get( tH, 'Tag' );		% 'Frame', 'MovieStart', or 'MovieStop'
		SetMessage( [ 'Select new ' tCursType ' cursor location in ' tDomain ' window...' ], 'status' )
		figure( tFigH )
		set( tFigH, 'pointer', 'fullcrosshair' )
		waitforbuttonpress;
		set( tFigH, 'pointer', 'arrow' )
		if gcf ~= tFigH
			SetMessage( [ 'You must click on the most recent ' tDomain ' plot...Please try again' ], 'error' )
		end
		tCOH = gco;		% clicked object, back-up to axis
		tCOType = get( tCOH, 'Type' );
		while ~strcmpi( tCOType, 'axes' )
			if isempty( tCOH ) || strcmpi( tCOType, 'figure' ) % we missed all axes
				SetMessage( 'You must click on an axis...Please try again', 'error' )
			end
			% crawl up object heirarchy
			tCOH = get( tCOH, 'Parent' );
			tCOType = get( tCOH, 'Type' );
		end
		tX = get( tCOH, 'CurrentPoint' ); % 2x3 matrix.  this does not necessarily map onto a data coordinate...
		SetCursData( tDomain, tCursDomain, tCursType, tX(1) )
	end

	function mrC_CursorEdit_CB( tH, varargin )
		% callback for Frame/MovieStart/MovieStop Cursor edit boxes
		[ tDomain, tCursDomain ] = GetDomain;
		switch tCursDomain
		case 'Wave'
			tStepInc = GetDTms(1);
		case 'Spec'
			tStepInc = GetDFHz(1);
		end
		if isfield( gCurs.(tCursDomain), 'XData' )
			try
				tX = eval( get( tH, 'String' ) );
				if ~( isnumeric(tX) && isscalar(tX) )
					tX = NaN;
					SetMessage( 'Invalid cursor value.', 'warning'  )
				end
			catch
				tX = NaN;
				SetMessage( 'Invalid cursor value.', 'warning'  )
			end
		else
			tX = NaN;
			SetMessage( ['No ',tDomain,' plot.'], 'warning'  )
		end		
		tCursType = get( tH, 'Tag' );		% 'Frame', 'MovieStart', or 'MovieStop'
		if isnan(tX)
			UpdateCursorEditBox( tCursDomain, tCursType )		% restore valid string for previous value
		else
			tiX = round( tX / tStepInc );
			if ( tiX >= 1 ) && ( tiX <= numel( gCurs.(tCursDomain).XData ) )
				if ~IsCursor( tCursDomain, tCursType )		% && ishandle( gCurs.(tCursDomain).(tCursType).LH )
					figure( findtag( [ 'mrC_Plot_', GetSpace, tDomain ] ) )		% *** NEED TO GET IN RIGHT AXIS, NOT JUST FIGURE
				end
				SetCursData( tDomain, tCursDomain, tCursType, gCurs.(tCursDomain).XData( tiX ) )
			else
				UpdateCursorEditBox( tCursDomain, tCursType )
				SetMessage( 'Requested cursor location exceeds wave dimensions.', 'warning' )
			end
		end
	end

	function mrC_CursorStep_CB( tH, varargin )
		% callback for Step F/B pushbuttons
		[ tDomain, tCursDomain ] = GetDomain;
		if ~IsCursor( tCursDomain, 'Frame' )
			SetMessage( 'Set a Frame cursor before using F or B pushbuttons.', 'warning' )
			return							
		end
		switch tCursDomain
		case 'Wave'
			tStepInd = round( gCurs.(tCursDomain).StepX / GetDTms(1) );
		case 'Spec'
			tStepInd = round( gCurs.(tCursDomain).StepX / GetDFHz(1) );
		end
		if tH == gH.FrameUp
			tiX = gCurs.(tCursDomain).Frame.iX + tStepInd;
		else
			tiX = gCurs.(tCursDomain).Frame.iX - tStepInd;
		end
		if ( tiX >= 1 ) && ( tiX <= numel( gCurs.(tCursDomain).XData ) )
			figure( findtag( [ 'mrC_Plot_', GetSpace, tDomain ] ) )		% *** THIS COULD BE TOPO!!!
			SetCursData( tDomain, tCursDomain, 'Frame', gCurs.(tCursDomain).XData( tiX ) )
		else
			SetMessage( 'Requested cursor step exceeds wave dimensions.', 'warning' )
		end
	end

	function mrC_CursorStepBy_CB( tH, varargin )
		% callback for Step By edit box
		[ tDomain, tCursDomain ] = GetDomain;
		try	% check if legal expression entered
			tVal = eval( get( tH, 'String' ) );		% str2double( get( tH, 'String' ) );
			if isnumeric(tVal) && isscalar(tVal) && ~isnan(tVal)
				switch tCursDomain
				case 'Wave'
					tIncr = GetDTms(1);
				case 'Spec'
					tIncr = GetDFHz(1);
				otherwise
					SetMessage( 'Step By control only valid in Wave and Spec domains.', 'warning' )
					return		% don't reset edit box string until you switch to a relevant domain
				end
				gCurs.(tCursDomain).StepX = max(1,round(tVal/tIncr)) * tIncr;
				UpdateCursorUserdata( tDomain, tCursDomain )
			else
				SetMessage( 'Invalid cursor step expression.', 'warning' )
			end
		catch
			SetMessage( 'Invalid cursor step expression.', 'warning' )
		end
		set( gH.CursorStep, 'String', sprintf('%0.2f',gCurs.(tCursDomain).StepX) )
	end

	function mrC_CursorClear_CB( varargin )
		% callback for Cursor 'Clear All' pushbutton
		[ tDomain, tCursDomain ] = GetDomain;
		if isfield( gCurs, tCursDomain )
			tCursTypes = { 'Frame', 'MovieStart', 'MovieStop' };
			for iCursType = 1:numel( tCursTypes )
				if isfield( gCurs.(tCursDomain), tCursTypes{ iCursType } )
					if ishandle( gCurs.(tCursDomain).( tCursTypes{ iCursType } ).LH )
						delete( gCurs.(tCursDomain).( tCursTypes{ iCursType } ).LH )
% 					end
% 					if ishandle( gCurs.(tCursDomain).( tCursTypes{ iCursType } ).TH )
						delete( gCurs.(tCursDomain).( tCursTypes{ iCursType } ).TH )
					end
					gCurs.(tCursDomain) = rmfield( gCurs.(tCursDomain), tCursTypes{ iCursType } );
					% NOTE: gCurs.(tCursDomain).XData & StepX remain.
					UpdateCursorUserdata( tDomain, tCursDomain )
					set( gH.( [ tCursTypes{ iCursType }, 'Edit' ] ), 'String', '' ) 
				end
			end
		end
	end


%% -- Cursor Helpers
	function SetCursData( tDomain, tCursDomain, tCursType, tX )
		% sets iX,X,XStr fields in gDurs.(tCursDomain).(tCursType), and updates edit box
		% if necessary, increment to nearest data point
		tiX = sum( gCurs.(tCursDomain).XData <= tX );
		if tiX == 0 || ( tiX < numel(gCurs.(tCursDomain).XData) && ( tX - gCurs.(tCursDomain).XData( tiX ) ) > ( gCurs.(tCursDomain).XData( tiX + 1 ) - tX ) )
			tiX = tiX + 1;
		end
		gCurs.(tCursDomain).(tCursType).iX = tiX;
		gCurs.(tCursDomain).(tCursType).X  = gCurs.(tCursDomain).XData( tiX );
		if IsPlot( 'Wave' )
			gCurs.(tCursDomain).(tCursType).XStr = sprintf( ' %0.0fms', gCurs.(tCursDomain).(tCursType).X );
		else
			gCurs.(tCursDomain).(tCursType).XStr = sprintf( ' %gHz', round( 100 * gCurs.(tCursDomain).(tCursType).X ) / 100 );
		end
		set( gH.( [ tCursType, 'Edit' ] ) ,'String', sprintf( '%0.2f', tX ) );
		PlotCursor( tDomain, tCursDomain, tCursType )
		SetMessage( [ tCursType, ' cursor plotted sucessfully.' ], 'status' )
	end

	function PlotCursor( tDomain, tCursDomain, tCursType )
		tX = gCurs.(tCursDomain).(tCursType).X;
		if isfield( gCurs.(tCursDomain).(tCursType), 'LH' ) && ishandle( gCurs.(tCursDomain).(tCursType).LH )			% line exists
			tY = get( get( gCurs.(tCursDomain).(tCursType).LH, 'Parent' ), 'YLim' );
			set( gCurs.(tCursDomain).(tCursType).LH, 'XData', [ tX tX ] )
			set( gCurs.(tCursDomain).(tCursType).TH, 'Position', [ tX,  0.05 * diff(tY) + tY(1), 0 ], 'String', gCurs.(tCursDomain).(tCursType).XStr )
		else
			tY = ylim;
			gCurs.(tCursDomain).(tCursType).LH = line( [ tX tX ], tY, 'Color', [ .7 .7 .7 ] );										% LH is line handle
			gCurs.(tCursDomain).(tCursType).TH = text( tX, 0.05 * diff(tY) + tY(1), gCurs.(tCursDomain).(tCursType).XStr );		% TH is text handle
		end
		UpdateCursorUserdata( tDomain, tCursDomain )
		if strcmp( tCursType, 'Frame' )
			if IsOptSel( 'AutoPaint', 'on' ) && gCortex.Open
				mrC_CortexPaint_CB		% ([],[]),  handle & eventData not currently used by this function
			end
		else
			set( gCurs.(tCursDomain).(tCursType).LH, 'LineStyle', '--' )
		end
	end

	function UpdateCursorUserdata( tDomain, tCursDomain )
		% called by: PlotCursor, mrC_CursorClear_CB, mrC_CursorStepBy_CB
		tFigH = findtag( [ 'mrC_Plot_', GetSpace, tDomain ] );
		tUD = get( tFigH, 'UserData' );
		tUD.Cursor = gCurs.(tCursDomain);
		set( tFigH, 'UserData', tUD )
	end

	function ReplaceCursors
		% called by Offset_Format
		[ tDomain, tCursDomain ] = GetDomain;
		if isfield( gCurs, tCursDomain )
			tCursTypes = { 'Frame', 'MovieStart', 'MovieStop' };
			for iCursType = 1:numel( tCursTypes )
				if isfield( gCurs.(tCursDomain), tCursTypes{ iCursType } )
					PlotCursor( tDomain, tCursDomain, tCursTypes{ iCursType } )
				end
			end
		end
	end

	function UpdateCursorEditBoxes
		tH = [ gH.FrameEdit, gH.FramePick, gH.FrameDown, gH.FrameUp, gH.MovieStartEdit, gH.MovieStopEdit, gH.MovieStartPick, gH.MovieStopPick, gH.MoviePlay, gH.CursorClear, gH.CursorStep, gH.CortexPaint ];
		if IsPlot( 'Cursor' )	% domain = Wave or Spec
			set( tH, 'enable', 'on' )
			tCursDomain = GetDomain;
			if strcmp( tCursDomain, 'SpecPhase' )
				tCursDomain = 'Spec';
			end
			tTypes = { 'Frame', 'MovieStart', 'MovieStop' };
			for iTypes = 1:numel(tTypes)
				UpdateCursorEditBox( tCursDomain, tTypes{iTypes} )
			end
			set( tH(11), 'String', sprintf('%0.2f',gCurs.(tCursDomain).StepX) )
		else
			set( tH, 'enable', 'off' )
			set( tH([1 5 6 11]), 'String', '' )
		end
	end

	function UpdateCursorEditBox( tCursDomain, tCursType )
		if IsCursor( tCursDomain, tCursType )
			set( gH.( [ tCursType, 'Edit' ] ), 'String', sprintf( '%0.2f', gCurs.(tCursDomain).(tCursType).X ) )
		else
			set( gH.( [ tCursType, 'Edit' ] ), 'String', '' )
		end
	end

	function tIsCursor = IsCursor( tCursDomain, tCursType )
		tIsCursor = isfield( gCurs, tCursDomain ) && isfield( gCurs.(tCursDomain), tCursType );
	end


%% Cortex

% 	function tCortexOpen = IsCortexOpen
% 		tCortexOpen = ~isempty( gCortex.Name );
% % 		tCortexOpen = ~isempty( gH.CortexAxis ) && ishandle( gH.CortexAxis );
% 	end

%% -- ConfigureCortex
	function ConfigureCortex
		
		tCortexNm = GetOptSelx( 'Cortex', 1 );
		switch tCortexNm
		case gCortex.Name
			if gCortex.Open
				return
			end
		case 'none'
			if gCortex.Open
				delete( gH.CortexFigure )			% use delete, not close to prevent recalling CloseRequestFcn
				gCortex.Open = false;
% 				[ gCortex.Name, gCortex.InvName ] = deal('');
% 				[ gCortex.InvM, gCortex.sensorData ] = deal([]);
% 				[ gH.CortexFigure, gH.CortexAxis, gH.CortexPatch, gH.CortexLights, gH.CortexText ] = deal([]);
			end
			return
		end
		
		if ispref( 'mrCurrent', 'AnatomyFolder' )
			tAnatFold = getpref( 'mrCurrent', 'AnatomyFolder' );
		else
			tAnatFold = uigetdir( '', 'Browse to Anatomy folder' );
			setpref( 'mrCurrent', 'AnatomyFolder', tAnatFold );
		end
		gCortex.Name = tCortexNm;
		SetMessage( [ 'Reading ' gCortex.Name '''s mesh for CortexFig...' ], 'status' )
		tMshData = load( fullfile( tAnatFold, gCortex.Name, 'Standard', 'meshes', 'defaultCortex.mat' ) );

		SetMessage( [ 'Configuring ' gCortex.Name '''s mesh for CortexFig...' ], 'status' )
		tNV = size( tMshData.msh.data.vertices, 2 );
% 		gCortex.colors                    = tMshData.msh.data.colors(1:3,:)'/255;
		gCortex.origin                    = -tMshData.msh.data.origin([3 1 2]).*[1 -1 -1];
		tMshData.msh.data.vertices        =  tMshData.msh.data.vertices([3 1 2],:)';				% PIR -> RPI
		tMshData.msh.data.vertices(:,2:3) = -tMshData.msh.data.vertices(:,2:3);						%     -> RAS
		tMshData.msh.data.vertices = tMshData.msh.data.vertices - repmat( gCortex.origin, tNV, 1 );

		% reverse triangles for outward normals in matlab.  better in general, needed for openGL on mac
		if gCortex.Open
			set( gH.CortexPatch, 'Vertices', tMshData.msh.data.vertices, 'Faces', 1 + tMshData.msh.data.triangles([3 2 1],:)', 'FaceVertexCData', repmat( 0.5, tNV, 3 ) ) %gCortex.colors )
			set( gH.CortexText, 'String', '' )
		else
			if strncmpi(computer,'MAC',3)	% ismac
				tRenderer = 'zbuffer';
			else
				tRenderer = 'OpenGL';
			end
			gH.CortexFigure = figure( 'Position', [ 400 300 400 400 ], 'Color', 'w', 'Renderer', tRenderer, 'CloseRequestFcn', @mrC_CloseCortex_CB );
			gH.CortexAxis = axes( 'Position', [ 0.05 0.05 0.9 0.9 ], 'DataAspectRatio', [1 1 1], ...
				'view', [ 0 0 ], 'cameraposition', [ 0 -gCortex.dCam 0 ], 'cameraviewangle', 2*atan(max(abs(gCortex.FOV))/gCortex.dCam)*180/pi, ...
				'XLim', gCortex.FOV, 'YLim', gCortex.FOV, 'ZLim', gCortex.FOV, 'XTick', [], 'YTick', [], 'ZTick', [], 'Visible', 'off');
			gH.CortexPatch = patch( 'Vertices',tMshData.msh.data.vertices, 'Faces',tMshData.msh.data.triangles([3 2 1],:)'+1,...
				'FaceVertexCData',repmat( 0.5, tNV, 3 ),...  %gCortex.colors,...   % 
				'FaceColor','interp', 'FaceLighting','gouraud', 'BackFaceLighting','unlit', 'EdgeColor','none',...
				'DiffuseStrength',0.7, 'SpecularStrength',0.05, 'SpecularExponent',5, 'SpecularColorReflectance',0.5 );
% 				'DiffuseStrength',0.6, 'SpecularStrength',0.01, 'SpecularExponent',10, 'SpecularColorReflectance',1 );
			gH.CortexText = text( 'String', '', 'Position', [0 1], 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top' );
			gH.CortexLights = [ light( 'Position' , [1 -1 0 ] ), light( 'Position', [-1 -1 0 ] ) ];
			set( gH.CortexLights , 'Color', [ 1 1 1 ], 'Style', 'infinite' )
			gCortex.Open = true;
		end

% 		gCortex.InvM = [];
		gCortex.InvName = '';
		set( gH.CortexFigure, 'Name', gCortex.Name )

		[ tDomain, tCursDomain ] = GetDomain;
		if IsOptSel( 'AutoPaint', 'on' ) && IsPlot( 'Offset' ) && IsCursor( tCursDomain, 'Frame' )
			mrC_CortexPaint_CB
		end

		% update scalp (contours get updated by mrC_CortexPaint_CB above, scalp is indendent of data)
		if get( gH.CortexScalp, 'Value' ) == 1
			mrC_CortexScalp_CB( gH.CortexScalp )
		end
		
		SetMessage( [ 'Configuring ' gCortex.Name '''s mesh for CortexFig...Done' ], 'status' )
	end

	function mrC_CloseCortex_CB( varargin )
		if isempty( findobj( 'Tag', 'mrC_GUI' ) )		% mrCurrent already closed, user closing cortex window.
			delete( varargin{1} )							% this shouldn't happen anymore, CloseRequestFcn should be turned off
		else
			% Restores option listbox cortex item setting to 'none'.
			% + sets off chain of calls that closes cortex window
			SetOptSel( 'Cortex', 'none' );
		end
	end

%% -- SetCortexFigColorMap
	function SetCortexFigColorMap
% 		tCutFrac = GetOptSelx( 'ColorCutoff', 1, true ) / 100.0;
		tCutoff = GetOptSelx( 'ColorCutoff', 1, true );
		tCLim = get(gH.CortexAxis,'CLim');
% 		tCutFrac = ( tCutoff - tCLim(1) ) / diff( tCLim );
		tCutFrac = tCutoff / tCLim(2);
		tCutFrac = min( tCutFrac, 1 );
		switch GetDomain
		case 'Wave'
			tCM = flow( 255, tCutFrac );
		case 'SpecPhase'
			tCM = hsv(255);
		otherwise	% 'Spec'?
			tCLevels = 255;
			tCM = hot( tCLevels + 100 );
			tCM = tCM( 1:tCLevels, : );
			tCM( 1:(round(tCLevels*tCutFrac)), : ) = 0.5;
		end
		set( gH.CortexFigure, 'colormap', tCM ); % This will be confused by more than one figure
	end

%% -- Paint
	function PaintROIsOnCortex
		if ~gCortex.Open
			SetMessage( 'Load a cortex 1st to paint ROIs.', 'error' )
		end
		tCortexROIsPN = GetSbjROIsPN( gCortex.Name );
		tAllROIs = gChartFs.ROIs.Items( gChartFs.ROIs.Sel );
		tHems = gChartFs.Hems.Items( gChartFs.Hems.Sel );
		if numel( tHems ) == 1
			switch tHems{1}
				case 'Bilat'
					tAllROIs = [ strcat(tAllROIs,'-L.mat'); strcat(tAllROIs,'-R.mat') ];
				case 'Left'
					tAllROIs = strcat(tAllROIs,'-L.mat');
				case 'Right'
					tAllROIs = strcat(tAllROIs,'-R.mat');
			end
		else
			tAllROIs = [ strcat(tAllROIs,'-L.mat'); strcat(tAllROIs,'-R.mat') ];
		end
		tCmap = repmat( 0.5, size( get( gH.CortexPatch, 'Vertices' ), 1 ), 3 ); % gCortex.colors;
		fprintf('\n\nPainting ROIs on %s cortex\n',gCortex.Name)
		for iROI = 1:numel(tAllROIs)
			tROI = load( fullfile( tCortexROIsPN, tAllROIs{iROI} ) );
			tZeroInd = tROI.ROI.meshIndices == 0;
			if any( tZeroInd )
				tROI.ROI.meshIndices = tROI.ROI.meshIndices( ~tZeroInd );
				fprintf( '%s: %0.1f%% zero-index nodes\n', tROI.ROI.name, sum(tZeroInd)*(100/numel(tZeroInd)) )
			else
% 				fprintf( '%s: no unmapped nodes\n', tROI.ROI.name )
			end
			if ischar(tROI.ROI.color)
				switch tROI.ROI.color
				case 'r'
					tCmap(tROI.ROI.meshIndices,1) = 1;
					tCmap(tROI.ROI.meshIndices,2:3) = 0;
				case 'g'
					tCmap(tROI.ROI.meshIndices,[1 3]) = 0;
					tCmap(tROI.ROI.meshIndices,2) = 1;
				case 'b'
					tCmap(tROI.ROI.meshIndices,1:2) = 0;
					tCmap(tROI.ROI.meshIndices,3) = 1;
				case 'm'
					tCmap(tROI.ROI.meshIndices,[1 3]) = 1;
					tCmap(tROI.ROI.meshIndices,2) = 0;
				case 'y'
					tCmap(tROI.ROI.meshIndices,1:2) = 1;
					tCmap(tROI.ROI.meshIndices,3) = 0;
				case 'c'
					tCmap(tROI.ROI.meshIndices,1) = 0;
					tCmap(tROI.ROI.meshIndices,2:3) = 1;
				case 'k'
					tCmap(tROI.ROI.meshIndices,:) = 0;
				case 'w'
					tCmap(tROI.ROI.meshIndices,:) = 1;
				otherwise
					SetMessage( ['Unknown color for ROI ',tROI.ROI.name, ' .'], 'warning' )
				end
			else
				tCmap(tROI.ROI.meshIndices,:) = repmat( tROI.ROI.color, numel( tROI.ROI.meshIndices ), 1 );
			end
		end
		set( gH.CortexPatch, 'FaceVertexCData', tCmap )
		set( gH.CortexText, 'String', 'ROI' )
	end

	function mrC_CortexPaint_CB( varargin )
		[ tDomain, tCursDomain ] = GetDomain;
		if nargin ~= 0		% called from pushbutton
			if ~gCortex.Open													% *** disable paint button in these conditions?
				SetMessage( 'Need a cortex before painting.', 'error' )
			end
			if ~IsPlot( 'Offset' )	% || IsPlot( 'Sensor' )
				SetMessage( 'Can''t paint cortex from this Domain &/or Space', 'error' )		% Wave or Spec
			end
			if ~IsCursor( tCursDomain, 'Frame' )
				SetMessage( 'Need to set a frame cursor before painting.', 'warning' )
				return
			end
% 		elseif ~all( [ gCortex.Open, IsPlot( 'Offset' ), IsCursor( tCursDomain, 'Frame' ) ] )
% 			return
		end

		% For now, only first of selected Invs.
		% Soon, we will allow context-sensitive comparisons
		tInvNm = GetChartSelx( 'Invs', 1 );
		if isempty( gCortex.InvM ) || ~strcmp( gCortex.InvName, tInvNm )
			tInvPFN = fullfile( gProjPN, gCortex.Name, gInvDir, [ tInvNm '.inv' ] );
			SetMessage( [ 'Reading ' gCortex.Name '''s inverse for CortexFig...' ], 'status' )
			gCortex.InvM = mrC_readEMSEinvFile( tInvPFN )';			% should be tNV x tNCh.
			gCortex.InvName = tInvNm;
		end
		
		SetFilteredWaveforms							% need this to paint filtered data.
		
		switch tCursDomain
		case 'Wave'
			tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
		case 'Spec'
			tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
		end
		SD = InitSliceDescription( tValidFields, false );		% only first of selected Cnds, Flts.  all Chans.
		if ( numel( SD.Cnds.Items ) > 1 ) || ( numel( SD.Flts.Items ) > 1 )
			SetMessage( 'Cortex painting only showing 1st of multiple selected conditions or filters.', 'warning' )
		end
		tNSbj = numel( SD.Sbjs.Items );		% # selections, not necessarily subjects
		tAvgSbjs = tNSbj > 1;
		if tAvgSbjs
			SD.Sbjs.Sel = 1:tNSbj;
		elseif strncmp( SD.Sbjs.Items{ SD.Sbjs.Sel(1) }, 'GROUP_', 6 )
			tAvgSbjs = true;
		end
		[ tYM, tJunk, tNSbjs ] = getAvgSliceData( [ tAvgSbjs, false ], SD, tDomain, tValidFields );
		% non-conjugate transposed to nCh x nX, for use as operand for max(max()) and inv multiplication.
		tYM = tYM.';		% nX = #time points or frequencies
		if tAvgSbjs
			SetMessage( sprintf( 'Projecting %d-subject sensor average to single cortex.', tNSbjs ), 'warning' )
		end

% 		SetCortexFigColorMap
		tiX = gCurs.(tCursDomain).Frame.iX;
		if strcmp( tCursDomain, 'Wave' )
			tNT = size( tYM, 2 );
			if tiX > tNT
				tiX = mod( tiX-1, tNT ) + 1;
			end
		end
		if ~strcmp( tDomain, 'SpecPhase' )
			tCmax = GetOptSelx( 'ColorMapMax', 1 );
			switch tCmax
			case 'All'
				tCmax = mrC_CortexGetClim( tYM );
				SetMessage( sprintf('Colormap Max = %0.3g',tCmax), 'status' )
			case 'Cursor'
				tCmax = max( abs( gCortex.InvM * ( tYM( :, tiX ) * 1e6 ) ) );
				SetMessage( sprintf('Colormap Max = %0.3g',tCmax), 'status' )
			otherwise
				tCmax = eval( tCmax );
			end
		end
		gCortex.sensorData = tYM( :, tiX ) * 1e6;
		switch tDomain
		case 'Wave'
			caxis( gH.CortexAxis, [ -tCmax tCmax ] );		% default assuming WavePlot
			set( gH.CortexPatch, 'FaceVertexCData', gCortex.InvM * gCortex.sensorData );
		case 'SpecPhase'
			caxis( gH.CortexAxis, [ -180 180 ] );
			set( gH.CortexPatch, 'FaceVertexCData', angle( gCortex.InvM * gCortex.sensorData ) * (180/pi) );
		otherwise
			caxis( gH.CortexAxis, [ 0 tCmax ] );
			set( gH.CortexPatch, 'FaceVertexCData', abs( gCortex.InvM * gCortex.sensorData ) );
		end
		set( gH.CortexText, 'String', get( gCurs.(tCursDomain).Frame.TH, 'String' ) )
		SetCortexFigColorMap
		
		mrC_CortexContour_CB( gH.CortexContour )
	end

	function mrC_CortexContour_CB( tH, varargin )
		
		if ~gCortex.Open
			if get( tH, 'Value') == 1
				SetMessage( 'Need a cortex before drawing sensor contours.', 'warning' )
			end
			return
		end
		
		delete( gH.CortexLines )
		gH.CortexLines = [];
		if get( tH, 'Value') == 0
			return
		end
		
		[ tDomain, tCursDomain ] = GetDomain;
		if ~IsCursor( tCursDomain, 'Frame' )
			SetMessage( 'Need to set a frame cursor for sensor contours.', 'error' )
		end
		
		tEpos = GetSensorPos( gCortex.Name, true );
% 		tNE = size(tEpos,1);
		
		% register with MRI
		tReg = load( '-ascii', fullfile(gProjPN,gCortex.Name,'_MNE_','elp2mri.tran') )';		% 4x3 after transponse, last col = [0;0;0;1]
		tEpos = [ tEpos(1:128,:)*1e3, ones(128,1) ] * tReg(:,1:3);
		
		% subtract origin of best fitting sphere & convert to spherical coords [theta,phi,radius]
		tOrigin = fminsearch( @(tO) mrC_SphereObjFcn(tO,tEpos,128), median(tEpos) );
		[ tEpos(:,1), tEpos(:,2), tEpos(:,3) ] = cart2sph( tEpos(:,1)-tOrigin(1), tEpos(:,2)-tOrigin(2), tEpos(:,3)-tOrigin(3) );
		% map radius as function of theta & phi
		[ ThetaGrid, PhiGrid ] = meshgrid( linspace(-pi,pi,30), linspace(-pi/2,pi/2,20) );
		RadiusGrid = griddata( tEpos(1:128,1), tEpos(1:128,2), tEpos(1:128,3), ThetaGrid, PhiGrid, 'v4' );
		% flatten to [x,y] coords, z-dimension = activity
		tPflat = 0.6;
		tEflat = [ zeros( 128, 2 ), gCortex.sensorData ];
		[ tEflat(:,1), tEflat(:,2) ] = pol2cart( tEpos(1:128,1), ( 1 - sin( tEpos(1:128,2) ) ).^tPflat );
		switch tDomain
		case 'Spec'
			tEflat(:,3) = abs( tEflat(:,3) );
		case 'SpecPhase'
			tEflat(:,3) = angle( tEflat(:,3) ) * (180/pi);
		end
		% Get contours lines on flattened spherical projection
% 		tNc = 8;								% # contour values
		tNc = eval( get( gH.CortexContourNum, 'String' ) );		% *** give this uicontrol a callback to enforce legal values
		tZmin = min( tEflat(:,3) );
		tZmax = max( tEflat(:,3) );
		tZdelta = ( tZmax - tZmin ) / ( tNc + 1 );
		tXYgrid = -1.5:0.01:1.5;
		[ tXgrid, tYgrid ] = meshgrid( tXYgrid );
		C = contourc( double(tXYgrid), double(tXYgrid), griddata( double(tEflat(:,1)), double(tEflat(:,2)), double(tEflat(:,3)), double(tXgrid), double(tYgrid), 'cubic' ),...
							double(linspace( tZmin + tZdelta/2, tZmax - tZdelta/2, tNc ) ));
		% loop through contours & add to cortex plot
		tOrigin = tOrigin - (gCortex.origin+[-128 128 128]);
		
% 		tNmap = 255;
% 		tCmap = jet(tNmap);
		tCmap = get( gH.CortexFigure, 'colormap' );
		tNmap = size( tCmap, 1 );
		
		switch tDomain
		case 'Wave'
			if tZmax > -tZmin
				tZmin = -tZmax;
			else
				tZmax = -tZmin;
			end
% 		case 'Spec'
% 			tZmin = 0;
		case 'SpecPhase'
			tZmin = -180;
			tZmax =  180;
		end
		
		k = 0;
		while k < size(C,2)
			k = k + 1;
			tkC = ( k + 1 ):( k + C(2,k) );
			% retrieve theta & phi from flattened contours
			cTheta = atan2( C(2,tkC), C(1,tkC) );
			cPhi   = asin( 1 - hypot( C(1,tkC), C(2,tkC) ).^(1/tPflat) );
			% interpolate radius & transform to cartesian coords
			[ tX3D, tY3D, tZ3D ] = sph2cart( cTheta, cPhi, interp2( ThetaGrid, PhiGrid, RadiusGrid, cTheta, cPhi, 'cubic' ) );		% nearest,linear,spline,cubic
			gH.CortexLines = cat( 1, gH.CortexLines,...
				line( tX3D+tOrigin(1), tY3D+tOrigin(2), tZ3D+tOrigin(3), 'Parent', gH.CortexAxis,...
						'Color', tCmap( 1 + round( (tNmap-1)/(tZmax-tZmin) * ( C(1,k) - tZmin ) ), : ), 'LineWidth', 2 ) );
			k = tkC( C(2,k) );
		end
		
	end

	function mrC_CortexScalp_CB( tH, varargin )
		if ~gCortex.Open
			if get( tH, 'value' ) == 1
				SetMessage( 'Need a cortex before adding scalp.', 'warning' )
			end
			return
		end
		delete( gH.ScalpPatch )
		gH.ScalpPatch = [];
		if get( tH, 'Value') == 0
			return
		end
		% scalp, outer skull, inner skull (m) head-centered RAS coords
		try
			tBEM = mne_read_bem_surfaces( fullfile( getpref('mrCurrent','AnatomyFolder'), 'FREESURFER_SUBS',...
													[gCortex.Name,'_fs4'] , 'bem', [gCortex.Name,'_fs4-bem.fif'] ) );
		catch
			if ~exist('mne_read_bem_surfaces','file')
				SetMessage( 'mrCurrent Scalp requires MNE Matlab toolbox.', 'error' )
			end
		end
% 		tOrigin = tOrigin - (gCortex.origin+[-128 128 128]);
		tBEM(1).rr = tBEM(1).rr*1000;
		tBEM(1).rr = tBEM(1).rr - repmat( gCortex.origin + [-128 128 128], tBEM(1).np, 1 );
		gH.ScalpPatch = patch( 'Vertices', tBEM(1).rr, 'Faces', tBEM(1).tris, 'FaceColor', [1 0.5 0.5], 'EdgeColor', 'none',...
										'FaceAlpha', 0.25, 'FaceLighting', 'gouraud', 'Parent', gH.CortexAxis );
	end

	function mrC_CursorPlay_CB( varargin )
		if ~gCortex.Open
			SetMessage( 'Need a cortex before playing animation.', 'error' )
		end

		[ tDomain, tCursDomain ] = GetDomain;
		if ~( IsCursor( tCursDomain, 'MovieStart' ) && IsCursor( tCursDomain, 'MovieStop' ) )
			SetMessage( 'Need to set movie start and end cursors before playing animation.', 'error' )
		end

		% get mean sensor data for requested time/frequency points
		switch tCursDomain
		case 'Wave'
			tStepBy = round( gCurs.Wave.StepX / GetDTms(1) );
			iMovie = [ gCurs.Wave.MovieStart.iX,  (gCurs.Wave.MovieStart.iX+tStepBy):tStepBy:(gCurs.Wave.MovieStop.iX-1) , gCurs.Wave.MovieStop.iX ];
			tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
		case 'Spec'
			tStepBy = round( gCurs.Spec.StepX / GetDFHz(1) );
			iMovie = [ gCurs.Spec.MovieStart.iX,  (gCurs.Spec.MovieStart.iX+tStepBy):tStepBy:(gCurs.Spec.MovieStop.iX-1) , gCurs.Spec.MovieStop.iX ];
			tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
		otherwise
			SetMessage( 'Cortex Playback only works in Wave and Spec domains.', 'warning' )
			return							
		end

% 		SD = InitSliceDescription( tValidFields, false );		% only first of selected Cnds, Flts.  all selected Chans.
% 		if ( numel( SD.Cnds.Items ) > 1 ) || ( numel( SD.Flts.Items ) > 1 )
% 			SetMessage( 'Cortex playback only showing 1st of multiple selected conditions or filters.', 'warning' )
% 		end
% 		tYM = getAvgSliceData( [ true, false ], SD, tDomain, tValidFields, false(1,3), iMovie ).' * 1e6;

		SD = InitSliceDescription( tValidFields, false );		% only first of selected Cnds, Flts.  all Chans.
		if ( numel( SD.Cnds.Items ) > 1 ) || ( numel( SD.Flts.Items ) > 1 )
			SetMessage( 'Cortex playback only showing 1st of multiple selected conditions or filters.', 'warning' )
		end
		tNSbj = numel( SD.Sbjs.Items );		% # selections, not necessarily subjects
		tAvgSbjs = tNSbj > 1;
		if tAvgSbjs
			SD.Sbjs.Sel = 1:tNSbj;
		elseif strncmp( SD.Sbjs.Items{ SD.Sbjs.Sel(1) }, 'GROUP_', 6 )
			tAvgSbjs = true;
		end
		[ tYM, tJunk, tNSbjs ] = getAvgSliceData( [ tAvgSbjs, false ], SD, tDomain, tValidFields, false(1,3), iMovie );
		tYM = tYM.' * 1e6;		% nX = #time points or frequencies
		if tAvgSbjs
			SetMessage( sprintf( 'Projecting %d-subject sensor average to single cortex.', tNSbjs ), 'warning' )
		end


		SetCortexFigColorMap
		SetMessage( 'Playing cortex animation.', 'warning' )
% 		tInvNm = GetChartSelx( 'Invs', 1 );
		tHprogL = line('Parent',get(gCurs.(tCursDomain).MovieStart.LH,'Parent'),'XData',get(gCurs.(tCursDomain).MovieStart.LH,'XData'),'YData',get(gCurs.(tCursDomain).MovieStart.LH,'YData'),'Color','k','LineWidth',1);
		tic
		switch tCursDomain
		case 'Wave'
			for iFrame = 1:numel(iMovie)
				tX = gCurs.(tCursDomain).XData( iMovie( iFrame ) );
				set( gH.CortexPatch, 'FaceVertexCData', gCortex.InvM * tYM( :, iFrame ) );
				set( gH.CortexText, 'String', [ num2str(round(tX)), 'ms' ] )
				set( tHprogL, 'XData', [ tX tX ] )
				drawnow
			end
		case 'Spec'
			for iFrame = 1:numel(iMovie)
				tX = gCurs.(tCursDomain).XData( iMovie( iFrame ) );
				if strcmp( tDomain, 'SpecPhase' )
					set( gH.CortexPatch, 'FaceVertexCData', angle( gCortex.InvM * tYM( :, iFrame ) ) * (180/pi) );
				else
					set( gH.CortexPatch, 'FaceVertexCData', abs( gCortex.InvM * tYM( :, iFrame ) ) );
				end
				set( gH.CortexText, 'String', [ num2str(round(100*tX)/100), 'Hz' ] )
				set( tHprogL, 'XData', [ tX tX ] )
				drawnow
			end
		end
		delete( tHprogL )
		SetMessage( sprintf('Playback complete. (%0.1f sec)',toc), 'status' )
	end

	function makeCortexMosaic

		if ~gCortex.Open
			SetMessage( 'Load a cortex before creating mosaic.', 'error' )
		end
		[ tDomain, tCursDomain ] = GetDomain;
		tSpecFlag = strcmp( tCursDomain, 'Spec' );
		if tSpecFlag
			tSpecCursorFlag = IsCursor( tCursDomain, 'Frame' );
			if tSpecCursorFlag
				tValid = { 'Cnds', 'Sbjs', 'Chans', 'Invs' };
			else
				tValid = { 'Cnds', 'Sbjs', 'Chans', 'Comps', 'Invs' };
			end
			tSpecPhaseFlag = strcmp( tDomain, 'SpecPhase' );
			if tSpecPhaseFlag
				caxis( gH.CortexAxis, [ -180 180 ] );
				SetCortexFigColorMap
			end
		else
			if ~IsCursor( tCursDomain, 'Frame' )
				SetMessage( 'Set frame cursor before creating mosaic.', 'error' )
			end
			tValid = { 'Cnds', 'Sbjs', 'Flts', 'Chans', 'Invs' };
		end

		% note: there's no subject averaging in makeCortexMosaic!
		SD = InitSliceDescription( tValid, false );
		SD.Sbjs.Items = unique( Groups2Members( SD.Sbjs.Items ) );

		[tRowDim,tNrow] = testMosaicDim(1);
		[tColDim,tNcol] = testMosaicDim(2);
		[tCmpDim,tNcmp] = testMosaicDim(3);
		if tNcmp > 1
			tSels = gChartFs.(tCmpDim).Sel;
			for iCmp = 1:tNcmp
% 				gChartFs.(tCmpDim).Sel = tSels(iCmp);
				gChartFs.(tCmpDim).Sel = find( strcmp( gChartFs.(tCmpDim).Items, SD.(tCmpDim).Items{iCmp} ) );
				UpdateChartListBox
				makeCortexMosaic
			end
			gChartFs.(tCmpDim).Sel = tSels;
			UpdateChartListBox
			return
		end
		
		for tCheck = setdiff( tValid, 'Chans' )
			SD.(tCheck{1}).Items  = check4VectorPage( SD.(tCheck{1}).Items, tCheck{1} );
		end
		
		if isempty(tRowDim)
			tYlabel = '';
		else
			tYlabel = GetChartSelx( tRowDim );
		end
		if isempty(tColDim)
			tXlabel = '';
		else
			tXlabel = GetChartSelx( tColDim );
		end
				
% 		SetCortexFigColorMap		% only needs update if ColorCutoff or Wave/Spec-type changed
		
		% cortex figure needs to be on main screen for getFrame (at least on my win2K)
		tFigPos = get( gH.CortexFigure, 'Position' );
		tScreenSize = get(0,'screensize');
		if any( tFigPos(1:2) <0 ) || any( (tFigPos(1:2)+tFigPos(3:4)) > tScreenSize(3:4) )
			set( gH.CortexFigure, 'Position', [ 20, tScreenSize(4)-tFigPos(4)-75-20, tFigPos(3:4) ] )
		end
		tMosDim = size( frame2im( getframe( gH.CortexAxis ) ) );		% depends on axes view anyhow
		tMosaic = uint8( zeros( tNrow*tMosDim(1), tNcol*tMosDim(2), 3 ) );
		tCmaxMode = GetOptSelx( 'ColorMapMax', 1 );
		if ~any( strcmp( tCmaxMode, { 'All', 'Cursor' } ) )
			tCmax = eval( tCmaxMode );		% UserDef:
		end

		for iSbj = 1:numel( SD.Sbjs.Items )
			iRow = 1;
			iCol = 1;
			SD.Sbjs.Sel = iSbj;
			checkRowCol( 'Sbjs' )
			if ~strcmp( SD.Sbjs.Items{iSbj}, gCortex.Name )
				set( gH.CortexContour, 'Value', 0 )
				SetOptSel( 'Cortex', SD.Sbjs.Items{iSbj} )	% this lead to ConfigureCortex call & is where contours getting updated at the moment.  once per subject = NO GOOD.
				ConfigureCortex		% redundant?
			elseif get( gH.CortexContour, 'Value' ) ~= 0
				set( gH.CortexContour, 'Value', 0 )
				mrC_CortexContour_CB( gH.CortexContour )
			end
			set( gH.CortexText, 'String', '' )
			for iInv = 1:numel( SD.Invs.Items )
				SD.Invs.Sel = iInv;
				checkRowCol( 'Invs' )
				if isempty( gCortex.InvM ) || ~strcmp( gCortex.InvName, SD.Invs.Items{iInv} )
					SetMessage( [ 'Reading ' gCortex.Name '''s inverse for CortexFig...' ], 'status' )
					gCortex.InvM = mrC_readEMSEinvFile( fullfile( gProjPN, gCortex.Name, gInvDir, [ SD.Invs.Items{iInv}, '.inv' ] ) )';
					gCortex.InvName = SD.Invs.Items{iInv};
				end
				for iCnd = 1:numel( SD.Cnds.Items )
					SD.Cnds.Sel = iCnd;
					checkRowCol( 'Cnds' )
					if tSpecFlag
						tData = getSliceData( SD, tDomain, tValid );
						if ~tSpecPhaseFlag
							switch tCmaxMode
							case 'All'
								tCmax = mrC_CortexGetClim( tData.' );
								caxis( gH.CortexAxis, [ 0 tCmax ] );
								SetCortexFigColorMap
							case 'Cursor'
							otherwise
								caxis( gH.CortexAxis, [ 0 tCmax ] );
								SetCortexFigColorMap
							end
						end
						if tSpecCursorFlag	% use Cursor, not Comps
							if tSpecPhaseFlag
								set( gH.CortexPatch, 'FaceVertexCData', angle( gCortex.InvM * ( 1e6 * tData(gCurs.Spec.Frame.iX,:).' ) ) * (180/pi) )
							else
								if strcmp( tCmaxMode, 'Cursor' )
									tCmax = max( abs( gCortex.InvM * ( 1e6 * tData(gCurs.Spec.Frame.iX,:).' ) ) );
									caxis( gH.CortexAxis, [ 0 tCmax ] );
									SetCortexFigColorMap
								end
								set( gH.CortexPatch, 'FaceVertexCData', abs( gCortex.InvM * ( 1e6 * tData(gCurs.Spec.Frame.iX,:).' ) ) )
							end
							figure( gH.CortexFigure )
							tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gH.CortexAxis ) );
						else
							for iComp = 1:numel( SD.Comps.Items )
								SD.Comps.Sel = iComp;
								checkRowCol( 'Comps' )
% 								tData = getSliceData( SD, tDomain, tValid );
								tData = getSliceData( SD, 'Bar', tValid );
								if tSpecPhaseFlag
									set( gH.CortexPatch, 'FaceVertexCData', angle( gCortex.InvM * ( 1e6 * tData.' ) ) * (180/pi) )
								else
									if strcmp( tCmaxMode, 'Cursor' )
										tCmax = max( abs( gCortex.InvM * ( 1e6 * tData.' ) ) );
										caxis( gH.CortexAxis, [ 0 tCmax ] );
										SetCortexFigColorMap
									end
									set( gH.CortexPatch, 'FaceVertexCData', abs( gCortex.InvM * ( 1e6 * tData.' ) ) )
								end
								figure( gH.CortexFigure )
								tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gH.CortexAxis ) );
							end
						end
					else
						for iFlt = 1:numel( SD.Flts.Items )
							SD.Flts.Sel = iFlt;
							checkRowCol( 'Flts' )
							tData = getSliceData( SD, tDomain, tValid );
							set( gH.CortexPatch, 'FaceVertexCData', gCortex.InvM * ( 1e6 * tData( mod( gCurs.Wave.Frame.iX - 1, size(tData,1) ) + 1 , : ).' ) )
							switch tCmaxMode
							case 'All'
								tCmax = mrC_CortexGetClim( tData.' );
							case 'Cursor'
								tCmax = max( abs( get( gH.CortexPatch, 'FaceVertexCData' ) ) );
							end
							caxis( gH.CortexAxis, [ -tCmax tCmax ] );
% 							mrC_CortexContour_CB( gH.CortexContour )		*** need to udate gCortex.sensorData !!!
							figure( gH.CortexFigure )		% cortex figure should be on top
							SetCortexFigColorMap
							tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gH.CortexAxis ) );
						end
					end
				end
			end
		end
		
		tMosFig = figure('Units','pixels','Position',[100 100 700 500]);
		if ~isempty(tCmpDim)
			set( tMosFig, 'Name', gChartFs.(tCmpDim).Items{ gChartFs.(tCmpDim).Sel } )		% should only be 1 selection
		end
		image( tMosaic )
		axis image
		set( gca, 'XTick', (1:tNcol)*tMosDim(2)-tMosDim(2)/2, 'YTick', (1:tNrow)*tMosDim(1)-tMosDim(1)/2, 'XTickLabel', tXlabel, 'YTickLabel', tYlabel )
		if tSpecFlag
			if tSpecCursorFlag
				title( gCurs.Spec.Frame.XStr )
			end
		else
			title( gCurs.Wave.Frame.XStr )
		end
		SetMessage( 'Cortex mosaic done', 'status' )

		return %-----makeCortexMosaic sub-functions-----
		function [tDimName,tDimN] = testMosaicDim(iChart)
			tDimName = gChartL.Items{iChart};			
			if any( strcmp( tDimName, tValid ) )
% 				tDimN = numel( gChartFs.( tDimName ).Sel );
				tDimN = numel( SD.( tDimName ).Items );
			else
				tVectorDims = { 'row', 'col', 'cmp' };
				SetMessage( [tVectorDims{iChart},' dimension ',tDimName,' is irrelevant for Cortex Mosaic.'], 'warning' )
				tDimName = '';
				tDimN = 1;
			end
		end

		function tOutCell = check4VectorPage( tInCell, tField )
			tOutCell = tInCell;
			if ~any( strcmp( tField, { tRowDim, tColDim, tCmpDim } ) ) && numel( tInCell )>1
				tOutCell = tOutCell(1);
				SetMessage( [ 'Vector page dimension ',tField,' being scalarized for cortex mosaic'], 'warning' )
			end
		end

		function checkRowCol( tField )
			if strcmp( tField, tRowDim )
				iRow = find (strcmp( gChartFs.(tField).Items( gChartFs.(tField).Sel ), SD.(tField).Items{ SD.(tField).Sel } ) );
			elseif strcmp( tField, tColDim )
				iCol = find (strcmp( gChartFs.(tField).Items( gChartFs.(tField).Sel ), SD.(tField).Items{ SD.(tField).Sel } ) );
			end
		end
	end

	function tCYMx = mrC_CortexGetClim( tY )
		% get global max for balanced color limits; for complex, max returns complex w/ largest amp.
		[ tCYMx, tCiXMx ] = max( max( tY ) );			% max over channels, then over x
% 		tCYMx = abs( max( gCortex.InvM * ( tY( :, tCiXMx ) * 1e6 ) ) );		% max in source space; abs b/c max still may be complex.
		tCYMx = max( abs( gCortex.InvM * ( tY( :, tCiXMx ) * 1e6 ) ) );		% this way handles negative extrema
	end

%% -- Mesh Manipulation
	% these three functions can be consolidated into one callback with conditonals and nesting.
	function mrC_CortexRotate_CB( tH, varargin )		
		tView = get( gH.CortexAxis, 'view' );
		switch tH
		case gH.RotateR
			tView(1) = tView(1) + str2double( get( gH.RotateEdit, 'String' ) );
		case gH.RotateL
			tView(1) = tView(1) - str2double( get( gH.RotateEdit, 'String' ) );
		case gH.RotateD
			tView(2) = tView(2) + str2double( get( gH.RotateEdit, 'String' ) );
		case gH.RotateV
			tView(2) = tView(2) - str2double( get( gH.RotateEdit, 'String' ) );
		end
		set( gH.CortexAxis, 'view', tView )
		mrC_CortexCamlights
	end

	function mrC_CortexView_CB( tH, varargin )
		switch tH
		case gH.ViewP
			set( gH.CortexAxis, 'view', [ 0 0 ] )
		case gH.ViewA
			set( gH.CortexAxis, 'view', [ 180 0 ] )
		case gH.ViewL
			set( gH.CortexAxis, 'view', [ -90 0 ] )
		case gH.ViewR
			set( gH.CortexAxis, 'view', [ 90 0 ] )
		case gH.ViewD
			set( gH.CortexAxis, 'view', [ 0 90 ] )
		case gH.ViewV
			set( gH.CortexAxis, 'view', [ 0 -90 ] )
		end
		% note: campos doesn't update 'view' in time for mrC_CortexCamlights w/o a drawnow which is visibly awkward
		mrC_CortexCamlights
	end

	function mrC_CortexCamlights
		tView = get( gH.CortexAxis, 'view' ) * pi/180;
		rotMat = [	               cos(tView(1)),               sin(tView(1)),              0;...
						-cos(tView(2))*sin(tView(1)), cos(tView(2))*cos(tView(1)), -sin(tView(2));...
						-sin(tView(2))*sin(tView(1)), sin(tView(2))*cos(tView(1)),  cos(tView(2))	];
		set( gH.CortexAxis, 'cameraposition', [ 0 -gCortex.dCam 0]*rotMat )
		set( gH.CortexLights(1), 'Position', [ 1 -1 0]*rotMat )
		set( gH.CortexLights(2), 'Position', [-1 -1 0]*rotMat )
	end

%% Helpers
	function tH = findtag( aTagStr )
		tH = findobj( 'Tag', aTagStr );
	end

% 	function tHs = findtags( aCASTagStrs )
% 		tHs = cellfun( @(tTagStr) findtag( tTagStr ), aCASTagStrs );
% 	end

	function SetMessageText( aStr, aCM )
		set( gH.MessageText, 'String', aStr, 'backgroundcolor', aCM )
		drawnow
	end

	function SetMessage( aStr, aType )
		switch aType
		case 'status'
			SetMessageText( aStr, [ 0.7 1 0.7 ] )		% green-gray background
% 			disp( aStr )
		case 'warning'
			SetMessageText( aStr, [ 1 1 0 ] )			% yellow background
			warning( 'mrCurrent:Trouble', aStr )
		case 'error'
			SetMessageText( aStr, [ 1 0 0 ] )			% red background
			error( aStr )
		end
	end
	
	function SetWarning( aStr )
		SetMessageText( [ aStr '... Will continue in 5 sec.' ], [ 1 1 0 ] ); % yellow background
		pause( 5 );
	end

	function ResizeMrCG( tH, varargin )
		% When user resizes GUI, this function will re-center the figure
		% and rescale all UI objects, preserving the aspect ratio, and if
		% the figure is too large, will resize it to 90% of screen height.
		set( tH, 'Visible', 'off' ); % this doesn't quite work...
		tUD = get( tH, 'UserData' ); % a struct with field tOldPos, that was set the last time the figure was resized.
		tNewPos = get( tH, 'Position' );
		tVSF = tNewPos(4) / tUD.tOldPos(4); % vertical scale factor, assuming it's not too large.
		tScrPos = ScreenPosChar;
		% If it's bigger than 90% of screen size, reset tVSF
		if tNewPos(4) > 0.90 * tScrPos(4), tVSF = 0.90 * tScrPos(4) / tUD.tOldPos(4); end
		% set position to reflect this VSF
		set( tH, 'Position', [ tVSF * tNewPos( 1:2 ) tVSF * tUD.tOldPos( 3:4 ) ] );
		ReScaleMrCG( tH, tVSF ); % nested below
		% now, center it...
		tMrCGPos = get( tH, 'Position' );
		tMrCGPos(1:2) = 0.5 * ( tScrPos(3:4) - tMrCGPos(3:4) );
		% now reset user data to reflect new position.
		tUD.tOldPos = tMrCGPos;
		set( tH, 'Position', tMrCGPos, 'UserData', tUD, 'Visible', 'on' );

		function ReScaleMrCG( tPH, tVSF )
			% Start with gH.Figure, the handle for the figure.
			% Then, recursively drill down to each uicontrol object, resizing as we go.
			% untested tHSF should act like aspect ratio for width, for platform-specific behavior.
			tCHs = findobj( tPH, '-depth', 1 ); % get child handles from top level of parent
			% tCH(1) == tPH, so handle parent panel first, then children recursively
			if ~strcmpi( get( tCHs(1), 'Type' ), 'figure' )
				set( tCHs(1), 'FontSize', tVSF * get( tCHs(1), 'FontSize' ), 'Position', tVSF * get( tCHs(1), 'Position' ) );
			end
			for i = 2:numel( tCHs )
				tCH = tCHs(i);
				if strcmpi( get( tCH, 'Type' ), 'uipanel' )
					ReScaleMrCG( tCH, tVSF ); % begin recursion, using this panel as the new parent
				else
					set( tCH, 'FontSize', tVSF * get( tCH, 'FontSize' ), 'Position', tVSF * get( tCH, 'Position' ) );
				end
			end
		end

		function tScrPos = ScreenPosChar
			% get position coordinates of primary screen in characters
% 			tSFH = figure( 'Position', get( 0, 'screensize' ), 'Units', 'characters' );
% 			tScrPos = get( tSFH, 'Position' );
% 			close( tSFH );
			oldFontUnits = get(0,'defaulttextfontunits');
			set(0,'defaulttextfontunits','points')
			tScrPos = [0 0 round( get(0,'ScreenSize')*[zeros(2);eye(2)] / get(0,'ScreenPixelsPerInch') * 72 / get(0,'defaulttextfontsize') .* [8/3 1] ) ];
			set(0,'defaulttextfontunits',oldFontUnits)
		end
	end

	function tColorOrderMat = GetColorOrderRGB
		tDefaultColorOrderNames = mrC_DefaultColorOrderNames;
		tNColors = numel(tDefaultColorOrderNames);
		tColorOrderMat = zeros( tNColors, 3 );
		for iColor = 1:tNColors
			switch tDefaultColorOrderNames{iColor}
			case 'Blue'
				tColorOrderMat( iColor, : ) = [ 0 0 1 ];
			case 'LtGrn'
				tColorOrderMat( iColor, : ) = [ 0 1 0 ];
			case 'Red'
				tColorOrderMat( iColor, : ) = [ 1 0 0 ];
			case 'Cyan'
				tColorOrderMat( iColor, : ) = [ 0 1 1 ];
			case 'Yellow'
				tColorOrderMat( iColor, : ) = [ 1 1 0 ];
			case 'Magenta'
				tColorOrderMat( iColor, : ) = [ 1 0 1 ];
			case 'Black'
			case 'Orange'
				tColorOrderMat( iColor, : ) = [ 1 0.6 0 ];
			otherwise
				SetMessage( [ 'Unknown color requested: ', tDefaultColorOrderNames{iColor} ], 'warning'  )
			end
		end
		tColorOrderMat = tColorOrderMat( mrC_GetCellSub( GetOptSelx( 'Colors' ), tDefaultColorOrderNames ), : );
	end

	function tSbjROIsPN = GetSbjROIsPN( tSbjNm )
		if ~ispref( 'mrCurrent', 'AnatomyFolder' )
			setpref( 'mrCurrent', 'AnatomyFolder', uigetdir( '', 'Browse to Anatomy folder' ) );
		end
		tAnatFold = getpref( 'mrCurrent', 'AnatomyFolder' );
		tSbjROIsPN = fullfile( tAnatFold, tSbjNm, 'Standard', 'meshes', 'ROIs' );
	end

	function tSensorPos = GetSensorPos( tSbjNm, tRotEars )
		tElpDir = fullfile( gProjPN, tSbjNm, 'Polhemus' );
		tElpFile = dir( fullfile( tElpDir, '*.elp' ) );
		tNelp = numel( tElpFile );
		if tNelp == 0
			tSensorPos = [];
			SetMessage( [ 'No elp-file found for ', tSbjNm ], 'error' )
		elseif tNelp > 1
			SetMessage( [ 'Multiple elp-files found for ', tSbjNm ], 'warning'  );
			[junk,iElpFile] = max( [tElpFile.datenum] );
		else
			iElpFile = 1;
		end
		tSensorPos = mrC_readELPfile( fullfile( tElpDir, tElpFile(iElpFile).name ) , true, tRotEars, [ -2 1 3 ] );
	end

	function tComp = GetComp( varargin )
		% tComp = GetComp( tCompName, tVEPFS ), or  tCompNames = GetComp( 'getcomplist' )
		% where
		% tCompName is a string corresponding to a particular harmonic component from the list tComps below, and
		% tVEPFS is a VEPFreqSpec returned by GetVEPFreqSpecs.
		% When called with 'getcomplist', tCompNames is simply the list, tComps;
		% Otherwise, tComp is the index of the requested harmonic given the frequency specifications.

		tComps = { ...
			'1f1', '1f2', '2f1', '2f2',...
			'3f1' '4f1' '5f1' '6f1' '7f1' '8f1' '9f1' '10f1' '11f1' '12f1' '13f1' '14f1' ...
			'3f2' '4f2' '5f2' '6f2' '7f2' '8f2' '9f2' '10f2' '11f2' '12f2' '13f2' '14f2' ...
			'1f1+1f2' '1f1-1f2' '1f2-1f1' ...
			'1f1+2f2' '1f1-2f2' '2f2-1f1' ...
			'2f1+1f2' '2f1-1f2' '1f2-2f1' ...
			'2f1+2f2' '2f1-2f2' '2f2-2f1' ...
			'1f1+3f2' '1f1-3f2' '3f2-1f1' ...
			'3f1+1f2' '3f1-1f2' '1f2-3f1' ...
			'1f1-1n' '1f1+1n' '1f2-1n' '1f2+1n' ...
			'2f1-1n' '2f1+1n' '2f2-1n' '2f2+1n' ...
		};

		if nargin < 1
			error( 'GetComp requires at least one argument');
		end

		tCompName = lower( varargin{ 1 } );
		if strmatch( tCompName, 'getcomplist', 'exact' )

			% special argument returns list of valid components for TFs in this project.
% 			tVEPInfo = GetVEP1Cnd(1);	% VEP Info from first Cnd.
% 			tComp = {}; % commandeer the return value to return a list.
% 			for iComp = 1:numel( tComps )
% 				try
% 					tCompNm = tComps{ iComp };
% 					tCompSS = GetComp( tCompNm, tVEPInfo );
% 					tComp{ end + 1 } = tCompNm;
% 				catch % do nothing, implicitly continue
% 				end
% 			end

			% this works.  allows for different f1 & f2 across conditions.  dangerous?
			tVEPCndNms = gChartFs.Cnds.Items; %fieldnames( gVEPInfo );
			tVEPInfo = GetVEP1Cnd( 1 );
			for iCnd = 1:numel(tVEPCndNms)
				tComp1Cnd = {};
				for iComp = 1:numel(tComps)
					try
% 						tVEPInfo = load( fullfile( gProjPN, gChartFs.Sbjs.Items{1}, gChartFs.Mtgs.Items{1}, [ tVEPCndNms{iCnd}, '.mat' ] ), 'i1F1', 'i1F2', 'nFr' );
% 						tVEPInfo.nFr = tVEPInfo.nFr - 1;									% ??? should this be after error check ???
						GetComp( tComps{iComp}, tVEPInfo, tVEPCndNms{iCnd} );		% check for error (put Cnd indexing in GetVEP1Cnd here?)
						tComp1Cnd = cat( 2, tComp1Cnd, tComps(iComp) );
					catch
					end
				end
				if iCnd == 1
					tComp = tComp1Cnd;
				else
					tComp = intersect( tComp, tComp1Cnd );
				end
			end
			tComp = tComps(ismember(tComps,tComp));		% put back in unsorted order
			return
		else
			tiF = strmatch( tCompName, tComps, 'exact' );
			if ~isempty( tiF )
				[ tFN, tVEPFS ] = deal( varargin{1:2} );
				[ tkF1, tkF2, tkNoise ] = deal( 0 );
				tiF1 = findstr( 'f1', lower( tFN ) );
				tiF2 = findstr( 'f2', lower( tFN ) );
				if isempty( tiF1 )
					if isempty( tiF2 )
						% this handles ill-formed harmonic names that might appear in list above...
						SetMessage( [ 'Cannot parse harmonic component name: ' tFN ], 'error' )
					else
						tkF2 = str2double( tFN( 1:(tiF2-1) ) );		% sscanf is faster
					end
				elseif isempty( tiF2 )
					tkF1 = str2double( tFN( 1:(tiF1-1) ) );
				elseif tiF1 < tiF2
					tkF1 = str2double( tFN( 1:(tiF1-1) ) );
					tkF2 = str2double( tFN( (tiF1+2):(tiF2-1) ) );
				else
					tkF1 = str2double( tFN( (tiF2+2):(tiF1-1) ) );
					tkF2 = str2double( tFN( 1:(tiF2-1) ) );
				end
				tiNoise = findstr( 'n', lower( tFN ) );		% noise term has to be last in string
				if ~isempty( tiNoise )
					tkNoise = str2double( tFN( (max([tiF1,tiF2])+2):(tiNoise-1) ) );
				end
				tComp = tVEPFS.i1F1 * tkF1 + tVEPFS.i1F2 * tkF2 + tkNoise;
				if tComp <= 0
					SetMessage( [ 'Requested harmonic component ', tFN, ' frequency < 0.' ], 'error' )
				elseif tComp > tVEPFS.nFr
					if nargin >= 3
						disp( [ '   ', varargin{3}, ': Requested harmonic component ', tFN, ' exceeds limit of spectrum.' ] )
					else
						disp( [ 'Requested harmonic component ', tFN, ' exceeds limit of spectrum.' ] )
					end
					SetMessage( [ 'Requested harmonic component ', tFN, ' exceeds limit of spectrum.' ], 'error' )
				end
			else
				SetMessage( [ 'Attempt to get unknown harmonic component ' tCompName ], 'error' )
			end
		end
	end

	function tFilter = GetFilter( varargin )
		% tFilter = GetFilter( tFilterName, tVEPFS, [ tOrder ] )
		% tFilterNames = GetFilter( 'getfilterlist' )
		% where
		% tFilterName must a string from the list tFilters below, and
		% tVEPFS is a VEPFreqSpec returned by GetVEPFreqSpecs.
		% tOrder is optional order that defaults to 8
		% When called with 'getfilterlist', tFilterNames is simply the list, tFilters;
		% Otherwise, tFilter is the subscript for the requested filter given the frequency specifications.

		% v.1 = v.0 + ability to handle variable tOrder parameter (and, in general,
		% other parameters as well) through the magic of varargin.

		% v.2 separate getfilter and getharm

		tFilters = { ...
			'none' 'lo10' 'lo15' 'lo20' 'lo30' 'lo50' 'nf1' 'nf2' 'f2band' 'f2band1' 'f2band2' 'nf2band2' 'nf1clean' 'nf2clean' 'nf1low10' ...
			'nf1low15' 'nf1low20' 'nf1_odd1_odd3' 'nf1_odd3to15' 'nf1_odd1to11' 'nf1_even2to12' 'nf1_all_even' 'nf1_all_odd' 'rbtx_nf1' 'rbtx_nf2' 'rbtx_im' ...
		};

		if nargin < 1
			error( 'GetFilter requires at least one argument');
		end

		tFilterName = lower( varargin{ 1 } );
		if strmatch( tFilterName, 'getfilterlist', 'exact' )
% 			tFilter = tFilters;
			% special argument returns list of valid filters for TFs in this project.
			tVEPInfo = GetVEP1Cnd(1);		% VEP Info from first Cnd.
			tNFlts = numel( tFilters );
			tValidFlag = false( 1, tNFlts );
			for iFlt = 1:tNFlts
				try
					GetFilter( tFilters{ iFlt }, tVEPInfo );
					tValidFlag( iFlt ) = true;
				catch % do nothing, implicitly continue
				end
			end
			tFilter = tFilters(tValidFlag); % commandeer the return value to return a list.
			return
		end
		tiF = strmatch( tFilterName, tFilters, 'exact' );
		if isempty( tiF )
			SetMessage( [ 'Attempt to get unknown filter ' tFilterName ], 'error' )
		end
		% we need tVEPFS, if not...
		if nargin < 2
			error( 'GetFilter requires VEP frequency specification.' )
		end
		tVEPFS = varargin{2};
		iF = [ tVEPFS.i1F1 tVEPFS.i1F2 ];
		tNFr = tVEPFS.nFr;
		if nargin < 3
			tOrder = round( tNFr / min( iF ) ); % default value for optional third argument
		else
			tOrder = varargin{ 3 };
		end
		switch lower( tFilterName )
		case 'none'
			tFilter = ( 1:tNFr )';
		case 'lo10'
			tCutFr = round( 10 / tVEPFS.dFHz );
			tFilter = ( 1:min( [ tNFr tCutFr ] ) )';
		case 'lo15'
			tCutFr = round( 15 / tVEPFS.dFHz );
			tFilter = ( 1:min( [ tNFr tCutFr ] ) )';
		case 'lo20'
			tCutFr = round( 20.0 / tVEPFS.dFHz );
			tFilter = ( 1:min( [ tNFr tCutFr ] ) )';
		case 'lo30'
			tCutFr = round( 30 / tVEPFS.dFHz );
			tFilter = ( 1:min( [ tNFr tCutFr ] ) )';
		case 'lo50'
			tCutFr = round( 50 / tVEPFS.dFHz );
			tFilter = ( 1:min( [ tNFr tCutFr ] ) )';
		case 'nf1'
			tFilter = ( iF(1):iF(1):( min( [ tNFr iF(1)*tOrder ] ) ) )';
		case 'nf2'
			tFilter = ( iF(2):iF(2):( min( [ tNFr iF(2)*tOrder ] ) ) )';
		case 'f2band'
			tNF1 = GetFilter( 'nf1', tVEPFS , 8 ); % use tOrder == 8
			tFilter = iF(2) + [ -tNF1(end:-1:1); 0; tNF1(:) ];
        case 'f2band1'
			tNF1 = GetFilter( 'nf1', tVEPFS , 1 ); % use tOrder == 2
			tFilter = iF(2) + [ -tNF1(end:-1:1); 0; tNF1(:) ];
        case 'f2band2'
			tNF1 = GetFilter( 'nf1', tVEPFS , 2 ); % use tOrder == 2
			tFilter = iF(2) + [ -tNF1(end:-1:1); 0; tNF1(:) ];
        case 'nf2band2'
			tNF1 = GetFilter( 'nf1', tVEPFS , 2 ); % use tOrder == 2
            f2List = iF(2):iF(2):3*iF(2) %( min( [ tNFr iF(2)*tOrder ] ));
            tFilter = [];
            for iF2=1:length(f2List),         
                
                tFilter = [tFilter [f2List(iF2) + [ -tNF1(end:-1:1); 0; tNF1(:) ]]'];
            end
            
            tFilter = tFilter'
            
		case 'nf1clean'
			tNF1 = GetFilter( 'nf1', tVEPFS, floor( tNFr / iF(1) ) );
			tNF2 = GetFilter( 'nf2', tVEPFS, floor( tNFr / iF(2) ) );
			tFilter = setxor( tNF1, intersect( tNF1, tNF2 ) );
		case 'nf2clean'
			tNF1 = GetFilter( 'nf1', tVEPFS, floor( tNFr / iF(1) ) );
			tNF2 = GetFilter( 'nf2', tVEPFS, floor( tNFr / iF(2) ) );
			tFilter = setxor( tNF2, intersect( tNF1, tNF2 ) );
		case 'nf1low10'
			% low pass version of nf1; nF2 and IM terms are not removed.
			% Only intended for conditions with low global/noise
			% frequency and high update frequencies.
			% Hard-coded cut at 15Hz if f1 = 1Hz...
			tFilter = GetFilter( 'nf1', tVEPFS, 10 );
		case 'nf1low15'
			% low pass version of nf1; nF2 and IM terms are not removed.
			% Only intended for conditions with low global/noise
			% frequency and high update frequencies.
			% Hard-coded cut at 15Hz if f1 = 1Hz...
			tFilter = GetFilter( 'nf1', tVEPFS, 15 );
		case 'nf1low20'
			% low pass version of nf1; nF2 and IM terms are not removed.
			% Only intended for conditions with low global/noise
			% frequency and high update frequencies.
			% Hard-coded cut at 15Hz if f1 = 1Hz...
			tFilter = GetFilter( 'nf1', tVEPFS, 20 );
		case 'nf1_odd3to15'
			% Odd terms starting at 3 with hard-coded cut at 15th harm
			tFilter = iF(1) * ( 3:2:15 )';
        case 'nf1_all_odd'
			% Odd terms starting at 1 with hard-coded cut at 51st harm
			tFilter = iF(1) * ( 1:2:51 )';
        case 'nf1_all_even'
			% even terms starting at 1 with hard-coded cut at 50th harm
			tFilter = iF(1) * ( 2:2:50 )';
        case 'nf1_odd1_odd3'
            % Odd terms starting at 3 with hard-coded cut at 15th harm
            tFilter = iF(1) * ( 1:2:3 )';
        case 'nf1_odd1to11'
            % Odd terms starting at 1 with hard-coded cut at 11th harm
            tFilter = iF(1) * ( 1:2:11 )';
        case 'nf1_even2to12'
            % Even terms starting at 1 with hard-coded cut at 12th harm
			tFilter = iF(1) * ( 2:2:12 )';
		case 'rbtx_nf1'
			tFilter = iF(1) * [ 1 2 3 4 8 ]';
		case 'rbtx_nf2'
			tFilter = iF(2) * [ 1 2 3 4 8 ]';
		case 'rbtx_im'
			tCoeffs = [ 2 -1; -1 2; 3 -1; 1 1; -1 3; 2 1; 1 2; 1 3; 2 2; 1 3 ];
			tFilter = sum( tCoeffs .* repmat( iF, size( tCoeffs, 1 ), 1 ), 2 );
		otherwise
			error( 'Unknown filter name %s', tFilterName );
		end
		if isempty( tFilter ) || any( tFilter > tVEPFS.nFr ) || any( tFilter <= 0 )
			SetMessage( 'Requested filter exceeds limit of spectrum.', 'error' )		% this message doesn't get displayed?
		end
	end

	function SetFilteredWaveforms( tSD )
		if nargin == 0
			tMtg = GetChartSelx( 'Mtgs', 1 );
			tFltNms = GetChartSelx( 'Flts', 2, true );
			tSbjNms = GetChartSelx( 'Sbjs', 2, true );
			tCndNms = GetChartSelx( 'Cnds', 2, true );
		else
			tMtg = tSD.Mtgs.Items{ tSD.Mtgs.Sel };		% tMtg is string, not cell array of 1st Sel
			tFltNms = tSD.Flts.Items;
			tSbjNms = tSD.Sbjs.Items;
			tSbjNms = GetUsedRealItems( 'Sbjs', tSbjNms );		% replace CalcItems with used terms
			tSbjNms = Groups2Members( tSbjNms );					% get rid of groups
			tSbjNms = unique( tSbjNms );								% remove redundancies
            tCndNms = tSD.Cnds.Items;
			tCndNms = GetUsedRealItems( 'Cnds', tCndNms );
        end
        tSbjNms = cellfun(@(x) replaceChar(x,'-','_'),tSbjNms,'uni',false);

		for iFlt = 1:numel( tFltNms )
			if strcmp( tFltNms{iFlt}, 'none' )		% 'none' always exists, so skip it
				continue
			end
			SetMessage( [ 'Calculating filter ', tFltNms{iFlt} ], 'status' )
			makeFourierBasis = true;
			for iSbj = 1:numel( tSbjNms )
				for iCnd = 1:numel( tCndNms )
					if ~isfield( gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Wave, tFltNms{iFlt} )
						if makeFourierBasis
							% 1st few lines of this redundantly repeat, but minimizing what gets done when filters already exist
							tVEPInfo = GetVEP1Cnd(1);
							tNT = tVEPInfo.nT;
							tRC = gcd( tVEPInfo.i1F1, tVEPInfo.i1F2 );	% number of repeat cycles per fundamental wave period...
							if tRC > 1									% the number of time points must be multiplied to match the fundamental wave period.
								tNT = tNT * tRC;
							end
							tFltSS = GetFilter( tFltNms{iFlt}, tVEPInfo );
							if     tVEPInfo.i1F1 > tRC && ~any( rem( tFltSS, tVEPInfo.i1F1 ) )		% only harmonics of F1
								tRC = tVEPInfo.i1F1;
							elseif tVEPInfo.i1F2 > tRC && ~any( rem( tFltSS, tVEPInfo.i1F2 ) )		% only harmonics of F2
								tRC = tVEPInfo.i1F2;
							end
							tFB = 2*pi/tNT*(0:tNT-1)'*(tFltSS');
							tFBCos = cos( tFB );		% tested faster than old way of doing trig on 1 column & building matrices w/ indexing
							tFBSin = sin( tFB );
							makeFourierBasis = false;
						end
						gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Wave.(tFltNms{iFlt}) = ...
							tFBCos * real( gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Spec( tFltSS, : ) ) + ...
							tFBSin * imag( gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Spec( tFltSS, : ) );
						if tRC > 1			% if length of FB mats are more than one repeat cycle...
							% reshape to samples/cycle * cycles * #sensors
							% average across cycles then collape to 2D
							gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Wave.(tFltNms{iFlt}) = ...
								squeeze( mean( reshape( gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Wave.(tFltNms{iFlt}), tNT / tRC, tRC, [] ), 2 ) );
						end
					end
				end
			end
		end
	end

	function tCMap = flow( tNC, tCutFrac )
		% tCMap = flow( tNC, [ tThrFrac ] )
		% works like hsv, bone, & other color map functions
		% tNC: number of elements in the colormap
		% tCutFrac: Fractional distance from extrema to gray cutoff, default 1/3
		tCMap = zeros( tNC, 3 );
		
		% original blue->black->red colormap
% 		tNCF = round( tNC / 2 );	% fraction of tNC
% 		tCMap( (tNC-tNCF+1):tNC, 1 ) = linspace( 0, 1, tNCF )';		% increasing red
% 		tCMap( 1:tNCF, 3 )           = linspace( 1, 0, tNCF )';		% decreasing blue

		% New colormap
		tAngle = linspace( 0, 2*pi , tNC )';
		tQuadrant = [ pi/2 pi 1.5*pi ];
		% cyan -> blue
		kQuadrant = tAngle <= tQuadrant(1);
		tCMap(kQuadrant,2) = cos(tAngle(kQuadrant));
		tCMap(kQuadrant,3) = 1;
		% blue -> purple
		kQuadrant = tAngle > tQuadrant(1) & tAngle <= tQuadrant(2);
		tCMap(kQuadrant,1) = -cos(tAngle(kQuadrant))/2;
		tCMap(kQuadrant,2) = -cos(tAngle(kQuadrant))/4;
		tCMap(kQuadrant,3) =  sin(tAngle(kQuadrant))/2 + 0.5;
		% purple -> red
		kQuadrant = tAngle > tQuadrant(2) & tAngle <= tQuadrant(3);
		tCMap(kQuadrant,1) = -sin(tAngle(kQuadrant))/2 + 0.5;
		tCMap(kQuadrant,2) = -cos(tAngle(kQuadrant))/4;
		tCMap(kQuadrant,3) = -cos(tAngle(kQuadrant))/2;
		% red -> yellow
		kQuadrant = tAngle > tQuadrant(3);
		tCMap(kQuadrant,1) = 1;
		tCMap(kQuadrant,2) = cos(tAngle(kQuadrant));
		% fix any precision errors
		tCMap = max(min(tCMap,1),0);

		% The following line sets the fractional cutoff for the colormap...
		if nargin < 2
			tCutFrac = 1/3;
		end
		tNCF = round( tNC * ( 1 - tCutFrac ) / 2 ); % fraction of tNC
		tCMap( (tNCF+1):(tNC-tNCF), : ) = 0.5;
	end

%{
	function SpecToXL
		tDomain = GetDomain;
		tIsSourceSpace = IsOptSel( 'Space', 'Source' );
		if ~( any( strcmp( tDomain, {'2DPhase','Bar'} ) ) && tIsSourceSpace )
			SetMessage( 'SpecToXL needs source space 2DPhase or Bar chart', 'error' )		% not triplet?
		end
		
		tValidFields = { 'Sbjs', 'Cnds', 'Comps', 'Chans' };
		tSliceFlags = [ tIsSourceSpace, IsOptSel( 'SensorWaves', 'average' ), false ];
		if tSliceFlags(1)
			tValidFields = cat( 2, tValidFields, { 'Invs', 'Hems', 'ROIs', 'ROItypes' } );
		end
	
% 		[ tRowF, tNRows, tRowNms ] = checkValidity( 1, tValidFields );
% 		[ tColF, tNCols, tColNms ] = checkValidity( 2, tValidFields );
% 		[ tCmpF, tNCmps, tCmpNms ] = checkValidity( 3, tValidFields );
		[ tRowF, tNRows ] = checkValidity( 1, tValidFields );
		[ tColF, tNCols ] = checkValidity( 2, tValidFields );
		[ tCmpF, tNCmps ] = checkValidity( 3, tValidFields );
		
		SD = InitSliceDescription( tValidFields, false );

		tNSbjs = numel( SD.Sbjs.Items );
		tValidDims = [ ~[ isempty( tRowF ), isempty( tColF ), isempty( tCmpF )], IsSbjPage && ( tNSbjs > 1 ) ];
		
		% look into building this w/o loops like Mark did w/ fullfact
		if tValidDims(4)
			tData = cell( prod([tNRows tNCols tNCmps tNSbjs]) + 1, 5 );
		else
			tData = cell( prod([tNRows tNCols tNCmps]) + 1, 4 );
		end
		k = 1;
		tData(k,1:3) = { tRowF, tColF, tCmpF };
		if tValidDims(4)
			tData{k,4} = 'Sbjs';
		end
		switch tDomain
		case '2DPhase'
			tData(k,(4:5)+tValidDims(4)) = { 'SReal', 'SImag' };
			tCoherentBarMean = false;
		case 'Bar'
			tData{k,4+tValidDims(4)} = 'SAmp';
			tCoherentBarMean = IsOptSel( 'BarMean', 'Coherent' );
			if tCoherentBarMean
				tYSubj = zeros(tNSbjs,1);
			end
		end
		
		for iRow = 1:tNRows
			if tValidDims(1)
				SD.(tRowF).Sel = iRow;
			end
			for iCol = 1:tNCols
				if tValidDims(2)
					SD.(tColF).Sel = iCol;
				end
				for iCmp = 1:tNCmps
					if tValidDims(3)
						SD.(tCmpF).Sel = iCmp;
					end
					if numel( SD.Chans.Sel ) == 1
						tSliceFlags(2) = false;			% this flag is moot for source space anyhow!
					end
					if tValidDims(4)
						if tCoherentBarMean
% 							tYSubj(:) = 0;
							for iSbj = 1:tNSbjs
								SD.Sbjs.Sel = iSbj;
								tYSubj(iSbj) = getSliceData( SD, tDomain, tValidFields, tSliceFlags );
							end
							tYMean = mean( tYSubj );
							tYAmp = [ real(tYSubj), imag(tYSubj) ]*( [ real(tYMean); imag(tYMean) ] / abs( tYMean ) );
							for iSbj = 1:tNSbjs
								k = k + 1;
								tData{k,1} = SD.(tRowF).Items{ SD.(tRowF).Sel };
								tData{k,2} = SD.(tColF).Items{ SD.(tColF).Sel };
								tData{k,3} = SD.(tCmpF).Items{ SD.(tCmpF).Sel };
								tData{k,4} = SD.Sbjs.Items{ SD.Sbjs.Sel };
								tData{k,5} = tYAmp(iSbj);
							end
						else
							for iSbj = 1:tNSbjs
								SD.Sbjs.Sel = iSbj;
								k = k + 1;
								tY = getSliceData( SD, tDomain, tValidFields, tSliceFlags );
								tData{k,1} = SD.(tRowF).Items{ SD.(tRowF).Sel };
								tData{k,2} = SD.(tColF).Items{ SD.(tColF).Sel };
								tData{k,3} = SD.(tCmpF).Items{ SD.(tCmpF).Sel };
								tData{k,4} = SD.Sbjs.Items{ SD.Sbjs.Sel };
								switch tDomain
								case '2DPhase'
									tData(k,5:6) = num2cell([ real(tY), imag(tY) ]);
								case 'Bar'
									tData{k,5} = abs(tY);
								end
							end
						end
					else
						k = k + 1;
						tY = getSliceData( SD, tDomain, tValidFields, tSliceFlags );	% 1x1 complex
						tData{k,1} = SD.(tRowF).Items{ SD.(tRowF).Sel };
						tData{k,2} = SD.(tColF).Items{ SD.(tColF).Sel };
						tData{k,3} = SD.(tCmpF).Items{ SD.(tCmpF).Sel };
						switch tDomain
						case '2DPhase'
							tData(k,4:5) = num2cell([ real(tY), imag(tY) ]);
						case 'Bar'
							tData{k,4} = abs(tY);
						end
					end
				end
			end
		end
		% xlswrite handles up to 65536x256 matrix
		xlswrite( GetOptSelx( 'XLBookName', 1 ), tData, GetOptSelx( 'XLSheetName', 1 ) );
		
	end
%}

 	function SpecToTXT
		tDomain = GetDomain;
		tIsSourceSpace = IsOptSel( 'Space', 'Source' );
		if ~IsPlot( 'Component' ) 
			SetMessage( 'SpecToTXT needs 2DPhase or Bar chart', 'error' )
		end
		
		tValidFields = { 'Sbjs', 'Cnds', 'Comps', 'Chans' };
		tSliceFlags = [ tIsSourceSpace, IsOptSel( 'SensorWaves', 'average' ), false ];
		if tSliceFlags(1)
			tValidFields = cat( 2, tValidFields, { 'Invs', 'Hems', 'ROIs', 'ROItypes' } );
		end
	
		[ tRowF, tNRows ] = checkValidity( 1, tValidFields );
		[ tColF, tNCols ] = checkValidity( 2, tValidFields );
		[ tCmpF, tNCmps ] = checkValidity( 3, tValidFields );
% 		disp({tRowF,tColF,tCmpF})

		SD = InitSliceDescription( tValidFields, false );
		SD.Sbjs.Items = Groups2Members( SD.Sbjs.Items );
% 		SD.Sbjs.Items = unique( SD.Sbjs.Items );
		% fix export dimensions in the event of groups
		switch 'Sbjs'
		case tRowF
			tNRows = numel( SD.Sbjs.Items );
		case tColF
			tNCols = numel( SD.Sbjs.Items );
		case tCmpF
			tNCmps = numel( SD.Sbjs.Items );
		end

		% Shouldn't need this virtual duplicate???
		% SD.Chans.Items = [1x128 double]
		% SDc.Chans.Items = {1x128 cell} of char
		SDc = SD;
		if ismember( 'Chans', { tRowF, tColF, tCmpF } )
			SDc.Chans.Items = cellfun( @int2str, num2cell( SDc.Chans.Items ), 'UniformOutput', false );
		end

		tNSbjs = numel( SD.Sbjs.Items );
		tValidDims = [ ~[ isempty( tRowF ), isempty( tColF ), isempty( tCmpF )], IsSbjPage && ( tNSbjs > 1 ) ];
		
		% look into building this w/o loops like Mark did w/ fullfact
% 		tFileName = strrep( GetOptSelx( 'XLBookName', 1 ), 'xlw', 'tab' );
		[ tFileName, tPathName ] = uiputfile( '*.tab', 'Save tab-delimited ascii file', fullfile(gProjPN,'mrCurrentData.tab') );
		if isnumeric( tFileName )
			return
		else
			tFileName = strcat( tPathName, tFileName );
		end
		fid = fopen( tFileName, 'w' );
		if fid == -1
			SetMessage( sprintf( 'Can''t open %s', tFileName ), 'error' )
		end
		try
			tValidDimCode = sum( [4 2 1].*tValidDims(1:3) );
			switch tValidDimCode
			case 7
				fprintf( fid, '%s\t%s\t%s', tRowF, tColF, tCmpF );
			case 6
				fprintf( fid, '%s\t%s', tRowF, tColF );
			case 5
				fprintf( fid, '%s\t%s', tRowF, tCmpF );
			case 4
				fprintf( fid, '%s', tRowF );
			case 3
				fprintf( fid, '%s\t%s', tColF, tCmpF );
			case 2
				fprintf( fid, '%s', tColF );
			case 1
				fprintf( fid, '%s', tCmpF );
			case 0
			end
			if tValidDims(4)
				if tValidDimCode == 0
					fprintf( fid, 'Sbjs' );
				else
					fprintf( fid, '\tSbjs' );
				end
			end
			tTripletFlag = strcmp( tDomain, 'BarTriplet' );
			if tTripletFlag
				fprintf( fid, '\tTriplet' );
			end
			switch tDomain
			case '2DPhase'
				fprintf( fid, '\tSReal\tSImag' );
				tCoherentBarMean = false;
			case {'Bar','BarTriplet'}
				fprintf( fid, '\tSAmp' );
				tCoherentBarMean = IsOptSel( 'BarMean', 'Coherent' );
				if tCoherentBarMean
					tYSubj = zeros(tNSbjs,1+2*tTripletFlag);
				end
			end
			for iRow = 1:tNRows
				if tValidDims(1)
					SD.(tRowF).Sel = iRow;
				end
				for iCol = 1:tNCols
					if tValidDims(2)
						SD.(tColF).Sel = iCol;
					end
					for iCmp = 1:tNCmps
						if tValidDims(3)
							SD.(tCmpF).Sel = iCmp;
						end
						if numel( SD.Chans.Sel ) == 1
							tSliceFlags(2) = false;			% this flag is moot for source space anyhow!
						end
						if tValidDims(4)				% subjects column
							if tCoherentBarMean		% implies bar chart
	% 							tYSubj(:) = 0;
								for iSbj = 1:tNSbjs
									SD.Sbjs.Sel = iSbj;
									tYSubj(iSbj,:) = getSliceData( SD, tDomain, tValidFields, tSliceFlags )';
								end
								tYMean = mean( tYSubj );					% complex mean - 1x3
								tYMean = tYMean ./ abs( tYMean );
								tYAmp = [ real(tYSubj), imag(tYSubj) ] * [ diag(real(tYMean)); diag(imag(tYMean)) ];
								for iSbj = 1:tNSbjs
									SD.Sbjs.Sel = iSbj;
									switch tDomain
									case 'Bar'
										writeRowLabels
										fprintf( fid, '%s\t%0.8f', SD.Sbjs.Items{ SD.Sbjs.Sel }, tYAmp(iSbj) );
									case 'BarTriplet'
										for iTriplet = 1:3
											writeRowLabels
											fprintf( fid, '%s\t%d\t%0.8f', SD.Sbjs.Items{ SD.Sbjs.Sel }, iTriplet-2, tYAmp(iSbj,iTriplet) );
										end
									end
								end
							else
								for iSbj = 1:tNSbjs
									SD.Sbjs.Sel = iSbj;
									tY = getSliceData( SD, tDomain, tValidFields, tSliceFlags );
									switch tDomain
									case '2DPhase'
										writeRowLabels
										fprintf( fid, '%s\t%0.8f\t%0.8f',SD.Sbjs.Items{ SD.Sbjs.Sel }, real(tY), imag(tY) );
									case 'Bar'
										writeRowLabels
										fprintf( fid, '%s\t%0.8f',SD.Sbjs.Items{ SD.Sbjs.Sel }, abs(tY) );
									case 'BarTriplet'
										for iTriplet = 1:3
											writeRowLabels
											fprintf( fid, '%s\t%d\t%0.8f',SD.Sbjs.Items{ SD.Sbjs.Sel }, iTriplet-2, abs(tY(iTriplet)) );
										end
									end
								end
							end
						else
							tY = getSliceData( SD, tDomain, tValidFields, tSliceFlags );	% 1x1 complex, or 3x1 complex if Triplet
							switch tDomain
							case '2DPhase'
								writeRowLabels
								fprintf( fid, '%0.8f\t%0.8f', real(tY), imag(tY) );
							case 'Bar'
								writeRowLabels
								fprintf( fid, '%0.8f', abs(tY) );
							case 'BarTriplet'
								for iTriplet = 1:3
									writeRowLabels
									fprintf( fid, '%d\t%0.8f', iTriplet-2, abs(tY(iTriplet)) );
								end
							end
						end
					end
				end
			end
		catch
			if fclose(fid) == -1
				warning( 'mrCurrent:fclose', 'Problem closing %s', tFileName )
			end
			SetMessage( sprintf( 'Problem building %s', tFileName ), 'error' )
		end
		if fclose(fid) == -1
			warning( 'mrCurrent:fclose', 'Problem closing %s', tFileName )
		else
			disp( [ 'Wrote ',tFileName ] )
		end
		function writeRowLabels
			switch tValidDimCode
			case 7
% 				fprintf( fid, '\r\n%s\t%s\t%s\t%s\t', SDc.(tRowF).Items{ SD.(tRowF).Sel }, SDc.(tColF).Items{ SD.(tColF).Sel }, SDc.(tCmpF).Items{ SD.(tCmpF).Sel } );
				fprintf( fid, '\r\n%s\t%s\t%s\t', SDc.(tRowF).Items{ SD.(tRowF).Sel }, SDc.(tColF).Items{ SD.(tColF).Sel }, SDc.(tCmpF).Items{ SD.(tCmpF).Sel } );
			case 6
				fprintf( fid, '\r\n%s\t%s\t', SDc.(tRowF).Items{ SD.(tRowF).Sel }, SDc.(tColF).Items{ SD.(tColF).Sel } );
			case 5
				fprintf( fid, '\r\n%s\t%s\t', SDc.(tRowF).Items{ SD.(tRowF).Sel }, SDc.(tCmpF).Items{ SD.(tCmpF).Sel } );
			case 4
				fprintf( fid, '\r\n%s\t', SDc.(tRowF).Items{ SD.(tRowF).Sel } );
			case 3
				fprintf( fid, '\r\n%s\t%s\t', SDc.(tColF).Items{ SD.(tColF).Sel }, SDc.(tCmpF).Items{ SD.(tCmpF).Sel } );
			case 2
				fprintf( fid, '\r\n%s\t', SDc.(tColF).Items{ SD.(tColF).Sel } );
			case 1
				fprintf( fid, '\r\n%s\t', SDc.(tCmpF).Items{ SD.(tCmpF).Sel } );
			case 0
				fprintf( fid, '\r\n' );
			end
		end
	end

	function SpoofMAxxFig
		SetMessage( 'Exporting data to MAxxFig...', 'status' )
		tSliceFlags = [ IsOptSel( 'Space', 'Source' ), false, false ];		% [ SourceSpace AvgChans GFP ]
		tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
		if tSliceFlags(1)
			tValidFields = cat( 2, tValidFields, { 'Invs', 'Hems', 'ROIs', 'ROItypes' } );
		elseif IsOptSel( 'SensorWaves', 'GFP' )
			tSliceFlags(3) = true;			
			tFN = sprintf( 'Sensor GFP (%d)', numel( GetChartSelx( 'Chans' ) ) );
		else	%if IsOptSel( 'SensorWaves', 'average' )
			tSliceFlags(2) = true;
			tFN = sprintf( 'Sensor Mean (%d)', numel( GetChartSelx( 'Chans' ) ) );
		end

		SD = InitSliceDescription( tValidFields, false );

		tCndInfo = GetVEP1Cnd(1);			% assuming same VEP info for all conditions for CalcItems

		gMF.FN = gProjPN;
		gMF.PN = gProjPN;
		gMF.MatFN = [];
		gMF.MatPN = [];
		if tSliceFlags(1)
			gMF.casChan = SD.ROIs.Items';											% *** transpose ???
		else
			gMF.casChan = {tFN};
		end
		[ gMF.nChD, gMF.nChP ] = deal( numel( gMF.casChan ) );		% # data channels, # channels to plot
		gMF.casCond = SD.Cnds.Items';											% *** e.g. {2x1 cell}
		tNCnd = numel( gMF.casCond );
		gMF.casSess = repmat( { SD.Sbjs.Items' }, 1, tNCnd );			% *** e.g. {{10x1 cell} {10x1 cell}}
		for iCnd = 1:tNCnd
			SD.Cnds.Sel = iCnd;
			for iROI = 1:gMF.nChD
				if tSliceFlags(1)
					SD.ROIs.Sel = iROI;
				end
				for iSbj = 1:numel( SD.Sbjs.Items )
					SD.Sbjs.Sel = iSbj;
% 					gMF.Data{ iCnd }.R( :, iROI, iSbj ) = getSliceData( SD, 'Wave', tValidFields, tSliceFlags );
% 					tSpecData =                           getSliceData( SD, 'Spec', tValidFields(~strcmp(tValidFields,'Flts')), tSliceFlags );					
					gMF.Data{ iCnd }.R( :, iROI, iSbj ) = getAvgSliceData( [true false], SD, 'Wave', tValidFields, tSliceFlags );
					tSpecData =                           getAvgSliceData( [true false], SD, 'Spec', tValidFields(~strcmp(tValidFields,'Flts')), tSliceFlags );					
					gMF.Data{ iCnd }.A(   :, iROI, iSbj ) = [ 0;  abs( tSpecData ) ];
					gMF.Data{ iCnd }.Cos( :, iROI, iSbj ) = [ 0; real( tSpecData ) ];
					gMF.Data{ iCnd }.Sin( :, iROI, iSbj ) = [ 0; imag( tSpecData ) ];
				end
			end
			gMF.Data{iCnd}.T    = tCndInfo.dTms * ( 1:size( gMF.Data{iCnd}.R, 1 ) )';
			gMF.Data{iCnd}.F    = tCndInfo.dFHz * ( 1:size( gMF.Data{iCnd}.Sin, 1 ) )';
			gMF.Data{iCnd}.i1F1 = tCndInfo.i1F1;
			gMF.Data{iCnd}.i1F2 = tCndInfo.i1F2;
		end
		gMF.iCond1 = 0;
		gMF.iCond2 = 0;
		gMF.WavePlot = []; %axis handles
		gMF.SpecPlot = [];
		save( fullfile( gProjPN, 'MAxxFigData.mat' ), 'gMF' );
		SetMessage( 'Exporting data to MAxxFig... Done', 'status' )
	end

% 	function ExportToODBC
% 		[ tSDs, tSIs ] = GetSliceArrays;
% 		tSFNms = fieldnames( tSDs(1) );
% 		tFID_Fact = fopen( 'Fact.txt', 'w' );
% 		tFID_YDat = fopen( 'YDat.txt', 'w' );
% 		if IsSbjMultiPage
% 			fprintf( tFID_Fact, '%s\t%s\t%s\t%s\tFactPK\n', tSFNms{ 1:4 } );
% 		else
% 			fprintf( tFID_Fact, '%s\t%s\t%s\tFactPK\n', tSFNms{ 1:3 } );
% 		end
% 		fprintf( tFID_YDat, 'FactFK\tTDatFK\tuV\n' );
% 		tNT = size( gY );
% 		tNT = tNT( end );
% 		tNT = 1:tNT;
% 		for iS = 1:numel( tSDs )
% 			tSD = tSDs( iS ); % Slice Descriptor
% 			tSI = tSIs( iS, : ); % Slice Index
% 			if IsSbjMultiPage
% 				fprintf( tFID_Fact, '%s\t%s\t%s\t%s\t%d\n', ...
% 					tSD.(tSFNms{1}), tSD.(tSFNms{2}), tSD.(tSFNms{3}), tSD.(tSFNms{4}), iS );
% 				tYDat = cat( 1, tNT, squeeze( gY( tSI(1), tSI(2), tSI(3), tSI(4), : ) )' );
% 			else
% 				fprintf( tFID_Fact, '%s\t%s\t%s\t%d\n', ...
% 					tSD.(tSFNms{1}), tSD.(tSFNms{2}), tSD.(tSFNms{3}), iS );
% 				tYDat = cat( 1, tNT, squeeze( gY( tSI(1), tSI(2), tSI(3), : ) )' );
% 			end
% 			tFormatStr = [ int2str( iS ) '\t%d\t%.6f\n' ];
% 			fprintf( tFID_YDat, tFormatStr, tYDat );
% 		end
% 		tFID_TDat = fopen( 'TDat.txt', 'w' );
% 		fprintf( tFID_TDat, 'TDatPK\tpApmm2\n' );
% 		fprintf( tFID_TDat, '%d\t%.3f\n', cat( 1, tNT, linspace( 0, 1, numel( tNT ) ) ) );
% 		fclose( tFID_Fact );
% 		fclose( tFID_YDat );
% 		fclose( tFID_TDat );
% 		SetMessage( 'Done Exporting to ODBC', 'status' )
% 	end

%% CalcItems

	function SetCalcItem
		% Handles creation of CalcItems which are chart field items
		% corresponding to some expression involving other field items.
		% Data is created for these only by request, at run time, and
		% is not added to gD or to saved data.  Expression strings are
		% contained in a data structure, which is saved/loaded with
		% project.
		tChartF = gChartL.Items{ gChartL.Sel };
		if strcmp( tChartF, 'Chans' )
			SetMessage( 'Channels CalcItems not allowed', 'error' )
		end
		tItemSels = GetChartSelx( tChartF );
		tNItemSels = numel( tItemSels );
		if tNItemSels == 1 && isstruct( gCalcItems ) && isfield( gCalcItems, tChartF ) && isfield( gCalcItems.(tChartF), tItemSels{1} )
			% retrieve existing CalcItem expression string for editing
			tExprStr = [ tChartF, ':', gCalcItems.(tChartF).(tItemSels{1}) ];
		else
			% make a default expression from selected items in selected chart field.
			if tNItemSels == 1
				tExprStr = [ tChartF, ':NewCalcItem = ', tItemSels{1} ];
			else
				tExprStr = sprintf( '%s:NewCalcItem = ( %s%s ) / %d', tChartF,...
					sprintf( '%s + ', tItemSels{1:tNItemSels-1} ), tItemSels{tNItemSels}, tNItemSels );
			end
		end
% 		tExprStr = inputdlg( 'Edit CalcItem Expression:', 'CalcItem', [ 1 numel( tExprStr ) ], { tExprStr }, 'on' );
		tExprStr = { mrC_InputBigFont( 'CalcItem', 'Edit CalcItem Expression:', tExprStr, 16 ) };

		if ~isempty( tExprStr{1} )
			tExprStr = tExprStr{ 1 }; % change back to string
			% extract name of new CalcItem: must be immediately bordered by ':' and ' ='.
			[ tCalcItemNm, tExprStr ] = strtok( tExprStr );
			[ tCIFieldNm, tCIItemNm ] = GetCalcItemPartNames( tCalcItemNm );
			% if = [], then delete the item; safe if item doesn't exist, nothing happens.
			% otherwise, add expression to gCalcItems;
			if ~strcmp( tExprStr, ' = []' )
				SetMessage( [ 'Adding CalcItem ' tCIItemNm ' to ' tChartF ], 'status' )
				if ~isfield( gCalcItems, tChartF ) || ~isfield( gCalcItems.(tChartF), tCIItemNm )
					gChartFs.(tChartF).Items{ end + 1 } = tCIItemNm;		% add item to GUI
					gCalcItemOrder{ end + 1 } = tCalcItemNm;
				end
				gCalcItems.(tChartF).(tCIItemNm) = [ tCIItemNm, tExprStr ];
			elseif isstruct( gCalcItems ) && isfield( gCalcItems, tChartF ) && isfield( gCalcItems.(tChartF), tCIItemNm )
				SetMessage( [ 'Deleting CalcItem ' tCIItemNm ' from ' tChartF ], 'status' )
				gCalcItems.(tChartF) = rmfield( gCalcItems.(tChartF), tCIItemNm );
				if isempty( fieldnames( gCalcItems.( tChartF ) ) )
					gCalcItems = rmfield( gCalcItems, tChartF );
				end
				RemoveCalcItem			% remove item from GUI
			end
			% refresh GUI
			mrC_ChartList_CB
			mrC_ItemsList_CB
			save( fullfile( gProjPN, 'CalcItems.mat' ), 'gCalcItems', 'gCalcItemOrder' );
		end
		function RemoveCalcItem
			% Removing CalcItem from full list of Items, then from selection if needed
			gChartFs.(tChartF).Items = gChartFs.(tChartF).Items( ~strcmp( gChartFs.(tChartF).Items, tCIItemNm ) );
			gChartFs.(tChartF).Sel   = mrC_GetCellSub( tItemSels( ~strcmp( tItemSels, tCIItemNm ) ), gChartFs.(tChartF).Items );
			if isempty( gChartFs.(tChartF).Sel )
				gChartFs.(tChartF).Sel = 1;
			end
			gCalcItemOrder = gCalcItemOrder( ~ismember( gCalcItemOrder, {[tChartF,':',tCIItemNm]} ) );
		end
	end

	function SetCalcItemOrder
		% Handles order of CalcItems fields which determine order of
		% evaluation.
		if ~isempty( gCalcItemOrder )
			tCIOStr = sprintf( '%s ', gCalcItemOrder{:} );
			tCIOStr = inputdlg( 'Order of CalcItem Evaluation, e.g. 1st( 2nd( 3rd(...) ) ):', 'CalcItemOrder', ...
				[ 1 min( [ 100 numel( tCIOStr ) + 20 ] ) ], { tCIOStr }, 'on' );
			if ~isempty( tCIOStr )
				gCalcItemOrder = GetTokens( tCIOStr{ 1 } );
				save( fullfile( gProjPN, 'CalcItems.mat' ), 'gCalcItems', 'gCalcItemOrder' );
			end
		end
	end

	function [ tCIFieldNm, tCIItemNm ] = GetCalcItemPartNames( tCalcItemNm )
		% parses the tCIFieldNm:tCIItemNm convention used by gCalcItemOrder
		tCIPartNms =  GetTokens( tCalcItemNm, ':' );
		[ tCIFieldNm, tCIItemNm ] = deal( tCIPartNms{:} );
	end

	function tCalcItemTerms = GetCalcItemTerms( tCalcItemNm )
		% returns cell array of used values in the expression associated with a CalcItem name, e.g. 'Cnds:Avg12'
		% tCalcItemNm uses the tCIFieldNm:tCIItemNm convention for gCalcItemOrder
		[ tCIFieldNm, tCIItemNm ] = GetCalcItemPartNames( tCalcItemNm );
		tTok = GetTokens( gCalcItems.(tCIFieldNm).(tCIItemNm) );
		tItems = gChartFs.(tCIFieldNm).Items;
		tCalcItemTerms = tItems( unique( mrC_GetCellSub( tTok(2:end), tItems ) ) );
	end

	function tTok = GetTokens( tStr, tDlm )
		% tTok = GetTokens( tStr, [ tDlm ] )
		% Convert string, tStr, of token fields delimited by tDlm (default = whitespace)
		% into a 1xN cell array, tTok, of token strings.
		while iscell( tStr )
			tStr = tStr{ 1 };
		end
		if nargin == 1
			tTok = textscan( tStr, '%s' );
		else
			tTok = textscan( tStr, '%s', 'delimiter', tDlm );
		end
		tTok = tTok{1}';
	end

	function tIsCalcItem = IsCalcItem( tCalcItemNm )
		if isempty( gCalcItemOrder )
			tIsCalcItem = false;
		elseif iscell( tCalcItemNm )
			tIsCalcItem = ismember( tCalcItemNm, gCalcItemOrder );			% vector
		else %if ischar( tCalcItemNm )
			tIsCalcItem = ismember( { tCalcItemNm }, gCalcItemOrder );		% scalar
		end
	end

	function tChartItemNms = GetUsedRealItems( tChartDim, tChartItemNms )
		tChartNms =  strcat( tChartDim, ':', tChartItemNms );
		iCalcItems = IsCalcItem( tChartNms );
		while any( iCalcItems )
			iCalcItems = find( iCalcItems );
			for iChartNm = iCalcItems
				tChartItemNms = cat( 2, tChartItemNms, GetCalcItemTerms( tChartNms{iChartNm} ) );		% append CalcItem terms
			end
			tChartItemNms( iCalcItems ) = [];		% remove current batch of CalcItems
			tChartNms =  strcat( tChartDim, ':', tChartItemNms );
			iCalcItems = IsCalcItem( tChartNms );
		end
	end


% these functions are workarounds for CalcItems that need some VEP
% metadata; for now they just allow you to directly adress the VEPInfo for
% the actual VEP cnds using numerical indices, and assumes that all VEPInfo
% (esp. input frequency indices) are the same for all cnds.  A more general
% solution would take CndName as argument and use IsCalcItem and
% GetCalcItemTerms to find appropriate VEPInfo for CalcItems.
	function tVEP1Cnd = GetVEP1Cnd( iVEPCnd )
		tVEPCndNms = fieldnames( gVEPInfo );
		tVEP1Cnd = gVEPInfo.( tVEPCndNms{ iVEPCnd } );
	end

	function tDTms = GetDTms( iVEPCnd )
		tVEP1Cnd = GetVEP1Cnd( iVEPCnd );
		tDTms = tVEP1Cnd.dTms;
	end

	function tDFHz = GetDFHz( iVEPCnd )
		tVEP1Cnd = GetVEP1Cnd( iVEPCnd );
		tDFHz = tVEP1Cnd.dFHz;
	end

	function rW = Shift180( aW )
		% Takes a periodic waveform and shifts it by 180 degrees
		% exists only for use in CalcItems?
		tNW = size( aW );
		if all( tNW(1:2) > 1 )		% matrix
			tNHW = tNW(1)/2;
			rW = aW( [(tNHW+1):tNW(1),1:tNHW], : );
		else
			% original code
			tNHW = numel( aW ) / 2; % numel in halfwave
			rW = reshape( [ aW( (tNHW+1):end ) aW( 1:tNHW ) ], size( aW ) );
		end
	end

	function GroupSbjCreate
% 		gGroups = struct('name',{},'members',{});		% 0x0 structure

		tSbjNms = fieldnames(gD)';
		tNSbjs = numel( tSbjNms );
		if gProjVer == 3
			tSbjViews = {'ID','Age','Diagnoses','Handedness','DomEye','SsnLabel','SsnLevel'};
		else
			tSbjViews = {'ID'};
		end
		tNGroups = numel( gGroups );
		tGroupsChanged = false;
		uiSize = [200; 25; 10];		% [width; height; margin]
		uiD = dialog('Name','Grouper','Position',[400 400 ([1 0 2;0 17 4]*uiSize)']); %,'defaultuipanelunits','pixels','defaultuipaneltitleposition','centertop');
		uiC = [...
					uicontrol(uiD,'Position',([0 0 1;0 16 3;1 0 0;0  1 0]*uiSize)','Style','text','String','Group')...
					uicontrol(uiD,'Position',([0 0 1;0 15 3;1 0 0;0  1 0]*uiSize)','Style','popup','String',[ gGroups.name, { '<new>' } ],'Value',tNGroups+1,'Callback',@SelectGroup)...
					uicontrol(uiD,'Position',([0 0 1;0 14 2;1 0 0;0  1 0]*uiSize)','Style','text','String','Subjects')...
					uicontrol(uiD,'Position',([0 0 1;0 13 2;1 0 0;0  1 0]*uiSize)','Style','popup','String',tSbjViews,'Value',1,'Callback',@SbjsViewBy)...
					uicontrol(uiD,'Position',([0 0 1;0  3 2;1 0 0;0 10 0]*uiSize)','Style','listbox','String',tSbjNms,'Max',2,'listboxtop',1,'Value',[])... %,'enable','inactive')...
					uicontrol(uiD,'Position',([0 0 1;0  2 1;1 0 0;0  1 0]*uiSize)','Style','pushbutton','String','Create / Modify','Callback',@SetGroupMembers)...
					uicontrol(uiD,'Position',([0 0 1;0  1 1;1 0 0;0  1 0]*uiSize)','Style','pushbutton','String','Remove',         'Callback',@RemoveGroup,'Enable','off')...
					uicontrol(uiD,'Position',([0 0 1;0  0 1;1 0 0;0  1 0]*uiSize)','Style','pushbutton','String','Done','Callback','uiresume')...
				];		
		uiwait(uiD)
		if ishandle(uiD)
			close(uiD)
		end
		if tGroupsChanged
% 			UpdateChartListBox
			if strcmp( get( gH.ItemsList, 'UserData' ), 'Chart' ) && strcmp( gChartL.Items{gChartL.Sel}, 'Sbjs' )
				mrC_ChartList_CB
			end
		end
		return
		%-------------------------------
		function SbjsViewBy( varargin )
			tStr = tSbjNms;
			tView = tSbjViews{ get( varargin{1}, 'Value' ) };
			switch tView
			case 'ID'
			case 'Age'
				% 365.2425 days per year: 365 + 1/4 - 1/100 + 1/400
				tDpY = 365.25;
				for iSbj = 1:tNSbjs
					tYears = floor( gD.(tSbjNms{iSbj}).SsnHeader.AgeDays / tDpY );
					tStr{iSbj} = sprintf( '%02dy%03.0fd', tYears, gD.(tSbjNms{iSbj}).SsnHeader.AgeDays - tYears*tDpY );
				end
			case 'Diagnoses'
				for iSbj = 1:tNSbjs
					tStr{iSbj} = sprintf( [ repmat( '%s + ', 1, numel( gD.(tSbjNms{iSbj}).SsnHeader.StdDiags ) - 1 ), '%s' ] , gD.(tSbjNms{iSbj}).SsnHeader.StdDiags{:} );
				end
			case {'Handedness','DomEye','SsnLabel','SsnLevel'}
				for iSbj = 1:tNSbjs
					tStr{iSbj} = gD.(tSbjNms{iSbj}).SsnHeader.(tView);
				end
			end
			set( uiC(5), 'String', tStr )
		end
		function SelectGroup( varargin )
			tGroupSel = get( uiC(2), 'Value' );
			if tGroupSel == ( tNGroups + 1 )
				set( uiC(7), 'Enable', 'off' )
				set( uiC(5), 'Enable', 'on', 'Value', [] )
			else
				set( uiC(5), 'Enable', 'inactive', 'Value', find( ismember( tSbjNms, gGroups(tGroupSel).members ) ) )
				set( uiC(7), 'Enable', 'on' )
			end
		end
		function RemoveGroup( varargin )
			tGroupSel = get( uiC(2), 'Value' );
			tGroupName = gGroups(tGroupSel).name;
			if ~strcmp( questdlg( sprintf( 'Really remove group %s?', tGroupName ), 'mrCurrent', 'Yes', 'No', 'No' ), 'Yes' )
				return
			end
			gGroups = gGroups( setdiff( 1:tNGroups, tGroupSel ) );
			tNGroups = numel(gGroups);
			tGroupSel = max( tGroupSel-1, 1 );
			set( uiC(2), 'String', [ gGroups.name, { '<new>' } ], 'Value', tGroupSel )
			SelectGroup

			tChartItem = find( strcmp( gChartFs.Sbjs.Items , [ 'GROUP_', tGroupName ] ) );
			tChartSel  = gChartFs.Sbjs.Sel( gChartFs.Sbjs.Sel ~= tChartItem );
			if isempty( tChartSel )
				tChartSel = 1;
			else
				tChartHigh = tChartSel > tChartItem;
				if any( tChartHigh )
					tChartSel( tChartHigh ) = tChartSel( tChartHigh ) - 1;
				end
			end
			gChartFs.Sbjs.Items( tChartItem ) = [];
			gChartFs.Sbjs.Sel = tChartSel;
			tGroupsChanged = true;
			save( fullfile( gProjPN, 'SbjGroups.mat' ), 'gGroups' )
		end
		function SetGroupMembers( varargin )
			if strcmp( get( uiC(5), 'Enable' ), 'inactive' )
				set( uiC(5), 'Enable', 'on' )
				return
			end
			tSbjSel = get( uiC(5), 'Value' );
			if numel( tSbjSel ) < 2
				disp('Must select at least 2 subjects to create group!')
				return
			end
			tGroupSel = get( uiC(2), 'Value' );
			if tGroupSel == ( tNGroups + 1 )
				tGroupName = inputdlg( 'New Group Name', 'mrCurrent', 1, {''} );
				if isempty( tGroupName ) || isempty( tGroupName{1} )
					return
				elseif any( strcmpi( { gGroups.name }, tGroupName{1} ) )
					disp( ['Group ', tGroupName{1}, ' already exists' ] )
					return
				end
				tNGroups = tGroupSel;	% tNGroups + 1;
				gGroups(tGroupSel).name    = tGroupName{1};
				gGroups(tGroupSel).members = tSbjNms( tSbjSel );
				set( uiC(2), 'String', [ gGroups.name, { '<new>' } ], 'Value', tNGroups )
				set( uiC(7), 'Enable', 'on' )

				gChartFs.Sbjs.Items{ numel(gChartFs.Sbjs.Items) + 1 } = [ 'GROUP_', gGroups(tGroupSel).name ];
			else
				gGroups(tGroupSel).members = tSbjNms( tSbjSel );
			end
			set( uiC(5), 'Enable', 'inactive' )
			tGroupsChanged = true;
			save( fullfile( gProjPN, 'SbjGroups.mat' ), 'gGroups' )
		end
	end

%% Task


	function mrC_Task_SetAnatFold
		setpref( 'mrCurrent', 'AnatomyFolder', uigetdir( '', 'Browse to Anatomy folder' ) );
	end

	function mrC_ExportData
		uiSize = [100 20 10];	% [width height margin]
		tDomain = 'Wave';
		tFlts = fieldnames( gD.(replaceChar(GetChartSelx('Sbjs',1,true),'-','_')).(GetChartSelx('Cnds',1,true)).(GetChartSelx('Mtgs',1,true)).Wave );
		uiH = zeros(1,11);
		uiH(1) = dialog('defaultuipanelunits','pixels','Name','Workspace Export','Position',[400 400 uiSize*[2 0;0 5;7 10]]); %,'Color',[0.9 0.9 0]); %,'defaultuipaneltitleposition','centertop');
		uiH(2) = uibuttongroup('Parent',uiH(1),'Position',uiSize*[0 0 1 0;0 2 0 3;1 6 2 3],'Title','Space');
		uiH(3) = uibuttongroup('Parent',uiH(1),'Position',uiSize*[1 0 1 0;0 2 0 3;4 6 2 3],'Title','Domain','SelectionChangeFcn',@ButtonGroup_CB);
		uiH(4) =       uipanel('Parent',uiH(1),'Position',uiSize*[0 0 2 0;0 1 0 1;1 2 5 3],'Title','Filter');
		uiH(5)  = uicontrol(uiH(2),'Position',uiSize*[0 0 1 0;0 2 0 1;1 1 0 0],'Style','radiobutton','String','Source','Value',1);
		uiH(6)  = uicontrol(uiH(2),'Position',uiSize*[0 0 1 0;0 1 0 1;1 1 0 0],'Style','radiobutton','String','Sensor');
		uiH(7)  = uicontrol(uiH(3),'Position',uiSize*[0 0 1 0;0 2 0 1;1 1 0 0],'Style','radiobutton','String','Wave','Value',1);
		uiH(8)  = uicontrol(uiH(3),'Position',uiSize*[0 0 1 0;0 1 0 1;1 1 0 0],'Style','radiobutton','String','Spec');
		uiH(9)  = uicontrol(uiH(3),'Position',uiSize*[0 0 1 0;0 0 0 1;1 1 0 0],'Style','radiobutton','String','Harm');
		uiH(10) = uicontrol(uiH(4),'Position',uiSize*[0 0 2 0;0 0 0 1;1 1 3 0],'Style','popup','String',tFlts);
		uiH(11) = uicontrol(uiH(1),'Position',uiSize*[0 0 2 0;0 0 0 1;1 1 5 0],'Style','pushbutton','String','GO','Callback','uiresume');
		uiwait
		tFlt = tFlts{ get(uiH(10),'Value') };
		[Y,Ydim] = gD2array( gD, gVEPInfo, gSbjROIFiles, get(uiH(5),'Value')==1, tDomain, tFlt );
		close(uiH(1))
		assignin( 'base', 'Y', Y );
		assignin( 'base', 'Ydim', Ydim );
		assignin( 'base', 'Yfilter', tFlt );
		SetMessage( 'Export Complete', 'status' )
		function ButtonGroup_CB( tH, tE )
			tDomain = get( tE.NewValue, 'String' );
		end
	end


	function MakeTopoGUI

		uiSize = [80; 20; 10];		% [width; height; margin]
		uiD = dialog('Name','TopoGUI','Position',[400 400 ([6 0 4;0 7 4]*uiSize)']); %,'defaultuipanelunits','pixels','defaultuipaneltitleposition','centertop');
		uiC = [...
			uicontrol(uiD,'Position',([0 0 1;0 6 3;2 0 0;0 1 0]*uiSize)','Style','text','String','Subject(s)')...
			uicontrol(uiD,'Position',([2 0 2;0 6 3;2 0 0;0 1 0]*uiSize)','Style','text','String','Condition')...
			uicontrol(uiD,'Position',([4 0 3;0 6 3;2 0 0;0 1 0]*uiSize)','Style','text','String','Filter')...
			uicontrol(uiD,'Position',([0 0 1;0 2 3;2 0 0;0 4 0]*uiSize)','Style','listbox','String',gChartFs.Sbjs.Items,'Max',2)...
			uicontrol(uiD,'Position',([2 0 2;0 2 3;2 0 0;0 4 0]*uiSize)','Style','listbox','String',gChartFs.Cnds.Items)...
			uicontrol(uiD,'Position',([4 0 3;0 2 3;2 0 0;0 4 0]*uiSize)','Style','listbox','String',gChartFs.Flts.Items)...
			uicontrol(uiD,'Position',([0 0 1;0 1 2;1 0 0;0 1 0]*uiSize)','Style','text','String','size (pixels)')...
			uicontrol(uiD,'Position',([1 0 1;0 1 2;1 0 0;0 1 0]*uiSize)','Style','edit','String','500')...
			uicontrol(uiD,'Position',([0 0 1;0 0 1;6 0 2;0 1 0]*uiSize)','Style','pushbutton','String','continue','Callback','uiresume') ];
		uiwait(uiD)

		if ~ishandle(uiD)
			return
		end
		iSbj = get(uiC(4),'Value');
		iCnd = get(uiC(5),'Value');
		iFlt = get(uiC(6),'Value');
		axW = eval(get(uiC(8),'String'));					% topo axis width,height (pixels)
		close(uiD)

		tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
% 		SD = InitSliceDescription( tValidFields );
		SD = gChartFs;
		SD.Sbjs.Items = gChartFs.Sbjs.Items(iSbj);
		SD.Cnds.Items = gChartFs.Cnds.Items(iCnd);
		SD.Flts.Items = gChartFs.Flts.Items(iFlt);			% *** check that this filter exists
		
% 		[ SD.Sbjs.Sel, SD.Cnds.Sel, SD.Flts.Sel ] = deal(1);
		tNSbjs = numel(iSbj);
		SD.Sbjs.Sel = 1:tNSbjs;
		[ SD.Cnds.Sel, SD.Flts.Sel ] = deal(1);
		% force selection of all channels
		[ SD.Chans.Items, SD.Chans.Sel ] = deal( 1:numel(gChartFs.Chans.Items) );
		
		SetFilteredWaveforms( SD )

		Y = getAvgSliceData( [ true, false ], SD, 'Wave', tValidFields );
		if tNSbjs == 1
			tSbjTag = SD.Sbjs.Items{1};
		else
			tSbjTag = sprintf('Mean%dSelections',tNSbjs);
		end
	
		tNT = size( Y, 1 );
		tCndInfo = GetVEP1Cnd(1);			% assuming same VEP info for all conditions for CalcItems
		tX = tCndInfo.dTms * ( 1:tNT );
				
		cbW = 70;					% ~colorbar width (pixels)
		axM = 30;					% margins (pixels)
		axH = [ axW-cbW, 0 ];	% axes heights (pixels) [ topo, timeSeries ]
		axH(2) = round( 0.2*axH(1) );

		figW = 2*axM + axW;
		figH = 3*axM + sum(axH);
		figH = ceil( figH / 4 ) * 4;		% multiple of 4 for avi codec

		ss = get(0,'screensize');
		tNmap = 200;		% 236 = max color vals in avi???
		tCutoff = GetOptSelx( 'ColorCutoff', 1, true );
% 		AVIpars.colormap = flow( tNmap, min( tCutoff / max( abs( Y(:) ) ), 1 ) );

		fig = figure('defaultaxesunits','pixels','Position',[max(ceil((ss(3)-figW)/2),1) max(ceil((ss(4)-figH)/2),1) figW figH],...
						'Colormap', flow( tNmap, min( tCutoff / max( abs( Y(:) ) ), 1 ) ) );
		uiM = uimenu('label','TopoMenu');
		uiCM = uicontextmenu( 'Parent', fig );		% note: has to have same parent figure as objects it gets assigned to
		uimenu( uiCM, 'Label', 'ID Vertices', 'Callback', 'mrC_IDpatchVertices' )
		ax = [	axes('DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'Box','on','Position',[axM axM+axH(2)+axM axW axH(1)]),...
					axes('Position',[axM axM axW axH(2)])	];

		axes(ax(2))
		tYLim  = [-1 1]*max(abs([ min(Y(:)), max(Y(:)) ]));
		plot(tX,Y,'k','HitTest','off')
		set(ax(2),'XLim',[0 tX(tNT)],'YLim',tYLim*1.05) %,'XTick',[],'YTick',[],'Box','on')
		iX = 1;
		tHline = line(tX([iX iX]),get(ax(2),'YLim'),'Color',[0 0.75 0]);
		title( [ 'Filter = ', SD.Flts.Items{1} ], 'Interpreter', 'none' )

		axes(ax(1))
		Pflat = load('defaultFlatNet.mat');		% 128x2 variable xy
		tHpatch = patch(	'Vertices',[Pflat.xy,zeros(128,1)], 'Faces',mrC_EGInetFaces(false),...
								'FaceVertexCData',Y(iX,:)', 'FaceColor','interp', 'CDataMapping','scaled',...
								'EdgeColor','k', 'LineWidth',1, 'Marker','.', 'MarkerSize',16, 'UIContextMenu', uiCM );
		set(ax(1),'CLim',tYLim)
		title( [ 'Subject = ', tSbjTag, ', Condition = ', SD.Cnds.Items{1} ], 'Interpreter', 'none' )
		colorbar('peer',ax(1),'EastOutside')

		set(ax(2),'ButtonDownFcn',@TopoUpdate)
		function TopoUpdate(varargin)
			tCurPoint = get(ax(2),'CurrentPoint');
% 			set( tHline, 'XData', tCurPoint(1,[1 1]) )
			iX = round( tCurPoint(1,1) / tCndInfo.dTms );
			if iX>=1 && iX<=tNT
				set( tHline, 'XData', tX([iX iX]) )
				set( tHpatch, 'FaceVertexCData', Y(iX,:)' )
			else
				disp('clicked out of bounds')
			end
		end
		
		uimenu(uiM,'label','Reset cutoff','Callback',@TopoColorMap)
		function TopoColorMap(varargin)
			% mrC_InputBigFont(tTitleStr,tPromptStr,tExprStr,tFontSize)
			tCutStr = inputdlg({'Cutoff'},'TopoGUI',1,{num2str(tCutoff)});
			if isempty( tCutStr )
				return
			end
			tCutoff = eval( tCutStr{1} );
			set( fig, 'colormap', flow( tNmap, min( tCutoff / max( abs( Y(:) ) ), 1 ) ) )
		end
		
		uimenu(uiM,'label','MakeMovie','Callback',@TopoMovie)
		function TopoMovie(varargin)
			
			aviOpts = inputdlg( {'Start (ms)','Stop (ms)',sprintf('Step (# %0.3fms samples)',tCndInfo.dTms),'fps','compression','quality [1,100]'},...
				'TopoGUI', 1, {num2str(ceil(tX(1))),num2str(floor(tX(tNT))),'10','4','None','100'} );
			if isempty(aviOpts)
				return
			end
			iStart = round ( eval( aviOpts{1} ) / tCndInfo.dTms );
			if iStart<1 || iStart>tNT
				error('Start time out of bounds')
			end
			iStop = round( eval( aviOpts{2} ) / tCndInfo.dTms );
			if iStop<1 || iStop>tNT || iStop<iStart
				error('Stop time out of bounds or < start')
			end
			iStep = round( eval( aviOpts{3} ) );
			if iStop < 1
				error('No backward movie support')
			end
			AVIfps = eval( aviOpts{4} );
			AVIquality = round( eval( aviOpts{6} ) );
			if AVIquality<1 || AVIquality>100
				error('AVI quality out of range')
			end
			set(tHline,'XData',tX([iStart iStart]))
			set(tHpatch,'facevertexcdata',Y(iStart,:)')
			
			[aviName,aviPath] = uiputfile(fullfile(gProjPN,'*.avi'),'Save AVI file');
			saveAVI = ischar(aviName);
			if saveAVI
				avi = avifile([aviPath,aviName],'colormap',get(fig,'colormap'),'fps',AVIfps,'compression',aviOpts{5},'quality',AVIquality);	%,'videoname','xxx');
			end

			disp('Press key to start.  Don''t cover any part of the figure window while building an avi-file.')
			set( fig, 'Name', '---PRESS KEY TO START---' )
			figure( fig )
			pause
			if saveAVI
				set( fig, 'Name', '---BUILDING AVI. DON''T COVER FIGURE!---' )
			else
				set( fig, 'Name', '' )
			end
			for iX = iStart:iStep:iStop
				set(tHline,'XData',tX([iX iX]))
				set(tHpatch,'facevertexcdata',Y(iX,:)')
				drawnow
				if saveAVI
					avi = addframe( avi, getframe(fig) );
				end
			end
			if saveAVI
				set( fig, 'Name', '' )
				avi = close(avi);
			end
		end

		uimenu(uiM,'label','ImageStack4Mac','Callback',@MacStack)
		function MacStack(varargin)
			
			stackOpts = inputdlg( {'Start (ms)','Stop (ms)',sprintf('Step (# %0.3fms samples)',tCndInfo.dTms)},...
				'TopoGUI', 1, {num2str(ceil(tX(1))),num2str(floor(tX(tNT))),'10'} );
			if isempty(stackOpts)
				return
			end
			iStart = round ( eval( stackOpts{1} ) / tCndInfo.dTms );
			if iStart<1 || iStart>tNT
				error('Start time out of bounds')
			end
			iStop = round( eval( stackOpts{2} ) / tCndInfo.dTms );
			if iStop<1 || iStop>tNT || iStop<iStart
				error('Stop time out of bounds or < start')
			end
			iStep = round( eval( stackOpts{3} ) );
			if iStop < 1
				error('No backward movie support')
			end
			set(tHline,'XData',tX([iStart iStart]))
			set(tHpatch,'facevertexcdata',Y(iStart,:)')
			
			stackDir = uigetdir( gProjPN, 'Save image stack to' );
			if isnumeric( stackDir )
				return
			end
			if exist( fullfile( stackDir, 'image0001.gif' ), 'file' )
				if ~strcmp( questdlg( 'Image(s) exist.  Overwrite?', 'MacStack', 'Yes', 'No', 'No' ), 'Yes' )
					return
				end
			end

			iStack = 0;
			disp('Press key to start.  Don''t cover any part of the figure window while generating images.')
			set( fig, 'Name', '---PRESS KEY TO START---' )
			figure( fig )
			pause
			set( fig, 'Name', '---GENERATING IMAGES. DON''T COVER FIGURE!---' )
			for iX = iStart:iStep:iStop
				set(tHline,'XData',tX([iX iX]))
				set(tHpatch,'facevertexcdata',Y(iX,:)')
				drawnow
				tFrame = getframe(fig);
				iStack = iStack + 1;
				if iStack == 1
					[ tImg, tMap ] = rgb2ind( tFrame.cdata, 256, 'nodither' );
				else
					[ tImg, tMap ] = rgb2ind( tFrame.cdata, 256, 'nodither' );
% 					tImg = rgb2ind( tFrame.cdata, tMap, 'nodither' );
% 					tImg(:,:,1,iStack) = rgb2ind( tFrame.cdata, tMap, 'nodither' );
				end
				imwrite( tImg, tMap, fullfile( stackDir, sprintf( 'image%04d.gif', iStack ) ), 'gif' )
			end
% 			imwrite( tImg, tMap, '', 'gif', 'DelayTime', 0, 'LoopCount', 0 )		% try animated gif?
			set( fig, 'Name', '' )
		end

% 		image(TopoFrames(1).cdata)
% 		set(gca,'Units','pixels','Position',[20 20 561 609],'Box','off','XTick',[],'YTick',[],'Color','g','Visible','off')

    end
    
    function outStr = replaceChar(inStr,badStr,newStr)
        outStr = inStr;
        outStr(strfind(inStr,badStr))=newStr;
    end

end