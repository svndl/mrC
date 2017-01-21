function mrCurrent403ch(initPath)
%% General initialization
	disp( 'MrCurrent Version 10.0' );
	% Version commentary managed by CVS
	% Preceding version commentary available in X:\projects\pettet\mrPrototypes\mrCurrent\mrCurrent.m.

	% Initialize these variables here first to force outer scope
	ghMrCurrentGUI = []; % handle to this GUI, to enforce singleton.
	gProjPN = 0; % project path name
	gProjVer = 0;
	gInvDir = '';
	gD = []; % root of the main data structure
	gVEPInfo = []; % VEP metadata from Axx files
	gCndFiles = [];
	gSbjROIFiles = [];
% 	gSbjROIs = [];
% 	gN = []; % global structure for keeping track of item list sizes
	gCortex = [];
	gIsPivotOn = false; % flag for pivoting
	gChartFs = []; % structure of chart fields
	gChartL = [];
	gOptFs = []; % structure of option fields
	gOptL = [];
	gCompFieldNms = []; % since readable harmonic component expressions don't make good struct field names.
	gSPHs = [];
	gCurs = [];
	gCalcItems = [];
	gCalcItemOrder = [];

	InitMrCurrentGUI;
	InitPivotFieldsStruct;
	if nargin >= 1
		NewProject_CB(initPath)
	end

	function InitMrCurrentGUI
		ghMrCurrentGUI = findtag( 'mrCG' );	% look for existing gui;
		if ~isempty( ghMrCurrentGUI )		% if it already exists...
			figure( ghMrCurrentGUI );		% use it...
			return;							% and stop here.
		end
		% if we get here, start building new gui
		ghMrCurrentGUI = MakeMrCG;	% "make mrCurrent GUI" build new gui;
		set( ghMrCurrentGUI, 'ResizeFcn', @ResizeMrCG );		% ResizeMrCG runs here, but not if you put a pause 1st longer than 0.1 or so???

		set( findtags( { 'mrCG_Project_text' 'mrCG_Messages_text' } ), 'horizontalalignment', 'left' );
		set( findtag( 'mrCG_Project_text' ), 'fontsize', 1.25 * get( findtag( 'mrCG_Project_text' ), 'fontsize' ) );

		set( [ findobj( ghMrCurrentGUI, 'style', 'listbox', '-or', 'style', 'popupmenu', '-or', 'style', 'edit' );...
				findtags( { 'mrCG_Project_text', 'mrCG_Messages_text' } )' ], 'backgroundcolor', [ .85 .85 .85 ] );

		set( findtags( { 'mrCG_Cursor_Frame', 'mrCG_Cursor_Movie', 'mrCG_Cortex_View', 'mrCG_Cortex_Rotate' } ), 'TitlePosition', 'centertop' );

% 		set( findtag( 'mrCG_Pivot_NewPlot_pushbutton' ), 'callback', @mrCG_Pivot_NewPlot_CB );
% 		set( findtag( 'mrCG_Pivot_ClonePlot_pushbutton' ), 'callback', @mrCG_Pivot_ClonePlot_CB );
		
		tDisabledControls = {	'mrCG_Pivot_Items_UserDefined_edit', ...
			'mrCG_Cursor_Frame_At_edit', 'mrCG_Cursor_Start_At_edit', 'mrCG_Cursor_End_At_edit', ...
			'mrCG_Cursor_Frame_Pick_pushbutton', 'mrCG_Cursor_Start_Pick_pushbutton', 'mrCG_Cursor_End_Pick_pushbutton', ...
			'mrCG_Cursor_Step_By_edit', 'mrCG_Cursor_Step_B_pushbutton', 'mrCG_Cursor_Step_F_pushbutton', ...
			'mrCG_Cortex_Paint_pushbutton', 'mrCG_Cursor_Play_pushbutton', 'mrCG_Cursor_Clear_pushbutton' };
		set( findtags( tDisabledControls ), 'enable', 'off' );
		
		ConfigureTaskControls;

		SetMessage( 'Click Project New button...' );

		drawnow;
		function tFH = MakeMrCG

			tUD.tOldPos = [ 40 15 178 54 ];
			tFH = figure( 'tag', 'mrCG', 'Units','characters', 'Position', tUD.tOldPos , 'userdata', tUD, 'menubar', 'none', 'color', [0 0.3 0.3],...
				'defaultuipanelunits', 'characters', 'defaultuipanelfontsize', 12, 'defaultuicontrolunits', 'characters', 'defaultuicontrolfontsize', 12 );

			% pivot panel
			tH1 = uipanel( tFH, 'position', [   2 22.5 174  31 ], 'title', 'Pivot', 'tag', 'mrCG_Pivot' );
			tH2 = uipanel(      'position', [   2  4.5  72  25 ], 'title', 'Chart', 'tag', 'mrCG_Pivot_Chart', 'parent', tH1 );
			    uicontrol( tH2, 'position', [   2    1  58  22 ], 'style', 'listbox', 'string', { 'None...' }, 'tag', 'mrCG_Pivot_Chart_listbox', 'max', 1, 'callback', @mrCG_Pivot_Chart_listbox_CB );
			    uicontrol( tH2, 'position', [  61    1   9  22 ], 'style', 'pushbutton', 'string', 'Pivot', 'tag', 'mrCG_Pivot_Chart_Pivot_pushbutton', 'callback', @mrCG_Pivot_Chart_Pivot_pushbutton_CB );
			tH2 = uipanel( 'parent', tH1, 'position', [  75  4.5  40  25 ], 'title', 'Items', 'tag', 'mrCG_Pivot_Items' );
			    uicontrol( tH2, 'position', [   2    8  36  15 ], 'style', 'listbox', 'string', { 'None...' }, 'tag', 'mrCG_Pivot_Items_listbox', 'max', 1, 'ListboxTop', 1, 'callback', @mrCG_Pivot_Items_listbox_CB );
			    uicontrol( tH2, 'position', [   2  5.5   6   2 ], 'style', 'pushbutton', 'string', 'Up'  , 'tag', 'mrCG_Pivot_Items_Up_pushbutton'  , 'callback', @ManageListBoxSelection_CB );
			    uicontrol( tH2, 'position', [   9  5.5  10   2 ], 'style', 'pushbutton', 'string', 'Down', 'tag', 'mrCG_Pivot_Items_Down_pushbutton', 'callback', @ManageListBoxSelection_CB );
			    uicontrol( tH2, 'position', [  20  5.5   8   2 ], 'style', 'pushbutton', 'string', 'Top' , 'tag', 'mrCG_Pivot_Items_Top_pushbutton' , 'callback', @ManageListBoxSelection_CB );
			    uicontrol( tH2, 'position', [  29  5.5   9   2 ], 'style', 'pushbutton', 'string', 'Flip', 'tag', 'mrCG_Pivot_Items_Flip_pushbutton', 'callback', @ManageListBoxSelection_CB );
			tH3 = uipanel( 'parent', tH2, 'position', [   2  0.5  36 4.5 ], 'title', 'UserDefined', 'tag', 'mrCG_Pivot_Items_UserDefined' );
			    uicontrol( tH3, 'position', [   2  0.5  32   2 ], 'style', 'edit', 'string', '', 'tag', 'mrCG_Pivot_Items_UserDefined_edit', 'callback', @mrCG_Pivot_Items_UserDefined_edit_CB );
			tH2 = uipanel( 'parent', tH1, 'position', [ 116  4.5  56  25 ], 'title', 'Options', 'tag', 'mrCG_Pivot_Options' );
			    uicontrol( tH2, 'position', [   2    1   9  22 ], 'style', 'pushbutton', 'string', 'Pivot', 'tag', 'mrCG_Pivot_Options_Pivot_pushbutton', 'callback', @mrCG_Pivot_Options_Pivot_pushbutton_CB );
			    uicontrol( tH2, 'position', [  12    1  42  22 ], 'style', 'listbox', 'string', { 'None...' }, 'tag', 'mrCG_Pivot_Options_listbox', 'max', 1, 'callback', @mrCG_Pivot_Options_listbox_CB );
			    uicontrol( tH1, 'position', [   2    1  84 2.5 ], 'style', 'pushbutton', 'string', 'New Plot', 'tag', 'mrCG_Pivot_NewPlot_pushbutton', 'callback', @PivotPlot_CB );
			    uicontrol( tH1, 'position', [  88    1  84 2.5 ], 'style', 'pushbutton', 'string', 'Revise Plot', 'tag', 'mrCG_Pivot_RevisePlot_pushbutton', 'callback', @PivotPlot_CB );
			% project panel
			tH1 = uipanel( tFH, 'position', [   2  14 57   8 ], 'title', 'Project', 'tag', 'mrCG_Project' );
			    uicontrol( tH1, 'position', [   2 3.5 53   2 ], 'style', 'text', 'string', { 'None...' }, 'tag', 'mrCG_Project_text' );
			    uicontrol( tH1, 'position', [   2 0.5 53   2 ], 'style', 'pushbutton', 'string', 'New', 'tag', 'mrCG_Project_New_pushbutton', 'callback', @NewProject_CB );
			% task panel
			tH1 = uipanel( tFH, 'position', [   2   6 57 7.5 ], 'tag', 'mrCG_Task', 'title', 'Task' );
			    uicontrol( tH1, 'position', [   2 3.5 53   2 ], 'style', 'popupmenu', 'string', { 'None...' }, 'tag', 'mrCG_Task_Function_popupmenu' );
			    uicontrol( tH1, 'position', [   2 0.5 53   2 ], 'style', 'pushbutton', 'string', 'Go', 'tag', 'mrCG_Task_Go_pushbutton' );
			% cursor panel
			tH1 = uipanel( tFH, 'position', [   61   6  65   16 ], 'title', 'Cursor', 'tag', 'mrCG_Cursor' );
			tH2 = uipanel( 'parent', tH1, 'position', [    2   5  19  9.5 ], 'title', 'Frame', 'tag', 'mrCG_Cursor_Frame' );
			    uicontrol( tH2, 'position', [    2 5.5  15    2 ], 'style', 'edit', 'string', '', 'tag', 'mrCG_Cursor_Frame_At_edit', 'callback', @mrCG_Cursor_Edit_CB );
			    uicontrol( tH2, 'position', [    2   3  15    2 ], 'style', 'pushbutton', 'string', 'Pick', 'tag', 'mrCG_Cursor_Frame_Pick_pushbutton', 'callback', @mrCG_Cursor_Pick_CB );
			    uicontrol( tH2, 'position', [    2 0.5   7    2 ], 'style', 'pushbutton', 'string', '<<', 'tag', 'mrCG_Cursor_Step_B_pushbutton', 'callback', @mrCG_Cursor_Step_CB );
			    uicontrol( tH2, 'position', [   10 0.5   7    2 ], 'style', 'pushbutton', 'string', '>>', 'tag', 'mrCG_Cursor_Step_F_pushbutton', 'callback', @mrCG_Cursor_Step_CB );
			tH2 = uipanel( 'parent', tH1, 'position', [   23   5  40  9.5 ], 'title', 'Movie', 'tag', 'mrCG_Cursor_Movie' );
			    uicontrol( tH2, 'position', [    2 5.5  15    2 ], 'style', 'edit', 'string', '', 'tag', 'mrCG_Cursor_Start_At_edit', 'callback', @mrCG_Cursor_Edit_CB );
			    uicontrol( tH2, 'position', [    2   3  15    2 ], 'style', 'pushbutton', 'string', 'Pick', 'tag', 'mrCG_Cursor_Start_Pick_pushbutton', 'callback', @mrCG_Cursor_Pick_CB );
			    uicontrol( tH2, 'position', [   18 5.5   4    2 ], 'style', 'text', 'string', 'to', 'tag', 'mrCG_Cursor_Play_To' );
			    uicontrol( tH2, 'position', [   23 5.5  15    2 ], 'style', 'edit', 'string', '', 'tag', 'mrCG_Cursor_End_At_edit', 'callback', @mrCG_Cursor_Edit_CB );
			    uicontrol( tH2, 'position', [   23   3  15    2 ], 'style', 'pushbutton', 'string', 'Pick', 'tag', 'mrCG_Cursor_End_Pick_pushbutton', 'callback', @mrCG_Cursor_Pick_CB );
			    uicontrol( tH2, 'position', [    2 0.5  36    2 ], 'style', 'pushbutton', 'string', 'Play', 'tag', 'mrCG_Cursor_Play_pushbutton', 'callback', @mrCG_Cursor_Play_CB );				 
			    uicontrol( tH1, 'position', [    2 0.5  19    4 ], 'style', 'pushbutton', 'string', 'Clear All', 'tag', 'mrCG_Cursor_Clear_pushbutton', 'callback', @mrCG_Cursor_Clear_CB );
			    uicontrol( tH1, 'position', [   25 0.5  20    2 ], 'style', 'text', 'string', 'Step by', 'tag', 'mrCG_Cursor_Step' );
			    uicontrol( tH1, 'position', [   46 0.5  17    2 ], 'style', 'edit', 'string', '', 'tag', 'mrCG_Cursor_Step_By_edit', 'callback', @mrCG_Cursor_Step_By_CB );
			% cortex panel
			tH1 = uipanel( tFH, 'position', [ 128   6 48   16 ], 'title', 'Cortex', 'tag', 'mrCG_Cortex' );
			tH2 = uipanel( 'parent', tH1, 'position', [  2    5 21  9.5 ], 'title', 'Set View', 'tag', 'mrCG_Cortex_View' );
			    uicontrol( tH2, 'position', [  2  5.5  8    2 ], 'style', 'pushbutton', 'string', 'P', 'tag', 'mrCG_Cortex_View_P_pushbutton', 'callback', @mrCG_Cortex_View_CB );
			    uicontrol( tH2, 'position', [ 11  5.5  8    2 ], 'style', 'pushbutton', 'string', 'A', 'tag', 'mrCG_Cortex_View_A_pushbutton', 'callback', @mrCG_Cortex_View_CB );
			    uicontrol( tH2, 'position', [  2    3  8    2 ], 'style', 'pushbutton', 'string', 'L', 'tag', 'mrCG_Cortex_View_L_pushbutton', 'callback', @mrCG_Cortex_View_CB );
			    uicontrol( tH2, 'position', [ 11    3  8    2 ], 'style', 'pushbutton', 'string', 'R', 'tag', 'mrCG_Cortex_View_R_pushbutton', 'callback', @mrCG_Cortex_View_CB );
			    uicontrol( tH2, 'position', [  2  0.5  8    2 ], 'style', 'pushbutton', 'string', 'D', 'tag', 'mrCG_Cortex_View_D_pushbutton', 'callback', @mrCG_Cortex_View_CB );
			    uicontrol( tH2, 'position', [ 11  0.5  8    2 ], 'style', 'pushbutton', 'string', 'V', 'tag', 'mrCG_Cortex_View_V_pushbutton', 'callback', @mrCG_Cortex_View_CB );
			tH2 = uipanel( 'parent', tH1, 'position', [ 25    5 21  9.5 ], 'title', 'Rotate', 'tag', 'mrCG_Cortex_Rotate' );
			    uicontrol( tH2, 'position', [  2  5.5  8    2 ], 'style', 'pushbutton', 'string', 'L', 'tag', 'mrCG_Cortex_Rot_L_pushbutton', 'callback', @mrCG_Cortex_Rotate_CB );
			    uicontrol( tH2, 'position', [ 11  5.5  8    2 ], 'style', 'pushbutton', 'string', 'R', 'tag', 'mrCG_Cortex_Rot_R_pushbutton', 'callback', @mrCG_Cortex_Rotate_CB );
			    uicontrol( tH2, 'position', [  2    3  8    2 ], 'style', 'pushbutton', 'string', 'D', 'tag', 'mrCG_Cortex_Rot_D_pushbutton', 'callback', @mrCG_Cortex_Rotate_CB );
			    uicontrol( tH2, 'position', [ 11    3  8    2 ], 'style', 'pushbutton', 'string', 'V', 'tag', 'mrCG_Cortex_Rot_V_pushbutton', 'callback', @mrCG_Cortex_Rotate_CB );
			    uicontrol( tH2, 'position', [  2  0.5  8    2 ], 'style', 'text', 'string', 'by', 'tag', 'mrCG_Cortex_Rot_By' );
			    uicontrol( tH2, 'position', [ 11  0.5  8    2 ], 'style', 'edit', 'string', '15', 'tag', 'mrCG_Cortex_Rot_By_edit' );
			    uicontrol( tH1, 'position', [  2  0.5 14    4 ], 'style', 'pushbutton', 'string', 'Paint', 'tag', 'mrCG_Cortex_Paint_pushbutton', 'callback', @mrCG_Cortex_Paint_CB );
			    uicontrol( tH1, 'position', [ 18  2.5 19    2 ], 'style', 'checkbox', 'string', 'Scalp', 'tag', 'mrCG_Cortex_Scalp_checkbox', 'callback', @mrCG_Cortex_Scalp_CB );
			    uicontrol( tH1, 'position', [ 18  0.5 19    2 ], 'style', 'checkbox', 'string', 'Contours', 'tag', 'mrCG_Cortex_Contour_checkbox', 'callback', @mrCG_Cortex_Contour_CB );
			    uicontrol( tH1, 'position', [ 38  0.5  8    2 ], 'style', 'edit', 'string', '10', 'tag', 'mrCG_Cortex_Contour_edit' );
			% message panel
			tH1 = uipanel( tFH, 'position', [ 2 0.5 174   5 ], 'title', 'Message', 'tag', 'mrCG_Messages' );
			    uicontrol( tH1, 'position', [ 2 0.5 170 2.5 ], 'style', 'text', 'string', { 'None...' }, 'tag', 'mrCG_Messages_text' );

		end
		
	end

%% Pivot Functions
	function InitPivotFieldsStruct
		tPFPropVals = { ...
		'Space',       'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Source' 'Sensor' 'Topo' }; ...
 		'Domain',      'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Wave' 'Spec' '2DPhase' 'Bar' 'BarTriplet' }; ...
% 		'Stats',       'mrCG_Pivot_Options_listbox', 'mOpt', 1, { 'Mean' 'Dispersion' 'Scatter' 'SbjNames' 'Significance' }; ...
		'Stats',       'mrCG_Pivot_Options_listbox', 'mOpt', 1, { 'Mean' 'Dispersion' 'Scatter' }; ...
		'Colors',      'mrCG_Pivot_Options_listbox', 'mOpt', 1:8, DefaultColorOrderNames; ...
		'Cortex',      'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'none' }; ...
		'ScaleBy',     'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'All' 'Rows' 'Cols' 'Panels' 'Reuse' }; ...
		'SpecPlotCmp', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'UpDown' 'Overlay' }; ...
		'Patches',     'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'on' 'off' }; ...
		'WaveSpacing', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '5' '10' '1' '2.5' 'UsrDef: ' }; ...
		'SpecSpacing', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '.5' '1' '2.5' '5' 'UsrDef: ' }; ...
		'SpecXLim',    'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '20' '10' '50' 'Max' 'UsrDef: ' }; ...
		'ColorCutoff', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '1' '2' '5' '10' '20' '50' '100' 'UsrDef: ' }; ...
		'AutoPaint',   'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'on' 'off' }; ...
		'ColorMapMax', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'All' 'Cursor' 'UsrDef: ' }; ...
		'BarMean',     'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Coherent' 'Incoherent' }; ...
% 		'AmpType',     'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'projected' 'scalar' }; ...
% 		'SignifTest',  'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Bonferroni' 'PermTVals' 'PermTRuns' }; ...
% 		'SignifCrit',  'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Omnibus' 'Chan/ROI' }; ...
% 		'SignifMarkers', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'OnWaves' 'OnAxis' }; ...
% 		'GhostTest',   'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'off' 'on' }; ...
		'DisperScale', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'SEM' '95%CI' }; ...
		'SensorWaves', 'mrCG_Pivot_Options_listbox', 'sOpt', 2, { 'butterfly', 'average', 'GFP' }; ...
		'TopoMap',     'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'elp-File', 'Standard' }; ...
		'XLBookName',  'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'mrCurrentData.xlw' 'UsrDef: ' }; ...
		'XLSheetName', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'mrCurrentData' 'UsrDef: ' }; ...
		};
		for iF = 1:numel( tPFPropVals( :, 1 ) )
			gOptFs.( tPFPropVals{ iF, 1 } ).ListTag = tPFPropVals{ iF, 2 };
			gOptFs.( tPFPropVals{ iF, 1 } ).Dim     = tPFPropVals{ iF, 3 };
			gOptFs.( tPFPropVals{ iF, 1 } ).Sel     = tPFPropVals{ iF, 4 };
			gOptFs.( tPFPropVals{ iF, 1 } ).Items   = tPFPropVals{ iF, 5 };
		end
% 		gOptL = struct( 'Items', fieldnames( gOptFs ), 'Sel', 1 );
		gOptL.Items = fieldnames( gOptFs );
		gOptL.Sel = 1;

		tPFPropVals = { ...
		'Cnds',  'mrCG_Pivot_Chart_listbox',   [], {}, false; ...
		'Hems',  'mrCG_Pivot_Chart_listbox',   DefaultChartVals( 'Hems', false ), DefaultChartVals( 'Hems', true ), false; ...
		'ROIs',  'mrCG_Pivot_Chart_listbox',   [], {}, false; ...
		'ROItypes', 'mrCG_Pivot_Chart_listbox', DefaultChartVals( 'ROItypes', false ), DefaultChartVals( 'ROItypes', true ), false; ...
		'Sbjs',  'mrCG_Pivot_Chart_listbox',   [], {}, true; ...
		'Flts',  'mrCG_Pivot_Chart_listbox',   [], {}, false; ...
		'Comps', 'mrCG_Pivot_Chart_listbox',   [], {}, false; ...
		'Invs',  'mrCG_Pivot_Chart_listbox',   [], {}, false; ...
		'Mtgs',  'mrCG_Pivot_Options_listbox', [], {}, false; ...
		'Chans', 'mrCG_Pivot_Options_listbox', [], {}, true; ...
		};
		for iF = 1:numel( tPFPropVals( :, 1 ) )
% 			gChartFs.( tPFPropVals{ iF, 1 } ) = struct( 'ListTag', tPFPropVals( :, 2 ), 'Dim', tPFPropVals( :, 3 ), ...
% 				'Sel', tPFPropVals( :, 4 ), 'Items', tPFPropVals( :, 5 ) );
			gChartFs.( tPFPropVals{ iF, 1 } ).ListTag    = tPFPropVals{ iF, 2 };
			gChartFs.( tPFPropVals{ iF, 1 } ).Dim        = '';
			gChartFs.( tPFPropVals{ iF, 1 } ).Sel        = tPFPropVals{ iF, 3 };
			gChartFs.( tPFPropVals{ iF, 1 } ).Items      = tPFPropVals{ iF, 4 };
			gChartFs.( tPFPropVals{ iF, 1 } ).pageVector = tPFPropVals{ iF, 5 };
		end
% 		gChartL = struct( 'Items', fieldnames( gChartFs ), 'Sel', 1 );
		gChartL.Items = fieldnames( gChartFs );
		gChartL.Sel = 1;

		UpdateChartListBox;
		UpdateOptionsListBox;
	end

	function tDefaultVal = DefaultChartVals( tChartFNm, tItemFlag )
		switch tChartFNm
		case 'ROItypes'
			if tItemFlag
				tDefaultVal = { 'Mean', 'SVD' };
			else
				tDefaultVal = 1;
			end
		case 'Hems'
			if tItemFlag
				tDefaultVal = { 'Bilat', 'Left', 'Right' };
			else
				tDefaultVal = 2:3;
			end
		otherwise
			tDefaultVal = [];
		end
	end

	function tCompNms = TranslateCompNames( tCompNms )
		for iComp = 1:numel( tCompNms )
			tCompNms{ iComp } = TranslateCompName( tCompNms{ iComp } );
		end
	end

	function tCompNm = TranslateCompName( tCompNm )
		tCompNm = [ 'x' tCompNm ];
		tCompNm = strrep( tCompNm, '+', 'p' );
		tCompNm = strrep( tCompNm, '-', 'm' );
	end

	function mrCG_Pivot_Chart_listbox_CB( tH, varargin )
		gIsPivotOn = false;
		gChartL.Sel = get( tH, 'value' );
		if isempty( gChartFs.( gChartL.Items{ gChartL.Sel } ).Items )
			set( findtag( 'mrCG_Pivot_Items_listbox' ), 'string', {}, 'value', [], 'max', 1, 'ListboxTop', 1, 'userdata', 'Chart' );
		else
			tCFNm = gChartL.Items{ gChartL.Sel };
			tMax = 2 - ( strcmp( gChartFs.( tCFNm ).Dim, 'page' ) && ~gChartFs.( tCFNm ).pageVector );
			tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
			set( tILBH, 'ListboxTop', 1 )
			set( tILBH, 'string', gChartFs.( tCFNm ).Items, 'value', gChartFs.( tCFNm ).Sel, 'max', tMax, 'userdata', 'Chart' );
			set( tILBH, 'ListboxTop', min( gChartFs.( tCFNm ).Sel ) )
		end
		set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
	end

	function mrCG_Pivot_Chart_Pivot_pushbutton_CB( varargin )
		gIsPivotOn = true;
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		set( tILBH, 'ListboxTop', 1 )
		set( tILBH, 'value', gChartL.Sel, 'string', gChartL.Items, 'max', 2, 'userdata', 'Chart' );
		set( tILBH, 'ListboxTop', min( gChartL.Sel ) )
		set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
	end

	function mrCG_Pivot_Options_listbox_CB( tH, varargin )
		gIsPivotOn = false;
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		gOptL.Sel = get( tH, 'value' );
		if isempty( gOptL.Sel )
			set( tILBH, 'value', [], 'string', {}, 'max', 1, 'ListboxTop', 1 );
		else
			tOFNm = gOptL.Items{ gOptL.Sel };
			tOF = gOptFs.(tOFNm);
			set( tILBH, 'ListboxTop', 1 )
			set( tILBH, 'string', tOF.Items, 'value', tOF.Sel, 'max', 2 - strcmp( tOF.Dim, 'sOpt' ), 'userdata', 'Options' );
			set( tILBH, 'ListboxTop', min( tOF.Sel ) )
			if IsOptSelUserDefined( tOFNm )
				set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', GetOptSel( tOFNm ), 'enable', 'on' );
			else
				set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
			end
		end
	end

	function mrCG_Pivot_Options_Pivot_pushbutton_CB( varargin )
		gIsPivotOn = true;
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		set( tILBH, 'ListboxTop', 1 )
		set( tILBH, 'string', gOptL.Items, 'value', gOptL.Sel, 'max', 2, 'userdata', 'Options' );
		set( tILBH, 'ListboxTop', min( gOptL.Sel ) )
		set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
	end

	function mrCG_Pivot_Items_listbox_CB( tH, varargin )
		tListBoxName = get( tH, 'userdata' );
		switch tListBoxName
			case 'Chart'
				tNCmps = numel( gChartFs.(gChartL.Items{3}).Sel );
				if gIsPivotOn
					gChartL.Items = get( tH, 'string' );
					UpdateChartListBox;
				else
					tFNm = gChartL.Items{ gChartL.Sel };
					gChartFs.(tFNm).Items = get( tH, 'string' )';
					gChartFs.(tFNm).Sel = get( tH, 'value' );
					if strcmp( tFNm, 'Sbjs' ), ResolveSbjROIs; end
					UpdateChartListBox;
				end
				if tNCmps ~= numel( gChartFs.(gChartL.Items{3}).Sel )
					UpdateOptionsListBox;			% for color management
				end
			case 'Options'
				if gIsPivotOn
					gOptL.Items = get( tH, 'string' );
					UpdateOptionsListBox;
				else
					tFNm = gOptL.Items{ gOptL.Sel };
					gOptFs.(tFNm).Items = get( tH, 'string' )';
					gOptFs.(tFNm).Sel = get( tH, 'value' );
					UpdateOptionsListBox;
					if IsOptSelUserDefined( tFNm )
						set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', GetOptSel( tFNm ), 'enable', 'on' );
					else
						set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
					end
				end
		end
	end

	function mrCG_Pivot_Items_UserDefined_edit_CB( tH, varargin )
		tPILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		tList = get( tPILBH, 'string' );
		iUD = strmatch( 'UsrDef: ', tList );
		tList{ iUD } = [ 'UsrDef: ' get( tH, 'string' ) ];
		set( tPILBH, 'string', tList );
		mrCG_Pivot_Items_listbox_CB( tPILBH )
	end

	function UpdateChartListBox
		tNList = numel( gChartL.Items );
		tChartList = cell(1,tNList);
		tDimNms = { 'row' 'col' 'cmp' 'page' };
		for iF = 1:tNList
			tFNm = gChartL.Items{ iF }; % get each chart field name
			gChartFs.(tFNm).Dim = tDimNms{ min(iF,4) };
			if strcmp( gChartFs.(tFNm).Dim, 'page' ) && ~gChartFs.(tFNm).pageVector && ~isempty( gChartFs.(tFNm).Sel )
				gChartFs.(tFNm).Sel = gChartFs.(tFNm).Sel( 1 ); % when when changing to page field, take first item.
			end
			tItemSel = gChartFs.(tFNm).Items( gChartFs.(tFNm).Sel );
% 			tIsSbjAll = strcmp( tFNm, 'Sbjs' ) && numel( tItemSel ) == numel( gChartFs.Sbjs.Items );
% 			if tIsSbjAll
% 				tItemSel = { 'All' };
% 			end % For 'All' Sbjs.
			if gChartFs.(tFNm).pageVector
				if numel( tItemSel ) == numel( gChartFs.(tFNm).Items )
					tItemSel = { 'All' };
				end
			end
			tChartList{ iF } = [ gChartFs.(tFNm).Dim ': ' tFNm ': ' sprintf( '%s,', tItemSel{:} ) ];
			tChartList{ iF } = tChartList{ iF }( 1:(end-1) );
		end
		set( findtag( 'mrCG_Pivot_Chart_listbox' ), 'string', tChartList );
	end

	function UpdateOptionsListBox
		% updates whole options list.  make it just do selected option?
% 		gOptFs.Colors.Sel = 1:numel( gChartFs.(gChartL.Items{3}).Sel );		% don't automatically adjust to #cmps
		tNList = numel( gOptL.Items );
		tOptionsList = cell(1,tNList);
		for iF = 1:tNList
			tFNm = gOptL.Items{ iF }; % get each chart field name
			tItemSel = GetOptSels(tFNm);
			tOptionsList{ iF } = [ tFNm ': ' sprintf( '%s,', tItemSel{:} ) ];
			tOptionsList{ iF } = tOptionsList{ iF }( 1:(end-1) );
		end
		set( findtag( 'mrCG_Pivot_Options_listbox' ), 'string', tOptionsList );
		ConfigureCortex;
% 		if ~isempty( gCortex )		% causes error with UsrDef cutoff
% 			SetCortexFigColorMap;
% 		end
	end

	function ManageListBoxSelection_CB( tH, varargin )
% 		tTagStr = get( tH, 'Tag' ); % get tag of button being pushed, e.g., 'mrCG_Pivot_Files_Cnd_Up_pushbutton'
% 		tDlms = strfind( tTagStr, '_' );
% 		tTaskStr = tTagStr( (tDlms(end-1)+1):(tDlms(end)-1) );% e.g., use 'mrCG_Pivot_Files_Cnd_Up_pushbutton' to get task string, 'Up'
		tTok = textscan( get( tH, 'Tag' ), '%s', 'delimiter', '_' );
		tTaskStr = tTok{ 1 }{ 4 };
		tLBH = findtag( 'mrCG_Pivot_Items_listbox' );
		% Now get the properties we need to manipulate...
		tList = get( tLBH, 'string' );
		tNAll = numel( tList );
		tiAll = ( 1:tNAll )'; % subscript of full list
		tiSel = get( tLBH, 'value' )'; % subscripts of currently selected items
		tNSel = numel( tiSel );
		tiUnSel = setxor( tiAll, tiSel ); % subscripts of unselected items
		tiNewSel = tiSel;
		switch tTaskStr
			case 'Top'
				tiNewSel = ( 1:tNSel )';
			case 'Up'
				if any( diff( tiSel ) > 1 ) % non-contiguous, squeeze up
					tiNewSel = ( tiSel(1) : ( tiSel(1) + tNSel - 1 ) )';
				else % contiguous, promote by one
					if min( tiSel ) > 1
						tiNewSel = tiSel - 1;
					end
				end
			case 'Down'
				if any( diff( tiSel ) > 1 ) % non-contiguous, squeeze down
					tiNewSel =  ( ( tiSel(end) - tNSel + 1 ) : -1 : tiSel(end) )';
				else % contiguous, demote by one
					if max( tiSel ) < tNAll
						tiNewSel = tiSel + 1;
					end
				end
			case 'Flip'
				tiNewSel = flipud( tiSel(:) );
		end
		if any( tiNewSel ~= tiSel )
			tiNewUnSel = setxor( tiAll, tiNewSel );
			tNewList( tiNewSel ) = tList( tiSel );
			tNewList( tiNewUnSel ) = tList( tiUnSel );
			if strcmpi( tTaskStr, 'Flip' ), tiNewSel = flipud( tiNewSel ); end
			set( tLBH, 'string', tNewList, 'value', tiNewSel, 'listboxtop', 1 );
		end
		mrCG_Pivot_Items_listbox_CB( tLBH );
	end

	function ResolveSbjROIs
		% find the intersection of ROIs wrt sbjs
		tSbjNms      = GetChartSelsData( 'Sbjs' );
		tOldROIItems = gChartFs.ROIs.Items;						% any ROI CalcItems will be in this list
		tNewROIItems = gSbjROIFiles.( tSbjNms{ 1 } ).Name; % ROI names shared in common; start with 1st sbj.
		for iSbj = 2:numel( tSbjNms )
			tNewROIItems = intersect( tNewROIItems, gSbjROIFiles.( tSbjNms{ iSbj } ).Name );
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

	function tIsSbjPage = IsSbjPage, tIsSbjPage = strcmp( gChartFs.Sbjs.Dim, 'page' ); end

	function tIsOptSelUserDefined = IsOptSelUserDefined( aOptName )
		tOptSel = gOptFs.( aOptName ).Items( gOptFs.( aOptName ).Sel ); % deliberately sidestep GetOptSel's UsrDef handling.
		tIsOptSelUserDefined = ~isempty( strmatch( 'UsrDef: ', tOptSel ) );
	end

	% return single selection or (implicitly) first of multiple selection
	function tOptSel = GetOptSel( aOptName )
		tOptSel = gOptFs.( aOptName ).Items{ gOptFs.( aOptName ).Sel };	% tOptSel gets 1st string if multiple RHS items
		if IsOptSelUserDefined( aOptName ),
			if numel( tOptSel > 8 )
				tOptSel = tOptSel(9:end);		% drop 'UsrDef: '
			else
				tOptSel = '';
			end
		end
	end

	% same, but convert to num
	function tOptSelNum = GetOptSelNum( aOptName ), tOptSelNum = str2double( GetOptSel( aOptName ) ); end

	% return cell array of selection, even if just one item
	function tOptSel = GetOptSels( aOptName ), tOptSel = gOptFs.( aOptName ).Items( gOptFs.( aOptName ).Sel ); end

	function tIsOptSel = IsOptSel( aOptName, aOptValue ), tIsOptSel = strcmp( GetOptSel( aOptName ), aOptValue ); end

	function tIsOptSel = IsAnyOptSel( aOptName, aOptValue ), tIsOptSel = AnyStrMatch( aOptValue, GetOptSels( aOptName ) ); end

	function SetOptSel( aOptName, aOptValue )
		tSel = CAS2SS( { aOptValue }, gOptFs.( aOptName ).Items );
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		tIsOptLSel = IsOptLSel( aOptName );
		tIsOptLastPivot = strcmpi( get( tILBH, 'userdata' ), 'Options' );
		tIsOptInItems = tIsOptLSel && tIsOptLastPivot && ~gIsPivotOn;
		if tIsOptInItems
			set( tILBH, 'value', tSel );
			mrCG_Pivot_Items_listbox_CB( tILBH );
		else
			gOptFs.( aOptName ).Sel = tSel;
			UpdateOptionsListBox;
		end
	end

	function tOptLSel = GetOptLSel, tOptLSel = gOptL.Items{ gOptL.Sel }; end

	function tIsOptLSel = IsOptLSel( aOptName ), tIsOptLSel = strcmp( GetOptLSel, aOptName ); end

	% return single selection or (implicitly) first of multiple selection
	function tChartSel = GetChartSel( aChartName ), tChartSel = gChartFs.( aChartName ).Items{ gChartFs.( aChartName ).Sel }; end

	% return cell array of selection, even if just one item
	function tChartSel = GetChartSels( aChartName ), tChartSel = gChartFs.( aChartName ).Items( gChartFs.( aChartName ).Sel ); end

	function tChartSelData = GetChartSelData( aChartName )
		% return single selection or (implicitly) first of multiple selection
		% from items with data (by parsing CalcItem if needed)
		tChartSelData = GetChartSel( aChartName );
		tCalcItemNm = [ aChartName, ':', tChartSelData ];
		while IsCalcItem( tCalcItemNm )
			tCalcItemTerms = GetCalcItemTerms( tCalcItemNm );
			tChartSelData = tCalcItemTerms{1};
			tCalcItemNm = [ aChartName, ':', tChartSelData ];
		end
	end

	function tChartSelsData = GetChartSelsData( aChartName )
		% return cell array of selection, even if just one item
		% from items with data (by parsing CalcItem if needed)
		tChartSelsData = GetChartSels( aChartName );
		if isempty( gCalcItemOrder )
			return
		end
		iCalcItems = ismember( strcat( aChartName, ':', tChartSelsData ), gCalcItemOrder );
		while any( iCalcItems )
			for iChartSel = 1:numel( tChartSelsData )
				tCalcItemNm = [ aChartName, ':', tChartSelsData{iChartSel} ];
				if iCalcItems(iChartSel)
					tChartSelsData = cat( 2, tChartSelsData, GetCalcItemTerms( tCalcItemNm ) );		% append CalcItem terms
				end
			end
			tChartSelsData( find( iCalcItems ) ) = [];		% remove current batch of CalcItems
			iCalcItems = ismember( strcat( aChartName, ':', tChartSelsData ), gCalcItemOrder );
		end
		tChartSelsData = unique( tChartSelsData );			% remove redundancies
	end



%% NewProject
	function NewProject_CB( tH, varargin )
	
		if ishandle( tH )
			SetMessage( 'Browse to new project folder...' );
			if ischar( gProjPN ) && ~isempty( dir( gProjPN ) )
				gProjPN = uigetdir( gProjPN );
			else
				gProjPN = uigetdir;
			end
			if gProjPN == 0
				return
			end
		else
			gProjPN = tH;
			if ~isdir( gProjPN )
				error( 'bad project directory name: %s', gProjPN )
			end
		end

		tDlm = filesep;
		if ispc, tDlm = '\\'; end % needs escape character for textscan
		tTok = textscan( gProjPN, '%s', 'delimiter', tDlm );
		set( findtag( 'mrCG_Project_text' ), 'string', tTok{ 1 }{ end } );

		% reinitialize all these...
		[gD,gVEPInfo,gCndFiles,gSbjROIFiles,gCurs,gCortex] = deal([]);		% *** check gCortex for handle & delete cortex window?
% 		gSbjROIs = [];

		% Need to rebuild everything to get rid of old CalcItems
		% Clear isn't necessary but playing it safe
		tFNms = fieldnames( gChartFs );
		for iFNm = 1:numel(tFNms)
			gChartFs.(tFNms{iFNm}).Items = {};
			gChartFs.(tFNms{iFNm}).Sel   = [];
		end

		% start drilling...
		tSbjNms = DirFoldNames( gProjPN );
		gChartFs.Sbjs.Items = tSbjNms;
		tNSbjs = numel( tSbjNms );
		if tNSbjs == 0
			SetError( [ 'No subject folders in ', gProjPN] );
			error( [ 'No subject folders in ', gProjPN ] );
		end
		t1stSbjPN = fullfile( gProjPN, tSbjNms{1} ); % also used in nested ManageCndNames below.
		recompute = false;		% flag for RE-computing ROI montages if they already exist
 		if isdir( fullfile( t1stSbjPN, '_mrC_' ) ) && isdir( fullfile( t1stSbjPN, 'Inverses' ) )
			gProjVer = 2;
			gInvDir = 'Inverses';
			SetMessage( 'Loading project type 2...' );
			% check for inverse ROI montage directories under 1st subject
			% if found, allow for override of default behavior to use them
			if ~isempty( DirFoldNames( fullfile( t1stSbjPN, '_mrC_' ) ) )
				recompute = strcmp(questdlg('Recompute ROI montages?','mrCurrent','No','Yes','No'),'Yes');
			end
		else
			gProjVer = 1;
			gInvDir = 'ROI';
			SetMessage( 'Loading original project type...' );
			if ~isempty( DirFoldNames( fullfile( t1stSbjPN, 'ROI' ) ) )
				recompute = strcmp(questdlg('Recompute ROI montages?','mrCurrent','No','Yes','No'),'Yes');
			end
		end

		GetSbjROIFiles; % do this here so we can later add error catch.

% 		if gProjVer==1
% 			tMtgNms = DirFoldNames( t1stSbjPN ); % also used below in ManageCndNames.
% 		else
% 			tMtgNms = DirFoldNames( fullfile( t1stSbjPN, 'Exp_MATL*' ) );
% 			tMtgNms{ end + 1 } = 'ROI';
% 		end

		gChartFs.Mtgs.Items = DirFoldNames( fullfile( t1stSbjPN, 'Exp_MATL*' ) );
		ManageCndNames;		% sets gChartFs.Cnds.Items and gCndFiles.
		gChartFs.Invs.Items = DirFileNamesNoExt( fullfile( t1stSbjPN, gInvDir, '*.inv' ) );
		gChartFs.Hems.Items = DefaultChartVals( 'Hems', true );
		gChartFs.ROItypes.Items = DefaultChartVals( 'ROItypes', true );
		
		gChartFs.Sbjs.Sel = 1:numel( gChartFs.Sbjs.Items );
		gChartFs.Cnds.Sel = 1;
		gChartFs.Mtgs.Sel = 1;
		gChartFs.Invs.Sel = 1;
		gChartFs.Hems.Sel = DefaultChartVals( 'Hems', false );
		gChartFs.ROItypes.Sel = DefaultChartVals( 'ROItypes', false );

		gOptFs.Cortex.Items = cat( 2, { 'none' }, gChartFs.Sbjs.Items );
		gOptFs.Cortex.Sel = 1;
		
		SetMessage( 'New project opened; configure pivot controls and click NewPlot to load data' );
		LoadData				% Sets gChartFs: Flts,Comps,Chans
		LoadInverses		% Create new mtg data if not already created by LoadData.
			ResolveSbjROIs;
			gChartFs.ROIs.Sel = 1;
		ConfigureCalcItems
		
		mrCG_Pivot_Chart_listbox_CB( findtag( 'mrCG_Pivot_Chart_listbox' ) );
		mrCG_Pivot_Items_listbox_CB( findtag( 'mrCG_Pivot_Items_listbox' ) );
		UpdateOptionsListBox;
	
%% -- GetSbjROIFiles
		function GetSbjROIFiles
			tSbjROIs = struct( 'Name', [], 'Hem', [] );
			for iSbj = 1:tNSbjs
				tSbjNm = tSbjNms{ iSbj };
				if gProjVer == 1
					tSbjROIFilesPFN = fullfile( gProjPN, tSbjNm, 'ROI', 'SbjROIFiles.mat' );
				else
					tSbjROIFilesPFN = fullfile( gProjPN, tSbjNm, '_mrC_', 'SbjROIFiles.mat' );
				end
				if isempty( dir( tSbjROIFilesPFN ) ) || recompute		% faster than exist( tSbjROIFilesPFN, 'file' )
					tSbjROIsPN = GetSbjROIsPN( tSbjNm );
					if ~isdir( tSbjROIsPN )
						SetError( [ tSbjROIsPN ' does not exist.' ] );
						error( [ tSbjROIsPN ' does not exist.' ] );
					end
					tSbjROIFiles = DirFileNames( fullfile( tSbjROIsPN, '*.mat' ) );
					tNROIs = numel( tSbjROIFiles );
					if tNROIs == 0
						SetError( [ tSbjROIsPN ' has no mat-files.' ] );
						error( [ tSbjROIsPN ' has no mat-files.' ] );
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
				gSbjROIFiles.(tSbjNm) = tSbjROIs;
			end
		end

%% -- ManageCndNames
		function ManageCndNames
			% this should only be called for first sbj and first mtg
			tIsCndNamesChanged = false;
			if gProjVer == 1
				tCndNamesFileNm = fullfile( gProjPN, 'CndFiles.mat' );
			else
				% t1stSbjPN defined by enclosing function NewProject_CB.
				tCndNamesFileNm = fullfile( t1stSbjPN, '_mrC_', 'CndFiles.mat' );		% or just stick it in outer folder like v1?
			end
			if isempty( dir( tCndNamesFileNm ) ) || recompute
				% use names of .mat files from first non-ROI mtg from 1st sbj as default cnd name
				% we must strip extensions to make valid field name strings, so
				% it must be re-appended when using the name for file loading/saving.
				tCndFiles = DirFileNamesNoExt( fullfile( t1stSbjPN, gChartFs.Mtgs.Items{ 1 }, 'Axx*.mat' ) );
% 				tCndFiles = tCndFiles( ~strncmpi( tCndFiles, 'Montage', 7 ) );
				tNCndFiles = numel( tCndFiles );
				for iCndFile = 1:tNCndFiles
					tCndFileNames.( tCndFiles{ iCndFile } ) = tCndFiles{ iCndFile };
				end
				tIsCndNamesChanged = true; % to ensure this new info is saved below
			else
				load( tCndNamesFileNm, 'tCndFileNames' ); % initialize tCndFileNames from file
			end
			% prompt for any changes
			tOldCndNames = fieldnames( tCndFileNames ); 
			tNewCndNames = inputdlg( tOldCndNames, 'Enter new Cnd names', 1, tOldCndNames );		% returns column cell array even w/ row input
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
				SetMessage( [ 'Loading file data for ' tCndNm '...' ] );
				% to construct path to sens mtg cnd data file for 1st sbj
				% and get VEP info to construct subscripts for harmonic components.
				tPFN = fullfile( gProjPN, gChartFs.Sbjs.Items{1}, gChartFs.Mtgs.Items{1}, [ gCndFiles.(tCndNm) '.mat' ] );
				gVEPInfo.(tCndNm) = load( tPFN, 'dFHz', 'dTms', 'i1F1', 'i1F2', 'nFr', 'nT', 'nCh' ); % VEP info data
				gVEPInfo.(tCndNm).nFr = gVEPInfo.(tCndNm).nFr - 1;
				if iCnd == 1
					gChartFs.Comps.Items = GetComp( 'getcomplist' );
					gChartFs.Comps.Sel = 1;
					gCompFieldNms = TranslateCompNames( gChartFs.Comps.Items );
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
					for iMtg = 1:numel( gChartFs.Mtgs.Items )
						tMtg = gChartFs.Mtgs.Items{ iMtg };
						tPFN = fullfile( gProjPN, tSbjNm, tMtg, [ gCndFiles.(tCndNm) '.mat' ] );
						tVEP = load( tPFN, 'Wave', 'Sin', 'Cos' ); % VEP data
						tNCh = size( tVEP.Wave, 2 );
						if tNCh > gVEPInfo.(tCndNm).nCh					% *** why is this check in here?  do we need it? check for 129???
							disp(['nCh = ',int2str(gVEPInfo.(tCndNm).nCh),', size(Wave,2) = ',int2str(tNCh)])
							tNCh = gVEPInfo.(tCndNm).nCh;
						end
						gD.(tSbjNm).(tCndNm).(tMtg).Wave.( 'none' ) = tVEP.Wave( :, 1:tNCh );
						gD.(tSbjNm).(tCndNm).(tMtg).Spec = tVEP.Cos( 2:end, 1:tNCh ) + tVEP.Sin( 2:end, 1:tNCh ) * i;
						for iComp = 1:tNComp
% 							gD.(tSbjNm).(tCndNm).(tMtg).Harm.( gCompFieldNms{ iComp } ) = ...
% 								gD.(tSbjNm).(tCndNm).(tMtg).Spec( tiComp( iComp ), : );
							gD.(tSbjNm).(tCndNm).(tMtg).Harm.( gCompFieldNms{ iComp } ) = tiComp( iComp );
						end
					end
				end
			end
			if ~recompute
				for iSbj = 1:numel( gChartFs.Sbjs.Items )
					tSbjNm = gChartFs.Sbjs.Items{ iSbj };			
					for iInv = 1:numel( gChartFs.Invs.Items )
						tInvNm = gChartFs.Invs.Items{ iInv };
						if gProjVer == 1
							tPFN = fullfile( gProjPN, tSbjNm, 'ROI', tInvNm, 'Inv.mat' );
						else
							tPFN = fullfile( gProjPN, tSbjNm, '_mrC_', tInvNm, 'Inv.mat' );
						end
						if ~isempty( dir( tPFN ) )		% Newbie sbjs might not have ROI mtgs yet...
							tVEP = load( tPFN );			% InvMean & InvSVD
							gD.(tSbjNm).ROI.(tInvNm).Mean = tVEP.InvMean;
							gD.(tSbjNm).ROI.(tInvNm).SVD  = tVEP.InvSVD;
						end
					end
				end
			end
			gCurs = struct(	'Wave', struct( 'StepX', gVEPInfo.(tCndNm).dTms ),...
									'Spec', struct( 'StepX', gVEPInfo.(tCndNm).dFHz ) );
			SetMessage( 'Done loading file data' );
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
				tSbjROIsPN = GetSbjROIsPN( tSbjNm );
				tBilat = find( gSbjROIFiles.(tSbjNm).Hem == 3 );
				tNROIs = numel( tBilat );				
				for iInv = 1:numel( gChartFs.Invs.Items )
					tInvNm = gChartFs.Invs.Items{ iInv };
					if isfield( gD.(tSbjNm), 'ROI' ) && isfield( gD.(tSbjNm).ROI, tInvNm )
						continue;
					else % create ROI Mtg data for this sbj and inv
						% Load sbj's inverse
						SetMessage( [ 'Loading inverse ', tInvNm, ' for ', tSbjNm  ] );
						tMtgPN = fullfile( gProjPN, tSbjNm, gInvDir );
						if gProjVer == 1
							tInvPN = fullfile( tMtgPN, tInvNm );			% montage pathname = inverse file,  inverse pathname = ROI montage file???
						else
							tInvPN = fullfile( gProjPN, tSbjNm, '_mrC_', tInvNm );
						end
						tInvM = mrC_readEMSEinvFile( fullfile( tMtgPN, [ tInvNm '.inv' ] ) ) * 1e6;		% convert to pAmp/mm2
						tNCh = size( tInvM, 1 );		% channels x vertices
						% Build an inverver matrix using variables set by GetSbjROIFiles.
						[ InvMean, InvSVD ] = deal( zeros(tNCh,tNROIs,3) );
% 						[ SpecMean, SpecSVD ] = deal( zeros(tNFr,tNROIs,3) ); 
						for iROI = 1:tNROIs
							tROINm = fullfile( tSbjROIsPN, gSbjROIFiles.(tSbjNm).Name{ tBilat( iROI ) } );
							
							tROIindicesL = unique( getfield( getfield( load( [ tROINm, '-L.mat' ] ), 'ROI' ), 'meshIndices' ) );
							tROIindicesL( tROIindicesL == 0 ) = [];
							if isempty( tROIindicesL )
								disp(['WARNING: ',tROINm,'-L.mat has no non-zero mesh indices.'])
							else
								[tSVDu,tSVDs,tSVDv] = svd( tInvM(:,tROIindicesL), 'econ' );
								InvSVD(:,iROI,1)  = tSVDu(:,1) * tSVDs(1,1) * ( mean(abs(tSVDv(:,1))) * sign(sum(tSVDv(:,1))) );
								InvMean(:,iROI,1) = mean( tInvM(:,tROIindicesL), 2 );
% 								for iCnd = 1:tNCnds
% 									tCndNm = 
% 									tMtg = 
% 									SpecMean(:,iROI,1,iCnd) = mean( abs( gD.(tSbjNm).(tCndNm).(tMtg).Spec * tInvM(:,tROIindicesL) ), 2 );
% 								end
							end
							
							tROIindicesR = unique( getfield( getfield( load( [ tROINm, '-R.mat' ] ), 'ROI' ), 'meshIndices' ) );
							tROIindicesR( tROIindicesR == 0 ) = [];
							if isempty( tROIindicesR )
								disp(['WARNING: ',tROINm,'-R.mat has no non-zero mesh indices.'])
							else
								[tSVDu,tSVDs,tSVDv] = svd( tInvM(:,tROIindicesR), 'econ' );
								InvSVD(:,iROI,2)  = tSVDu(:,1) * tSVDs(1,1) * ( mean(abs(tSVDv(:,1))) * sign(sum(tSVDv(:,1))) );
								InvMean(:,iROI,2) = mean( tInvM(:,tROIindicesR), 2 );
							end
							
% 							tROIindicesLR = cat( 2, tROIindicesL, tROIindicesR );			% duplicate overlapping vertices?
							tROIindicesLR = union( tROIindicesL, tROIindicesR );			% or not?
							if ~isempty(tROIindicesLR)
								[tSVDu,tSVDs,tSVDv] = svd( tInvM(:,tROIindicesLR), 'econ' );
								InvSVD(:,iROI,3)  = tSVDu(:,1) * tSVDs(1,1) * ( mean(abs(tSVDv(:,1))) * sign(sum(tSVDv(:,1))) );
								InvMean(:,iROI,3) = mean( tInvM(:,tROIindicesLR), 2 );
							end
						end
						gD.(tSbjNm).ROI.(tInvNm).Mean = InvMean;
						gD.(tSbjNm).ROI.(tInvNm).SVD  = InvSVD;
						if isempty( dir( tInvPN ) )
							mkdir( tInvPN )
						end
						save( fullfile( tInvPN, 'Inv.mat' ), 'InvMean', 'InvSVD' )
					end
% 					if ~AnyStrMatch( 'ROI', gChartFs.Mtgs.Items, 'exact' ), gChartFs.Mtgs.Items{ end + 1 } = 'ROI'; end % now done in NewProject_CB?.
				end
			end
			SetMessage( 'Done Loading Inverses' );
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
	function PivotPlot_CB( tH, varargin )
		tDomain = GetDomain; % sets outer scope for nested functions that handle plot domain
		tPPFigTag = [ 'PPFig_' GetOptSel( 'Space' ) tDomain ];
		tFigH = findtag( tPPFigTag );
		tIsNoFigYet = isempty( tFigH ); % figure doesn't yet exist
		tOldYLim = []; % sets outer scope for nested functions that handle ScaleBy:Reuse
		tOldXLim = [];
		PrepareToReuseScales;
		if tIsNoFigYet
			tFigH = figure( 'tag', tPPFigTag );
		else 
			tIsNewPlotButton = strcmp( get( tH, 'tag' ), 'mrCG_Pivot_NewPlot_pushbutton' );
			if tIsNewPlotButton
				tPos = get( tFigH, 'position' );
				set( tFigH, 'tag', '' ); % neuter existing fig
				tFigH = figure( 'tag', tPPFigTag, 'position', tPos );
			else %RevisePlot button
				clf( tFigH );
				figure( tFigH );
			end
		end
		
		% store gui state info
		tUD = struct( 'gChartFs', gChartFs, 'gChartL', gChartL, 'gOptFs', gOptFs, 'gOptL', gOptL, 'gIsPivotOn', gIsPivotOn,...
			'Pivot_Items_listbox_userdata', get( findtag( 'mrCG_Pivot_Items_listbox' ), 'userdata' ) );

		% everything else
		tSbjNms = GetChartSels( 'Sbjs' );
		tNSbjs = numel( tSbjNms );
		
		tFltRC = [];	% structure for filter repeat cycles
							% external scope here, set by nested function SetFilterRepeatCycles.
		tNT = [];
% 		tX = [];
		if IsDomain( 'Wave' )
			SetFilteredWaveforms
			SetFilterRepeatCycles
		end

		tColorOrderMat = PPFig_ColorOrderMat; % this gets set to figure, and reused extensively below.
		% set colormap, buttondownfcn
		set( tFigH, 'DefaultAxesColorOrder', tColorOrderMat, 'WindowButtonDownFcn', @mrCG_SetPlotFocus_CB, 'Name', GetFigName )
		
		[iCol,iCmp,tOffset] = deal([]);		% fix this.  for offset format
		
		if IsDomain('Source')
			Data_Graph
		else		% sensor domain
			switch GetOptSel( 'Space' )
				case 'Sensor',		Data_Graph
				case 'Topo',		Data_Topograph
			end
			if ~ishandle( tFigH )
				return		% catches figure closures from bad domain calls
			end
		end

		if IsDomain( 'Cursor' )
			tUD.Cursor = gCurs.( GetDomain );
		end
		set( tFigH, 'userdata', tUD );
		UpdateCursorEditBoxes
		SetMessage( 'Done Plotting' );

		% Nested functions ----------

		function PrepareToReuseScales
			if ~IsOptSel( 'ScaleBy', 'Reuse' ), return; end
			if tIsNoFigYet, SetWarning( 'ScaleBy:Reuse can''t find previous plot; using ScaleBy:All' ); return; end
			% check to see that subplot rows and cols are compatibile
			tSPSize = [ numel( GetChartSels( gChartL.Items{1} ) ) numel( GetChartSels( gChartL.Items{2} ) ) ];
			if IsDomain( 'Offset' ), tSPSize( 1 ) = 1; end;
			if all( tSPSize == size( gSPHs ) )
				tOldYLim = get( gSPHs, 'ylim' );
				tOldXLim = get( gSPHs, 'xlim' );
			else
				SetError( 'If ScaleBy is "Reuse", the number of rows and columns must not change' );
			end
		end

		function SetFilterRepeatCycles
			tFltNms = GetChartSelsData( 'Flts' );
			tNFlts = numel( tFltNms );
			tCnd = GetChartSelData( 'Cnds' );
			tMtg = GetChartSel( 'Mtgs' );
			tSbj = GetChartSelData( 'Sbjs' );
			if tNFlts > 1
				% note that GetChartSel(...) returns a string that is first selected item
				tWL = zeros(1,tNFlts);	% wavelength
				for iFlt = 1:tNFlts
% 					tWL( iFlt ) = size( gD.(tSbjNms{1}).(tCnd).(tMtg).Wave.(tFltNms{iFlt}), 1 );
					tWL( iFlt ) = size( gD.(tSbj).(tCnd).(tMtg).Wave.(tFltNms{iFlt}), 1 );
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
% 				tNT = size( gD.(tSbjNms{1}).(tCnd).(tMtg).Wave.(tFltNms{1}), 1 );
				tNT = size( gD.(tSbj).(tCnd).(tMtg).Wave.(tFltNms{1}), 1 );
				tFltRC.(tFltNms{1}) = 1;
			end
		end
		
		function tFigNm = GetFigName
			tNPages = numel( gChartL.Items ) - 3;
			tPageItems = cell( 1, tNPages );
			for iPage = 1:tNPages
				tItemSel = GetChartSels( gChartL.Items{ iPage + 3 } );
				switch gChartL.Items{iPage + 3}
				case {'Sbjs','Chans'}
					GetMultiPageStr( gChartL.Items{iPage + 3} )
				otherwise
					tPageItems{ iPage } = tItemSel{1};
				end % For 'All' Sbjs.
			end
			tFigNm = [ sprintf( '%s,', tPageItems{1:tNPages-1} ), tPageItems{tNPages} ];
			function GetMultiPageStr( tItemNm )
				tNItemSel = numel( tItemSel );
				switch tNItemSel
				case 1
					tPageItems{iPage} = tItemSel{1};
				case numel( gChartFs.(tItemNm).Items )
					tPageItems{iPage} = [ 'All ', tItemNm ];
				otherwise
					tPageItems{iPage} = [ int2str( tNItemSel ), ' ', tItemNm ];
				end
			end
		end
	
%% -- Data Graph
		function Data_Graph

			tDomain = GetDomain;
			tCndInfo = GetVEP1Cnd(1);			% assuming same VEP info for all conditions for CalcItems
			switch tDomain
			case 'Wave'
				tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
				tGFP  = IsOptSel( 'SensorWaves', 'GFP' );
				tIsOffset = true;
				tX = tCndInfo.dTms * ( 1:tNT );
			case 'Spec'
				tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
				tGFP = false;
				tIsOffset = true;
				tX = tCndInfo.dFHz * ( 1:tCndInfo.nFr );
			case {'2DPhase','Bar','BarTriplet'}
				tValidFields = { 'Sbjs', 'Cnds', 'Comps', 'Chans' };
				tGFP = false;
				tIsOffset = false;
			otherwise
				error( 'Invalid plot domain %s', tDomain )
			end
			tIsSourceSpace = IsOptSel( 'Space', 'Source' );
			if tIsSourceSpace
				tValidFields = cat( 2, tValidFields, { 'Invs', 'Hems', 'ROIs', 'ROItypes' } );
				tAvgChans = false;
			elseif tIsOffset
				tAvgChans = IsOptSel( 'SensorWaves', 'average' );	% only applies to sensor space, force true for bar,2DPhase???
			else
				tAvgChans = true;
			end

			% already have variables tSbjNms & tNSbjs
			[ tRowF, tNRows, tRowNms ] = checkValidity( 1, tValidFields );
			[ tColF, tNCols, tColNms ] = checkValidity( 2, tValidFields );
			[ tCmpF, tNCmps, tCmpNms ] = checkValidity( 3, tValidFields );
			tValidDims = ~[ isempty( tRowF ), isempty( tColF ), isempty( tCmpF ) ];
			
% 			tColorOrderMat = PPFig_ColorOrderMat;
% 			set( tFigH, 'DefaultAxesColorOrder', tColorOrderMat )
			tNColors = size( tColorOrderMat, 1 );
			
			tAvgSbjs = IsSbjPage && ( tNSbjs > 1 );
			if tAvgSbjs
				tCalcSE = IsAnyOptSel( 'Stats', 'Dispersion' ); % && ~strcmp( tDomain, 'Spec' );		% get SE across subjects.  won't do channels.
			else
				tCalcSE = false;
			end

			SD = InitSliceDescription( tValidFields );
			
			if tIsOffset
				tSPRows = 1;
				if tNRows == 1
					tOffset = 0;
				else
% 					tOffset = GetOptSelNum( [tDomain,'Spacing'] ) * ( tNRows - 1 ) / 2;
% 					tOffset = linspace( tOffset, -tOffset, tNRows );
					tOffset = GetOptSelNum( [tDomain,'Spacing'] ) * (( tNRows - 1 ):-1:0);
				end
			else
				tSPRows = tNRows;
			end			
			gSPHs = zeros(tSPRows,tNCols);
			
			for iCol = 1:tNCols				% columns are definitely subplots
				if tIsOffset
					gSPHs(iCol) = subplot(1,tNCols,iCol);
				end
				if tValidDims(2)
					SD.( tColF ).Sel = iCol;
				end
				for iRow = 1:tNRows			% rows may or may not be separate subplots
					if tIsOffset
						iRowSP = 1;				% row index into matlab's subplots
					else
						gSPHs(iRow,iCol) = subplot(tNRows,tNCols,sub2ind([tNCols tNRows],iCol,iRow));
						iRowSP = iRow;
					end
					if tValidDims(1)
						SD.( tRowF ).Sel = iRow;
					end
					for iCmp = 1:tNCmps		% stack
						if tValidDims(3)
							SD.( tCmpF ).Sel = iCmp;
						end
						if numel( SD.Chans.Sel ) == 1
							tAvgChans = false;
							tGFP      = false;
						end
						if iCmp == 1
							if tIsOffset
								line( tX([1 end]), tOffset([iRow iRow]), 'color', [0 0 0] )
							elseif strcmp( tDomain, '2DPhase' )
								line( 0,0, 'linestyle','none', 'marker','+', 'markersize',20, 'color','k' )
							end
						end
						iColor = mod( iCmp-1, tNColors ) + 1;

						tSliceFlags = [ tIsSourceSpace, tAvgChans, tGFP ];
						switch tDomain
						case 'Wave'
							if all( tSliceFlags == false )	% butterfly sensor plot, don't do any stats
								tCalcSE = false;
							end
							tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );			% tY = [nT x 1]
							if tCalcSE
								tSE = tY.^2;
							end
							if tAvgSbjs
								for iSbj = 2:tNSbjs
									SD.Sbjs.Sel = iSbj;
									tYi = getSliceData( SD, tValidFields, tDomain, tSliceFlags, tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );
									tY = tY + tYi;
									if tCalcSE
										tSE = tSE + tYi.^2;
									end
								end
								SD.Sbjs.Sel = 1;
								tY = tY / tNSbjs;
								if tCalcSE
									tSE = sqrt( ( tSE - tY.^2 ) / (tNSbjs - 1 ) );
									if IsOptSel( 'DisperScale', 'SEM' )
										tSE = tSE / sqrt( tNSbjs - 1 );
									else			% 95% CI, note how this differs from 2D-phase version, since we project into 1-D.
										tSE = tSE * sqrt( finv( 0.95, 1, tNSbjs - 1 ) / tNSbjs );
									end
								end
							end
							line(	tX, tY + tOffset(iRow), 'linewidth', 2, 'color', tColorOrderMat( iColor, : ) )
							if tCalcSE
								if IsOptSel( 'Patches', 'on' )
									patch( tX([ 1:tNT, tNT:-1:1 ]), tY([ 1:tNT, tNT:-1:1 ]) + [ tSE(1:tNT); -tSE(tNT:-1:1) ] + tOffset(iRow), tColorOrderMat( iColor, : ), 'facealpha', 0.25, 'linestyle', 'none' );
								else
									line( tX([ 1:tNT, tNT:-1:1 ]), tY([ 1:tNT, tNT:-1:1 ]) + [ tSE(1:tNT); -tSE(tNT:-1:1) ] + tOffset(iRow), 'color', tColorOrderMat( iColor, : ), 'linestyle', ':' );
								end
							end
						case 'Spec'
							tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );			% tY = [nFr x 1]
							if tAvgSbjs
								for iSbj = 2:tNSbjs
									SD.Sbjs.Sel = iSbj;
									tY = tY + getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
								end
								SD.Sbjs.Sel = 1;
								tY = tY / tNSbjs;
							end
							tY = abs( tY );
							if IsOptSel( 'SpecPlotCmp', 'UpDown' ) && ( mod(iCmp,2) == 0 )
								tY = -tY;
							end
							if tIsSourceSpace || tAvgChans
								line(	[ tX; tX ], [ repmat( tOffset(iRow), 1, tCndInfo.nFr ); tY' + tOffset(iRow) ], 'linewidth', 2, 'color', tColorOrderMat( iColor, : ) )
							else
								line(	tX, tY + tOffset(iRow), 'linewidth', 2, 'color', tColorOrderMat( iColor, : )  )
							end
						case '2DPhase'
							% tY = [1 x 1]
							if tAvgSbjs
								tYSubj = zeros(tNSbjs,1);
								for iSbj = 1:tNSbjs
									SD.Sbjs.Sel = iSbj;
									tYSubj(iSbj) = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
								end
								SD.Sbjs.Sel = 1;
								tY = mean( tYSubj );
							else
								tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
							end
							tX = real( tY );
							tY = imag( tY );
							if IsAnyOptSel( 'Stats', 'Mean' ) || ~tAvgSbjs
%								line(	tX, tY, 'linestyle', 'none', 'marker', '.', 'markersize', 15, ...
%												'markeredgecolor', tColorOrderMat( iColor, : ), 'markerfacecolor', tColorOrderMat( iColor, : ) )
								line(	[0 tX], [0 tY], 'color', tColorOrderMat( iColor, : ), 'linewidth', 2) %, 'marker', '.', 'markersize', 20 )
							end
							if tCalcSE
								tNellip = 30;
								tTh = linspace( 0, 2*pi, tNellip )';
								if IsOptSel( 'DisperScale', 'SEM' )
									tNormK = 1 / (tNSbjs-2);
								else % 95% CI
									tNormK = (tNSbjs-1)/tNSbjs/(tNSbjs-2) * finv( 0.95, 2, tNSbjs - 2 );
								end
								[ tEVec, tEVal ] = eig( cov( [ real( tYSubj ), imag( tYSubj ) ] ) ); % Compute eigen-stuff
								tXY = [ cos(tTh), sin(tTh) ] * sqrt( tNormK * tEVal ) * tEVec'; % Error/confidence ellipse
								tXY = tXY + repmat( [tX tY], tNellip, 1 );
								if IsOptSel( 'Patches', 'on' )
									% patches with transparent fills look great, but Matlab throws an error when trying to save them as AI files.
									patch( tXY(:,1), tXY(:,2), tColorOrderMat( iColor, : ), 'facealpha', .25, 'edgecolor', tColorOrderMat( iColor, : ), 'linewidth', 2 );
								else
									% use the following when making AI files.
									line( tXY(:,1), tXY(:,2), 'color', tColorOrderMat( iColor, : ), 'linewidth', 2 );
								end
							end
							if IsAnyOptSel( 'Stats', 'Scatter' ) && tAvgSbjs
								line( real(tYSubj), imag(tYSubj), 'linestyle', 'none', 'marker', '.', 'markersize', 15, ...
									'markeredgecolor', tColorOrderMat( iColor, : ), 'markerfacecolor', tColorOrderMat( iColor, : ) );
							end
						case 'Bar'
							% tY = [1 x 1]
							if tAvgSbjs
								tYSubj = zeros(tNSbjs,1);
								for iSbj = 1:tNSbjs
									SD.Sbjs.Sel = iSbj;
									tYSubj(iSbj) = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
								end
								SD.Sbjs.Sel = 1;
								tY = mean( tYSubj );		% complex mean - scalar
								if IsOptSel( 'BarMean', 'Coherent' )
									tYM = abs( tY );		% abs(mean)
									tYA = [ real(tYSubj), imag(tYSubj) ]*[ real(tY); imag(tY) ] / tYM;
								else
									tYA = abs( tYSubj );
									tYM = mean( tYA );	% mean(abs)
								end
								patch( iCmp + [-1 -1 1 1]*0.45, [0 1 1 0]*tYM, tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
								if IsAnyOptSel( 'Stats', 'Dispersion' )
									if IsOptSel( 'DisperScale', 'SEM' )
										tYSE = std( tYA ) / sqrt( tNSbjs - 1 ); % projected SEM
									else % 95% CI, note how this differs from 2D-phase version, since we project into 1-D.
										tYSE = std( tYA ) * sqrt( finv( 0.95, 1, tNSbjs - 1 ) / tNSbjs ); % projected SEM
									end
% 									line( [ iCmp; iCmp ], [ max( [ 0; tYM - tYSE ] ); tYM + tYSE ], 'color', [ 0 0 0 ], 'linewidth', 2 ); 
									line( [ iCmp, iCmp ], [ tYM - tYSE, tYM + tYSE ], 'color', [ 0 0 0 ], 'linewidth', 2 );		% SCN removed the zero clip
								end
								if IsAnyOptSel( 'Stats', 'Scatter' )
									line( repmat( iCmp, tNSbjs, 1 ), tYA, 'color', [ 0 0 0 ], 'linestyle', 'none', 'marker', 'o' );
								end
							else
								tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
								patch( iCmp + [-1 -1 1 1]*0.45, [0 1 1 0]*abs(tY), tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
							end
						case 'BarTriplet'
							if tAvgSbjs
								tYSubj = zeros(tNSbjs,3);
								for iSbj = 1:tNSbjs
									SD.Sbjs.Sel = iSbj;
									tYSubj(iSbj,:) = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 )';
								end
								SD.Sbjs.Sel = 1;
								tY = mean( tYSubj );		% complex mean - 1x3
								if IsOptSel( 'BarMean', 'Coherent' )
									tYM = abs( tY );		% abs(mean)
									tYA = ( real(tYSubj)*diag(real(tY)) + imag(tYSubj)*diag(imag(tY)) ) * diag(1./tYM);
								else
									tYA = abs( tYSubj );
									tYM = mean( tYA );	% mean(abs)
								end
								patch( iCmp + [-0.45 -0.45 -0.15 -0.15], [0 1 1 0]*tYM(1), tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
								patch( iCmp + [-0.15 -0.15  0.15  0.15], [0 1 1 0]*tYM(2), tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
								patch( iCmp + [ 0.15  0.15  0.45  0.45], [0 1 1 0]*tYM(3), tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
								if IsAnyOptSel( 'Stats', 'Dispersion' )
									if IsOptSel( 'DisperScale', 'SEM' )
										tYSE = std( tYA ) / sqrt( tNSbjs - 1 ); % projected SEM
									else % 95% CI, note how this differs from 2D-phase version, since we project into 1-D.
										tYSE = std( tYA ) * sqrt( finv( 0.95, 1, tNSbjs - 1 ) / tNSbjs ); % projected SEM
									end
% 									line( [ iCmp; iCmp ], [ max( [ 0; tYM - tYSE ] ); tYM + tYSE ], 'color', [ 0 0 0 ], 'linewidth', 2 ); 
									line( repmat( iCmp + [ -0.3 0 0.3 ], 2, 1 ), [ tYM - tYSE; tYM + tYSE ], 'color', [ 0 0 0 ], 'linewidth', 2 );		% SCN removed the zero clip
								end
								if IsAnyOptSel( 'Stats', 'Scatter' )
									line( repmat( iCmp, tNSbjs, 1 ), tYA(:,2), 'color', [ 0 0 0 ], 'linestyle', 'none', 'marker', 'o' );
								end
							else
								tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );		% 3x1 vector
								patch( iCmp + [-0.45 -0.45 -0.15 -0.15], [0 1 1 0]*abs(tY(1)), tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
								patch( iCmp + [-0.15 -0.15  0.15  0.15], [0 1 1 0]*abs(tY(2)), tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
								patch( iCmp + [ 0.15  0.15  0.45  0.45], [0 1 1 0]*abs(tY(3)), tColorOrderMat( iColor, : ), 'edgecolor', [ 0 0 0 ] )
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
			if tIsOffset		% IsDomain( 'Cursor' ) ?
				gCurs.(tDomain).XData = tX;
			end
			
		
			function Offset_Format
				title( tColNms{ iCol }, 'interpreter', 'none' );
				if iCol == tNCols && iCmp == tNCmps
					All_Format;
% 					tXLim = tX( [ 1 end ] );
					tXLim = [0 ceil(tX(end)/10)*10];
					if strcmp( tDomain, 'Spec' )
% 						tXLim( 1 ) = 0;
						if ~IsOptSel( 'SpecXLim', 'Max' )
							tXLim( 2 ) = GetOptSelNum( 'SpecXLim' );
						end
					end
					set( gSPHs( 1, : ), 'xlim', tXLim );
					tLabelFS = 12;
					axes( gSPHs( 1, end ) );
					% data units, messes up if you change xlim
					text( 1.025 * tXLim( 2 ) * ones( tNRows, 1 ), tOffset', tRowNms, 'interpreter', 'none', 'fontsize', tLabelFS, 'tag', 'rowLabel' );
					% normalized units, messes up if you change ylim
					if tNCmps <= 10
						for iiCmp = 1:tNCmps
							text( 'units','normalized', 'horizontalalignment','center', 'verticalalignment','top', 'interpreter','none', 'fontweight','bold', 'fontsize',tLabelFS,...
								'position',[(iiCmp-0.5)/tNCmps 0.99], 'string',tCmpNms{iiCmp}, 'color',tColorOrderMat( mod(iiCmp-1,tNColors)+1, : ) )
						end
					else
% 						text( 'units','normalized', 'horizontalalignment','center', 'verticalalignment','top', 'interpreter','none', 'fontweight','bold', 'fontsize',tLabelFS,...
% 							'position',[2.5/7 0.99], 'string',tCmpNms{1}, 'color',tColorOrderMat(1,:) )
% 						text( 'units','normalized', 'horizontalalignment','center', 'verticalalignment','top', 'interpreter','none', 'fontweight','bold', 'fontsize',tLabelFS,...
% 							'position',[3.5/7 0.99], 'string','...', 'color','k' )
% 						text( 'units','normalized', 'horizontalalignment','center', 'verticalalignment','top', 'interpreter','none', 'fontweight','bold', 'fontsize',tLabelFS,...
% 							'position',[4.5/7 0.99], 'string',tCmpNms{tNCmps}, 'color',tColorOrderMat(tNCmps,:) )
						text( 'units','normalized', 'horizontalalignment','center', 'verticalalignment','top', 'interpreter','none', 'fontweight','bold', 'fontsize',tLabelFS,...
							'position',[0.5 0.99], 'string',[tCmpNms{1},' ... ',tCmpNms{tNCmps},' (',int2str(tNCmps),')'], 'color','k' )
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
						set( gSPHs( iRowSP, iCol ), 'xtick', 1:tNCmps, 'xticklabel', tCmpNms );
					else
						set( gSPHs( iRowSP, iCol ), 'xtick', [], 'xticklabel', [] );
					end
				end
				if iRow == 1
					title( tColNms{ iCol }, 'interpreter', 'none', 'fontsize', tLabelFS );
				end
				if iRow == tNRows && iCol == tNCols
					All_Format;
					for iRowL = 1:tNRows
						axes( gSPHs( iRowL, end ) );
						tXLRight = xlim;
						tXLRight = 1.025 * tXLRight( end );
						tYLCenter = mean( ylim );
						text( tXLRight, tYLCenter, tRowNms{ iRowL }, 'interpreter', 'none', 'fontsize', tLabelFS )	%,...
%								'horizontalalignment', 'center', 'verticalalignment', 'top', 'rotation', 90 )
%								'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'rotation', -90 )
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
						text( tLegTextX, tLegTextY, tCmpNms, 'interpreter', 'none', 'fontsize', tLabelFS );
					end
				end
			end

			function All_Format
				% Handle ylim
				if numel( gSPHs ) > 1
					tYLAll = reshape( get( gSPHs, 'ylim' ), size( gSPHs ) ); % All the ylims, in cell array shaped like plot.
					tScaleBy = GetOptSel( 'ScaleBy' );
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
									set( gSPHs( iRowL, : ), 'ylim', tYLm );
									if strcmp( tDomain, '2DPhase' )
										set( gSPHs( iRowL, : ), 'xlim', tYLm )
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
									set( gSPHs( :, iColL ), 'ylim', tYLm );
									if strcmp( tDomain, '2DPhase' )
										set( gSPHs( :, iColL ), 'xlim', tYLm )
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
							set( gSPHs, 'ylim', tYLm );
							if strcmp( tDomain, '2DPhase' )
								set( gSPHs, 'xlim', tYLm )
							end
						case 'Reuse'
							if numel( gSPHs ) == 1
								tOldYLim = { tOldYLim }; tOldXLim = { tOldXLim };
							else
								for iSPH = 1:numel( gSPHs )
									set( gSPHs( iSPH ), 'ylim', tOldYLim{ iSPH } );
									set( gSPHs( iSPH ), 'xlim', tOldXLim{ iSPH } );
								end
							end
					end
				end
			end
		
		end

%% -- Data Topograph
		function Data_Topograph

			if gProjVer == 1
				SetError( 'Topo plots only work for V2 projects'  );
				close( tFigH )
				return
			end			
			if IsDomain( 'Component' )
				SetError( 'Attempt to call Data_Topograph on component data' )
				close( tFigH )
				return
			end
				
			tDomain = GetDomain;
			if ~IsCursor( tDomain, 'Frame' )
				SetError( ['Need to set a ',tDomain,' cursor before creating Topo',tDomain,' plot.'] );
% 				close( tFigH )
				return
			end
	
			tCndNms = GetChartSels( 'Cnds' );
			tNCnds = numel( tCndNms );
			tEGIfaces = mrC_EGInetFaces( false );
			if IsOptSel( 'TopoMap', 'Standard' )
				tEpos = load('defaultFlatNet.mat');		% xy = 128x2
				tNE = size( tEpos.xy, 1 );
				tEpos = [ tEpos.xy, zeros( tNE, 1 ) ];
% 				tEGIfaces = tEGIfaces(1:end-2,:);		% exclude last 2 trianges
			end
% 			tEGIfaces = tEGIfaces(1:end-2,:);		% exclude last 2 trianges
	
			% plot Sbjs x Cnds (or Cnds x Sbjs) regardless of pivot chart
			tIsWave = strcmp( tDomain, 'Wave' );
			if tIsWave
% 				set( tFigH, 'ColorMap', jet(256) )
				tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
			else
% 				set( tFigH, 'ColorMap', hot(256) )
				tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
			end
			
			SD = InitSliceDescription( tValidFields );
			% force selection of all channels
			[ SD.Chans.Items, SD.Chans.Sel ] = deal( 1:numel(gChartFs.Chans.Items) );

			tIsSbjPage = IsSbjPage;
			tNSbjSP = tNSbjs^(~tIsSbjPage);		% # subject subplots
			tCmax = GetOptSel( 'ColorMapMax' );
			tZmax = zeros( 1, tNSbjSP );
			if strcmp( tCmax, 'All' )		% get most extreme Sbj sensor value across all chosen conditions
				if tIsSbjPage		% average subjects
					for iCnd = 1:tNCnds
						SD.Cnds.Sel = iCnd;
						tZ = 0;
						for iSbj = 1:tNSbjs
							SD.Sbjs.Sel = iSbj;
							if tIsWave
								tZ = tZ +  getSliceData( SD, tValidFields, tDomain, false(1,3), tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );
							else		% component domains already excluded, this should be Spec
								% Spec plots calculate average before taking abs, doing same here
% 								tZ = tZ + gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Spec;
								tZall = getSliceData( SD, tValidFields, tDomain, false(1,3), 1 );
								tZ = tZ + tZall( 2:end, : );
							end
						end
						tZ = tZ / tNSbjs;
						tZmax(1) = max( tZmax, max( abs( tZ(:) ) ) );
					end
				else
					for iSbj = 1:tNSbjs
						SD.Sbjs.Sel = iSbj;
						for iCnd = 1:tNCnds
							SD.Cnds.Sel = iCnd;
							if tIsWave
								tZall = getSliceData( SD, tValidFields, tDomain, false(1,3), tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );
								tZmax(iSbj) = max( tZmax(iSbj), max(      abs( tZall(:) )   ) );
							else
								tZall = getSliceData( SD, tValidFields, tDomain, false(1,3), 1 );
								tZmax(iSbj) = max( tZmax(iSbj), max( max( abs( tZall(2:end,:)    ) ) ) );
							end
						end
					end
				end
			end

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
			for iSbj = 1:tNSbjs
				SD.Sbjs.Sel = iSbj;
				if (~tIsSbjPage) || (iSbj==1)
					if IsOptSel( 'TopoMap', 'elp-File' )
						tEpos = GetSensorPos( tSbjNms{iSbj} );		% sorted, reference name=400 last
						tNE = size(tEpos,1);
						tEpos = tEpos - repmat( fminsearch( @(tO) sphereObjFcn(tO,tEpos,tNE), median(tEpos) ), tNE, 1 );		% subtract origin of best fitting sphere
						[ tEpos(:,1), tEpos(:,2), tEpos(:,3) ] = cart2sph( tEpos(:,1), tEpos(:,2), tEpos(:,3) );					% convert to spherical coords [theta,phi,radius]
						% if you're going to rotate, transform tEpos.  CameraUpVector tilts axes lines.  after flattening?
	% 					i = [17 15 16 11 6 55 62 72 75 81];				% midline electrodes
	% 					thetaNose = sum((tEpos(i,1)+pi*(tEpos(i,1)<0)).*tEpos(i,3))/sum(tEpos(i,3));
						[ tEpos(:,1), tEpos(:,2) ] = pol2cart( tEpos(:,1), ( 1 - sin( tEpos(:,2) ) ).^0.6 );			% flatten to [x,y] coords
						tNE = tNE - 1;		% exclude ref
					end
					tXLim = [ min(tEpos(1:tNE,1))-0.05 max(tEpos(1:tNE,1))+0.05 ];
					tYLim = [ min(tEpos(1:tNE,2))-0.05 max(tEpos(1:tNE,2))+0.05 ];
				end
				for iCnd = 1:tNCnds
					SD.Cnds.Sel = iCnd;
					if tIsWave
						tZall = getSliceData( SD, tValidFields, tDomain, false(1,3), tFltRC.( SD.Flts.Items{ SD.Flts.Sel } ) );
						tZ = tZall( gCurs.(tDomain).Frame.iX, : );		% 1x128
					else
						tZall = getSliceData( SD, tValidFields, tDomain, false(1,3), 1 );
						tZ = abs( tZall( gCurs.(tDomain).Frame.iX, : ) );
					end
					if tIsSbjPage && (iSbj>1)
						if iSbj == tNSbjs
							set( tH(iCnd), 'FaceVertexCData', ( get( tH(iCnd), 'FaceVertexCData' ) + tZ(1:tNE)' ) / tNSbjs )
						else
							set( tH(iCnd), 'FaceVertexCData', get( tH(iCnd), 'FaceVertexCData' ) + tZ(1:tNE)' ) 
						end
					else
						iSbjSP = iSbj^(~tIsSbjPage);
						if tCndRows
							gSPHs(iCnd,iSbjSP) = subplot( tNRows, tNCols, sub2ind( [ tNCols tNRows ], iSbjSP, iCnd ), 'XLim', tXLim, 'YLim', tYLim );
						else
							gSPHs(iSbjSP,iCnd) = subplot( tNRows, tNCols, sub2ind( [ tNCols tNRows ], iCnd, iSbjSP ), 'XLim', tXLim, 'YLim', tYLim );
						end
						% always Sbjs x Cnds, might be transpose of subplots
						tH(iSbjSP,iCnd) = patch( 'Vertices', [ tEpos(1:tNE,1:2), zeros(tNE,1) ], 'Faces', tEGIfaces,...
							'EdgeColor', [ 0.25 0.25 0.25 ],'FaceColor', 'interp', 'FaceVertexCData', tZ(1:tNE)', 'CDataMapping', 'scaled' );	% 'Marker', '.', 'MarkerEdgeColor', 'k',
						switch tCmax
						case 'All'
						case 'Cursor'
							tZmax(iSbjSP) = max( abs(tZ(1:tNE)) );
						otherwise
							tZmax(iSbjSP) = eval( tCmax );
						end
						if tIsWave
							set( get( tH(iSbjSP,iCnd), 'parent' ), 'CLim', [ -tZmax(iSbjSP), tZmax(iSbjSP) ] )
						else
							set( get( tH(iSbjSP,iCnd), 'parent' ), 'CLim', [ 0, tZmax(iSbjSP) ] )
						end
						if tCndRows
							if iCnd == tNRows
								if tIsSbjPage && (tNSbjs>1)
									if tNSbjs <= 3
										xlabel( [gChartFs.Sbjs.Items{gChartFs.Sbjs.Sel(1)},sprintf(', %s',gChartFs.Sbjs.Items{gChartFs.Sbjs.Sel(2:tNSbjs)})] )
									else
										xlabel( 'average' )
									end
								else
									xlabel( tSbjNms{iSbj} )
								end
							end
							if iSbjSP == 1
								ylabel( tCndNms{iCnd}, 'interpreter', 'none' )
							end
						else
							if iSbjSP == tNRows
								xlabel( tCndNms{iCnd}, 'interpreter', 'none' )
							end
							if iCnd == 1
								if tIsSbjPage && (tNSbjs>1)
									if tNSbjs <= 3
										ylabel( [gChartFs.Sbjs.Items{gChartFs.Sbjs.Sel(1)},sprintf(', %s',gChartFs.Sbjs.Items{gChartFs.Sbjs.Sel(2:tNSbjs)})] )
									else
										ylabel( 'average' )
									end
								else
									ylabel( tSbjNms{iSbj} )
								end
							end
						end
						if ( iSbj == 1 ) && ( iCnd == 1 )
							if tIsWave
								title( sprintf( '%0.1f ms', gCurs.(tDomain).Frame.iX * GetDTms(1) ) )
							else
								title( sprintf( '%0.1f Hz', gCurs.(tDomain).Frame.iX * GetDFHz(1) ) )
							end
						end
					end
				end
			end

			% match cortex colormaps
			tCutFrac = min( GetOptSelNum( 'ColorCutoff' ) / max( tZmax ), 1 );
			if tIsWave
				set( tFigH, 'ColorMap', flow( 256, tCutFrac ) )
			else
				tCM = hot(356);
				tCM = tCM(1:256,:);
				tCM( 1:round(tCutFrac*256), : ) = 0.5;
				set( tFigH, 'ColorMap', tCM )
			end

% 			tFigColor = get( tFigH, 'color' );
			set( gSPHs, 'dataaspectratio', [ 1 1 1 ], 'xtick', [], 'ytick', [] ) %, 'color', 'none', 'box', 'on' )
			%, 'xcolor', tFigColor, 'ycolor', tFigColor, 'xcolor', tFigColor ) %'xlim', [ -1.6 1.6 ], 'ylim', [ -1.6 1.6 ] )

		end

	end

	function [ tF, tN, tNms ] = checkValidity( iDim, tValidFields )
		tNms = GetChartSels( gChartL.Items{iDim} );
% 		if any( strcmp( tValidFields, gChartL.Items{iDim} ) )
		if ismember( gChartL.Items{iDim}, tValidFields )
			tF = gChartL.Items{iDim};
			tN = numel( tNms );
		else
			tF = '';
			tN = 1;
			tNms = { tF };		% avoid inappropriate labels
		end
	end

	function tSD = InitSliceDescription( tValidFields )
		tSD = gChartFs;		% field names not in order
		for iFNm = 1:numel( tValidFields )
			if strcmp( tValidFields{iFNm}, 'Chans' )
				tSD.( tValidFields{iFNm} ).Items = gChartFs.Chans.Sel;
				tSD.( tValidFields{iFNm} ).Sel = 1:numel(gChartFs.Chans.Sel);
			else
				tSD.( tValidFields{iFNm} ).Items = GetChartSels( tValidFields{iFNm} );
				tSD.( tValidFields{iFNm} ).Sel = 1;
			end
		end
	end

	function tYj = getSliceData( tSD, tValidFields, tDomain, tFlags, tRC )
		if IsSliceCalcItem
			tYj = ConvertCalcItemSlice( tSD, @getSliceData );
		else
			tSbjField = tSD.Sbjs.Items{ tSD.Sbjs.Sel };
			tCndField = tSD.Cnds.Items{ tSD.Cnds.Sel };
			tChans    = tSD.Chans.Items( tSD.Chans.Sel );
			tMtg      = tSD.Mtgs.Items{ 1 };
			switch tDomain
			case 'Wave'
				tEEG = gD.(tSbjField).(tCndField).(tMtg).Wave.( tSD.Flts.Items{ tSD.Flts.Sel } )( :, tChans );
			case 'Spec'
				tEEG = gD.(tSbjField).(tCndField).(tMtg).Spec( :, tChans );
% 				tFlags(3) = false;
%				tRC = 1;
			case {'2DPhase','Bar'}
% 				tEEG = gD.(tSbjField).(tCndField).(tMtg).Harm.( TranslateCompName( tSD.Comps.Items{ tSD.Comps.Sel } ) )( tChans );
				tEEG = gD.(tSbjField).(tCndField).(tMtg).Spec( gD.(tSbjField).(tCndField).(tMtg).Harm.( TranslateCompName( tSD.Comps.Items{ tSD.Comps.Sel } ) ), tChans );
% 				tFlags(3) = false;
%				tRC = 1;
			case 'BarTriplet'
				iSpec = gD.(tSbjField).(tCndField).(tMtg).Harm.( TranslateCompName( tSD.Comps.Items{ tSD.Comps.Sel } ) );
				if iSpec == 1
					tEEG = [ repmat(NaN,1,numel(tChans)); gD.(tSbjField).(tCndField).(tMtg).Spec( iSpec+[0,1], tChans ) ];
				elseif iSpec == size( gD.(tSbjField).(tCndField).(tMtg).Spec, 1 )
					tEEG = [ gD.(tSbjField).(tCndField).(tMtg).Spec( iSpec+[-1,0], tChans ); repmat(NaN,1,numel(tChans)) ];
				else
					tEEG = gD.(tSbjField).(tCndField).(tMtg).Spec( iSpec+[-1,0,1], tChans );
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
				tInvM = gD.(tSbjField).ROI.(tInvField).(tTypeField)( tChans, strcmp( gSbjROIFiles.(tSbjField).Name, tROINm ), 1 );
			case 'Right'
				tInvM = gD.(tSbjField).ROI.(tInvField).(tTypeField)( tChans, strcmp( gSbjROIFiles.(tSbjField).Name, tROINm ), 2 );
			case 'Bilat'
				tInvM = gD.(tSbjField).ROI.(tInvField).(tTypeField)( tChans, strcmp( gSbjROIFiles.(tSbjField).Name, tROINm ), 3 );
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
				tOCITSM.( tOCITv{iOCIT} ) = feval( tCaller, aSD, tValidFields, tDomain, tFlags, tRC );		% recursively drills from outer to inner CalcItems
				tExpr = strrep( tExpr, tOCITs{iOCIT}, [ 'tOCITSM.', tOCITv{iOCIT} ] );
			end
			tExpr = ReplaceWithArrayOps( tExpr );
			try
	% 			eval( [ tExpr ';' ] ); % now rSM is a slice correspoding to the CalcItem
				rSM = eval( tExpr );
			catch
				SetError( 'Error in CalcItem formula' );
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


	function mrCG_SetPlotFocus_CB( tH, varargin )
		% MakePPFig sets the ButtonDownFcn of each plot figure to this callback.
		% If caller does not have tPPFigTag, steal it from fig that does (if any).
		% Then, restore GUI state from the calling fig's userdata.
		if ~isempty( findobj( 'tag', 'mrCG' ) );
			% Recall GUI state from figure userdata
			tUD = get( tH, 'userdata' );

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
			tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
			set( tILBH, 'userdata', tCallingLB );
			if strcmpi( tCallingLB, 'Options' )
				mrCG_Pivot_Options_listbox_CB( findtag( 'mrCG_Pivot_Options_listbox' ), [] );
				UpdateChartListBox;
			else
				mrCG_Pivot_Chart_listbox_CB( findtag( 'mrCG_Pivot_Chart_listbox' ) );
				UpdateOptionsListBox;
			end
			mrCG_Pivot_Items_listbox_CB( tILBH );
			
			tDomain = GetDomain;
			if IsDomain( 'Cursor' )
				gCurs.( tDomain ) = tUD.Cursor;
			end
			UpdateCursorEditBoxes;
			% Now determine if calling figure is the last pivot plot made...
			tPPFigTag = [ 'PPFig_' GetOptSel( 'Space' ) tDomain ];
			tPPFigH = findtag( tPPFigTag );
			if isempty(tPPFigH) || (tH ~= tPPFigH) % ...if not...
				set( tPPFigH, 'tag', '' );
				set( tH, 'tag', tPPFigTag );
			end

			if strcmp( GetOptSel('AutoPaint'), 'on' ) && ~isempty( gCortex ) && IsDomain( 'Offset' ) && IsCursor( tDomain, 'Frame' )
				mrCG_Cortex_Paint_CB
			end
		end
		% If user subsequently clones this fig, then the GUI state can be
		% coerced using this callback by clicking a fig from another domain; a new plot
		% in the first domain should then match the settings from the second.
	end

%% Cursor
% Cursors are entities that allow data from a particular slice of a VEP
% pivot plot to be selected and painted onto a cortical mesh.  Cursor data
% are stored in gCurs.( PPDomain ).( CursType ), where PPDomain is
% the pivot plot domain, i.e., Wave, and/or Spec, etc.; and CursType is
% Start, End, and/or Frame.

%% -- Cursor GUI callbacks
	function mrCG_Cursor_Pick_CB( tH, varargin )
		tDomain = GetDomain;
		if ~IsDomain( 'Offset' )
			SetError( [ tDomain ' domain does not allow cursors' ] );
			return
		end
		tPPFigH = findtag( [ 'PPFig_' GetOptSel( 'Space' ) tDomain ] );
		if isempty( tPPFigH )
			SetWarningNoPause( 'You are attempting to place a cursor in a non-existant plot' );
			return
		end
		tPickButtonTag = get( tH, 'tag' );				% mrCG_Cursor_xxx_Pick_pushbutton
		tCursType = tPickButtonTag( 13:(end-16) );	% 'Frame', 'Start', or 'End'
		SetWarningNoPause( [ 'Select new ' tCursType ' cursor location in ' tDomain ' window...' ] );
		figure( tPPFigH )
		set( tPPFigH, 'pointer', 'fullcrosshair' )
		waitforbuttonpress;
		set( tPPFigH, 'pointer', 'arrow' )
		if gcf ~= tPPFigH
			SetWarningNoPause( [ 'You must click on the most recent ' tDomain ' plot...Please try again' ] );
			return
		end
		tCOH = gco;		% clicked object, back-up to axis
		tCOType = get( tCOH, 'type' );
		while ~strcmpi( tCOType, 'axes' )
			if isempty( tCOH ) || strcmpi( tCOType, 'figure' ) % we missed all axes
				SetWarningNoPause( 'You must click on an axis...Please try again' );
				return
			end
			% crawl up object heirarchy
			tCOH = get( tCOH, 'parent' );
			tCOType = get( tCOH, 'type' );
		end
		tX = get( tCOH, 'currentpoint' ); % 2x3 matrix.  this does not necessarily map onto a data coordinate...
		SetCursData( tDomain, tCursType, tX(1) )
	end

	function mrCG_Cursor_Edit_CB( tH, varargin )
		% callback for Frame/Start/End Cursor edit boxes
		tDomain = GetDomain;
		switch tDomain
			case 'Wave'
				tStepInc = GetDTms(1);
			case 'Spec'
				tStepInc = GetDFHz(1);
		end
		if isfield(gCurs.(tDomain),'XData')
			try
				tX = eval( get( tH, 'string' ) );
				if ~( isnumeric(tX) && isscalar(tX) )
					tX = NaN;
					SetWarningNoPause( 'Invalid cursor value.'  );
				end
			catch
				tX = NaN;
				SetWarningNoPause( 'Invalid cursor value.'  );
			end
		else
			tX = NaN;
			SetWarningNoPause( ['No ',tDomain,' plot.']  );
		end		
		tTag = get( tH, 'tag' );		% 		tags = strrep( 'mrCG_Cursor_X_At_edit', 'X', {'Frame','Start','End'} )
		tCursType = tTag(13:(end-8));
		if isnan(tX)
			UpdateCursorEditBox( tDomain, tCursType )		% restore valid string for previous value
		else
			tiX = round( tX / tStepInc );
			if ( tiX >= 1 ) && ( tiX <= numel( gCurs.( tDomain ).XData ) )
				if ~IsCursor( tDomain, tCursType )		% && ishandle( gCurs.(tDomain).(tCursType).LH )
					figure( findtag( [ 'PPFig_' GetOptSel( 'Space' ) tDomain ] ) )		% *** NEED TO GET IN RIGHT AXIS, NOT JUST FIGURE
				end
				SetCursData( tDomain, tCursType, gCurs.(tDomain).XData( tiX ) )
			else
				UpdateCursorEditBox( tDomain, tCursType )
				SetWarningNoPause( 'Requested cursor location exceeds wave dimensions.'  );
			end
		end
	end

	function mrCG_Cursor_Step_CB( tH, varargin )
		% callback for Step F/B pushbuttons
		tDomain = GetDomain;
		if ~IsCursor( tDomain, 'Frame' )
			SetWarningNoPause( 'Set a Frame cursor before using F or B pushbuttons.'  );
			return							
		end
		switch tDomain
			case 'Wave'
				tStepInd = round( gCurs.(tDomain).StepX / GetDTms(1) );
			case 'Spec'
				tStepInd = round( gCurs.(tDomain).StepX / GetDFHz(1) );
		end
		if strcmp( get( tH, 'string' ), '>>' )
			tiX = gCurs.( tDomain ).Frame.iX + tStepInd;
		else
			tiX = gCurs.( tDomain ).Frame.iX - tStepInd;
		end
		if ( tiX >= 1 ) && ( tiX <= numel( gCurs.( tDomain ).XData ) )
			figure( findtag( [ 'PPFig_' GetOptSel( 'Space' ) tDomain ] ) )		% *** THIS COULD BE TOPO!!!
			SetCursData( tDomain, 'Frame', gCurs.(tDomain).XData( tiX ) )
		else
			SetWarningNoPause( 'Requested cursor step exceeds wave dimensions.'  );
		end
	end

	function mrCG_Cursor_Step_By_CB( tH, varargin )
		% callback for Step By edit box
		tDomain = GetDomain;
		try	% check if legal expression entered
			tVal = eval( get( tH, 'string' ) );		% str2double( get( tH, 'string' ) );
			if isnumeric(tVal) && isscalar(tVal) && ~isnan(tVal)
				switch tDomain
				case 'Wave'
					tIncr = GetDTms(1);
				case 'Spec'
					tIncr = GetDFHz(1);
				otherwise
					SetWarningNoPause( 'Step By control only valid in Wave and Spec domains.'  );
					return		% don't reset edit box string until you switch to a relevant domain
				end
				gCurs.(tDomain).StepX = max(1,round(tVal/tIncr)) * tIncr;
				UpdateCursorUserdata( tDomain )
			else
				SetWarningNoPause( 'Invalid cursor step expression.'  );
			end
		catch
			SetWarningNoPause( 'Invalid cursor step expression.'  );
		end
		set( findtag( 'mrCG_Cursor_Step_By_edit' ), 'string', sprintf('%0.2f',gCurs.(tDomain).StepX) )
	end

	function mrCG_Cursor_Clear_CB( varargin )
		% callback for Cursor 'Clear All' pushbutton
		tDomain = GetDomain;
		if isfield( gCurs, tDomain )
			tCursTypes = { 'Frame', 'Start', 'End' };
			for iCursType = 1:numel( tCursTypes )
				if isfield( gCurs.(tDomain), tCursTypes{ iCursType } )
					if ishandle( gCurs.(tDomain).( tCursTypes{ iCursType } ).LH )
						delete( gCurs.(tDomain).( tCursTypes{ iCursType } ).LH )
% 					end
% 					if ishandle( gCurs.(tDomain).( tCursTypes{ iCursType } ).TH )
						delete( gCurs.(tDomain).( tCursTypes{ iCursType } ).TH )
					end
					gCurs.(tDomain) = rmfield( gCurs.(tDomain), tCursTypes{ iCursType } );
					% NOTE: gCurs.(tDomain).XData & StepX remain.
					UpdateCursorUserdata( tDomain )
					set( findtag( [ 'mrCG_Cursor_', tCursTypes{ iCursType }, '_At_edit' ] ), 'string', '' ) 
				end
			end
		end
	end


%% -- Cursor Helpers
	function SetCursData( tDomain, tCursType, tX )
		% sets iX,X,XStr fields in gDurs.(tDomain).(tCursType), and updates edit box
		% if necessary, increment to nearest data point
		tiX = sum( gCurs.(tDomain).XData <= tX );
		if tiX == 0 || ( tiX < numel(gCurs.(tDomain).XData) && ( tX - gCurs.(tDomain).XData( tiX ) ) > ( gCurs.(tDomain).XData( tiX + 1 ) - tX ) )
			tiX = tiX + 1;
		end
		gCurs.(tDomain).(tCursType).iX = tiX;
		gCurs.(tDomain).(tCursType).X  = gCurs.(tDomain).XData( tiX );
		if IsDomain( 'Wave' )
			gCurs.(tDomain).(tCursType).XStr = sprintf( ' %0.0fms', gCurs.(tDomain).(tCursType).X );
		else
			gCurs.(tDomain).(tCursType).XStr = sprintf( ' %gHz', round( 100 * gCurs.(tDomain).(tCursType).X ) / 100 );
		end
		set( findtag( ['mrCG_Cursor_',tCursType,'_At_edit'] ) ,'string', sprintf( '%0.2f', tX ) );
		PlotCursor( tDomain, tCursType )
		SetMessage( [ tCursType, ' cursor plotted sucessfully.' ] );
	end

	function PlotCursor( tDomain, tCursType )
		tX = gCurs.(tDomain).(tCursType).X;
		if isfield( gCurs.(tDomain).(tCursType), 'LH' ) && ishandle( gCurs.(tDomain).(tCursType).LH )			% line exists
			tY = get( get( gCurs.(tDomain).(tCursType).LH, 'parent' ), 'ylim' );
			set( gCurs.(tDomain).(tCursType).LH, 'xdata', [ tX tX ] )
			set( gCurs.(tDomain).(tCursType).TH, 'position', [ tX,  0.05 * diff(tY) + tY(1), 0 ], 'string', gCurs.(tDomain).(tCursType).XStr )
		else
			tY = ylim;
			gCurs.(tDomain).(tCursType).LH = line( [ tX tX ], tY, 'color', [ .7 .7 .7 ] );										% LH is line handle
			gCurs.(tDomain).(tCursType).TH = text( tX, 0.05 * diff(tY) + tY(1), gCurs.(tDomain).(tCursType).XStr );		% TH is text handle
		end
		UpdateCursorUserdata( tDomain )
		if strcmp( tCursType, 'Frame' )
			if strcmp( GetOptSel('AutoPaint'), 'on' ) && ~isempty( gCortex )
				mrCG_Cortex_Paint_CB		% ([],[]),  handle & eventData not currently used by this function
			end
		else
			set( gCurs.(tDomain).(tCursType).LH, 'linestyle', '--' )
		end
	end

	function UpdateCursorUserdata( tDomain )
		% called by: PlotCursor, mrCG_Cursor_Clear_CB, mrCG_Cursor_Step_By_CB
		tFig = findtag( [ 'PPFig_', GetOptSel( 'Space' ), tDomain ] );
		tUD = get( tFig, 'userdata' );
		tUD.Cursor = gCurs.( tDomain );
		set( tFig, 'userdata', tUD )
	end

	function ReplaceCursors
		% called by Offset_Format
		tDomain = GetDomain;
		if isfield( gCurs, tDomain )
			tCursTypes = { 'Frame', 'Start', 'End' };
			for iCursType = 1:numel( tCursTypes )
				if isfield( gCurs.(tDomain), tCursTypes{ iCursType } )
					PlotCursor( tDomain, tCursTypes{ iCursType } )
				end
			end
		end
	end

	function UpdateCursorEditBoxes
		tH = findtags( { 'mrCG_Cursor_Frame_At_edit', 'mrCG_Cursor_Start_At_edit', 'mrCG_Cursor_End_At_edit', ...
			'mrCG_Cursor_Frame_Pick_pushbutton', 'mrCG_Cursor_Start_Pick_pushbutton', 'mrCG_Cursor_End_Pick_pushbutton', ...
			'mrCG_Cursor_Step_By_edit', 'mrCG_Cursor_Step_B_pushbutton', 'mrCG_Cursor_Step_F_pushbutton', ...
			'mrCG_Cortex_Paint_pushbutton', 'mrCG_Cursor_Play_pushbutton', 'mrCG_Cursor_Clear_pushbutton' } );
		if IsDomain( 'Cursor' )	% domain = Wave or Spec
			set( tH, 'enable', 'on' )
			tDomain = GetDomain;
			tTypes = { 'Frame', 'Start', 'End' };
			for iTypes = 1:numel(tTypes)
				UpdateCursorEditBox( tDomain, tTypes{iTypes} )
			end
			set( tH(7), 'string', sprintf('%0.2f',gCurs.(tDomain).StepX) )
		else
			set( tH, 'enable', 'off' )
			set( tH([1 2 3 7]), 'string', '' )
		end
	end

	function UpdateCursorEditBox( tDomain, tCursType )
		if IsCursor( tDomain, tCursType )
			set( findtag( [ 'mrCG_Cursor_', tCursType, '_At_edit' ] ), 'string', sprintf( '%0.2f', gCurs.(tDomain).(tCursType).X ) )
		else
			set( findtag( [ 'mrCG_Cursor_', tCursType, '_At_edit' ] ), 'string', '' )
		end
	end

	function tIsCursor = IsCursor( tDomain, tCursType )
		tIsCursor = isfield( gCurs, tDomain ) && isfield( gCurs.(tDomain), tCursType );
	end


%% Cortex
% 	% forbid cortex comparison of multiple columns
% 	tColPF = GetPFByField( 'Dim', 'col' );
% 	if numel( tColPF.Sel ) > 1, SetError( [ 'Cannot compare cortex for multiple columns.' ] ); return; end
% 	% forbid cortex comparison of ROIs, Hems, Sbjs
% 	Use bar charts for Comps, and 2DPhase plots for phase
%	Some code for copying images...
% 	axes( findtag( 'CortexAxis2D' ) );
% 	axis( [ 0 2*tVMx 0 2*tVMx ] )
% 	image( 'parent', findtag( 'CortexAxis2D' ), 'cdata', getfield( getframe( findtag( 'mrC_CortexAxis' ) ), 'cdata' ) );
% 	axis ij image off;

%% -- ConfigureCortex
	function ConfigureCortex
		if IsOptSel( 'Cortex', 'none' )
			% if window is open, close it, otherwise do nothing
			if ~isempty( gCortex ) && ishandle( gCortex.FH )
% 				set( gCortex.FH, 'CloseRequestFcn', 'closereq' )
% 				close( gCortex.FH )
				delete( gCortex.FH )			% use delete instead of close, to prevent recalling mrCG_CloseCortex_CB
			end
			gCortex = [];
			return
		end
		if isempty( gCortex )
% 			if ismac, tRenderer = 'zbuffer'; else, tRenderer = 'OpenGL'; end
			if strncmpi(computer,'MAC',3)
				tRenderer = 'zbuffer';
			else
				tRenderer = 'OpenGL';
			end
% 			gCortex = struct('FOV',220,'dCam',1e3,'Name','','FH',[],'AH',[],'M',[],'MH',[],'TH',[],'LH',[]);
			gCortex.FOV = [-125 125];
			gCortex.dCam = 1e3;
			gCortex.Name = '';
			gCortex.FH = figure( 'position', [ 400 300 400 400 ], 'tag', 'mrC_CortexFig', 'renderer', tRenderer, ...
				'CloseRequestFcn', @mrCG_CloseCortex_CB );
			gCortex.AH = axes( 'position', [ 0.05 0.05 0.9 0.9  ], 'tag', 'mrC_CortexAxis', 'dataaspectratio', [1 1 1], ...
				'view', [ 0 0 ], 'cameraposition', [ 0 -gCortex.dCam 0 ], 'cameraviewangle', 2*atan(max(abs(gCortex.FOV))/gCortex.dCam)*180/pi, ...
				'xlim', gCortex.FOV, 'ylim', gCortex.FOV, 'zlim', gCortex.FOV, 'xtick', [], 'ytick', [], 'ztick', [], 'visible', 'off');
		end

		tCortex = GetOptSel( 'Cortex' );
		if isfield( gCortex, 'MH' ) && strcmp( gCortex.Name, tCortex )
			return
		end
		
		gCortex.Name = tCortex;
		SetMessage( [ 'Reading ' gCortex.Name '''s mesh for CortexFig...' ] );
		gCortex.M = getfield( getfield( load( GetSbjMeshPFN( gCortex.Name ) ), 'msh' ), 'data' );			% *** this doesn't all need to be stored in gCortex
		SetMessage( [ 'Configuring ' gCortex.Name '''s mesh for CortexFig...' ] );
		tNV = size( gCortex.M.vertices, 2 );
		gCortex.M.vertices = gCortex.M.vertices([3 1 2],:)';		% PIR -> RPI
		gCortex.M.vertices(:,2:3) = -gCortex.M.vertices(:,2:3);	%     -> RAS
		gCortex.M.origin = -gCortex.M.origin([3 1 2]).*[1 -1 -1];
		gCortex.M.vertices = gCortex.M.vertices - repmat( gCortex.M.origin, tNV, 1 );
		
% 		gCortex.M.colors = gCortex.M.colors(1:3,:)'/255;
		% reverse triangles for outward normals in matlab.  better in general, needed for openGL on mac
		if isfield( gCortex, 'MH' ) % && ishandle( gCortex.MH )
			set( gCortex.MH, 'Vertices', gCortex.M.vertices, 'Faces', 1 + gCortex.M.triangles([3 2 1],:)', 'FaceVertexCData', repmat( 0.5, tNV, 3 ) ) %gCortex.M.colors )
			set( gCortex.TH, 'String', '' )
		else
			cla( gCortex.AH );
			axes( gCortex.AH );
			gCortex.MH = patch( 'tag', 'CortexFigBrain', 'Vertices',gCortex.M.vertices,...
				  'Faces',gCortex.M.triangles([3 2 1],:)'+1,'FaceVertexCData',repmat( 0.5, tNV, 3 ),...  %gCortex.M.colors,...   % 
				  'FaceColor','interp','FaceLighting','gouraud','BackFaceLighting','unlit','EdgeColor','none',...
				  'DiffuseStrength',0.7,'SpecularStrength',0.05,'SpecularExponent',5,'SpecularColorReflectance',0.5);
% 				  'DiffuseStrength',0.6,'SpecularStrength',0.01,'SpecularExponent',10,'SpecularColorReflectance',1);
			gCortex.TH = text( 'string', '', 'position', [0 1], 'units', 'normalized',...
				'horizontalalignment', 'left', 'verticalalignment', 'top', 'tag', 'CortexText' );
			gCortex.LH = [ light( 'position' , [1 -1 0 ] ), light( 'position', [-1 -1 0 ] ) ];
			set( gCortex.LH , 'color', [ 1 1 1 ], 'style', 'infinite' )
		end
		% defaultCortex.msh.data has large fields triangles, normals, vertices, & colors.  removed unused ones?
% 		gCortex.M = rmfield( gCortex.M, 'normals');
% 		gCortex.M = rmfield( gCortex.M, 'triangles');
% 		gCortex.M = rmfield( gCortex.M, 'colors');
		if isfield( gCortex, 'InvM' )
			gCortex = rmfield( gCortex, 'InvM' );
		end
		set( gCortex.FH, 'name', gCortex.Name )
		
		if strcmp( GetOptSel('AutoPaint'), 'on' ) && IsDomain( 'Offset' ) && IsCursor( GetDomain, 'Frame' )
			mrCG_Cortex_Paint_CB
		end

		% update scalp (contours get updated by mrCG_Cortex_Paint_CB above)
		tH = findtag( 'mrCG_Cortex_Scalp_checkbox' );
		if get( tH, 'value' ) == 1
% 			set( tH, 'value', 0 )
% 			delete( findobj( gCortex.AH, 'tag', 'CortexScalp' ) )
			mrCG_Cortex_Scalp_CB( tH )
		end
% 		tH = findtag( 'mrCG_Cortex_Contour_checkbox' );
% 		if get( tH, 'value' ) == 1
% % 			set( tH, 'value', 0 )
% % 			delete( findobj( gCortex.AH, 'tag', 'CortexContour' ) )
% 			mrCG_Cortex_Contour_CB( tH )
% 		end
		
		SetMessage( [ 'Configuring ' gCortex.Name '''s mesh for CortexFig...Done' ] );
	end

	function mrCG_CloseCortex_CB( varargin )
		if isempty( findobj( 'tag', 'mrCG' ) )
% 			set( varargin{1}, 'CloseRequestFcn', 'closereq' )
% 			close( varargin{1} )
			delete( varargin{1} )
		else
			% Restores option listbox cortex item setting to 'none'.
			% + sets off chain of calls that closes cortex window
			SetOptSel( 'Cortex', 'none' );
		end
	end

%% -- SetCortexFigColorMap
	function SetCortexFigColorMap
% 		tCutFrac = GetOptSelNum( 'ColorCutoff' ) / 100.0;
		tCutoff = GetOptSelNum( 'ColorCutoff' );
		tCLim = get(gCortex.AH,'CLim');
% 		tCutFrac = ( tCutoff - tCLim(1) ) / diff( tCLim );
		tCutFrac = tCutoff / tCLim(2);
		tCutFrac = min( tCutFrac, 1 );
		if IsDomain( 'Wave' )
			tCM = flow( 255, tCutFrac );
		else
			tCLevels = 255;
			tCM = hot( tCLevels + 100 );
			tCM = tCM( 1:tCLevels, : );
			tCM( 1:(round(tCLevels*tCutFrac)), : ) = 0.5;
		end
% 		set( findtag( 'mrC_CortexFig' ), 'colormap', tCM ); % This will be confused by more than one figure
		set( gCortex.FH, 'colormap', tCM ); % This will be confused by more than one figure
	end

%% -- Paint
	function PaintROIsOnCortex
		if isempty( gCortex )
			SetError( 'Load a cortex 1st to paint ROIs.'  );
			return
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
		tCmap = repmat( 0.5, size( gCortex.M.vertices, 1 ), 3 ); % gCortex.M.colors;
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
						SetWarningNoPause( ['Unknown color for ROI ',tROI.ROI.name, ' .']  )
				end
			else
				tCmap(tROI.ROI.meshIndices,:) = repmat( tROI.ROI.color, numel( tROI.ROI.meshIndices ), 1 );
			end
		end
		set( gCortex.MH, 'FaceVertexCData', tCmap )
		set( gCortex.TH, 'string', 'ROI' )
	end

	function mrCG_Cortex_Paint_CB( varargin )
		if isempty( gCortex )																% *** disable paint button in these conditions?
			SetError( 'Need a cortex before painting.'  );
			return
		end
		if ~IsDomain( 'Offset' )	% || IsDomain( 'Sensor' )
			SetError( 'Can''t paint cortex from this Domain &/or Space' )		% Wave or Spec
			return
		end
		tDomain = GetDomain;
		if ~IsCursor( tDomain, 'Frame' )
			SetError( 'Need to set a frame cursor before painting.'  );
			return			
		end

		% For now, only first of selected Invs.
		% Soon, we will allow context-sensitive comparisons
		tInvNm = GetChartSel( 'Invs' );
		if ~isfield( gCortex, 'InvM' ) || ~isfield( gCortex.InvM, tInvNm );
			tInvPFN = fullfile( gProjPN, gCortex.Name, gInvDir, [ tInvNm '.inv' ] );
			SetMessage( [ 'Reading ' gCortex.Name '''s inverse for CortexFig...' ] );
			gCortex.InvM.( tInvNm ) = mrC_readEMSEinvFile( tInvPFN )';			% should be tNV x tNCh.
		end
		
		SetFilteredWaveforms							% need this to paint filtered data.
		
		switch tDomain
		case 'Wave'
			tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
		case 'Spec'
			tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
		end
		SD = InitSliceDescription( tValidFields );		% only first of selected Cnds, Flts.  all Chans.
		tYM = getSliceData( SD, tValidFields, tDomain, false(1,3), 1 );		% #time points or frequencies x tNCh
		tNsbj = numel( SD.Sbjs.Items );
		if tNsbj > 1
			for iSbj = 2:tNsbj
				SD.Sbjs.Sel = iSbj;
				tYM = tYM + getSliceData( SD, tValidFields, tDomain, false(1,3), 1 );
			end
			tYM = tYM / tNsbj;
		end
		tYM = tYM.'; % non-conjugate transposed to nCh x nX, for use as operand for max(max()) and inv multiplication.

		SetCortexFigColorMap;
		tiX = gCurs.(tDomain).Frame.iX;
		if strcmp( tDomain, 'Wave' )
			tNT = size( tYM, 2 );
			if tiX > tNT
				tiX = mod( tiX-1, tNT ) + 1;
			end
		end
		tCmax = GetOptSel( 'ColorMapMax' );
		switch tCmax
			case 'All'
				tCmax = mrCG_Cortex_GetClim( tYM, tInvNm );
				SetMessage( sprintf('Colormap Max = %0.3g',tCmax) )
			case 'Cursor'
				tCmax = max( abs( gCortex.InvM.( tInvNm ) * ( tYM( :, tiX ) * 1e6 ) ) );
				SetMessage( sprintf('Colormap Max = %0.3g',tCmax) )
			otherwise
				tCmax = eval( tCmax );
		end
		gCortex.sensorData = tYM( :, tiX ) * 1e6;
		if IsDomain( 'Wave' )
			caxis( gCortex.AH, [ -tCmax tCmax ] );		% default assuming WavePlot
			set( gCortex.MH, 'FaceVertexCData', gCortex.InvM.( tInvNm ) * gCortex.sensorData );
		else
			caxis( gCortex.AH, [ 0 tCmax ] );
			set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( tInvNm ) * gCortex.sensorData ) );
		end
		set( gCortex.TH, 'string', get( gCurs.(tDomain).Frame.TH, 'string' ) )
		
		mrCG_Cortex_Contour_CB( findtag( 'mrCG_Cortex_Contour_checkbox' ) )
	end

	function mrCG_Cursor_Play_CB( varargin )
		if isempty( gCortex )
			SetError( 'Need a cortex before playing animation.'  );
			return
		end

		tDomain = GetDomain;
		if ~( IsCursor( tDomain, 'Start' ) && IsCursor( tDomain, 'End' ) )
			SetError( 'Need to set start and end cursors before playing animation.'  );
			return			
		end

		% get mean sensor data for requested time/frequency points
		switch tDomain
		case 'Wave'
			tStepBy = round( gCurs.Wave.StepX / GetDTms(1) );
			iMovie = [ gCurs.(tDomain).Start.iX,  (gCurs.(tDomain).Start.iX+tStepBy):tStepBy:(gCurs.(tDomain).End.iX-1) , gCurs.(tDomain).End.iX ];
			tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
		case 'Spec'
			tStepBy = round( gCurs.Spec.StepX / GetDFHz(1) );
			iMovie = [ gCurs.(tDomain).Start.iX,  (gCurs.(tDomain).Start.iX+tStepBy):tStepBy:(gCurs.(tDomain).End.iX-1) , gCurs.(tDomain).End.iX ];
			tValidFields = { 'Sbjs', 'Cnds', 'Chans' };
		otherwise
			SetWarningNoPause( 'Cortex Playback only works in Wave and Spec domains.'  );
			return							
		end
		SD = InitSliceDescription( tValidFields );		% only first of selected Cnds, Flts.  all Chans.
		tData = getSliceData( SD, tValidFields, tDomain, false(1,3), 1 );		% #time points or frequencies x tNCh
		if strcmp( tDomain, 'Wave' )
			iMovieFlt = mod( iMovie-1, size( tData, 1 ) ) + 1;
		else
			iMovieFlt = iMovie;
		end
		tYM = tData(iMovieFlt,:);
		tNsbj = numel( SD.Sbjs.Items );
		if tNsbj > 1
			for iSbj = 2:tNsbj
				SD.Sbjs.Sel = iSbj;
				tData = getSliceData( SD, tValidFields, tDomain, false(1,3), 1 );		% #time points or frequencies x tNCh
				tYM = tYM + tData(iMovieFlt,:);
			end
			tYM = tYM / tNsbj;
		end
		tYM = tYM.' * 1e6; % non-conjugate transposed to nCh x nX, for use as operand for max(max()) and inv multiplication.

		SetCortexFigColorMap
		SetWarningNoPause( 'Playing cortex animation.' );
		tInvNm = GetChartSel( 'Invs' );
		tHprogL = line('parent',get(gCurs.(tDomain).Start.LH,'parent'),'xdata',get(gCurs.(tDomain).Start.LH,'xdata'),'ydata',get(gCurs.(tDomain).Start.LH,'ydata'),'color','k','linewidth',1);
		tic
		if IsDomain( 'Wave' )
			for iFrame = 1:numel(iMovie)
				tX = gCurs.(tDomain).XData( iMovie( iFrame ) );
				set( gCortex.MH, 'FaceVertexCData', gCortex.InvM.( tInvNm ) * tYM( :, iFrame ) );
				set( gCortex.TH, 'string', [ num2str(round(tX)), 'ms' ] )
				set( tHprogL, 'xdata', [ tX tX ] )
				drawnow
			end
		else
			for iFrame = 1:numel(iMovie)
				tX = gCurs.(tDomain).XData( iMovie( iFrame ) );
				set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( tInvNm ) * tYM( :, iFrame ) ) );
				set( gCortex.TH, 'string', [ num2str(round(100*tX)/100), 'Hz' ] )
				set( tHprogL, 'xdata', [ tX tX ] )
				drawnow
			end
		end
		delete( tHprogL )
		SetMessage( sprintf('Playback complete. (%0.1f sec)',toc) );
	end

	function makeCortexMosaic

		if isempty(gCortex)
			SetError( 'Load a cortex & set frame cursor before creating mosaic.' )
			return
		end
		tDomain = GetDomain;
		tSpecFlag = IsDomain( 'Spec' );
		if tSpecFlag
			tSpecCursorFlag = IsCursor( tDomain, 'Frame' );
			if tSpecCursorFlag
				tValid = { 'Cnds', 'Sbjs', 'Chans', 'Invs' };
			else
				tValid = { 'Cnds', 'Sbjs', 'Chans', 'Comps', 'Invs' };
			end
		else
			if ~IsCursor( tDomain, 'Frame' )
				SetError( 'Set frame cursor before creating mosaic.' )
				return
			end
			tValid = { 'Cnds', 'Sbjs', 'Flts', 'Chans', 'Invs' };
		end
		[tRowDim,tNrow] = testMosaicDim(1);
		[tColDim,tNcol] = testMosaicDim(2);
		[tCmpDim,tNcmp] = testMosaicDim(3);
		if tNcmp > 1
			tSels = gChartFs.(tCmpDim).Sel;
			for iCmp = 1:tNcmp
				gChartFs.(tCmpDim).Sel = tSels(iCmp);
				UpdateChartListBox;
				makeCortexMosaic
			end
			gChartFs.(tCmpDim).Sel = tSels;
			UpdateChartListBox;
			return
		end
		
		SD = InitSliceDescription( tValid );
		
		SD.Sbjs.Items  = check4VectorPage( SD.Sbjs.Items, 'Sbjs' );
		SD.Invs.Items  = check4VectorPage( SD.Invs.Items, 'Invs' );
		SD.Cnds.Items  = check4VectorPage( SD.Cnds.Items, 'Cnds' );
		if tSpecFlag
			if ~tSpecCursorFlag
				SD.Comps.Items = check4VectorPage( SD.Comps.Items, 'Comps' );
			end
		else
			SD.Flts.Items  = check4VectorPage( SD.Flts.Items, 'Flts' );
		end
		
		if isempty(tRowDim)
			tYlabel = '';
		else
			tYlabel = GetChartSels( tRowDim );
		end
		if isempty(tColDim)
			tXlabel = '';
		else
			tXlabel = GetChartSels( tColDim );
		end
				
% 		SetCortexFigColorMap;		% only needs update if ColorCutoff or Wave/Spec-type changed
		
		% cortex figure needs to be on main screen for getFrame (at least on my win2K)
		tFigPos = get( gCortex.FH, 'position' );
		tScreenSize = get(0,'screensize');
		if any( tFigPos(1:2) <0 ) || any( (tFigPos(1:2)+tFigPos(3:4)) > tScreenSize(3:4) )
			set( gCortex.FH, 'position', [ 20, tScreenSize(4)-tFigPos(4)-75-20, tFigPos(3:4) ] )
		end
		tMosDim = size( frame2im( getframe( gCortex.AH ) ) );		% depends on axes view anyhow
		tMosaic = uint8( zeros( tNrow*tMosDim(1), tNcol*tMosDim(2), 3 ) );
		tCmaxMode = GetOptSel( 'ColorMapMax' );
		if ~any( strcmp( tCmaxMode, { 'All', 'Cursor' } ) )
			tCmax = eval( tCmaxMode );
		end

		for iSbj = 1:numel( SD.Sbjs.Items )
			iRow = 1;
			iCol = 1;
			SD.Sbjs.Sel = iSbj;
			checkRowCol( 'Sbjs' )
			if ~strcmp( SD.Sbjs.Items{iSbj}, gCortex.Name )
				SetOptSel( 'Cortex', SD.Sbjs.Items{iSbj} )
				ConfigureCortex
			end
			set( gCortex.TH, 'string', '' )
			for iInv = 1:numel( SD.Invs.Items )
				SD.Invs.Sel = iInv;
				checkRowCol( 'Invs' )
				if ~isfield( gCortex, 'InvM' ) || ~isfield( gCortex.InvM, SD.Invs.Items{iInv} );
					SetMessage( [ 'Reading ' gCortex.Name '''s inverse for CortexFig...' ] );
					gCortex.InvM.( SD.Invs.Items{iInv} ) = mrC_readEMSEinvFile( fullfile( gProjPN, gCortex.Name, gInvDir, [ SD.Invs.Items{iInv}, '.inv' ] ) )';
				end
				for iCnd = 1:numel( SD.Cnds.Items )
					SD.Cnds.Sel = iCnd;
					checkRowCol( 'Cnds' )
					if tSpecFlag
						tData = getSliceData( SD, tValid, tDomain, false(1,3), 1 );
						switch tCmaxMode
						case 'All'
							tCmax = mrCG_Cortex_GetClim( tData.', SD.Invs.Items{iInv} );
						case 'Cursor'
							tCmax = max( abs( gCortex.InvM.( SD.Invs.Items{iInv} ) * ( 1e6 * tData(gCurs.Spec.Frame.iX,:).' ) ) );
						end
						caxis( gCortex.AH, [ 0 tCmax ] );
						if tSpecCursorFlag	% use Cursor, not Comps
							set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( SD.Invs.Items{iInv} ) * ( 1e6 * tData(gCurs.Spec.Frame.iX,:).' ) ) )
							figure( gCortex.FH )
							tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gCortex.AH ) );
						else
							for iComp = 1:numel( SD.Comps.Items )
								SD.Comps.Sel = iComp;
								checkRowCol( 'Comps' )
								tData = getSliceData( SD, tValid, tDomain, false(1,3), 1 );
								set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( SD.Invs.Items{iInv} ) * ( 1e6 * tData.' ) ) )
								figure( gCortex.FH )
								tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gCortex.AH ) );
							end
						end
					else
						for iFlt = 1:numel( SD.Flts.Items )
							SD.Flts.Sel = iFlt;
							checkRowCol( 'Flts' )
							tData = getSliceData( SD, tValid, tDomain, false(1,3), 1 );
							set( gCortex.MH, 'FaceVertexCData', gCortex.InvM.( SD.Invs.Items{iInv} ) * ( 1e6 * tData( mod( gCurs.Wave.Frame.iX - 1, size(tData,1) ) + 1 , : ).' ) )
							switch tCmaxMode
							case 'All'
								tCmax = mrCG_Cortex_GetClim( tData.', SD.Invs.Items{iInv} );
							case 'Cursor'
								tCmax = max( abs( get( gCortex.MH, 'FaceVertexCData' ) ) );
							end
							caxis( gCortex.AH, [ -tCmax tCmax ] );
							figure( gCortex.FH )		% cortex figure should be on top
							SetCortexFigColorMap;
							tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gCortex.AH ) );
						end
					end
				end
			end
		end
		
		tMosFig = figure('units','pixels','position',[100 100 700 500]);
		if ~isempty(tCmpDim)
			set( tMosFig, 'name', gChartFs.(tCmpDim).Items{ gChartFs.(tCmpDim).Sel } )		% should only be 1 selection
		end
		image( tMosaic )
		axis image
		set( gca, 'xtick', (1:tNcol)*tMosDim(2)-tMosDim(2)/2, 'ytick', (1:tNrow)*tMosDim(1)-tMosDim(1)/2, 'xticklabel', tXlabel, 'yticklabel', tYlabel )
		if tSpecFlag
			if tSpecCursorFlag
				title( gCurs.Spec.Frame.XStr )
			end
		else
			title( gCurs.Wave.Frame.XStr )
		end
		SetMessage( 'Cortex mosaic done' );

		return %-----makeCortexMosaic sub-functions-----
		function [tDimName,tDimN] = testMosaicDim(iChart)
			tDimName = gChartL.Items{iChart};			
			if any( strcmp( tDimName, tValid ) )
				tDimN = numel( gChartFs.( tDimName ).Sel );
			else
				tVectorDims = { 'row', 'col', 'cmp' };
				SetWarningNoPause( [tVectorDims{iChart},' dimension ',tDimName,' is irrelevant for Cortex Mosaic.'] )
				tDimName = '';
				tDimN = 1;
			end
		end

		function tOutCell = check4VectorPage( tInCell, tField )
			tOutCell = tInCell;
			if ~any( strcmp( tField, { tRowDim, tColDim, tCmpDim } ) ) && numel( tInCell )>1
				tOutCell = tOutCell(1);
				SetWarningNoPause( [ 'Vector page dimension ',tField,' being scalarized for cortex mosaic'] )
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

	function mrCG_Cortex_Contour_CB( tH, varargin )
		
		if isempty( gCortex )
			SetError( 'Need a cortex before drawing sensor contours.'  );
			return
		end
		
		delete( findobj( gCortex.AH, 'tag', 'CortexContour' ) )
		if get( tH, 'value') == 0
			return
		end
		
		tDomain = GetDomain;
		if ~IsCursor( tDomain, 'Frame' )
			SetError( 'Need to set a frame cursor for sensor contours.'  );
			return			
		end
		
		tEpos = GetSensorPos( gCortex.Name );
		tNE = size( tEpos, 1 ) - 1;
		
		% register with MRI
		tReg = load( '-ascii', fullfile(gProjPN,gCortex.Name,'_MNE_','elp2mri.tran') )';		% 4x3 after transponse, last col = [0;0;0;1]
		tEpos = [ tEpos(1:tNE,:)*1e3, ones(tNE,1) ] * tReg(:,1:3);
		
		% subtract origin of best fitting sphere & convert to spherical coords [theta,phi,radius]
		tOrigin = fminsearch( @(tO) sphereObjFcn(tO,tEpos,tNE), median(tEpos) );
		[ tEpos(:,1), tEpos(:,2), tEpos(:,3) ] = cart2sph( tEpos(:,1)-tOrigin(1), tEpos(:,2)-tOrigin(2), tEpos(:,3)-tOrigin(3) );
		% map radius as function of theta & phi
		[ ThetaGrid, PhiGrid ] = meshgrid( linspace(-pi,pi,30), linspace(-pi/2,pi/2,20) );
		RadiusGrid = griddata( tEpos(:,1), tEpos(:,2), tEpos(:,3), ThetaGrid, PhiGrid, 'v4' );
		% flatten to [x,y] coords, z-dimension = activity
		tPflat = 0.6;
		tEflat = [ zeros( tNE, 2 ), gCortex.sensorData ];
		[ tEflat(:,1), tEflat(:,2) ] = pol2cart( tEpos(:,1), ( 1 - sin( tEpos(:,2) ) ).^tPflat );
		if ~strcmp( tDomain, 'Wave' )
			tEflat(:,3) = abs( tEflat(:,3) );
		end
		% Get contours lines on flattened spherical projection
% 		tNc = 8;								% # contour values
		tNc = eval( get( findtag( 'mrCG_Cortex_Contour_edit' ), 'string' ) );		% *** give this uicontrol a callback to enforce legal values
		tZmin = min( tEflat(:,3) );
		tZmax = max( tEflat(:,3) );
		tZdelta = ( tZmax - tZmin ) / ( tNc + 1 );
		tXYgrid = -1.5:0.01:1.5;
		[ tXgrid, tYgrid ] = meshgrid( tXYgrid );
		C = contourc( tXYgrid, tXYgrid, griddata( tEflat(:,1), tEflat(:,2), tEflat(:,3), tXgrid, tYgrid, 'cubic' ),...
							linspace( tZmin + tZdelta/2, tZmax - tZdelta/2, tNc ) );
		% loop through contours & add to cortex plot
		tOrigin = tOrigin - (gCortex.M.origin+[-128 128 128]);
		
% 		tNmap = 255;
% 		tCmap = jet(tNmap);
		tCmap = get( gCortex.FH, 'colormap' );
		tNmap = size( tCmap, 1 );
		
		if strcmp( tDomain, 'Wave' )
			if tZmax > -tZmin
				tZmin = -tZmax;
			else
				tZmax = -tZmin;
			end
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
			line( tX3D+tOrigin(1), tY3D+tOrigin(2), tZ3D+tOrigin(3), 'color', tCmap( 1 + round( (tNmap-1)/(tZmax-tZmin) * ( C(1,k) - tZmin ) ), : ),...
				'linewidth', 2, 'parent', gCortex.AH, 'tag', 'CortexContour' )
			k = tkC( C(2,k) );
		end
		
	end

	function mrCG_Cortex_Scalp_CB( tH, varargin )
		if isempty( gCortex )
			SetError( 'Need a cortex before adding scalp.'  );
			return
		end
		
		delete( findobj( gCortex.AH, 'tag', 'CortexScalp' ) )
		if get( tH, 'value') == 0
			return
		end
		
		% scalp, outer skull, inner skull (m) head-centered RAS coords
		try
			tBEM = mne_read_bem_surfaces( fullfile( getpref('mrCurrent','AnatomyFolder'), 'FREESURFER_SUBS',...
													[gCortex.Name,'_fs4'] , 'bem', [gCortex.Name,'_fs4-bem.fif'] ) );
		catch
			if ~exist('mne_read_bem_surfaces','file')
				error('mrCurrent Scalp requires MNE Matlab toolbox.')
			end
		end
% 		tOrigin = tOrigin - (gCortex.M.origin+[-128 128 128]);
		tBEM(1).rr = tBEM(1).rr*1000;
		tBEM(1).rr = tBEM(1).rr - repmat( gCortex.M.origin + [-128 128 128], tBEM(1).np, 1 );
		patch( 'vertices', tBEM(1).rr, 'faces', tBEM(1).tris, 'facecolor', [1 0.5 0.5], 'edgecolor', 'none',...
			'facealpha', 0.25, 'facelighting', 'gouraud', 'parent', gCortex.AH, 'tag', 'CortexScalp' )

	end

	function fval = sphereObjFcn( tOxyz, tEpos, tNE )
		tDxyz = tEpos - repmat( tOxyz, tNE, 1 );
		tUnit = tDxyz ./ repmat( hypot( hypot( tDxyz(:,1), tDxyz(:,2) ), tDxyz(:,3) ), 1, 3 );
		fval = norm( tDxyz - tUnit * ( tUnit(:) \ tDxyz(:) ), 'fro' );
	end

	function tCYMx = mrCG_Cortex_GetClim(tY,tInvNm)
		% get global max for balanced color limits; for complex, max returns complex w/ largest amp.
		[ tCYMx, tCiXMx ] = max( max( tY ) );			% max over channels, then over x
% 		tCYMx = abs( max( gCortex.InvM.( tInvNm ) * ( tY( :, tCiXMx ) * 1e6 ) ) );		% max in source space; abs b/c max still may be complex.
		tCYMx = max( abs( gCortex.InvM.( tInvNm ) * ( tY( :, tCiXMx ) * 1e6 ) ) );		% this way handles negative extrema
	end

%% -- Mesh Manipulation
	% these three functions can be consolidated into one callback with conditonals and nesting.
	function mrCG_Cortex_Rotate_CB( tH, varargin )		
		tView = get( gCortex.AH, 'view' );
		switch get( tH, 'Tag' )
			case 'mrCG_Cortex_Rot_R_pushbutton'
				tView(1) = tView(1) + str2double( get( findtag( 'mrCG_Cortex_Rot_By_edit' ), 'string' ) );
			case 'mrCG_Cortex_Rot_L_pushbutton'
				tView(1) = tView(1) - str2double( get( findtag( 'mrCG_Cortex_Rot_By_edit' ), 'string' ) );
			case 'mrCG_Cortex_Rot_V_pushbutton'
				tView(2) = tView(2) - str2double( get( findtag( 'mrCG_Cortex_Rot_By_edit' ), 'string' ) );
			case 'mrCG_Cortex_Rot_D_pushbutton'
				tView(2) = tView(2) + str2double( get( findtag( 'mrCG_Cortex_Rot_By_edit' ), 'string' ) );
		end
		set( gCortex.AH, 'view', tView )
		mrCG_Cortex_CamLights
	end

	function mrCG_Cortex_View_CB( tH, varargin )
		switch get( tH, 'Tag' )
			case 'mrCG_Cortex_View_P_pushbutton'
				set( gCortex.AH, 'view', [ 0 0 ] )
			case 'mrCG_Cortex_View_A_pushbutton'
				set( gCortex.AH, 'view', [ 180 0 ] )
			case 'mrCG_Cortex_View_R_pushbutton'
				set( gCortex.AH, 'view', [ 90 0 ] )
			case 'mrCG_Cortex_View_L_pushbutton'
				set( gCortex.AH, 'view', [ -90 0 ] )
			case 'mrCG_Cortex_View_V_pushbutton'
				set( gCortex.AH, 'view', [ 0 -90 ] )
			case 'mrCG_Cortex_View_D_pushbutton'
				set( gCortex.AH, 'view', [ 0 90 ] )
		end
		% note: campos doesn't update 'view' in time for mrCG_Cortex_CamLights w/o a drawnow which is visibly awkward
		mrCG_Cortex_CamLights
	end

	function mrCG_Cortex_CamLights
		tView = get( gCortex.AH, 'view' ) * pi/180;
		rotMat = [	               cos(tView(1)),               sin(tView(1)),              0;...
						-cos(tView(2))*sin(tView(1)), cos(tView(2))*cos(tView(1)), -sin(tView(2));...
						-sin(tView(2))*sin(tView(1)), sin(tView(2))*cos(tView(1)),  cos(tView(2))	];
		set( gCortex.AH, 'cameraposition', [ 0 -gCortex.dCam 0]*rotMat )
		set( gCortex.LH(1), 'position', [ 1 -1 0]*rotMat )
		set( gCortex.LH(2), 'position', [-1 -1 0]*rotMat )
	end

%% Helpers
	function tH = findtag( aTagStr ), tH = findobj( 'tag', aTagStr ); end

	function tHs = findtags( aCASTagStrs )
		tHs = cellfun( @(tTagStr) findtag( tTagStr ), aCASTagStrs );
% 		for iTag = 1:numel( aCASTagStrs ), tHs( iTag ) = findtag( aCASTagStrs{ iTag } ); end
	end

	function SetMessageText( aStr, aCM )
		set( findtag( 'mrCG_Messages_text' ), 'String', aStr, 'backgroundcolor', aCM );
		drawnow;
	end

	function SetMessage( aStr ), SetMessageText( aStr, [ .7 1 .7 ] ); end % green-gray background
	
	function SetWarning( aStr )
		SetMessageText( [ aStr '... Will continue in 5 sec.' ], [ 1 1 0 ] ); % yellow background
		pause( 5 );
	end

	function SetWarningNoPause( aStr )
		SetMessageText( aStr, [ 1 1 0 ] ); % yellow background
	end

	function SetError( aStr ), SetMessageText( aStr, [ 1 0 0 ] ); end % red background

	function tS = GetListSelection( tH, varargin )
		if ischar( tH ), tH = findtag( tH ); end
		tList = get( tH, 'String' );
		tVal = get( tH, 'Value' );
		tS = tList( tVal ); % returns a cell array, even if it has only one item.
	end % function GetListSelection

% 	function tS = GetListSelectionString( tH, varargin )
% 		if ischar( tH ), tH = findtag( tH ); end
% 		tS = GetListSelection( tH );
% 		tS = tS{:};
% 	end
% 
% 	function SetListSelection( tH, aStrs, varargin )
% 		if ischar( tH ), tH = findtag( tH ); end
% 		tList = get( tH, 'String' );
% 		tVal = CAS2SS( aStrs, tList );
% 		set( tH, 'Value', tVal );
% 	end % function GetListSelection

	function tExprStr = inputBigFont(tTitleStr,tPromptStr,tExprStr,tFontSize)
		% similar to inputdlg but with char units & variable fontsize
		% only takes 1 item at the moment

		tGAPw = 1;			% width,height gaps between uicontrols (chars)
		tGAPh = 0.5;

		tButtonStr = { 'OK', 'Cancel' };
		tButtonChars = cellfun( @numel, tButtonStr ) + 4;
		tUIw = max([ numel( tExprStr )+10*tGAPw, numel( tPromptStr ), sum( tButtonChars )+tGAPw ]);
		tUIh = 1.5;

		scaleBy = tFontSize / get(0,'defaultuicontrolfontsize');
		% scaleBy = tFontSize / get(0,'FactoryUIControlFontSize');
		if scaleBy ~= 1
			tUIw = tUIw * scaleBy;
			tUIh = tUIh * scaleBy;
			tButtonChars = tButtonChars * scaleBy;
			tGAPw = tGAPw * scaleBy;
			tGAPh = tGAPh * scaleBy;
		end

		defaultScreenUnits = get(0,'units');
		set(0,'units','characters');
		SSchar = get(0,'screensize');
		set(0,'units',defaultScreenUnits)

		tDLGw = tUIw + 2*tGAPw;
		tDLGh = 3*tUIh + 3*tGAPh;
		tDLGl = max( ceil( ( SSchar(3) - tDLGw ) / 2 ), 1 );
		tDLGb = max( ceil( ( SSchar(4) - tDLGh ) / 2 ), 1 );
		uiD = dialog('name',tTitleStr,'units','characters','position',[ tDLGl tDLGb tDLGw tDLGh ],...
			'defaultuicontrolfontsize',tFontSize,'defaultuicontrolunits','characters');
		uiC = [...
			uicontrol(uiD,'position',[tGAPw 2*tGAPh+2*tUIh tUIw tUIh],'style','text','string',tPromptStr,'horizontalalignment','left')...
			uicontrol(uiD,'position',[tGAPw 2*tGAPh+tUIh tUIw tUIh],'style','edit','string',tExprStr,'horizontalalignment','left')...
			uicontrol(uiD,'position',[tGAPw tGAPh tButtonChars(1) tUIh],'style','pushbutton','string',tButtonStr{1},'callback','uiresume')...
			uicontrol(uiD,'position',[2*tGAPw+tButtonChars(1) tGAPh tButtonChars(2) tUIh],'style','pushbutton','string',tButtonStr{2},'callback','close(gcf)')	];

		uiwait(uiD)

		if ~ishandle(uiD)
			tExprStr = '';
			return
		end

		tExprStr = get(uiC(2),'string');

		close(uiD)
	end

	function ResizeMrCG( tH, varargin )
		% When user resizes mrCG, this function will re-center the figure
		% and rescale all UI objects, preserving the aspect ratio, and if
		% the figure is too large, will resize it to 90% of screen height.
		set( tH, 'visible', 'off' ); % this doesn't quite work...
		tUD = get( tH, 'userdata' ); % a struct with field tOldPos, that was set the last time the figure was resized.
		tNewPos = get( tH, 'position' );
		tVSF = tNewPos(4) / tUD.tOldPos(4); % vertical scale factor, assuming it's not too large.
		tScrPos = ScreenPosChar;
		% If it's bigger than 90% of screen size, reset tVSF
		if tNewPos(4) > 0.90 * tScrPos(4), tVSF = 0.90 * tScrPos(4) / tUD.tOldPos(4); end
		% set position to reflect this VSF
		set( tH, 'position', [ tVSF * tNewPos( 1:2 ) tVSF * tUD.tOldPos( 3:4 ) ] );
		ReScaleMrCG( tH, tVSF ); % nested below
		% now, center it...
		tMrCGPos = get( tH, 'position' );
		tMrCGPos(1:2) = 0.5 * ( tScrPos(3:4) - tMrCGPos(3:4) );
		% now reset user data to reflect new position.
		tUD.tOldPos = tMrCGPos;
		set( tH, 'position', tMrCGPos, 'userdata', tUD, 'visible', 'on' );

		function ReScaleMrCG( tPH, tVSF )
			% Start with ghMrCurrentGUI, the handle for the figure.
			% Then, recursively drill down to each uicontrol object, resizing as we go.
			% untested tHSF should act like aspect ratio for width, for platform-specific behavior.
			tCHs = findobj( tPH, '-depth', 1 ); % get child handles from top level of parent
			% tCH(1) == tPH, so handle parent panel first, then children recursively
			if ~strcmpi( get( tCHs(1), 'type' ), 'figure' )
				set( tCHs(1), 'fontsize', tVSF * get( tCHs(1), 'fontsize' ), 'position', tVSF * get( tCHs(1), 'position' ) );
			end
			for i = 2:numel( tCHs )
				tCH = tCHs(i);
				if strcmpi( get( tCH, 'type' ), 'uipanel' )
					ReScaleMrCG( tCH, tVSF ); % begin recursion, using this panel as the new parent
				else
					set( tCH, 'fontsize', tVSF * get( tCH, 'fontsize' ), 'position', tVSF * get( tCH, 'position' ) );
				end
			end
		end

		function tScrPos = ScreenPosChar
			% get position coordinates of primary screen in characters
% 			tSFH = figure( 'position', get( 0, 'screensize' ), 'units', 'characters' );
% 			tScrPos = get( tSFH, 'position' );
% 			close( tSFH );
			oldFontUnits = get(0,'defaulttextfontunits');
			set(0,'defaulttextfontunits','points')
			tScrPos = [0 0 round( get(0,'ScreenSize')*[zeros(2);eye(2)] / get(0,'ScreenPixelsPerInch') * 72 / get(0,'defaulttextfontsize') .* [8/3 1] ) ];
			set(0,'defaulttextfontunits',oldFontUnits)
		end
	end

	function tColorOrderMat = PPFig_ColorOrderMat
% 			tDefaultColorOrderNames = { 'Blue', 'Green', 'Red', 'Cyan', 'Magenta', 'Yellow', 'Black' };
		tDefaultColorOrderNames = DefaultColorOrderNames;
		tiColorOrder = CAS2SS( GetOptSels( 'Colors' ), tDefaultColorOrderNames );
		tColorOrderMat = DefaultColorOrderMat;
		tColorOrderMat = tColorOrderMat( tiColorOrder, : );
	end

	function tDefaultColorOrderNames = DefaultColorOrderNames
		tDefaultColorOrderNames = repmat( { 'Blue', 'LtGrn', 'Red', 'Cyan', 'Yellow', 'Magenta', 'Black', 'Orange' }, 1, 3 );
	end

	function tColorOrderMat = DefaultColorOrderMat
		tDefaultColorOrderNames = DefaultColorOrderNames;
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
				SetWarningNoPause( [ 'Unknown color requested: ', tDefaultColorOrderNames{iColor} ]  )
			end
		end
	end

	function tStr = GetPopupSelection( tH )
		if ischar( tH ), tH = findtag( tH ); end
		tStr = char( GetListSelection( tH ) ); end

	function tIsAnyStrMatch = AnyStrMatch( tStr, tCAS, varargin )
		% loop through strings in cell array tCAS and return whether any of
		% them match the leading characters of tStr.  In other words, is
		% the string tStr prefixed by any of the strings in tCAS?  Good for
		% finding structure field names that begin with a particular
		% string, e.g., when subsetting a tCCD structure without needing to
		% know all the fields exactly, eg, "Spec"...
		tIsAnyStrMatch = false;
		for i = 1:numel( tCAS )
			if nargin < 3
				tIsAnyStrMatch = ~isempty( strmatch( tCAS{ i }, tStr ) );
			else
				tIsAnyStrMatch = ~isempty( strmatch( tCAS{ i }, tStr, varargin{1} ) ); % assume varargin{1} is 'exact'
			end
			if tIsAnyStrMatch
				return;
			end
		end
	end

	function tSbjROIsPN = GetSbjROIsPN( tSbjNm )
		if ~ispref( 'mrCurrent', 'AnatomyFolder' )
			setpref( 'mrCurrent', 'AnatomyFolder', uigetdir( '', 'Browse to Anatomy folder' ) );
		end
		tAnatFold = getpref( 'mrCurrent', 'AnatomyFolder' );
		tSbjROIsPN = fullfile( tAnatFold, tSbjNm, 'Standard', 'meshes', 'ROIs' );
	end

	function tSbjMeshPFN = GetSbjMeshPFN( tSbjNm )
		if ~ispref( 'mrCurrent', 'AnatomyFolder' )
			setpref( 'mrCurrent', 'AnatomyFolder', uigetdir( '', 'Browse to Anatomy folder' ) );
		end
		tAnatFold = getpref( 'mrCurrent', 'AnatomyFolder' );
		tSbjMeshPFN = fullfile( tAnatFold, tSbjNm, 'Standard', 'meshes', 'defaultCortex.mat' );
	end

	function tSensorPos = GetSensorPos( tSbjNm )
		tElpDir = fullfile( gProjPN, tSbjNm, 'Polhemus' );
		tElpFile = dir( fullfile( tElpDir, '*.elp' ) );
		tNelp = numel( tElpFile );
		if tNelp == 0
			SetError( [ 'No elp-file found for ', tSbjNm ]  );
			tSensorPos = [];
			return
		elseif tNelp > 1
			SetWarningNoPause( [ 'Multiple elp-files found for ', tSbjNm ]  );
			[junk,iElpFile] = max( [tElpFile.datenum] );
		else
			iElpFile = 1;
		end
		tSensorPos = mrC_readELPfile( fullfile( tElpDir, tElpFile(iElpFile).name ) , true, [ -2 1 3 ] );
	end

	function tSS = CAS2SS( tCAS1, tCAS2 )
		% takes two cell arrays of strings tCAS1, and tCAS2 and returns the
		% subscripts in tCAS2 corresponding to the items in tCAS1
		% unlike function intersect, order of tCAS1 is preserved.
		% tCAS2{ CAS2SS(tCAS1,tCAS2) } = tCAS1
		[test,tSS] = ismember(tCAS1,tCAS2);
		tSS = tSS(test);
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
		}';

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
						 disp( [ 'Cannot parse harmonic component name: ' tFN ] );
						error( [ 'Cannot parse harmonic component name: ' tFN ] );
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
					error( [ 'Requested harmonic component ', tFN, ' frequency < 0.' ] )
				elseif tComp > tVEPFS.nFr
					if nargin >= 3
						disp( [ '   ', varargin{3}, ': Requested harmonic component ', tFN, ' exceeds limit of spectrum.' ] )
					else
						disp( [ 'Requested harmonic component ', tFN, ' exceeds limit of spectrum.' ] )
					end
					error( [ 'Requested harmonic component ', tFN, ' exceeds limit of spectrum.' ] )
				end
			else
				 disp( [ 'Attempt to get unknown harmonic component ' tCompName ] );
				error( [ 'Attempt to get unknown harmonic component ' tCompName ] );
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
			'none' 'lo20' 'lo30' 'lo50' 'nf1' 'nf2' 'f2band' 'nf1clean' 'nf2clean' 'nf1low10' ...
			'nf1low15' 'nf1low20' 'nf1_odd3to15' 'rbtx_nf1' 'rbtx_nf2' 'rbtx_im' ...
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
			disp( [ 'Attempt to get unknown filter ' tFilterName ] );
			error( [ 'Attempt to get unknown filter ' tFilterName ] );
		end
		% we need tVEPFS, if not...
		if nargin < 2, error( 'GetFilter requires VEP frequency specification.' ); end
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
			error( 'Requested filter exceeds limit of spectrum.' );		% this message doesn't get displayed?
		end
	end

	function SetFilteredWaveforms
		tMtg = GetChartSel( 'Mtgs' );
		tFltNms = GetChartSelsData( 'Flts' );
		tSbjNms = GetChartSelsData( 'Sbjs' );
		tCndNms = GetChartSelsData( 'Cnds' );

		for iFlt = 1:numel( tFltNms )
			if strcmp( tFltNms{iFlt}, 'none' )		% 'none' always exists, so skip it
				continue
			end
			SetMessage( [ 'Calculating filter ', tFltNms{iFlt} ] );
			makeFourierBasis = true;
			for iSbj = 1:numel( tSbjNms )
				for iCnd = 1:numel( tCndNms )
					if ~isfield( gD.(tSbjNms{iSbj}).(tCndNms{iCnd}).(tMtg).Wave, tFltNms{iFlt} )
						if makeFourierBasis
							% 1st few lines of this redundantly repeat, but minimizing what gets done when filters already exist
							tVEPInfo = GetVEP1Cnd(1);
							tNT = tVEPInfo.nT;
							tRC = gcd( tVEPInfo.i1F1, tVEPInfo.i1F2 );	% number of repeat cycles per fundamental wave period...
							if tRC > 1												% the number of time points must be multiplied to match the fundamental wave period.
								tNT = tNT * tRC;
							end
							tFltSS = GetFilter( tFltNms{iFlt}, tVEPInfo );
							if     tVEPInfo.i1F1 > tRC && ~any( rem( tFltSS, tVEPInfo.i1F1 ) )
								tRC = tVEPInfo.i1F1;
							elseif tVEPInfo.i1F2 > tRC && ~any( rem( tFltSS, tVEPInfo.i1F2 ) )
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

	function tDomain = GetDomain
		tDomain = GetOptSel( 'Domain' );
	end

	function tIsDomain = IsDomain( tDomain )
		% RENAME THIS TO DIFFERENTIATE FROM DOMAIN FIELD
		switch tDomain
		case {'Wave','Spec','2DPhase','Bar','BarTriplet'}
			tIsDomain = strcmp( GetDomain, tDomain );
		case 'Offset'
			tDomain = GetDomain;
			tIsDomain = strcmp( tDomain, 'Wave' ) || strcmp( tDomain, 'Spec' );
		case 'Component'
			tDomain = GetDomain;
			tIsDomain = strcmp( tDomain, '2DPhase' ) || strncmp( tDomain, 'Bar', 3 );
		case 'Source'
			tIsDomain = strcmp( GetOptSel( 'Space' ), 'Source' );
		case 'Sensor'
			tIsDomain = ~strcmp( GetOptSel( 'Space' ), 'Source' );
		case 'Cursor'
			tIsDomain = ~strcmp( GetOptSel( 'Space' ), 'Topo' ) && IsDomain( 'Offset' );
% 		case 'Time'
% 			tIsDomain = strcmp( GetDomain, 'Wave' );
% 		case 'Freq'
% 			tIsDomain = strcmp( GetDomain, 'Spec' );
		otherwise
			error('unknown domain %s',tDomain)
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

	function SpecToXL
		tDomain = GetDomain;
		tIsSourceSpace = IsOptSel( 'Space', 'Source' );
		if ~( any( strcmp( tDomain, {'2DPhase','Bar'} ) ) && tIsSourceSpace )
			SetError( 'SpecToXL needs source space 2DPhase or Bar chart' );		% not triplet?
			return
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
		
		SD = InitSliceDescription( tValidFields );

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
								tYSubj(iSbj) = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
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
								tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
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
						tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );	% 1x1 complex
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
		xlswrite( GetOptSel( 'XLBookName' ), tData, GetOptSel( 'XLSheetName' ) );
		
	end

 	function SpecToTXT
		tDomain = GetDomain;
		tIsSourceSpace = IsOptSel( 'Space', 'Source' );
		if ~IsDomain( 'Component' ) 
			SetError( 'SpecToTXT needs 2DPhase or Bar chart' );
			return
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
		
		SD = InitSliceDescription( tValidFields );
		SDc = SD;
		if ismember( 'Chans', { tRowF, tColF, tCmpF } )
			SDc.Chans.Items = cellfun( @int2str, num2cell( SDc.Chans.Items ), 'UniformOutput', false );
		end

		tNSbjs = numel( SD.Sbjs.Items );
		tValidDims = [ ~[ isempty( tRowF ), isempty( tColF ), isempty( tCmpF )], IsSbjPage && ( tNSbjs > 1 ) ];
		
		% look into building this w/o loops like Mark did w/ fullfact
% 		tFileName = strrep( GetOptSel( 'XLBookName' ), 'xlw', 'tab' );
		[ tFileName, tPathName ] = uiputfile( '*.tab', 'Save tab-delimited ascii file', fullfile(gProjPN,'mrCurrentData.tab') );
		if isnumeric( tFileName )
			return
		else
			tFileName = strcat( tPathName, tFileName );
		end
		fid = fopen( tFileName, 'w' );
		if fid == -1
			error( 'Can''t open %s', tFileName )
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
									tYSubj(iSbj,:) = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 )';
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
									tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );
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
							tY = getSliceData( SD, tValidFields, tDomain, tSliceFlags, 1 );	% 1x1 complex, or 3x1 complex if Triplet
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
			error( 'Problem building %s', tFileName )
		end
		if fclose(fid) == -1
			warning( 'mrCurrent:fclose', 'Problem closing %s', tFileName )
		else
			disp( [ 'Wrote ',tFileName ] )
		end
		function writeRowLabels
			switch tValidDimCode
			case 7
				fprintf( fid, '\r\n%s\t%s\t%s\t%s\t', SDc.(tRowF).Items{ SD.(tRowF).Sel }, SDc.(tColF).Items{ SD.(tColF).Sel }, SDc.(tCmpF).Items{ SD.(tCmpF).Sel } );
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
		SetMessage( 'Exporting data to MAxxFig...' );
		tSliceFlags = [ IsOptSel( 'Space', 'Source' ), false, false ];		% [ SourceSpace AvgChans GFP ]
		tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
		if tSliceFlags(1)
			tValidFields = cat( 2, tValidFields, { 'Invs', 'Hems', 'ROIs', 'ROItypes' } );
		elseif IsOptSel( 'SensorWaves', 'GFP' )
			tSliceFlags(3) = true;			
			tFN = sprintf( 'Sensor GFP (%d)', numel( GetChartSels('Chans') ) );
		else	%if IsOptSel( 'SensorWaves', 'average' )
			tSliceFlags(2) = true;
			tFN = sprintf( 'Sensor Mean (%d)', numel( GetChartSels('Chans') ) );
		end

		SD = InitSliceDescription( tValidFields );

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
					gMF.Data{ iCnd }.R( :, iROI, iSbj ) = getSliceData( SD, tValidFields, 'Wave', tSliceFlags, 1 );
					tSpecData =                           getSliceData( SD, tValidFields(~strcmp(tValidFields,'Flts')), 'Spec', tSliceFlags, 1 );					
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
		SetMessage( 'Exporting data to MAxxFig... Done' );
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
% 		SetMessage( 'Done Exporting to ODBC' );
% 	end

	function tDirFoldNms = DirFoldNames( aDirNm )
		% cell array of folder names in dir, excluding those with leading "."
		tDir = dir( aDirNm );
		tDir = tDir( [ tDir.isdir ] & ~strncmp( {tDir.name}, '.', 1 ) );
		tDirFoldNms = { tDir.name };
	end

	function tDirFileNms = DirFileNames( aDirNm )
		% cell array of file names in dir, excluding those with leading "."
		tDir = dir( aDirNm );
		tDir = tDir( ~[ tDir.isdir ] & ~strncmp( {tDir.name}, '.', 1 ) );
		tDirFileNms = { tDir.name };
	end

	function tDirFileNms = DirFileNamesNoExt( aDirNm )
		% cell array of file names without extensions in dir, excluding those with leading "."
		tDirFileNms = DirFileNames( aDirNm );
		for iFile = 1:numel( tDirFileNms )
			tDirFileNms{ iFile } = tDirFileNms{ iFile }(1:(end-4));
		end
	end

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
			SetError( 'Channels CalcItems not allowed' )
			return
		end
		tItemSels = GetChartSels( tChartF );
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
		tExprStr = { inputBigFont( 'CalcItem', 'Edit CalcItem Expression:', tExprStr, 16 ) };

		if ~isempty( tExprStr )
			tExprStr = tExprStr{ 1 }; % change back to string
			% extract name of new CalcItem: must be immediately bordered by ':' and ' ='.
			[ tCalcItemNm, tExprStr ] = strtok( tExprStr );
			[ tCIFieldNm, tCIItemNm ] = GetCalcItemPartNames( tCalcItemNm );
			% if = [], then delete the item; safe if item doesn't exist, nothing happens.
			% otherwise, add expression to gCalcItems;
			if ~strcmp( tExprStr, ' = []' )
				SetMessage( [ 'Adding CalcItem ' tCIItemNm ' to ' tChartF ] );
				if ~isfield( gCalcItems, tChartF ) || ~isfield( gCalcItems.(tChartF), tCIItemNm )
					gChartFs.(tChartF).Items{ end + 1 } = tCIItemNm;		% add item to GUI
					gCalcItemOrder{ end + 1 } = tCalcItemNm;
				end
				gCalcItems.(tChartF).(tCIItemNm) = [ tCIItemNm, tExprStr ];
			elseif isstruct( gCalcItems ) && isfield( gCalcItems, tChartF ) && isfield( gCalcItems.(tChartF), tCIItemNm )
				SetMessage( [ 'Deleting CalcItem ' tCIItemNm ' from ' tChartF ] );
				gCalcItems.(tChartF) = rmfield( gCalcItems.(tChartF), tCIItemNm );
				if isempty( fieldnames( gCalcItems.( tChartF ) ) )
					gCalcItems = rmfield( gCalcItems, tChartF );
				end
				RemoveCalcItem			% remove item from GUI
			end
			% refresh GUI
			mrCG_Pivot_Chart_listbox_CB( findtag( 'mrCG_Pivot_Chart_listbox' ) );
			mrCG_Pivot_Items_listbox_CB( findtag( 'mrCG_Pivot_Items_listbox' ) );
			save( fullfile( gProjPN, 'CalcItems.mat' ), 'gCalcItems', 'gCalcItemOrder' );
		end
		function RemoveCalcItem
			% Removing CalcItem from full list of Items, then from selection if needed
			gChartFs.(tChartF).Items = gChartFs.(tChartF).Items( ~strcmp( gChartFs.(tChartF).Items, tCIItemNm ) );
			gChartFs.(tChartF).Sel   = CAS2SS( tItemSels( ~strcmp( tItemSels, tCIItemNm ) ), gChartFs.(tChartF).Items );
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
		tCalcItemTerms = tItems( unique( CAS2SS( tTok(2:end), tItems ) ) );
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
		else
			tIsCalcItem = ismember( { tCalcItemNm }, gCalcItemOrder );
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

%% Task
	function ConfigureTaskControls
		tTask.ExportData = @mrCG_Task_ExportData;
% 		tTask.ExportChartData = @mrCG_Task_ExportChartData;
		tTask.CalcItem = @SetCalcItem;
		tTask.CalcItemOrder = @SetCalcItemOrder;
		tTask.PaintROIs = @PaintROIsOnCortex;
		tTask.CortexMosaic = @makeCortexMosaic;		% was there a reason not to do 'em all this way?
		tTask.SpecToXL = @mrCG_Task_SpecToXL;
		tTask.SpecToTXT = @mrCG_Task_SpecToTXT;
% 		tTask.ExportToODBC = @mrCG_Task_ExportToODBC;		% get these from Mark's code
		tTask.SpoofMAxxFig = @mrCG_Task_SpoofMAxxFig;
		tTask.DumpGlobals = @mrCG_Task_ExportGlobals;
		tTask.TopoGUI = @MakeTopoGUI;
		tTask.SetAnatFold = @mrCG_Task_SetAnatFold;
		set( findtag( 'mrCG_Task_Go_pushbutton' ), 'callback', @mrCG_Task_Go_CB );
		set( findtag( 'mrCG_Task_Function_popupmenu' ), 'string', fieldnames( tTask ) );
		function mrCG_Task_Go_CB( varargin )
			tTask.( GetPopupSelection( 'mrCG_Task_Function_popupmenu' ) )();
		end
		function mrCG_Task_ExportGlobals
			assignin( 'base', 'gD', gD );
			assignin( 'base', 'gSbjROIFiles', gSbjROIFiles );
			assignin( 'base', 'gChartFs', gChartFs );
			assignin( 'base', 'gCortex', gCortex );
			assignin( 'base', 'gVEPInfo', gVEPInfo );
			assignin( 'base', 'gOptFs', gOptFs );
			assignin( 'base', 'gCurs', gCurs );
			assignin( 'base', 'gChartL', gChartL );
			assignin( 'base', 'gCalcItems', gCalcItems );
			assignin( 'base', 'gCalcItemOrder', gCalcItemOrder );
		end
		function mrCG_Task_SpecToXL, SpecToXL; end
		function mrCG_Task_SpecToTXT, SpecToTXT; end
		function mrCG_Task_SpoofMAxxFig, SpoofMAxxFig; end
% 		function mrCG_Task_ExportToODBC, ExportToODBC; end
		function mrCG_Task_SetAnatFold, setpref( 'mrCurrent', 'AnatomyFolder', uigetdir( '', 'Browse to Anatomy folder' ) ); end
	end

	function mrCG_Task_ExportData
		uiSize = [100 20 10];	% [width height margin]
		tDomain = 'Wave';
		tFlts = fieldnames( gD.(GetChartSelData('Sbjs')).(GetChartSelData('Cnds')).(GetChartSelData('Mtgs')).Wave );
		uiH = zeros(1,11);
		uiH(1) = dialog('defaultuipanelunits','pixels','name','Workspace Export','position',[400 400 uiSize*[2 0;0 5;7 10]]); %,'color',[0.9 0.9 0]); %,'defaultuipaneltitleposition','centertop');
		uiH(2) = uibuttongroup('parent',uiH(1),'position',uiSize*[0 0 1 0;0 2 0 3;1 6 2 3],'title','Space');
		uiH(3) = uibuttongroup('parent',uiH(1),'position',uiSize*[1 0 1 0;0 2 0 3;4 6 2 3],'title','Domain','SelectionChangeFcn',@ButtonGroup_CB);
		uiH(4) =       uipanel('parent',uiH(1),'position',uiSize*[0 0 2 0;0 1 0 1;1 2 5 3],'title','Filter');
		uiH(5)  = uicontrol(uiH(2),'position',uiSize*[0 0 1 0;0 2 0 1;1 1 0 0],'style','radiobutton','string','Source','value',1);
		uiH(6)  = uicontrol(uiH(2),'position',uiSize*[0 0 1 0;0 1 0 1;1 1 0 0],'style','radiobutton','string','Sensor');
		uiH(7)  = uicontrol(uiH(3),'position',uiSize*[0 0 1 0;0 2 0 1;1 1 0 0],'style','radiobutton','string','Wave','value',1);
		uiH(8)  = uicontrol(uiH(3),'position',uiSize*[0 0 1 0;0 1 0 1;1 1 0 0],'style','radiobutton','string','Spec');
		uiH(9)  = uicontrol(uiH(3),'position',uiSize*[0 0 1 0;0 0 0 1;1 1 0 0],'style','radiobutton','string','Harm');
		uiH(10) = uicontrol(uiH(4),'position',uiSize*[0 0 2 0;0 0 0 1;1 1 3 0],'style','popup','string',tFlts);
		uiH(11) = uicontrol(uiH(1),'position',uiSize*[0 0 2 0;0 0 0 1;1 1 5 0],'style','pushbutton','string','GO','callback','uiresume');
		uiwait
		tFlt = tFlts{ get(uiH(10),'value') };
		[Y,Ydim] = gD2array( gD, gVEPInfo, gSbjROIFiles, get(uiH(5),'value')==1, tDomain, tFlt );
		close(uiH(1))
		assignin( 'base', 'Y', Y );
		assignin( 'base', 'Ydim', Ydim );
		assignin( 'base', 'Yfilter', tFlt );
		SetMessage( 'Export Complete' );
		function ButtonGroup_CB( tH, tE )
			tDomain = get( tE.NewValue, 'string' );
		end
	end


	function MakeTopoGUI

		uiSize = [80; 20; 10];		% [width; height; margin]
		uiD = dialog('name','TopoGUI','position',[400 400 ([6 0 4;0 7 4]*uiSize)']); %,'defaultuipanelunits','pixels','defaultuipaneltitleposition','centertop');
		uiC = [...
			uicontrol(uiD,'position',([0 0 1;0 6 3;2 0 0;0 1 0]*uiSize)','style','text','string','Subject(s)')...
			uicontrol(uiD,'position',([2 0 2;0 6 3;2 0 0;0 1 0]*uiSize)','style','text','string','Condition')...
			uicontrol(uiD,'position',([4 0 3;0 6 3;2 0 0;0 1 0]*uiSize)','style','text','string','Filter')...
			uicontrol(uiD,'position',([0 0 1;0 2 3;2 0 0;0 4 0]*uiSize)','style','listbox','string',gChartFs.Sbjs.Items,'max',2)...
			uicontrol(uiD,'position',([2 0 2;0 2 3;2 0 0;0 4 0]*uiSize)','style','listbox','string',gChartFs.Cnds.Items)...
			uicontrol(uiD,'position',([4 0 3;0 2 3;2 0 0;0 4 0]*uiSize)','style','listbox','string',gChartFs.Flts.Items)...
			uicontrol(uiD,'position',([0 0 1;0 1 2;1 0 0;0 1 0]*uiSize)','style','text','string','size (pixels)')...
			uicontrol(uiD,'position',([1 0 1;0 1 2;1 0 0;0 1 0]*uiSize)','style','edit','string','500')...
			uicontrol(uiD,'position',([0 0 1;0 0 1;6 0 2;0 1 0]*uiSize)','style','pushbutton','string','continue','callback','uiresume') ];
		uiwait(uiD)

		if ~ishandle(uiD)
			return
		end
		iSbj = get(uiC(4),'value');
		iCnd = get(uiC(5),'value');
		iFlt = get(uiC(6),'value');
		axW = eval(get(uiC(8),'string'));					% topo axis width,height (pixels)
		close(uiD)

		tValidFields = { 'Sbjs', 'Cnds', 'Flts', 'Chans' };
% 		SD = InitSliceDescription( tValidFields );
		SD = gChartFs;
		SD.Sbjs.Items = gChartFs.Sbjs.Items(iSbj);
		SD.Cnds.Items = gChartFs.Cnds.Items(iCnd);
		SD.Flts.Items = gChartFs.Flts.Items(iFlt);			% *** check that this filter exists
		
		[ SD.Sbjs.Sel, SD.Cnds.Sel, SD.Flts.Sel ] = deal(1);
		% force selection of all channels
		[ SD.Chans.Items, SD.Chans.Sel ] = deal( 1:numel(gChartFs.Chans.Items) );

		Y = getSliceData( SD, tValidFields, 'Wave', false(1,3), 1 );
		tNSbjs = numel(iSbj);
		if tNSbjs == 1
			tSbjTag = SD.Sbjs.Items{1};
		else
			for i = 2:tNSbjs
				SD.Sbjs.Sel = i;
				Y = Y +  getSliceData( SD, tValidFields, 'Wave', false(1,3), 1 );
			end
			Y = Y / tNSbjs;
			tSbjTag = sprintf('Mean%dSbjs',tNSbjs);
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
		tCutoff = GetOptSelNum( 'ColorCutoff' );
% 		AVIpars.colormap = flow( tNmap, min( tCutoff / max( abs( Y(:) ) ), 1 ) );

		fig = figure('defaultaxesunits','pixels','position',[max(ceil((ss(3)-figW)/2),1) max(ceil((ss(4)-figH)/2),1) figW figH],...
						'colormap', flow( tNmap, min( tCutoff / max( abs( Y(:) ) ), 1 ) ) );
		uiM = uimenu('label','TopoMenu');
		ax = [	axes('dataaspectratio',[1 1 1],'xtick',[],'ytick',[],'box','on','position',[axM axM+axH(2)+axM axW axH(1)]),...
					axes('position',[axM axM axW axH(2)])	];

		axes(ax(2))
		tYLim  = [-1 1]*max(abs([ min(Y(:)), max(Y(:)) ]));
		plot(tX,Y,'k','HitTest','off')
		set(ax(2),'xlim',[0 tX(tNT)],'ylim',tYLim*1.05) %,'xtick',[],'ytick',[],'box','on')
		iX = 1;
		tHline = line(tX([iX iX]),get(ax(2),'ylim'),'color',[0 0.75 0]);

		axes(ax(1))
		Pflat = load('defaultFlatNet.mat');		% 128x2 variable xy
		tHpatch = patch(	'vertices',[ Pflat.xy, zeros(size(Pflat.xy(:,1))) ], 'faces',mrC_EGInetFaces(false),...
								'facevertexcdata',Y(iX,:)', 'facecolor','interp', 'cdatamapping','scaled',...
								'edgecolor','k', 'linewidth',1, 'marker','.', 'markersize',16 );
		set(ax(1),'Clim',tYLim)
		title( [ 'Subject = ',tSbjTag,', Condition = ',SD.Cnds.Items{1}], 'interpreter', 'none' )
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
		
		uimenu(uiM,'label','Reset cutoff','callback',@TopoColorMap)
		function TopoColorMap(varargin)
			% inputBigFont(tTitleStr,tPromptStr,tExprStr,tFontSize)
			tCutStr = inputdlg({'Cutoff'},'TopoGUI',1,{num2str(tCutoff)});
			if isempty( tCutStr )
				return
			end
			tCutoff = eval( tCutStr{1} );
			set( fig, 'colormap', flow( tNmap, min( tCutoff / max( abs( Y(:) ) ), 1 ) ) )
		end
		
		uimenu(uiM,'label','MakeMovie','callback',@TopoMovie)
		function TopoMovie(varargin)
			
			aviOpts = inputdlg( {'Start (ms)','Stop (ms)',sprintf('Step (# %0.3fms samples)',tCndInfo.dTms),'fps','quality [1,100]'},...
				'TopoGUI', 1, {num2str(ceil(tX(1))),num2str(floor(tX(tNT))),'10','4','75'} );
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
			AVIquality = round( eval( aviOpts{5} ) );
			if AVIquality<1 || AVIquality>100
				error('AVI quality out of range')
			end
			set(tHline,'xdata',tX([iStart iStart]))
			set(tHpatch,'facevertexcdata',Y(iStart,:)')
			
			[aviName,aviPath] = uiputfile(fullfile(gProjPN,'*.avi'),'Save AVI file');
			saveAVI = ischar(aviName);
			if saveAVI
				avi = avifile([aviPath,aviName],'colormap',get(fig,'colormap'),'fps',AVIfps,'quality',AVIquality);	%,'videoname','xxx');
			end

			disp('Press key to start.  Don''t cover any part of the figure window while building an avi-file.')
			set( fig, 'name', '---PRESS KEY TO START---' )
			figure( fig )
			pause
			if saveAVI
				set( fig, 'name', '---BUILDING AVI. DON''T COVER FIGURE!---' )
			else
				set( fig, 'name', '' )
			end
			for iX = iStart:iStep:iStop
				set(tHline,'xdata',tX([iX iX]))
				set(tHpatch,'facevertexcdata',Y(iX,:)')
				drawnow
				if saveAVI
					avi = addframe( avi, getframe(fig) );
				end
			end
			if saveAVI
				set( fig, 'name', '' )
				avi = close(avi);
			end
		end

% 		image(TopoFrames(1).cdata)
% 		set(gca,'units','pixels','position',[20 20 561 609],'box','off','xtick',[],'ytick',[],'color','g','visible','off')

	end

end