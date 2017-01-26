function mrCurrent
%% General initialization
	disp( 'MrCurrent Version 9.0' );
	% Version commentary managed by CVS
	% Preceding version commentary available in X:\projects\pettet\mrPrototypes\mrCurrent\mrCurrent.m.
	
	% Initialize these variables here first to force outer scope
	ghMrCurrentGUI = []; % handle to this GUI, to enforce singleton.
	gProjPN = 0; % project path name
	gD = []; % root of the main data structure
	gY = []; % current N-D matrix of data being plotted
	gPM = []; % pivot map
	gVEPInfo = []; % VEP metadata from Axx files
	gCndFiles = [];
	gSbjROIFiles = [];
	gSbjROIs = [];
% 	gN = []; % global structure for keeping track of item list sizes
	gCortex = [];
	gIsPivotOn = false; % flag for pivoting
	gChartFs = []; % structure of chart fields
	gChartL = [];
	gOptFs = []; % structure of option fields
	gOptL = [];
	gDFs = []; % dimension fields
	gCompFieldNms = []; % since readable harmonic component expressions don't make good struct field names.
	gSPHs = [];
	gCurs = [];
	
	InitMrCurrentGUI;
	InitPivotFieldsStruct;
	
	function InitMrCurrentGUI
		ghMrCurrentGUI = findtag( 'mrCG' );	% look for existing gui;
		if ~isempty( ghMrCurrentGUI )		% if it already exists...
			figure( ghMrCurrentGUI );		% use it...
			return;							% and stop here.
		end
		% if we get here, start building new gui
		ghMrCurrentGUI = MakeMrCG;	% "make mrCurrent GUI" build new gui;
		set( ghMrCurrentGUI, 'ResizeFcn', @ResizeMrCG );

		set( findtags( { 'mrCG_Project_text' 'mrCG_Messages_text' } ), 'horizontalalignment', 'left' );
		set( findtag( 'mrCG_Project_text' ), 'fontsize', 1.25 * get( findtag( 'mrCG_Project_text' ), 'fontsize' ) );

		set( findobj( ghMrCurrentGUI, 'style', 'listbox', '-or', 'style', 'popupmenu', '-or', 'style', 'edit' , '-or', 'style', 'text' ), 'backgroundcolor', [ .85 .85 .85 ] );

		tCenteredPanels = findtags( { ...
			'mrCG_Cortex_Step' 'mrCG_Cortex_Step_By' 'mrCG_Cortex_Start' 'mrCG_Cortex_Start_At' ...
			'mrCG_Cortex_End' 'mrCG_Cortex_End_At' 'mrCG_Cortex_Frame' 'mrCG_Cortex_Frame_At' 'mrCG_Cortex_Move_By' ...
			} );
		set( tCenteredPanels, 'TitlePosition', 'centertop' );

		set( findtag( 'mrCG_Pivot_Chart_listbox' ), 'callback', @mrCG_Pivot_Chart_listbox_CB, 'max', 1 );
		set( findtag( 'mrCG_Pivot_Options_listbox' ), 'callback', @mrCG_Pivot_Options_listbox_CB, 'max', 1 );
		set( findtag( 'mrCG_Pivot_Chart_Pivot_pushbutton' ), 'callback', @mrCG_Pivot_Chart_Pivot_pushbutton_CB );
		set( findtag( 'mrCG_Pivot_Options_Pivot_pushbutton' ), 'callback', @mrCG_Pivot_Options_Pivot_pushbutton_CB );
		set( findtag( 'mrCG_Pivot_Items_listbox' ), 'callback', @mrCG_Pivot_Items_listbox_CB, 'max', 1 );
		set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'callback', @mrCG_Pivot_Items_UserDefined_edit_CB );

		set( findtag( 'mrCG_Project_New_pushbutton' ), 'callback', @NewProject );
		
		tListBoxButtonTags = strcat( repmat( 'mrCG_Pivot_Items', 4, 1 ), '_', { 'Up', 'Down', 'Top', 'Flip' }', '_pushbutton' );
		set( findtags( tListBoxButtonTags ), 'callback', @ManageListBoxSelection_CB );

		tPickButtonTags = strrep( 'mrCG_Cortex_X_Pick_pushbutton', 'X', { 'Frame' 'Start' 'End' } );
		for iTag = 1:numel( tPickButtonTags ), set( findtag( tPickButtonTags{ iTag } ), 'callback', @PickCursor ); end
		set( findtag( 'mrCG_Cortex_DeleteCursors_pushbutton' ), 'callback', @DeleteCursors );
	
		tRotateButtonTags = strrep( 'mrCG_Cortex_Move_X_pushbutton', 'X', { 'L' 'R' 'V' 'D' } );
		for iTag = 1:numel( tRotateButtonTags ), set( findtag( tRotateButtonTags{ iTag } ), 'callback', @mrCG_Cortex_Rotate ); end

		tViewButtonTags = strrep( 'mrCG_Cortex_View_X_pushbutton', 'X', { 'A' 'P' 'R' 'L' 'V' 'D' } );
		for iTag = 1:numel( tViewButtonTags ), set( findtag( tViewButtonTags{ iTag } ), 'callback', @mrCG_Cortex_View ); end

% 		set( findtag( 'mrCG_Pivot_NewPlot_pushbutton' ), 'callback', @mrCG_Pivot_NewPlot_CB );
% 		set( findtag( 'mrCG_Pivot_ClonePlot_pushbutton' ), 'callback', @mrCG_Pivot_ClonePlot_CB );
		set( findtag( 'mrCG_Pivot_NewPlot_pushbutton' ), 'callback', @PivotPlot_CB );
		set( findtag( 'mrCG_Pivot_RevisePlot_pushbutton' ), 'callback', @PivotPlot_CB );
		set( findtag( 'mrCG_Cortex_Paint_pushbutton' ), 'callback', @mrCG_Cortex_Paint_CB );
		
		set( findtag( 'mrCG_Cortex_Play_pushbutton' ), 'callback', @mrCG_Cortex_Play_CB );
		set( findtags( strrep( 'mrCG_Cortex_X_At_edit', 'X', {'Frame','Start','End'} ) ), 'callback', @mrCG_Cortex_EditCursor_CB );
		set( findtags( strrep( 'mrCG_Cortex_Step_X_pushbutton', 'X', {'F','B'} ) ), 'callback', @mrCG_Cortex_Step_CB );
		set( findtag( 'mrCG_Cortex_Step_By_edit' ), 'callback', @mrCG_Cortex_Step_By_CB );
		
		tDisabledControls = {	'mrCG_Pivot_Items_UserDefined_edit', 'mrCG_Cortex_Clone_pushbutton', ...
										'mrCG_Cortex_Save_pushbutton', 'mrCG_Cortex_Rew_pushbutton', ...
			'mrCG_Cortex_Frame_At_edit', 'mrCG_Cortex_Start_At_edit', 'mrCG_Cortex_End_At_edit', ...
			'mrCG_Cortex_Frame_Pick_pushbutton', 'mrCG_Cortex_Start_Pick_pushbutton', 'mrCG_Cortex_End_Pick_pushbutton', ...
			'mrCG_Cortex_Step_By_edit', 'mrCG_Cortex_Step_B_pushbutton', 'mrCG_Cortex_Step_F_pushbutton', ...
			'mrCG_Cortex_Paint_pushbutton', 'mrCG_Cortex_Play_pushbutton', 'mrCG_Cortex_DeleteCursors_pushbutton' };
		
		set( findtags( tDisabledControls ), 'enable', 'off' );
		
		ConfigureTaskControls;

		SetMessage( 'Click Project New button...' );

		drawnow;
		function tFH = MakeMrCG

			tUD.tOldPos = [ 74.00 27.00 178.00 53.92 ];
			tFH = figure( 'tag', 'mrCG', 'Units','characters', 'Position', tUD.tOldPos , 'userdata', tUD );
			tScaleParams = { 'units', 'characters', 'fontsize', 12 };
			
			uipanel(	'tag', 'mrCG_Task', 'parent', findobj( 0, 'tag', 'mrCG' ), 'title', 'Task', tScaleParams{:}, 'position', [ 143.80 12.46 32.00 9.54 ] );
			uicontrol(	'tag', 'mrCG_Task_Go_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Task' ), 'style', 'pushbutton', 'string', 'Go', tScaleParams{:}, 'position', [ 2.40 0.73 27.80 2.23 ] );
			uipanel(	'tag', 'mrCG_Task_Function', 'parent', findobj( 0, 'tag', 'mrCG_Task' ), 'title', 'Function', tScaleParams{:}, 'position', [ 2.00 3.35 28.40 4.46 ] );
			uicontrol(	'tag', 'mrCG_Task_Function_popupmenu', 'parent', findobj( 0, 'tag', 'mrCG_Task_Function' ), 'style', 'popupmenu', 'string', { 'None...' }, tScaleParams{:}, 'position', [ 1.40 0.46 25.40 2.15 ] );
			uipanel(	'tag', 'mrCG_Cortex', 'parent', findobj( 0, 'tag', 'mrCG' ), 'title', 'Cortex', tScaleParams{:}, 'position', [ 1.80 5.92 141.00 16.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Move', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'title', 'Move', tScaleParams{:}, 'position', [ 112.00 0.50 27.00 7.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Move_By', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Move' ), 'title', 'By', tScaleParams{:}, 'position', [ 14.40 0.62 10.80 4.69 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Move_By_edit', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Move_By' ), 'style', 'edit', 'string', '15', tScaleParams{:}, 'position', [ 1.60 0.69 6.80 2.15 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Move_D_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Move' ), 'style', 'pushbutton', 'string', 'D', tScaleParams{:}, 'position', [ 7.80 0.75 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Move_V_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Move' ), 'style', 'pushbutton', 'string', 'V', tScaleParams{:}, 'position', [ 7.80 2.90 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Move_L_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Move' ), 'style', 'pushbutton', 'string', 'L', tScaleParams{:}, 'position', [ 1.60 0.75 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Move_R_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Move' ), 'style', 'pushbutton', 'string', 'R', tScaleParams{:}, 'position', [ 1.60 2.90 6.00 2.00 ] );
			uibuttongroup(	'tag', 'mrCG_Cortex_View', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'title', 'View', tScaleParams{:}, 'position', [ 112.00 7.69 27.00 7.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_View_D_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_View' ), 'style', 'pushbutton', 'string', 'D', tScaleParams{:}, 'position', [ 14.00 0.75 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_View_V_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_View' ), 'style', 'pushbutton', 'string', 'V', tScaleParams{:}, 'position', [ 14.00 2.90 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_View_L_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_View' ), 'style', 'pushbutton', 'string', 'L', tScaleParams{:}, 'position', [ 7.80 0.75 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_View_R_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_View' ), 'style', 'pushbutton', 'string', 'R', tScaleParams{:}, 'position', [ 7.80 2.90 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_View_A_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_View' ), 'style', 'pushbutton', 'string', 'A', tScaleParams{:}, 'position', [ 1.60 0.75 6.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_View_P_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_View' ), 'style', 'pushbutton', 'string', 'P', tScaleParams{:}, 'position', [ 1.60 2.90 6.00 2.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Step', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'title', 'Step', tScaleParams{:}, 'position', [ 91.00 2.50 19.00 9.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Step_F_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Step' ), 'style', 'pushbutton', 'string', 'F', tScaleParams{:}, 'position', [ 10.00 0.50 8.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Step_B_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Step' ), 'style', 'pushbutton', 'string', 'B', tScaleParams{:}, 'position', [ 1.00 0.50 8.00 2.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Step_By', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Step' ), 'title', 'By', tScaleParams{:}, 'position', [ 1.00 2.80 17.00 4.70 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Step_By_edit', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Step_By' ), 'style', 'edit', 'string', '', tScaleParams{:}, 'position', [ 2.00 0.70 13.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Rew_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'style', 'pushbutton', 'string', 'Rew', tScaleParams{:}, 'position', [ 101.00 11.77 9.00 2.23 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Play_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'style', 'pushbutton', 'string', 'Play', tScaleParams{:}, 'position', [ 91.00 11.77 9.00 2.23 ] );
			uicontrol(	'tag', 'mrCG_Cortex_DeleteCursors_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'style', 'pushbutton', 'string', 'DeleteCursors', tScaleParams{:}, 'position', [ 16.00 3.00 73.00 2.23 ] );
			uipanel(	'tag', 'mrCG_Cortex_End', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'title', 'End', tScaleParams{:}, 'position', [ 65.00 5.69 24.00 9.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_End_Pick_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_End' ), 'style', 'pushbutton', 'string', 'Pick', tScaleParams{:}, 'position', [ 3.00 0.46 18.00 2.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_End_At', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_End' ), 'title', 'At', tScaleParams{:}, 'position', [ 1.00 2.62 22.00 4.85 ] );
			uicontrol(	'tag', 'mrCG_Cortex_End_At_edit', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_End_At' ), 'style', 'edit', 'string', '', tScaleParams{:}, 'position', [ 2.00 0.85 18.00 2.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Start', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'title', 'Start', tScaleParams{:}, 'position', [ 40.50 5.69 24.00 9.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Start_Pick_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Start' ), 'style', 'pushbutton', 'string', 'Pick', tScaleParams{:}, 'position', [ 3.00 0.46 18.00 2.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Start_At', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Start' ), 'title', 'At', tScaleParams{:}, 'position', [ 1.00 2.62 22.00 4.85 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Start_At_edit', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Start_At' ), 'style', 'edit', 'string', '', tScaleParams{:}, 'position', [ 2.00 0.85 18.00 2.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Frame', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'title', 'Frame', tScaleParams{:}, 'position', [ 16.00 5.69 24.00 9.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Frame_Pick_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Frame' ), 'style', 'pushbutton', 'string', 'Pick', tScaleParams{:}, 'position', [ 3.00 0.46 18.00 2.00 ] );
			uipanel(	'tag', 'mrCG_Cortex_Frame_At', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Frame' ), 'title', 'At', tScaleParams{:}, 'position', [ 1.00 2.62 22.00 4.85 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Frame_At_edit', 'parent', findobj( 0, 'tag', 'mrCG_Cortex_Frame_At' ), 'style', 'edit', 'string', '', tScaleParams{:}, 'position', [ 2.00 0.85 18.00 2.00 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Save_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'style', 'pushbutton', 'string', 'Save', tScaleParams{:}, 'position', [ 2.00 6.60 12.00 2.20 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Clone_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'style', 'pushbutton', 'string', 'Clone', tScaleParams{:}, 'position', [ 2.00 9.10 12.00 2.20 ] );
			uicontrol(	'tag', 'mrCG_Cortex_Paint_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Cortex' ), 'style', 'pushbutton', 'string', 'Paint', tScaleParams{:}, 'position', [ 2.00 11.60 12.00 2.20 ] );
			uipanel(	'tag', 'mrCG_Pivot', 'parent', findobj( 0, 'tag', 'mrCG' ), 'title', 'Pivot', tScaleParams{:}, 'position', [ 1.80 22.46 174.00 31.00 ] );
			uicontrol(	'tag', 'mrCG_Pivot_RevisePlot_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot' ), 'style', 'pushbutton', 'string', 'RevisePlot', tScaleParams{:}, 'position', [ 87.20 0.85 84.80 2.92 ] );
			uicontrol(	'tag', 'mrCG_Pivot_NewPlot_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot' ), 'style', 'pushbutton', 'string', 'NewPlot', tScaleParams{:}, 'position', [ 2.00 0.85 84.60 2.92 ] );
			uipanel(	'tag', 'mrCG_Pivot_Options', 'parent', findobj( 0, 'tag', 'mrCG_Pivot' ), 'title', 'Options', tScaleParams{:}, 'position', [ 116.40 4.31 56.00 24.92 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Options_listbox', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Options' ), 'style', 'listbox', 'string', { 'None...' }, tScaleParams{:}, 'position', [ 12.60 0.77 40.80 22.31 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Options_Pivot_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Options' ), 'style', 'pushbutton', 'string', 'Pivot', tScaleParams{:}, 'position', [ 2.00 0.77 9.00 22.23 ] );
			uipanel(	'tag', 'mrCG_Pivot_Items', 'parent', findobj( 0, 'tag', 'mrCG_Pivot' ), 'title', 'Items', tScaleParams{:}, 'position', [ 74.50 4.31 41.00 24.92 ] );
			uipanel(	'tag', 'mrCG_Pivot_Items_UserDefined', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Items' ), 'title', 'UserDefined', tScaleParams{:}, 'position', [ 1.20 0.38 38.00 4.77 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Items_UserDefined_edit', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Items_UserDefined' ), 'style', 'edit', 'string', '', tScaleParams{:}, 'position', [ 1.80 0.54 33.60 2.23 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Items_Flip_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Items' ), 'style', 'pushbutton', 'string', 'Flip', tScaleParams{:}, 'position', [ 28.40 5.31 7.20 2.23 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Items_Top_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Items' ), 'style', 'pushbutton', 'string', 'Top', tScaleParams{:}, 'position', [ 20.80 5.31 7.20 2.23 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Items_Down_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Items' ), 'style', 'pushbutton', 'string', 'Down', tScaleParams{:}, 'position', [ 10.40 5.31 10.00 2.23 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Items_Up_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Items' ), 'style', 'pushbutton', 'string', 'Up', tScaleParams{:}, 'position', [ 4.20 5.31 5.80 2.23 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Items_listbox', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Items' ), 'style', 'listbox', 'string', { 'None...' }, tScaleParams{:}, 'position', [ 1.40 8.15 37.20 14.77 ] );
			uipanel(	'tag', 'mrCG_Pivot_Chart', 'parent', findobj( 0, 'tag', 'mrCG_Pivot' ), 'title', 'Chart', tScaleParams{:}, 'position', [ 1.60 4.31 72.00 24.92 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Chart_Pivot_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Chart' ), 'style', 'pushbutton', 'string', 'Pivot', tScaleParams{:}, 'position', [ 61.20 0.69 9.00 22.38 ] );
			uicontrol(	'tag', 'mrCG_Pivot_Chart_listbox', 'parent', findobj( 0, 'tag', 'mrCG_Pivot_Chart' ), 'style', 'listbox', 'string', { 'None...' }, tScaleParams{:}, 'position', [ 1.60 0.77 58.40 22.38 ] );
			uipanel(	'tag', 'mrCG_Messages', 'parent', findobj( 0, 'tag', 'mrCG' ), 'title', 'Messages', tScaleParams{:}, 'position', [ 52.80 0.69 123.00 5.00 ] );
			uicontrol(	'tag', 'mrCG_Messages_text', 'parent', findobj( 0, 'tag', 'mrCG_Messages' ), 'style', 'text', 'string', { 'None...' }, tScaleParams{:}, 'position', [ 2.20 0.54 118.80 2.62 ] );
			uipanel(	'tag', 'mrCG_Project', 'parent', findobj( 0, 'tag', 'mrCG' ), 'title', 'Project', tScaleParams{:}, 'position', [ 1.80 0.69 50.00 5.00 ] );
			uicontrol(	'tag', 'mrCG_Project_New_pushbutton', 'parent', findobj( 0, 'tag', 'mrCG_Project' ), 'style', 'pushbutton', 'string', 'New', tScaleParams{:}, 'position', [ 40.20 0.85 8.00 2.23 ] );
			uicontrol(	'tag', 'mrCG_Project_text', 'parent', findobj( 0, 'tag', 'mrCG_Project' ), 'style', 'text', 'string', { 'None...' }, tScaleParams{:}, 'position', [ 1.40 0.85 38.20 2.23 ] );

		end
		
	end

%% Pivot Functions
	function InitPivotFieldsStruct
		tPFPropVals = { ...
 		'Domain', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Wave' 'Spec' '2DPhase' 'Bar' }; ...
% 		'Stats', 'mrCG_Pivot_Options_listbox', 'mOpt', 1, { 'Mean' 'Dispersion' 'Scatter' 'SbjNames' 'Significance' }; ...
		'Stats', 'mrCG_Pivot_Options_listbox', 'mOpt', 1, { 'Mean' 'Dispersion' 'Scatter' }; ...
		'Colors', 'mrCG_Pivot_Options_listbox', 'mOpt', 1, DefaultColorOrderNames; ...
		'Cortex', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'none' }; ...
		'ScaleBy', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'All' 'Rows' 'Cols' 'Panels' 'Reuse' }; ...
		'SpecPlotCmp', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'UpDown' 'Overlay' }; ...
		'Patches', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'on' 'off' }; ...
		'WaveSpacing', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '5' '10' '1' '2.5' 'UsrDef: ' }; ...
		'SpecSpacing', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '.5' '1' '2.5' '5' 'UsrDef: ' }; ...
		'SpecXLim', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '20' '10' '50' 'Max' 'UsrDef: ' }; ...
		'ColorCutoff', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { '33' '10' '0' 'UsrDef: ' }; ...
		'AutoPaint', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'on' 'off' }; ...
		'ColorMapMax', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'All' 'Cursor' 'UsrDef: ' }; ...
		'BarMean', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Coherent' 'Incoherent' }; ...
% 		'AmpType', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'projected' 'scalar' }; ...
% 		'SignifTest', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Bonferroni' 'PermTVals' 'PermTRuns' }; ...
% 		'SignifCrit', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'Omnibus' 'Chan/ROI' }; ...
% 		'SignifMarkers', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'OnWaves' 'OnAxis' }; ...
% 		'GhostTest', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'off' 'on' }; ...
		'DisperScale', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'SEM' '95%CI' }; ...
		'XLBookName', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'mrCurrentData.xlw' 'UsrDef: ' }; ...
		'XLSheetName', 'mrCG_Pivot_Options_listbox', 'sOpt', 1, { 'mrCurrentData' 'UsrDef: ' }; ...
		};
		for iF = 1:numel( tPFPropVals( :, 1 ) )
% 			gOptFs.( tPFPropVals{ iF, 1 } ) = struct( 'ListTag', tPFPropVals( :, 2 ), 'Dim', tPFPropVals( :, 3 ), ...
% 				'Sel', tPFPropVals( :, 4 ), 'Items', tPFPropVals( :, 5 ) );
			gOptFs.( tPFPropVals{ iF, 1 } ).ListTag = tPFPropVals{ iF, 2 };
			gOptFs.( tPFPropVals{ iF, 1 } ).Dim = tPFPropVals{ iF, 3 };
			gOptFs.( tPFPropVals{ iF, 1 } ).Sel = tPFPropVals{ iF, 4 };
			gOptFs.( tPFPropVals{ iF, 1 } ).Items = tPFPropVals{ iF, 5 };
		end
% 		gOptL = struct( 'Items', fieldnames( gOptFs ), 'Sel', 1 );
		gOptL.Items = fieldnames( gOptFs );
		gOptL.Sel = 1;

		tPFPropVals = { ...
		'ROIs', 'mrCG_Pivot_Chart_listbox', 'col', [], {}; ...
		'Hems', 'mrCG_Pivot_Chart_listbox', 'page', 1, { 'Bilat' 'Left' 'Right' }; ...
		'Cnds', 'mrCG_Pivot_Chart_listbox', 'cmp', [], {}; ...
		'Sbjs', 'mrCG_Pivot_Chart_listbox', 'page', [], {}; ...
		'Comps', 'mrCG_Pivot_Chart_listbox', 'row', [], {}; ...
		'Flts', 'mrCG_Pivot_Chart_listbox', 'page', [], {}; ...
		'Mtgs', 'mrCG_Pivot_Options_listbox', 'page', [], {}; ...
		'Invs', 'mrCG_Pivot_Chart_listbox', 'page', [], {}; ...
		};
		for iF = 1:numel( tPFPropVals( :, 1 ) )
% 			gChartFs.( tPFPropVals{ iF, 1 } ) = struct( 'ListTag', tPFPropVals( :, 2 ), 'Dim', tPFPropVals( :, 3 ), ...
% 				'Sel', tPFPropVals( :, 4 ), 'Items', tPFPropVals( :, 5 ) );
			gChartFs.( tPFPropVals{ iF, 1 } ).ListTag = tPFPropVals{ iF, 2 };
			gChartFs.( tPFPropVals{ iF, 1 } ).Dim = tPFPropVals{ iF, 3 };
			gChartFs.( tPFPropVals{ iF, 1 } ).Sel = tPFPropVals{ iF, 4 };
			gChartFs.( tPFPropVals{ iF, 1 } ).Items = tPFPropVals{ iF, 5 };
		end
% 		gChartL = struct( 'Items', fieldnames( gChartFs ), 'Sel', 1 );
		gChartL.Items = fieldnames( gChartFs );
		gChartL.Sel = 1;
		gDFs.row = gChartL.Items{1};
		gDFs.col = gChartL.Items{2};
		gDFs.cmp = gChartL.Items{3};
		gDFs.page = gChartL.Items(4:end);

		UpdateChartListBox;
		UpdateOptionsListBox;
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

	function mrCG_Pivot_Chart_listbox_CB( tH, tE )
		gIsPivotOn = false;
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		gChartL.Sel = get( tH, 'value' );
        if ~isfield(gChartFs.( gChartL.Items{ gChartL.Sel } ),'Items')
            gChartFs.( gChartL.Items{ gChartL.Sel } ).Items=[];
        end
        
            
		if ~isempty( gChartFs.( gChartL.Items{ gChartL.Sel } ).Items )
			tCFNm = gChartL.Items{ gChartL.Sel };
			tCF = gChartFs.( tCFNm );
			tMax = 2;
			if strcmp( tCF.Dim, 'page' ) && ~strcmp( tCFNm, 'Sbjs' ), tMax = 1; end % sbjs can be multi even when page.
			set( tILBH, 'string', tCF.Items, 'value', tCF.Sel, 'max', tMax, 'userdata', 'Chart' );
		else
			set( tILBH, 'string', {}, 'value', [], 'max', 1, 'userdata', 'Chart' );
		end
		set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
	end

	function mrCG_Pivot_Chart_Pivot_pushbutton_CB( tH, tE )
		gIsPivotOn = true;
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		set( tILBH, 'value', gChartL.Sel, 'string', gChartL.Items, 'max', 2, 'userdata', 'Chart' );
		set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
	end

	function mrCG_Pivot_Options_listbox_CB( tH, tE )
		gIsPivotOn = false;
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		gOptL.Sel = get( tH, 'value' );
		if ~isempty( gOptL.Sel )
			tOFNm = gOptL.Items{ gOptL.Sel };
			tOF = gOptFs.(tOFNm);
			tMax = 2;
			if strcmp( tOF.Dim, 'sOpt' ), tMax = 1; end
			set( tILBH, 'string', tOF.Items, 'value', tOF.Sel, 'max', tMax, 'userdata', 'Options' );
		else
			set( tILBH, 'value', [], 'string', {}, 'max', 1 );
		end
		if IsOptSelUserDefined( tOFNm )
			set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', GetOptSel( tOFNm ), 'enable', 'on' );
		else
			set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
		end
	end

	function mrCG_Pivot_Options_Pivot_pushbutton_CB( tH, tE )
		gIsPivotOn = true;
		tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		set( tILBH, 'string', gOptL.Items, 'value', gOptL.Sel, 'max', 2, 'userdata', 'Options' );
		set( findtag( 'mrCG_Pivot_Items_UserDefined_edit' ), 'string', '', 'enable', 'off' );
	end

	function mrCG_Pivot_Items_listbox_CB( tH, tE )
		tListBoxName = get( tH, 'userdata' );
		switch tListBoxName
			case 'Chart'
				tNCmps = numel( gChartFs.(gDFs.cmp).Sel );
				if gIsPivotOn
					gChartL.Items = get( tH, 'string' );
					UpdateChartListBox;
				else
					tFNm = gChartL.Items{ gChartL.Sel };
					gChartFs.(tFNm).Items = get( tH, 'string' );
					gChartFs.(tFNm).Sel = get( tH, 'value' );
					if strcmp( tFNm, 'Sbjs' ), ResolveSbjROIs; end
					UpdateChartListBox;
				end
				if tNCmps ~= numel( gChartFs.(gDFs.cmp).Sel ), UpdateOptionsListBox; end % for color management
			case 'Options'
				if gIsPivotOn
					gOptL.Items = get( tH, 'string' );
					UpdateOptionsListBox;
				else
					tFNm = gOptL.Items{ gOptL.Sel };
					gOptFs.(tFNm).Items = get( tH, 'string' );
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

	function mrCG_Pivot_Items_UserDefined_edit_CB( tH, tE )
		tPILBH = findtag( 'mrCG_Pivot_Items_listbox' );
		tList = get( tPILBH, 'string' );
		iUD = strmatch( 'UsrDef: ', tList );
		tList{ iUD } = [ 'UsrDef: ' get( tH, 'string' ) ];
		set( tPILBH, 'string', tList );
		mrCG_Pivot_Items_listbox_CB( tPILBH, tE )
	end

	function UpdateChartListBox
		tChartList = {};
% 		gDF = [];
		gDFs.page = {};
		gDFs.row = gChartL.Items{1};
		gDFs.col = gChartL.Items{2};
		gDFs.cmp = gChartL.Items{3};
		gDFs.page = gChartL.Items(4:end);
		for iF = 1:numel( gChartL.Items )
			tFNm = gChartL.Items{ iF }; % get each chart field name
			tDimNm = 'page';
			if iF < 4
				tDimNms = { 'row' 'col' 'cmp' };
				tDimNm = tDimNms{ iF };
			end
			gChartFs.(tFNm).Dim = tDimNm;
			if strcmp( tDimNm, 'page' ) && ~strcmp( tFNm, 'Sbjs' ) % Sbjs can be page and multi or All.
				if ~isempty( gChartFs.(tFNm).Sel )
					gChartFs.(tFNm).Sel = gChartFs.(tFNm).Sel( 1 ); % when when changing to page field, take first item.
				end
			end
			tItemSel = gChartFs.(tFNm).Items( gChartFs.(tFNm).Sel );
			tIsSbjAll = strcmp( tFNm, 'Sbjs' ) && numel( tItemSel ) == numel( gChartFs.Sbjs.Items );
			if tIsSbjAll, tItemSel = { 'All' }; end % For 'All' Sbjs.
			tChartList{ iF } = [ tDimNm ': ' tFNm ': ' sprintf( '%s,', tItemSel{:} ) ];
			tChartList{ iF } = tChartList{ iF }( 1:(end-1) );
		end
		set( findtag( 'mrCG_Pivot_Chart_listbox' ), 'string', tChartList );
	end

	function UpdateOptionsListBox
		gOptFs.Colors.Sel = 1:numel( gChartFs.(gDFs.cmp).Sel );
		tOptionsList = {};
		for iF = 1:numel( gOptL.Items )
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

	function ManageListBoxSelection_CB( tH, tE )
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
% 					tiNewSel = tiSel(1) + ( 0:( tNSel - 1 ) )';
					tiNewSel = ( tiSel(1) : ( tiSel(1) + tNSel - 1 ) )';
				else % contiguous, promote by one
					if min( tiSel ) > 1
						tiNewSel = tiSel - 1;
					end
				end
			case 'Down'
				if any( diff( tiSel ) > 1 ) % non-contiguous, squeeze down
% 					tiNewSel = tiSel(end) - ( ( tNSel - 1 ):-1:0 )';
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
		mrCG_Pivot_Items_listbox_CB( tLBH, [] );
	end

	function ResolveSbjROIs
		% find the intersection of ROIs wrt sbjs
		tSbjNms = gChartFs.Sbjs.Items( gChartFs.Sbjs.Sel );
		tNewROIItems = gSbjROIs.( tSbjNms{ 1 } ); % ROI names shared in common; start with 1st sbj.
		for iSbj = 2:numel( tSbjNms )
			tSbjROINms = gSbjROIs.( tSbjNms{ iSbj } );
			tiROIs = [];
			for iROI = 1:numel( tNewROIItems )
				% drop ROIs not shared by the current sbj
				if ~AnyStrMatch( tNewROIItems{ iROI }, tSbjROINms, 'exact' )
% 				if ~any( strcmpi( tNewROIItems{ iROI }, tSbjROINms ) )
					continue;
				end
				tiROIs( end + 1 ) = iROI;
			end
			tNewROIItems = tNewROIItems( tiROIs );
		end
		% determine new selection by identifing which of the old ROIs occur in the new set.
		tOldROISel =  gChartFs.ROIs.Items( gChartFs.ROIs.Sel );
		tNewSel = [];
		for iROI = 1:numel( tNewROIItems )
			if AnyStrMatch( tNewROIItems{ iROI }, tOldROISel, 'exact' )
% 			if any( strcmpi( tNewROIItems{ iROI }, tOldROISel ) )
				tNewSel( end + 1 ) = iROI;
			end
		end
% 		if isempty( tNewSel ) && ~isempty( tNewROIItems ), tNewSel = 1; end
		gChartFs.ROIs.Items = tNewROIItems;
		gChartFs.ROIs.Sel = tNewSel;
	end

	function ClearChartFItems( tFNm )
		gChartFs.(tFNm).Items = {};
		gChartFs.(tFNm).Sel = [];
	end

	function tSensMtgNm = GetSensMtgNm
		for iMtg = 1:numel( gChartFs.Mtgs.Items )
			tSensMtgNm = gChartFs.Mtgs.Items{ iMtg };
			if ~strcmp( tSensMtgNm, 'ROI' ), break; end,
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
		tIsOptLastPivot = strcmpi( get( findtag( 'mrCG_Pivot_Items_listbox' ), 'userdata' ), 'Options' );
		tIsOptInItems = tIsOptLSel && tIsOptLastPivot && ~gIsPivotOn;
		if tIsOptInItems
			set( tILBH, 'value', tSel );
			mrCG_Pivot_Items_listbox_CB( tILBH, [] );
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

% 	function tIsChartSel = IsChartSel( aChartName, aChartValue ), tIsChartSel = strcmp( GetChartSel( aChartName ), aChartValue ); end


%% NewProject
	function NewProject( tH, tED )
	
		SetMessage( 'Browse to new project folder...' );
		
		if ischar( gProjPN ) && ~isempty( dir( gProjPN ) )
			gProjPN = uigetdir( gProjPN );
		else
			gProjPN = uigetdir;
		end
		if gProjPN == 0, return; end

		tDlm = filesep;
		if ispc, tDlm = '\\'; end % needs escape character for textscan
		tTok = textscan( gProjPN, '%s', 'delimiter', tDlm );
		set( findtag( 'mrCG_Project_text' ), 'string', tTok{ 1 }{ end } );

		% reinitialize all these...
		gD = [];
		gVEPInfo = [];
		gCndFiles = [];
		gSbjROIFiles = [];
		gSbjROIs = [];
		gCurs = [];
		ClearChartFItems( 'Sbjs' );
		ClearChartFItems( 'Invs' );
		ClearChartFItems( 'Mtgs' );
		ClearChartFItems( 'Cnds' );
		ClearChartFItems( 'ROIs' );
		ClearChartFItems( 'Comps' );
		ClearChartFItems( 'Flts' );
		
		% start drilling...
		tSbjFolds = dir( gProjPN ); % this will have both icky and nice sbj folder names.
		tNSbjFolds = numel( tSbjFolds ); % total of both icky and nice
		t1stSbj = true;
		for iSbjFold = 1:tNSbjFolds
			if tSbjFolds( iSbjFold ).name(1) == '.' || ~tSbjFolds( iSbjFold ).isdir, continue; end % skip over icky folder names and SbjROINames.mat.
			tSbjNm = tSbjFolds( iSbjFold ).name;
			gChartFs.Sbjs.Items{ end + 1 } = tSbjNm;
			GetSbjROIFiles; % do this here so we can later add error catch.
			if t1stSbj % drill into project data heirarchy; Note that "if t1stSbj" assumes perfect uniformity across sbjs.
				t1stSbj = false;
				% now drill in using the same steps as above to get inverses, montages, and condition data...
% 				tMtgFolds = dir( [ gProjPN filesep tSbjNm ] );
				tMtgFolds = dir( fullfile( gProjPN, tSbjNm ) );
				tNMtgFolds = numel( tMtgFolds );
				t1stMtg = true;
				for iMtgFold = 1:tNMtgFolds
					if tMtgFolds( iMtgFold ).name(1) == '.' || ~tMtgFolds( iMtgFold ).isdir, continue; end % skip icky folder names
					tMtgNm = tMtgFolds( iMtgFold ).name;
					gChartFs.Mtgs.Items{ end + 1 } = tMtgNm;
					if t1stMtg
						t1stMtg = false;
						ManageCndNames; % this is new, and replaces...
					end
					if strcmp( tMtgNm, 'ROI' )
% 						tInvFiles = dir( [ gProjPN filesep tSbjNm filesep tMtgNm filesep '*.inv' ] );
						tInvFiles = dir( fullfile( gProjPN, tSbjNm, tMtgNm, '*.inv' ) );
						tNInvFiles = numel( tInvFiles );
						for iInvFile = 1:tNInvFiles
							if tInvFiles( iInvFile ).name(1) == '.', continue; end % skip icky file names
							tInvNm = tInvFiles( iInvFile ).name(1:(end-4));
							gChartFs.Invs.Items{ end + 1 } = tInvNm;
						end
					end
				end
			end
		end
		gChartFs.Sbjs.Sel = 1:numel( gChartFs.Sbjs.Items );
		gChartFs.Cnds.Sel = 1;
		gChartFs.Mtgs.Sel = 2;
		gChartFs.Invs.Sel = 1;
		
		gOptFs.Cortex.Items = cat( 2, { 'none' }, gChartFs.Sbjs.Items );
		gOptFs.Cortex.Sel = 1;
		
		SetMessage( 'New project opened; configure pivot controls and click NewPlot to load data' );
		LoadData;
		CreateROIMtgData; % Create new mtg data if not already created by LoadData.
		ConfigureROIMtgs;
		mrCG_Pivot_Chart_listbox_CB( findtag( 'mrCG_Pivot_Chart_listbox' ), [] );
		mrCG_Pivot_Items_listbox_CB( findtag( 'mrCG_Pivot_Items_listbox' ), [] );
		UpdateOptionsListBox;

		function GetSbjROIFiles
			tSbjROIFilesPFN = fullfile( gProjPN, tSbjNm, 'ROI', 'SbjROIFiles.mat' );
			if ~isempty( dir( tSbjROIFilesPFN ) )
				load( tSbjROIFilesPFN ); % loads variable 'tSbjROINms'
			else
				tAllROIFiles = dir( fullfile( GetSbjROIsPN( tSbjNm ), '*.mat' ) );
				if isempty( tAllROIFiles )
					SetError( [ GetSbjROIsPN( tSbjNm ) ' does not exist.' ] );
					disp( [ GetSbjROIsPN( tSbjNm ) ' does not exist.' ] );
					error( [ GetSbjROIsPN( tSbjNm ) ' does not exist.' ] );
				end
				tSbjROIFiles = {};
				for iFile = 1:numel( tAllROIFiles )
					if tAllROIFiles( iFile ).name(1) ~= '.'
						tSbjROIFiles{ end + 1 } = tAllROIFiles( iFile ).name;
					end
				end
				if isempty( tSbjROIFiles )
					SetError( [ GetSbjROIsPN( tSbjNm ) ' has no mat-files.' ] );
					disp( [ GetSbjROIsPN( tSbjNm ) ' has no mat-files.' ] );
					error( [ GetSbjROIsPN( tSbjNm ) ' has no mat-files.' ] );
				end
				save( tSbjROIFilesPFN, 'tSbjROIFiles' );
			end
			gSbjROIFiles.(tSbjNm) = tSbjROIFiles;
		end

		function ManageCndNames
			% this should only be called for first sbj and first mtg
			tIsCndNamesChanged = false;
			tCndNamesFileNm = fullfile( gProjPN, 'CndFiles.mat' );
			if ~isempty( dir( tCndNamesFileNm ) )
				load( tCndNamesFileNm, 'tCndFileNames' ); % initialize tCndFileNames from file
			else
				% initialize tCndFileNames by looping over dir '*.mat'
				tCndFiles = dir( [ gProjPN filesep tSbjNm filesep tMtgNm filesep '*.mat' ] );
				tNCndFiles = numel( tCndFiles );
				for iCndFile = 1:tNCndFiles
					if tCndFiles( iCndFile ).name(1) == '.', continue; end % skip icky file names
					 % use name of .mat file as default condition name; we must strip extension
					 % to make it a valid field name string, so be sure to append extension when you
					 % use the name for file loading/saving.
					tCndFileNm = tCndFiles( iCndFile ).name(1:(end-4));
					tCndFileNames.(tCndFileNm) = tCndFileNm; % use name of .mat file as default condition name
				end
				tIsCndNamesChanged = true; % to ensure this new info is saved below
			end
			% prompt for any changes
			tOldCndNames = fieldnames( tCndFileNames ); 
			tNewCndNames = inputdlg( tOldCndNames, 'Enter new Cnd names', 1, tOldCndNames );
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
			gChartFs.Cnds.Items = tNewCndNames;
			gCndFiles = tCndFileNames; % (re)initialize global variable
			% Now LoadData may use gCndFiles to obtain correct data from each file.
		end

%% -- LoadData
		function LoadData
			for iCnd = 1:numel( gChartFs.Cnds.Items )
				% Start by getting VEPinfo and harmonic component item subscripts
				tCndNm = gChartFs.Cnds.Items{ iCnd };
				SetMessage( [ 'Loading file data for ' tCndNm '...' ] );
				% to construct path to sens mtg cnd data file for 1st sbj
				% and get VEP info to
				% construct subscripts for harmonic components.
% 				tPFN = fullfile( gProjPN, gChartFs.Sbjs.Items{ 1 }, GetSensMtgNm, [ tCndNm '.mat' ] );
				tPFN = fullfile( gProjPN, gChartFs.Sbjs.Items{ 1 }, GetSensMtgNm, [ gCndFiles.(tCndNm) '.mat' ] );
				gVEPInfo.(tCndNm) = load( tPFN, 'dFHz', 'dTms', 'i1F1', 'i1F2', 'nFr', 'nT' ); % VEP info data
				gVEPInfo.(tCndNm).nFr = gVEPInfo.(tCndNm).nFr - 1;
				if iCnd == 1
					gChartFs.Comps.Items = GetComp( 'getcomplist' );
					gChartFs.Comps.Sel = 1;
					gCompFieldNms = TranslateCompNames( gChartFs.Comps.Items );
					gChartFs.Flts.Items = GetFilter( 'getfilterlist' );
					gChartFs.Flts.Sel = 1;
				end
				for iComp = 1:numel( gChartFs.Comps.Items ), tiComp( iComp ) = GetComp( gChartFs.Comps.Items{ iComp }, gVEPInfo.(tCndNm) ); end
				% set up data structures for sbjs and mtgs in project folders
				for iSbj = 1:numel( gChartFs.Sbjs.Items )
					tSbjNm = gChartFs.Sbjs.Items{ iSbj };
					for iMtg = 1:numel( gChartFs.Mtgs.Items )
						tSensMtgNm = GetSensMtgNm;
						tPFN = fullfile( gProjPN, tSbjNm, tSensMtgNm, [ gCndFiles.(tCndNm) '.mat' ] );
						tVEP = load( tPFN, 'Wave', 'Sin', 'Cos' ); % VEP data
						tNCh = size( tVEP.Wave, 2 );
						if tNCh > 128, tNCh = 128; end
						gD.(tSbjNm).(tCndNm).(tSensMtgNm).Wave.( 'none' ) = tVEP.Wave( :, 1:tNCh );
						gD.(tSbjNm).(tCndNm).(tSensMtgNm).Spec = tVEP.Cos( 2:end, 1:tNCh ) + tVEP.Sin( 2:end, 1:tNCh ) * i;
						for iComp = 1:numel( gChartFs.Comps.Items )
							gD.(tSbjNm).(tCndNm).(tSensMtgNm).Harm.( gCompFieldNms{ iComp } ) = ...
								gD.(tSbjNm).(tCndNm).(tSensMtgNm).Spec( tiComp( iComp ), : );
						end
						for iInv = 1:numel( gChartFs.Invs.Items )
							tInvNm = gChartFs.Invs.Items{ iInv };
% 							tPFN = fullfile( gProjPN, tSbjNm, 'ROI', tInvNm, [ tCndNm '.mat' ] );
							tPFN = fullfile( gProjPN, tSbjNm, 'ROI', tInvNm, [ gCndFiles.(tCndNm) '.mat' ] );
							if( ~isempty( dir( tPFN ) ) ) % Newbie sbjs might not have ROI mtgs yet...
								tVEP = load( tPFN, 'Wave', 'Sin', 'Cos' ); % VEP data
								tNCh = size( tVEP.Wave, 2 );
								if tNCh > 128, tNCh = 128; end
								gD.(tSbjNm).(tCndNm).('ROI').(tInvNm).Wave.( 'none' ) = tVEP.Wave( :, 1:tNCh );
								gD.(tSbjNm).(tCndNm).('ROI').(tInvNm).Spec = tVEP.Cos( 2:end, 1:tNCh ) + tVEP.Sin( 2:end, 1:tNCh ) * i;
								for iComp = 1:numel( gChartFs.Comps.Items )
									gD.(tSbjNm).(tCndNm).('ROI').(tInvNm).Harm.( gCompFieldNms{ iComp } ) = ...
										gD.(tSbjNm).(tCndNm).('ROI').(tInvNm).Spec( tiComp( iComp ), : );
								end
							end
						end
					end
				end
			end
			gCurs = struct( 'Wave', struct( 'StepX', gVEPInfo.(tCndNm).dTms ), 'Spec', struct( 'StepX', gVEPInfo.(tCndNm).dFHz ) );
			SetMessage( 'Done loading file data' );
		end

%% -- CreateROIMtgData
		function CreateROIMtgData
			% Check for ROI mtgs for each Inv and Sbj.  If it doesn't exist, create it,
			% and save it out for posterity.  Should test each sbj, in case of a newbie.
			% If all ROI data folders have already been created, nothing happens.
			% We don't follow exact order of tD data heirarchy, because we only
			% want to load the inverse once per sbj.
			tSensMtgNm = GetSensMtgNm;
			for iSbj = 1:numel( gChartFs.Sbjs.Items )
				tSbjNm = gChartFs.Sbjs.Items{ iSbj };
				tSbjROIsPN = GetSbjROIsPN( tSbjNm );
				tNROIs = numel( gSbjROIFiles.(tSbjNm) );
				for iInv = 1:numel( gChartFs.Invs.Items )
					tInvNm = gChartFs.Invs.Items{ iInv };
					if isfield( gD.(tSbjNm).(gChartFs.Cnds.Items{1}), 'ROI' ) ...
							&& isfield( gD.(tSbjNm).(gChartFs.Cnds.Items{1}).ROI, tInvNm )
						continue;
					else % create ROI Mtg data for this sbj and inv
						% Load sbj's inverse
						SetMessage( [ 'Creating ROI data for ' tSbjNm ' ' tInvNm ] );
						tMtgPN = fullfile( gProjPN, tSbjNm, 'ROI' );
						tInvPN = fullfile( tMtgPN, tInvNm );
						tInvM = ReadInverse( fullfile( tMtgPN, [ tInvNm '.inv' ] ) )';
						[ tNCh, tNV ] = size( tInvM );
						% Build an inverver matrix using variables set by GetSbjROIFiles.
						tInvtr = [];
						for iROI = 1:tNROIs
							tROIPFN = fullfile( tSbjROIsPN, gSbjROIFiles.(tSbjNm){ iROI } );
							tROISS = unique( getfield( getfield( load( tROIPFN ), 'ROI' ), 'meshIndices' ) );
							tROISS = tROISS( tROISS ~= 0 );
							tInvtr( :, iROI ) = mean( tInvM( :, tROISS ), 2 )  * 1e6; % convert to pAmp/mm2; 
						end
						% Apply inverter to sensor data to get ROI data
						for iCnd = 1:numel( gChartFs.Cnds.Items )
							tCndNm = gChartFs.Cnds.Items{ iCnd };
							gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.( 'none' ) = ...
								gD.(tSbjNm).(tCndNm).(tSensMtgNm).Wave.( 'none' ) * tInvtr;
							gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec = ...
								gD.(tSbjNm).(tCndNm).(tSensMtgNm).Spec * tInvtr;
							for iComp = 1:numel( gChartFs.Comps.Items )
								gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Harm.( gCompFieldNms{ iComp } ) = ...
									gD.(tSbjNm).(tCndNm).(tSensMtgNm).Harm.( gCompFieldNms{ iComp } ) * tInvtr;
							end
							% Save ROI data into project folder using PowerDIVA conventions.
							dFHz = gVEPInfo.(tCndNm).dFHz;
							dTms = gVEPInfo.(tCndNm).dTms;
							i1F1 = gVEPInfo.(tCndNm).i1F1;
							i1F2 = gVEPInfo.(tCndNm).i1F2;
							nFr = gVEPInfo.(tCndNm).nFr;
							nT = gVEPInfo.(tCndNm).nT;
							Wave = gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.( 'none' );
							% As per PowerDIVA convention, spectral parts must be padded with a leading row for zero DC;
							% that way, subsequent LoadData calls can use the same algorithm for ROI and Sensor Mtgs.
							Cos = cat( 1, zeros( 1, tNROIs ), real( gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec ) );
							Sin = cat( 1, zeros( 1, tNROIs ), imag( gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec ) );
							if isempty( dir( [ tInvPN ] ) ), mkdir( tInvPN ); end
							save( fullfile( tInvPN, [ gCndFiles.(tCndNm) '.mat' ] ), 'dFHz', 'dTms', 'i1F1', 'i1F2', 'nFr', 'nT', 'Wave', 'Cos', 'Sin' );
							clear( 'dFHz', 'dTms', 'i1F1', 'i1F2', 'nFr', 'nT', 'Wave', 'Cos', 'Sin' );
						end
					end
					if ~AnyStrMatch( 'ROI', gChartFs.Mtgs.Items, 'exact' ), gChartFs.Mtgs.Items{ end + 1 } = 'ROI'; end
				end
			end
			SetMessage( [ 'Done Creating ROI Data' ] );
		end

%% -- ConfigureROIMtgs
		function ConfigureROIMtgs
			% reconfigure raw loaded data for ROI mtgs into named struct fields.
			% Allow sbjs to have MRI-history-dependent ROI mtgs, encoded by gSbjROIFiles(tSbjNm).
			% construct bilateral ROIs here
			SetMessage( [ 'Configuring ROI Mtgs...' ] );
			for iSbj = 1:numel( gChartFs.Sbjs.Items )
				tSbjNm = gChartFs.Sbjs.Items{ iSbj };
	% 			gSbjROIFiles.(tSbjNm) = getfield( load( [ gProjPN filesep tSbjNm filesep 'SbjROINames.mat' ] ), 'tSbjROINms' );
				tNROIs = numel( gSbjROIFiles.(tSbjNm) );
				for iCnd = 1:numel( gChartFs.Cnds.Items )
					tCndNm = gChartFs.Cnds.Items{ iCnd };
					% copy and delete existing raw ROI data fields
					% and make temp variables for holding new hemispheric ones.
					for iInv = 1:numel( gChartFs.Invs.Items )
						tInvNm = gChartFs.Invs.Items{ iInv };
						tWaveNone = gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.( 'none' );
						gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.( 'none' ) = []; 
						tWaveNoneHem = [];
						tSpec = gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec;
						gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec = [];
						tSpecHem = [];
						tComps = gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Harm;
						gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Harm = [];
						tCompsHem = [];
						for iROI = 1:tNROIs
							tROINm = gSbjROIFiles.(tSbjNm){ iROI };
							tHemNm = tROINm( end-4 );
							if tHemNm == 'L', tHemNm = 'Left'; else tHemNm = 'Right'; end
							tROINm = tROINm( 1:(end-6) );
							tROINm = strrep( tROINm, '-' ,'_' ); % field name can't have dash
							tWaveNoneHem.(tHemNm).(tROINm) = tWaveNone( :, iROI );
							tSpecHem.(tHemNm).(tROINm) = tSpec( :, iROI );
							for iComp = 1:numel( gChartFs.Comps.Items )
								tCompNm = gCompFieldNms{ iComp };
								tCompsHem.(tCompNm).(tHemNm).(tROINm) = tComps.(tCompNm)( iROI );
							end
						end
						% Now repeat loop to compute Bilat
						tLROINms = fieldnames( tWaveNoneHem.Left );
						tNLROIs = numel( tLROINms );
						for iLROI = 1:tNLROIs
							tROINm = tLROINms{ iLROI };
							tWaveNoneHem.Bilat.(tROINm) = 0.5 * ( tWaveNoneHem.Left.(tROINm) + tWaveNoneHem.Right.(tROINm) );
							tSpecHem.Bilat.(tROINm) = 0.5 * ( tSpecHem.Left.(tROINm) + tSpecHem.Right.(tROINm) );
							for iComp = 1:numel( gChartFs.Comps.Items )
								tCompNm = gCompFieldNms{ iComp };
								tCompsHem.(tCompNm).Bilat.(tROINm) = ...
									0.5 * ( tCompsHem.(tCompNm).Left.(tROINm) + tCompsHem.(tCompNm).Right.(tROINm) );
							end
							gSbjROIs.(tSbjNm){iLROI} = tROINm;
						end
						% Reset gSbjROIFiles.(tSbjNm) = fieldnames(...)?
						gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.( 'none' ) = tWaveNoneHem;
						gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec = tSpecHem;
						gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Harm = tCompsHem;
					end
				end
			end
			ResolveSbjROIs;
			gChartFs.ROIs.Sel = 1;
			SetMessage( [ 'Done Configuring ROI Mtgs' ] );
		end

	end

%% Plotting
%% -- New & Replace
	function PivotPlot_CB( tH, tED )
		tDomain = GetDomain; % sets outer scope for nested functions that handle plot domain
		tPPFigTag = [ 'PPFig_' tDomain ];
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
		% set colormap, buttondownfcn
		tColorOrderMat = PPFig_ColorOrderMat; % this gets set to figure, and reused extensively below.
		set( tFigH, 'defaultaxescolororder', tColorOrderMat, 'WindowButtonDownFcn', @mrCG_SetPlotFocus_CB );
		
		% store gui state info
		tUD.gChartFs = gChartFs; % structure of chart fields
		tUD.gChartL = gChartL;
		tUD.gOptFs = gOptFs; % structure of option fields
		tUD.gOptL = gOptL;
		tUD.gIsPivotOn = gIsPivotOn;
		tUD.Pivot_Items_listbox_userdata = get( findtag( 'mrCG_Pivot_Items_listbox' ), 'userdata' );

		% everything else
		tFNms = gChartL.Items;
		tNFs = numel( tFNms );
		tSbjNms = GetChartSels( 'Sbjs' );
		tRowNms = GetChartSels( gDFs.row );
		tColNms = GetChartSels( gDFs.col );
		tCmpNms = GetChartSels( gDFs.cmp );
		tNSbjs = numel( tSbjNms );
		tNRows = numel( tRowNms );
		tNCols = numel( tColNms );
		tNCmps = numel( tCmpNms );
% 		tDomain = GetDomain;
		tIsUniformWave = true; % false when comparing "non-uniform" waveforms generated by non-commensurate filters.
		tFltRC = []; % structure for filter repeat cycles when tIsUniformWave == false;
					% external scope here, set by nested function SetFilterRepeatCycles.
% 		tColorOrderMat = PPFig_ColorOrderMat;
		gY = [];
		gPM = [];
		gPM.page = {};
		tNT = [];
		tX = [];
		if IsWavePlot
			SetFilteredWaveforms( tH, tED );
			SetFilterRepeatCycles;
		end
		% outer loop over sbjs because they have special behavior when page.
		for iSbj = 1:tNSbjs
			% loop over plot dimensions to create entry, tY, for the multi-D data matrix, gY, for this chart.
			for iRow = 1:tNRows
				for iCol = 1:tNCols
					for iCmp = 1:tNCmps,
						% loop over chart fields to generate map, tFN, of gD field names that will retrieve tY.
						for iF = 1:tNFs
							tFNm = tFNms{ iF };
							if strcmp( tFNm, 'Sbjs' ) && IsSbjPage, tFN.Sbjs = tSbjNms{ iSbj }; continue; end
							switch gChartFs.(tFNm).Dim
								case 'row', tFN.(tFNm) = tRowNms{ iRow };
								case 'col', tFN.(tFNm) = tColNms{ iCol };
								case 'cmp', tFN.(tFNm) = tCmpNms{ iCmp };
								case 'page', tFN.(tFNm) = GetChartSel( tFNm );
							end
							if strcmp( tFNm, 'Comps' ), tFN.(tFNm) = TranslateCompName( tFN.(tFNm) ); end
						end
						switch tDomain % for readability, we use temporary variable tYT to hold the data from this pass through the loop.
							case { '2DPhase', 'Bar' }
								tYT = gD.(tFN.Sbjs).(tFN.Cnds).ROI.(tFN.Invs).Harm.(tFN.Comps).(tFN.Hems).(tFN.ROIs);
							case 'Wave'
								tYT = gD.(tFN.Sbjs).(tFN.Cnds).ROI.(tFN.Invs).Wave.(tFN.Flts).(tFN.Hems).(tFN.ROIs);
								if ~tIsUniformWave, tYT = repmat( tYT, tFltRC.(tFN.Flts), 1 ); end
							case 'Spec'
								tYT = gD.(tFN.Sbjs).(tFN.Cnds).ROI.(tFN.Invs).Spec.(tFN.Hems).(tFN.ROIs);
						end
						% now set the particular item in the data matrix
						if IsSbjPage
							% Sbjs as page may have multiple items that we must keep
							% explicit so we can compute dispersion stats...
							gY( iRow, iCol, iCmp, iSbj, : ) = tYT;
						else
							gY( iRow, iCol, iCmp, : ) = tYT;
						end
					end
				end
			end
		end
		for iF = 1:tNFs
			tFNm = tFNms{ iF };
			tItemSel = GetChartSels( tFNm );
			if strcmp( tFNm, 'Sbjs' ) && numel( tItemSel ) == numel( gChartFs.Sbjs.Items ), tItemSel = { 'All' }; end % For 'All' Sbjs.
			if strcmp( gChartFs.(tFNm).Dim, 'page' )
				gPM.page{ end + 1 } = tItemSel{1};
			else
				gPM.( gChartFs.(tFNm).Dim ) = tItemSel;
			end
		end

		tFigNm = sprintf( '%s,', gPM.page{ : } );
		tFigNm = tFigNm( 1:(end-1) );
		set( findtag( tPPFigTag ), 'Name', tFigNm )

		% now do plotting loop
		gSPHs = [];
		tSPRows = tNRows;
		if IsOffsetPlot
			% these are used by both plotting and formatting fxns, so we init them here for outer scope.
			tOffset =[];
			tOffsets = [];
			tSPRows = 1;
		end
		for iRow = 1:tNRows
			if iRow > tSPRows, break; end; 
			for iCol = 1:tNCols
				gSPHs( iRow, iCol ) = subplot( tSPRows, tNCols, ( iRow - 1 ) * tNCols + iCol );
				set( gSPHs( iRow, iCol ), 'nextplot', 'replacechildren' );
				for iCmp = 1:tNCmps
					switch tDomain
						case 'Wave',	Wave_Plot; Wave_Format;
						case '2DPhase', TwoDPhase_Plot; TwoDPhase_Format;
						case 'Bar',		Bar_Plot; Bar_Format;
						case 'Spec',	Spec_Plot; Spec_Format;
					end
				end
			end
		end
		
		if IsOffsetPlot
			tUD.Cursor = gCurs.( tDomain );
		end
		set( tFigH, 'userdata', tUD );
		UpdateCursorEditBoxes;
		SetMessage( 'Done Plotting' );

		function SetFilterRepeatCycles
			tFltNms = GetChartSels( 'Flts' );
			tNFlts = numel( tFltNms );
			if tNFlts > 1
				% note that GetChartSel(...) returns a string that is first selected item
				tWave = gD.(GetChartSel('Sbjs')).(GetChartSel('Cnds')).ROI.(GetChartSel('Invs')).Wave;
				for iFlt = 1:tNFlts
					tFltNm = tFltNms{ iFlt };
					tWL( iFlt ) = size( tWave.(tFltNm).(GetChartSel('Hems')).(GetChartSel('ROIs')), 1 ); % wavelength
				end
				if any( diff( tWL ) )
					% if filters don't match
					tIsUniformWave = false;
					for iFlt = 2:tNFlts, tWLLCM( 1:iFlt ) = lcm( tWL( iFlt ), tWL( iFlt-1 ) ); end % cumulative wavelength least common multiple.
					for iFlt = 1:tNFlts, tFltRC.(tFltNms{ iFlt }) = tWLLCM( iFlt ) / tWL( iFlt ); end % repeat cycles for each filter.
					tNT = tWLLCM( 1 );
				else
					tNT = tWL( 1 );
				end
			else
				tNT = size( gD.(GetChartSel('Sbjs')).(GetChartSel('Cnds')).ROI.(GetChartSel('Invs'))...
					.Wave.(GetChartSel('Flts')).(GetChartSel('Hems')).(GetChartSel('ROIs')), 1 );
			end
		end
		
%% Plot_Fxns
%% -- Wave
		function Wave_Plot
% 			tIsMean = AnyStrMatch( 'Mean', tData, 'exact' );
			if iCmp == 1
				SetOffsets; % Sets Offsets, tX, and Cursor data
				line( tX( [ 1; end ] ), [ tOffset; tOffset ], 'color', [ 0 0 0 ] ) %, 'linestyle', ':' );
			end
			tY = shiftdim( gY( :, iCol, iCmp, :, : ), 1 ); % now  Col, Cmp, (Sbj,) T, Row
			tY = shiftdim( tY, 2 ); % now (Sbj,) T, Row
			if ~IsSbjPage || tNSbjs == 1
				if tNSbjs == 1, tY = shiftdim( tY ); end
				% if sbj is row col or cmp, or singleton, it gets
				% removed by "shiftdim( tY, 2 )", so we can't do
				% anything but plot tY
				line( tX, tY + tOffsets, 'color', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
			else
				% multi-subject page allows for all kinds of options...
				tYM = shiftdim( mean( tY ), 1 ); % now Time x Cmp
				line( tX, tYM + tOffsets, 'color', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
				if IsAnyOptSel( 'Stats', 'Dispersion' )
					tXP = cat( 1, tX, flipud( tX ) ); % tX for patch
% 					tYSEM = shiftdim( std( tY ) / sqrt( tNSbjs - 1 ), 1 ); % now Time x Cmp
					if IsOptSel( 'DisperScale', 'SEM' )
						tNormK = 1 / (tNSbjs-1);
					else % 95% CI, note how this differs from 2D-phase version, since we project into 1-D.
						tNormK = (tNSbjs-1)/tNSbjs/(tNSbjs-1) * finv( 0.95, 1, tNSbjs - 1 );
					end
					tYSEM = shiftdim( std( tY ) * sqrt( tNormK ), 1 ); % now Time x Cmp
					for iRD = 1:tNRows % iRowDispersion
						tYP = cat( 1, tYM( :, iRD ) + tYSEM( :, iRD ) + tOffsets( :, iRD ), flipud( tYM( :, iRD ) - tYSEM( :, iRD ) + tOffsets( :, iRD ) ) );
						if IsOptSel( 'Patches', 'on' )
							patch( tXP, tYP, tColorOrderMat( iCmp, : ), 'facealpha', 0.25, 'linestyle', 'none' );
						else
							line( tXP, tYP, 'color', tColorOrderMat( iCmp, : ), 'linestyle', ':' );
						end
					end
				end
			end
			
			function SetOffsets
				tCndNms = GetChartSels( 'Cnds' );
				tVI = gVEPInfo.( tCndNms{ 1 } );
				tX = tVI.dTms * ( 1:tNT )';
				gCurs.Wave.XData = tX;
				tOffset = GetOptSelNum( 'WaveSpacing' );
				if tNRows == 1
					tOffset = 0;
				else
					tOffset = tOffset * linspace( ( tNRows - 1 ) / 2, -( tNRows - 1 ) / 2, tNRows );
				end
				tOffsets = repmat( tOffset, tNT, 1 );
			end
		end

%% -- Spec
		function Spec_Plot
% 			disp( sprintf( 'Plotting Spec data for panel row %d col %d cmp %d.', iRow, iCol, iCmp ) );
% 			tIsMean = AnyStrMatch( 'Mean', tData, 'exact' );
			if iCmp == 1
				SetOffsets; % Sets Offsets, tX, and Cursor data
				line( tX( [ 1; end ] ), [ tOffset; tOffset ], 'color', [ 0 0 0 ] );
			end
			tSign = 1;
			if IsOptSel( 'SpecPlotCmp', 'UpDown' ) && ~mod( iCmp, 2 ), tSign = -tSign; end
			tY = shiftdim( gY( :, iCol, iCmp, :, : ), 1 ); % now  Col, Cmp, (Sbj,) T, Row
			tY = shiftdim( tY, 2 ); % now (Sbj,) T, Row
			if ~IsSbjPage || tNSbjs == 1
				if tNSbjs == 1, tY = shiftdim( tY ); end
				% if sbj is row col or cmp, or singleton, it gets
				% removed by "shiftdim( tY, 2 )", so we can't do
				% anything but plot tY
				line( tX, [ tOffsets; tSign * abs( tY(:) )' + tOffsets ], 'color', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
			else
				% multi-subject page allows for all kinds of options...
				tYM = shiftdim( mean( tY ), 1 ); % now Time x Cmp
				line( tX, [ tOffsets; tSign * abs( tYM(:) )' + tOffsets ], 'color', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
			end
			
			function SetOffsets
				tCndNms = GetChartSels( 'Cnds' );
				tVI = gVEPInfo.( tCndNms{ 1 } );
				tX = tVI.dFHz * [ 1:tVI.nFr ]';
				gCurs.Spec.XData = tX;
				tOffset = GetOptSelNum( 'SpecSpacing' );
				tNFr = numel( tX );
				if tNRows == 1
					tOffset = 0;
				else
					tOffset = tOffset * linspace( ( tNRows - 1 ) / 2, -( tNRows - 1 ) / 2, tNRows );
				end
				tOffsets = repmat( tOffset, tNFr, 1 );
				tOffsets = reshape( tOffsets, 1, numel( tOffsets ) );
				tX = repmat( tX', 2, tNRows );
			end
		end

%% -- 2DPhase
		function TwoDPhase_Plot
			if iCmp == 1, plot( 0, 0, 'k+', 'markersize', 20 ); end % origin cross-hairs
			hold on;
			tY = shiftdim( gY( iRow, iCol, iCmp, : ) );
			if numel( tY ) == 1 % sbj is row col or cmp, or singleton page, so we can't do anything but plot tY
				line( [ 0 real(tY) ]', [ 0 imag(tY) ]', 'color', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
			else
				tRMY = real( mean(tY) );
				tIMY = imag( mean(tY) );
				line( [ 0 tRMY ]', [ 0 tIMY ]', 'color', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
				if IsAnyOptSel( 'Stats', 'Dispersion' )
					% code for this borrowed from error_ellipse.m obtained from Matlab User Community.
					if IsOptSel( 'DisperScale', 'SEM' )
						tNormK = 1 / (tNSbjs-2);
					else % 95% CI
						tNormK = (tNSbjs-1)/tNSbjs/(tNSbjs-2) * finv( 0.95, 2, tNSbjs - 2 );
					end
					[ tEVec, tEVal ] = eig( cov( [ real( tY ) imag( tY ) ] ) ); % Compute eigen-stuff
					tTh = linspace( 0, 2*pi, 30 )';
					tXY = [ cos(tTh) sin(tTh) ] * sqrt( tNormK * tEVal ) * tEVec'; % Error/confidence ellipse
					tXE = tXY(:,1);
					tYE = tXY(:,2);
					tXE = tXE + repmat( tRMY, 30, 1 ); % outer product makes 30 x tN matrix of circle coords
					tYE = tYE + repmat( tIMY, 30, 1 );
					if IsOptSel( 'Patches', 'on' )
						% patches with transparent fills look great, but Matlab throws an error when trying to save them as AI files.
						patch( tXE, tYE, tColorOrderMat( iCmp, : ), 'facealpha', .25, 'edgecolor', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
					else
						% use the following when making AI files.
						line( tXE, tYE, 'color', tColorOrderMat( iCmp, : ), 'linewidth', 2 );
					end
				end
				if IsAnyOptSel( 'Stats', 'Scatter' )
					plot( real(tY), imag(tY), 'linestyle', 'none', 'marker', '.', 'markersize', 15, ...
						'markeredgecolor', tColorOrderMat( iCmp, : ), 'markerfacecolor', tColorOrderMat( iCmp, : ) );
				end
			end
		end

%% -- Bar
		function Bar_Plot
% 			disp( sprintf( 'Plotting Bar data for panel row %d col %d.', iRow, iCol ) );
			hold on;
			tY = shiftdim( gY( iRow, iCol, iCmp, : ) );
			if numel( tY ) == 1 % sbj is row col or cmp, or singleton page, so we can't do anything but plot tY
				tYA = abs( tY );
				tXP = [ iCmp - .45 iCmp - .45 iCmp + .45 iCmp + .45 ]';
				tYP = [ 0 tYA tYA 0 ]';
				patch( tXP, tYP, tColorOrderMat( iCmp, : ), 'edgecolor', [ 0 0 0 ] );
			else
				if IsOptSel( 'BarMean', 'Coherent' )
					tYri = [ real( tY ) imag( tY ) ]'; % convert to ordinary matrix, read "ri" as "real-imag", 2xtNSbjs.
					tYM = mean( tYri, 2 );
					tYA = ( tYM' * tYri ) / sqrt( tYM' * tYM );
% 					tYACx = ( tYM * tYA ) / sqrt( tYM' * tYM ); % keep this; complex data is handy for plotting to verify/illustrate projections.
					tYM = abs( tYM(1) + tYM(2)*i );
				else
					tYA = abs( tY );
					tYM = mean( tYA );
				end
				tXMP = [ iCmp - .45 iCmp - .45 iCmp + .45 iCmp + .45 ]';
				tYMP = [ 0 tYM tYM 0 ]';
				patch( tXMP, tYMP, tColorOrderMat( iCmp, : ), 'edgecolor', [ 0 0 0 ] );
				if IsAnyOptSel( 'Stats', 'Dispersion' )
					if IsOptSel( 'DisperScale', 'SEM' )
						tNormK = 1 / (tNSbjs-1);
					else % 95% CI, note how this differs from 2D-phase version, since we project into 1-D.
						tNormK = (tNSbjs-1)/tNSbjs/(tNSbjs-1) * finv( 0.95, 1, tNSbjs - 1 );
					end
				end
				if IsAnyOptSel( 'Stats', 'Dispersion' )
					tYSE = std( tYA ) * sqrt( tNormK ); % projected SEM
					line( [ iCmp; iCmp ], [ max( [ 0; tYM - tYSE ] ); tYM + tYSE ], 'color', [ 0 0 0 ], 'linewidth', 2 ); 
				end
				if IsAnyOptSel( 'Stats', 'Scatter' )
					line( iCmp * ones( size( tYA ) ), tYA, 'color', [ 0 0 0 ], 'linestyle', 'none', 'marker', 'o' );
				end
			end
			gY( iRow, iCol, iCmp, : ) = tYA;
		end

%% Format_Fxns
%% -- All
		function All_Format
			% Handle ylim
			if numel( gSPHs ) > 1
				tYLAll = reshape( get( gSPHs, 'ylim' ), size( gSPHs ) ); % All the ylims, in cell array shaped like plot.
				tScaleBy = GetOptSel( 'ScaleBy' );
				% Default to 'All' if user tries to 'Reuse' from non-existant figure.
				if strcmp( tScaleBy, 'Reuse' ) && isempty( tOldYLim ), tScaleBy = 'All'; end
				switch tScaleBy
					case 'Rows'
						if tNCols > 1
							for iRowL =1:tSPRows
								% global ylim max for this row
								tYLMx = max( max( abs( cat( 1, tYLAll{ iRowL, : } ) ) ) );
								% determine ylim modified by this scaling option
								tYLm = [ -tYLMx tYLMx ];
								if IsOptSel( 'Domain', 'Bar' )
									tYLMn = min( min( abs( cat( 1, tYLAll{ iRowL, : } ) ) ) );
									tYLm = [ tYLMn tYLMx ];
								end
								set( gSPHs( iRowL, : ), 'ylim', tYLm );
								if IsOptSel( 'Domain', '2DPhase' ), set( gSPHs( iRowL, : ), 'xlim', tYLm ); end
							end
						end
					case 'Cols'
						if tSPRows > 1
							for iColL =1:tNCols
								tYLMx = max( max( abs( cat( 1, tYLAll{ :, iColL } ) ) ) );
								tYLm = [ -tYLMx tYLMx ];
								if IsOptSel( 'Domain', 'Bar' )
									tYLMn = min( min( abs( cat( 1, tYLAll{ :, iColL } ) ) ) );
									tYLm = [ tYLMn tYLMx ];
								end
								set( gSPHs( :, iColL ), 'ylim', tYLm );
								if IsOptSel( 'Domain', '2DPhase' ), set( gSPHs( :, iColL ), 'xlim', tYLm ); end
							end
						end
					case 'All'
						tYLMx = max( max( abs( cat( 1, tYLAll{:} ) ) ) );
						tYLm = [ -tYLMx tYLMx ];
						if IsOptSel( 'Domain', 'Bar' )
							tYLMn = min( min( abs( cat( 1, tYLAll{:} ) ) ) );
							tYLm = [ tYLMn tYLMx ];
						end
						set( gSPHs, 'ylim', tYLm );
						if IsOptSel( 'Domain', '2DPhase' ), set( gSPHs, 'xlim', tYLm ); end
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

%% -- Wave
		function Wave_Format
			Offset_Format;
		end

%% -- Spec
		function Spec_Format
			Offset_Format;
		end

%% -- Offset
		function Offset_Format
			title( tColNms{ iCol }, 'interpreter', 'none' );
			if iCol == tNCols && iCmp == tNCmps
				All_Format;
				tXLim = tX( [ 1 end ] );
				if IsSpecPlot
					tXLim( 1 ) = 0;
					if ~IsOptSel( 'SpecXLim', 'Max' ), tXLim( 2 ) = GetOptSelNum( 'SpecXLim' ); end
				end
				set( gSPHs( 1, : ), 'xlim', tXLim );
				tLabelFS = 12;
				axes( gSPHs( 1, end ) );
				% data units, messes up if you change xlim
				text( 1.025 * tXLim( 2 ) * ones( tNRows, 1 ), tOffset', tRowNms, 'interpreter', 'none', 'fontsize', tLabelFS, 'tag', 'rowLabel' );
				% normalized units, messes up if you change ylim
% 				tYLim = get( gSPHs( 1, end ) , 'ylim' );
% 				text( repmat(1.025,1,tNRows), (tOffset-tYLim(1))/diff(tYLim), tRowNms, 'units', 'normalized', 'interpreter', 'none', 'fontsize', tLabelFS, 'tag', 'rowLabel'  );

% 				axes( gSPHs( 1, 1 ) );
% 				tLegX = linspace( 0, tXLim( 2 ), 2 + 8 * tNCmps );
% 				tLegX = tLegX( 2:(end-1) );
% 				tYLim = ylim;
% 				tLegLineX = [ tLegX( 1:8:end ); tLegX( 2:8:end ) ];
% 				tLegLineY = 0.95 * diff(tYLim) + tYLim(1) * ones( size( tLegLineX ) );
% 				line( tLegLineX, tLegLineY );
% 				tLegTextX = tLegX( 3:8:end );
% 				tLegTextY = 0.95 * diff(tYLim) + tYLim(1) * ones( size( tLegTextX ) );
% 				text( tLegTextX, tLegTextY, tCmpNms, 'interpreter', 'none', 'fontsize', tLabelFS );
				tCO = get(gca,'colororder');
				tnCO = size(tCO,1);
				for iCmp = 1:tNCmps
					text( 'units','normalized', 'horizontalalignment','center', 'verticalalignment','top', 'interpreter','none', 'fontweight','bold', 'fontsize',tLabelFS,...
						'position',[(iCmp-0.5)/tNCmps 0.99], 'string',tCmpNms{iCmp}, 'color',tCO(rem(iCmp-1,tnCO)+1,:) )
				end
				ReplaceCursors;
			end
		end

%% -- 2DPhase
		function TwoDPhase_Format
% 			disp( sprintf( 'Formating 2DPhase data for panel row %d col %d.', iRow, iCol ) );
			tL = max( abs( [ xlim ylim ] ) );
			if iCmp == tNCmps
				xlim( [ -tL tL ] );
				ylim( [ -tL tL ] );
				Component_Format;
			end
		end

%% -- Bar
		function Bar_Format
% 			disp( sprintf( 'Formatting Bar data for panel row %d col %d.', iRow, iCol ) );
			if iCmp == tNCmps
				xlim( [ 0 tNCmps + 1 ] );
				if iRow == tNRows && iCol == 1
					set( gSPHs( iRow, iCol ), 'xtick', 1:tNCmps, 'xticklabel', tCmpNms );
				else
					set( gSPHs( iRow, iCol ), 'xtick', [], 'xticklabel', [] );
				end
				Component_Format;
			end
		end

%% -- Component
		function Component_Format
			tLabelFS = 12;
			if iRow == 1 && iCmp == tNCmps
				title( tColNms{ iCol }, 'interpreter', 'none', 'fontsize', tLabelFS );
			end
			if iRow == tNRows && iCol == tNCols && iCmp == tNCmps
				All_Format;
				for iRowL = 1:tNRows
					axes( gSPHs( iRowL, end ) );
					tXLRight = xlim;
					tXLRight = 1.025 * tXLRight( end );
					tYLCenter = mean( ylim );
					text( tXLRight, tYLCenter, tRowNms{ iRowL }, 'interpreter', 'none', 'fontsize', tLabelFS );
				end
				if ~IsOptSel( 'Domain', 'Bar' )
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

		function PrepareToReuseScales
			if ~IsOptSel( 'ScaleBy', 'Reuse' ), return; end
			if tIsNoFigYet, SetWarning( 'ScaleBy:Reuse can''t find previous plot; using ScaleBy:All' ); return; end
			% check to see that subplot rows and cols are compatibile
			tSPSize = [ numel( GetChartSels( gDFs.row ) ) numel( GetChartSels( gDFs.col ) ) ];
			if IsOffsetPlot, tSPSize( 1 ) = 1; end;
			if all( tSPSize == size( gSPHs ) )
				tOldYLim = get( gSPHs, 'ylim' );
				tOldXLim = get( gSPHs, 'xlim' );
			else
				SetError( 'If ScaleBy is "Reuse", the number of rows and columns must not change' );
			end
		end

	end

	function mrCG_SetPlotFocus_CB( tH, tED )
		% MakePPFig sets the ButtonDownFcn of each plot figure to this callback.
		% If caller does not have tPPFigTag, steal it from fig that does (if any).
		% Then, restore GUI state from the calling fig's userdata.
		if ~isempty( findobj( 'tag', 'mrCG' ) );
% 			disp( 'Callback to mrCG_SetPlotFocus_CB' );
			% Recall GUI state from figure userdata
			tUD = get( tH, 'userdata' );
			% current state of cortex window should override that stored in Plot figure,
			% to prevent unwanted switching of cortex window.
			tUD.gOptFs.( 'Cortex' ).Sel = gOptFs.( 'Cortex' ).Sel;
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
				mrCG_Pivot_Chart_listbox_CB( findtag( 'mrCG_Pivot_Chart_listbox' ), [] );
				UpdateOptionsListBox;
			end
			mrCG_Pivot_Items_listbox_CB( tILBH, [] );
			
			tDomain = GetDomain;
			if IsOffsetPlot
				gCurs.( tDomain ) = tUD.Cursor;
			end
			UpdateCursorEditBoxes;
			% Now determine if calling figure is the last pivot plot made...
			tPPFigTag = [ 'PPFig_' tDomain ];
			tPPFigH = findtag( tPPFigTag );
			if isempty(tPPFigH) || (tH ~= tPPFigH) % ...if not...
				set( tPPFigH, 'tag', '' );
				set( tH, 'tag', tPPFigTag );
			end
						
			if strcmp( GetOptSel('AutoPaint'), 'on' ) && ~isempty( gCortex ) && IsOffsetPlot && isfield( gCurs.( tDomain ), 'Frame' )
				mrCG_Cortex_Paint_CB
			end
% 			disp(datestr(now))
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
% Cursor fields are:
% gCurs.( PPDomain ).XData the XData from the current pivot plot domain
% gCurs.( PPDomain ).( CursType ).X, the X value
% gCurs.( PPDomain ).( CursType ).iX, the index of the X value in XData
% gCurs.( PPDomain ).( CursType ).XStr, the label string
% gCurs.( PPDomain ).( CursType ).LH, handle to the cursor line object
% gCurs.( PPDomain ).( CursType ).LH, handle to the cursor label object
% Cursor managment applies to the currently selected pivot domain only, but
% the data persist when domain is changed.  PPFig_LoopPlot replaces any
% pre-existing cursors if new XData are compatible with previous plot.

% These functions can all detect state of Domain from gPF, but the CursType must be passed
% around since it can only be detected by the callback of the control invoking the cursor.

% DONE:
%	1) Implemented PickCursor for new/replacement cursors.
%	2) Implemented SetCursData and PlotCursor for calls from PickCursor.
%	3) Modify PPFig_LoopPlot to replace any exisiting cursors when replacing figure.
%	4) Add control/callbacks to delete cursors.
% TO DO:
%	5) Implement CursorAt for new/replacement cursors.
%	6) At controls should reflect current cursor positions.
% KNOWN ISSUE:
%	In multi-column offset plots, PickCursor allows you to place cursor in any
%	column.  However, ReplaceCursors will always move it to the last
%	column.  This is easier than trying to find all axes during PickCursor,
%	and keeping track of multiple columns during ReplaceCursors.  In any
%	case, cursors should probably only be used for single column plots so
%	that we only try to paint the items in the Cmps field.  This will also
%	simplify the process of 

%% -- Pick
	function PickCursor( tH, tED )
		tDomain = GetDomain;
		if ~IsOffsetPlot, SetError( [ tDomain ' does not allow cortex cursor' ] ); return; end
		tPPFigH = findtag( [ 'PPFig_' tDomain ] );
		if isempty( tPPFigH ), SetWarningNoPause( 'You are attempting to place a cursor in a non-existant plot' ); return; end
		tPickButtonTag = get( tH, 'tag' );
		tCursType = tPickButtonTag( 13:(end-16) ); % 'Frame', 'Start', or 'End'
		% if cursor field exists for this domain, then delete this cursor type, if it exists
		if IsCursor, DeleteCursor( tCursType ); end
		SetWarningNoPause( [ 'Select new ' tCursType ' cursor location in ' tDomain ' window...' ] );
		set(tPPFigH,'pointer','fullcrosshair')
		waitforbuttonpress;
		set(tPPFigH,'pointer','arrow')
		if gcf ~= tPPFigH
			SetWarningNoPause( [ 'You must click on the most recent ' tDomain ' plot...Please try again' ] );
			return;
		end
		tCOH = gco;
		tCOType = get( tCOH, 'type' );
		while ~strcmpi( tCOType, 'axes' )
			if isempty( tCOH ) || strcmpi( tCOType, 'figure' ) % we missed all axes
				SetWarningNoPause( 'You must click on an axis...Please try again' );
				return;
			end
			% crawl up object heirarchy
			tCOH = get( tCOH, 'parent' );
			tCOType = get( tCOH, 'type' );
		end
		tX = get( tCOH, 'currentpoint' ); % this does not necessarily map onto a data coordinate...
		tX = tX(1);
		SetCursData( tX, tCursType );
		PlotCursor( tCursType );
		SetMessage( [ tCursType ' cursor plotted sucessfully.' ] );
	end

%% -- Helpers
	function SetCursData( tX, tCursType )
		tDomain = GetDomain;
		tXData = gCurs.( tDomain ).XData; % this is set by plot fxns
		tiX = numel( tXData( tXData <= tX ) );
		% if necessary, increment to nearest data point
		if tiX == 0 || ( tiX < numel( tXData ) && tX - tXData( tiX ) > tXData( tiX + 1 ) - tX ), tiX = tiX + 1; end
		tX = tXData( tiX );
		gCurs.( tDomain ).( tCursType ).iX = tiX;
		gCurs.( tDomain ).( tCursType ).X = tX;
		if IsWavePlot
			gCurs.( tDomain ).( tCursType ).XStr = [ ' ' num2str( round( tX ) ) 'ms' ];
		else
			gCurs.( tDomain ).( tCursType ).XStr = [ ' ' num2str( round( 100.0 * tX ) / 100.0 ) 'Hz' ];
		end
		set( findtag(['mrCG_Cortex_',tCursType,'_At_edit']) ,'string', sprintf('%0.2f',tX) );
	end

	function PlotCursor( tCursType )
		tDomain = GetDomain;
		tX = gCurs.( tDomain ).( tCursType ).X;
		tY = ylim';
		tXStr = gCurs.( tDomain ).( tCursType ).XStr;
		gCurs.( tDomain ).( tCursType ).LH = line( [ tX tX ]', tY, 'color', [ .7 .7 .7 ] ); % LH is line handle
		gCurs.( tDomain ).( tCursType ).TH = text( tX, 0.05 * diff(tY) + tY(1), tXStr );		% TH is text handle
		UpdateCursorUserdata
		if strcmp(tCursType,'Frame')
			if strcmp( GetOptSel('AutoPaint'), 'on' ) && ~isempty( gCortex )
				mrCG_Cortex_Paint_CB		% ([],[]),  handle & eventData not currently used by this function
			end
		else
			set( gCurs.( tDomain ).( tCursType ).LH, 'linestyle', '--' )
		end
	end

	function tIsCursor = IsCursor, tIsCursor = isfield( gCurs, GetDomain ); end

	function ReplaceCursors % called by plot fxns when replacing figures with cursors
		tDomain = GetDomain;
		tCursTypes = { 'Frame' 'Start' 'End' };
		for iCursType = 1:numel( tCursTypes )
			tCursType = tCursTypes{ iCursType };
			if isfield( gCurs, tDomain ) && isfield( gCurs.( tDomain ), tCursType ), PlotCursor( tCursType ); end
		end
	end

	function DeleteCursors( tH, tED )
		% callback for DeleteCursors button
		tCursTypes = { 'Frame' 'Start' 'End' };
		for iCursType = 1:numel( tCursTypes )
			tCursType = tCursTypes{ iCursType };
			DeleteCursor( tCursType );
		end
	end

	function DeleteCursor( tCursType )
		% invoked by DeleteCursors and PickCursor
		tDomain = GetDomain;
		if IsCursor && isfield( gCurs.( tDomain ), tCursType )
			if ishandle( gCurs.( tDomain ).( tCursType ).LH ), delete( gCurs.( tDomain ).( tCursType ).LH ); end
			if ishandle( gCurs.( tDomain ).( tCursType ).TH ), delete( gCurs.( tDomain ).( tCursType ).TH ); end
			gCurs.( tDomain ) = rmfield( gCurs.( tDomain ), tCursType );
			% NOTE: gCurs.(tDomain).XData remains.  Remove this field too?
			UpdateCursorUserdata
			set( findtag( [ 'mrCG_Cortex_',tCursType,'_At_edit' ] ), 'string', '' ) 
		end
	end

	function UpdateCursorUserdata
		tDomain = GetDomain;
		tFig = findtag( [ 'PPFig_' tDomain ] );
		tUD = get( tFig, 'userdata' );
		tUD.Cursor = gCurs.( tDomain );
		set( tFig, 'userdata', tUD )
	end

	function UpdateCursorEditBoxes
		tH = findtags( { 'mrCG_Cortex_Frame_At_edit', 'mrCG_Cortex_Start_At_edit', 'mrCG_Cortex_End_At_edit', ...
			'mrCG_Cortex_Frame_Pick_pushbutton', 'mrCG_Cortex_Start_Pick_pushbutton', 'mrCG_Cortex_End_Pick_pushbutton', ...
			'mrCG_Cortex_Step_By_edit', 'mrCG_Cortex_Step_B_pushbutton', 'mrCG_Cortex_Step_F_pushbutton', ...
			'mrCG_Cortex_Paint_pushbutton', 'mrCG_Cortex_Play_pushbutton', 'mrCG_Cortex_DeleteCursors_pushbutton' } );
		if IsOffsetPlot	% domain = Wave or Spec
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

	function UpdateCursorEditBox( tDomain, tType )
		if isfield( gCurs.(tDomain), tType )
			set( findtag( ['mrCG_Cortex_',tType,'_At_edit'] ), 'string', sprintf('%0.2f',gCurs.(tDomain).(tType).X) )
		else
			set( findtag( ['mrCG_Cortex_',tType,'_At_edit'] ), 'string', '' )
		end
	end

%% -- Playback (on cortex)
	function mrCG_Cortex_Step_By_CB( tH, tE )
		% callback for Step By edit box
		tDomain = GetDomain;
		try	% check if legal expression entered
			tVal = eval( get( tH, 'string' ) );		% str2double( get( tH, 'string' ) );
			if isnumeric(tVal) && isscalar(tVal) && ~isnan(tVal)
				switch tDomain
					case 'Wave'
						tIncr = gVEPInfo.(GetChartSel( 'Cnds' )).dTms;
						gCurs.Wave.StepX = max(1,round(tVal/tIncr)) * tIncr;
						UpdateCursorUserdata
					case 'Spec'
						tIncr = gVEPInfo.(GetChartSel( 'Cnds' )).dFHz;
						gCurs.Spec.StepX = max(1,round(tVal/tIncr)) * tIncr;
						UpdateCursorUserdata
					otherwise
						SetWarningNoPause( 'Step By control only valid in Wave and Spec domains.'  );
						return		% don't reset edit box string until you switch to a relevant domain
				end
			else
				SetWarningNoPause( 'Invalid cursor step expression.'  );
			end
		catch
			SetWarningNoPause( 'Invalid cursor step expression.'  );
		end
		set( findtag( 'mrCG_Cortex_Step_By_edit' ), 'string', sprintf('%0.2f',gCurs.(tDomain).StepX) )
	end

	function mrCG_Cortex_Step_CB( tH, tE )
		% callback for Step F/B pushbuttons
		tDomain = GetDomain;
% 		if ~IsOffsetPlot, SetError( [ tDomain ' does not allow cortex cursor' ] ); return; end ***
		if ~isfield(gCurs,tDomain)
			SetWarningNoPause( ['No ',tDomain,' plot.']  );
			return							
		end
		switch tDomain
			case 'Wave'
				tStepInd = round( gCurs.Wave.StepX / gVEPInfo.(GetChartSel( 'Cnds' )).dTms );
			case 'Spec'
				tStepInd = round( gCurs.Spec.StepX / gVEPInfo.(GetChartSel( 'Cnds' )).dFHz );
		end
		if IsCursor && isfield( gCurs.( tDomain ), 'Frame' )
			if strcmp( get( tH, 'string' ), 'F' )
				tiX = gCurs.( tDomain ).Frame.iX + tStepInd;
			else
				tiX = gCurs.( tDomain ).Frame.iX - tStepInd;
			end			
			if ( tiX >= 1 ) && ( tiX <= numel( gCurs.( tDomain ).XData ) )
				axes( get( gCurs.(tDomain).Frame.LH, 'parent' ) )		% otherwise it ends up in mrCurrent window
				DeleteCursor( 'Frame' );
				SetCursData( gCurs.( tDomain ).XData(tiX), 'Frame' );
				PlotCursor( 'Frame' );
				SetMessage( 'Frame cursor adjusted sucessfully.' );
			else
				SetWarningNoPause( 'Requested cursor step exceeds wave dimensions.'  );
			end
		else
			SetWarningNoPause( 'Set a Frame cursor before using F or B pushbuttons.'  );
		end
	end

	function mrCG_Cortex_EditCursor_CB( tH, tE )
		% callback for Frame/Start/End Cursor edit boxes
		tDomain = GetDomain;
		switch tDomain
			case 'Wave'
				tStepInc = gVEPInfo.(GetChartSel( 'Cnds' )).dTms;
			case 'Spec'
				tStepInc = gVEPInfo.(GetChartSel( 'Cnds' )).dFHz;
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
		tTag = get( tH, 'tag' );		% 		tags = strrep( 'mrCG_Cortex_X_At_edit', 'X', {'Frame','Start','End'} )
		tType = tTag(13:(end-8));
		if isnan(tX)
			UpdateCursorEditBox( tDomain, tType )
		else
			tiX = round( tX / tStepInc );
			if ( tiX >= 1 ) && ( tiX <= numel( gCurs.( tDomain ).XData ) )
				if IsCursor && isfield( gCurs.( tDomain ), tType ) % && ishandle( gCurs.(tDomain).(tType).LH )
					axes( get( gCurs.(tDomain).(tType).LH, 'parent' ) )
					DeleteCursor( tType );
				else
					figure( findtag( [ 'PPFig_' tDomain ] ) )		% *** NEED TO GET IN RIGHT AXIS, NOT JUST FIGURE
				end
				SetCursData( gCurs.( tDomain ).XData(tiX), tType );
				PlotCursor( tType );
				SetMessage( [ tType, ' cursor adjusted sucessfully.' ] );
			else
				UpdateCursorEditBox( tDomain, tType )
				SetWarningNoPause( 'Requested cursor location exceeds wave dimensions.'  );
			end
		end
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
			% use delete instead of close, to prevent reentry when invoked by CloseRequestFcn callback.
			if ~isempty( gCortex ) && ishandle( gCortex.FH ), delete( gCortex.FH ); end
			gCortex = [];
			return;
		end
		if isempty( gCortex )
% 			if ismac, tRenderer = 'zbuffer'; else, tRenderer = 'OpenGL'; end
			if strncmpi(computer,'MAC',3), tRenderer = 'zbuffer'; else, tRenderer = 'OpenGL'; end
% 			gCortex = struct('FOV',220,'dCam',1e3,'Name','','FH',[],'AH',[],'M',[],'MH',[],'TH',[],'LH',[]);
			gCortex.FOV = [-110 110];
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
		gCortex.M = getfield( getfield( load( GetSbjMeshPFN( gCortex.Name ) ), 'msh' ), 'data' );
		SetMessage( [ 'Configuring ' gCortex.Name '''s mesh for CortexFig...' ] );
		tNV = size( gCortex.M.vertices, 2 );
		gCortex.M.vertices = gCortex.M.vertices([3 1 2],:)';		% PIR -> RPI
		gCortex.M.vertices(:,2:3) = -gCortex.M.vertices(:,2:3);	%     -> RAS
		gCortex.M.vertices = gCortex.M.vertices - repmat( median( gCortex.M.vertices ), tNV, 1 );
		
% 		gCortex.M.colors = gCortex.M.colors(1:3,:)'/255;
		if isfield( gCortex, 'MH' ) % && ishandle( gCortex.MH )
			set( gCortex.MH, 'Vertices', gCortex.M.vertices, 'Faces', 1 + gCortex.M.triangles', 'FaceVertexCData', repmat( 0.5, tNV, 3 ) ) %gCortex.M.colors )
			set( gCortex.TH, 'String', '' )
		else
			cla( gCortex.AH );
			axes( gCortex.AH );
			gCortex.MH = patch( 'tag', 'CortexFigBrain', 'Vertices',gCortex.M.vertices,...
				  'Faces',gCortex.M.triangles'+1,'FaceVertexCData',repmat( 0.5, tNV, 3 ),...  %gCortex.M.colors,...   % 
				  'FaceColor','interp','linestyle','none','specularstrength',0.01,'facelighting','gouraud');
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
		SetMessage( [ 'Configuring ' gCortex.Name '''s mesh for CortexFig...Done' ] );
	end

	function mrCG_CloseCortex_CB( tH, tED )
		% ConfigureCortex sets the CloseRequestFcn of the cortex figure to this callback.
		% Restores option listbox cortex item setting to 'none'.
		if ~isempty( findobj( 'tag', 'mrCG' ) );
			% sets off chain of calls that updates UI and closes cortex window
			SetOptSel( 'Cortex', 'none' ); 
% 			if IsOptInItems( 'Cortex' )
% 				tILBH = findtag( 'mrCG_Pivot_Items_listbox' );
% 				set( tILBH, 'value', gOptFs.Cortex.Sel );
% 				mrCG_Pivot_Items_listbox_CB( tILBH, [] );
% 			else
% 				UpdateOptionsListBox;
% 			end
		end
		closereq
	end

%% -- SetCortexFigColorMap
	function SetCortexFigColorMap
% 		tCutFrac = str2num( get( findtag( 'mrCG_Cortex_Cutoff_edit' ), 'string' ) ) / 100.0;
		tCutFrac = GetOptSelNum( 'ColorCutoff' ) / 100.0;
		if IsWavePlot
			tCM = flow( 255, tCutFrac );
		else
			tCLim = 255;
			tCM = hot( tCLim + 100 );
			tCM = tCM( 1:tCLim, : );
			tCM( 1:(round(tCLim*tCutFrac)), : ) = 0.5;
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
% 		tAllROIs = gSbjROIFiles.( gCortex.Name) ;		
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

	function mrCG_Cortex_Paint_CB( tH, tED )
		if isempty( gCortex )																% *** disable paint button in these conditions?
			SetError( 'Need a cortex before painting.'  );
			return
		end
		tDom = GetOptSel( 'Domain' );
		if ~isfield( gCurs.(tDom), 'Frame' )
			SetError( 'Need to set a frame cursor before painting.'  );
			return			
		end

		% For now, only first of selected Cnds, Flts, Invs.
		% Soon, we will allow context-sensitive comparisons
		tCndNm = GetChartSel( 'Cnds' );
		tFltNm = GetChartSel( 'Flts' );
		tInvNm = GetChartSel( 'Invs' );
		if ~isfield( gCortex, 'InvM' ) || ~isfield( gCortex.InvM, tInvNm );
			tInvPFN = fullfile( gProjPN, gCortex.Name, 'ROI', [ tInvNm '.inv' ] );
			SetMessage( [ 'Reading ' gCortex.Name '''s inverse for CortexFig...' ] );
			gCortex.InvM.( tInvNm ) = ReadInverse( tInvPFN ); % should be tNV x tNCh.
		end
		tSbjNms = GetChartSels( 'Sbjs' );
		tNsbj = numel( tSbjNms );
		tSensMtgNm = GetSensMtgNm;			% returns 1st thing in gChartFs.Mtgs.Items that ~= 'ROI' 
		switch tDom
			case 'Wave', tYM = gD.(tSbjNms{1}).(tCndNm).(tSensMtgNm).Wave.(tFltNm);		% #time points x tNCh
			case 'Spec', tYM = gD.(tSbjNms{1}).(tCndNm).(tSensMtgNm).Spec;					% #frequencies x tNCh
		end
		for iSbj = 2:tNsbj
			switch tDom
				case 'Wave', tYM = tYM + gD.(tSbjNms{iSbj}).(tCndNm).(tSensMtgNm).Wave.(tFltNm);
				case 'Spec', tYM = tYM + gD.(tSbjNms{iSbj}).(tCndNm).(tSensMtgNm).Spec;
			end
		end
		if tNsbj > 1
			tYM = tYM / tNsbj;
		end
		tYM = tYM.'; % non-conjugate transposed to nCh x nX, for use as operand for max(max()) and inv multiplication.

		SetCortexFigColorMap;
		tiX = gCurs.(tDom).Frame.iX;
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
		if IsWavePlot
			caxis( gCortex.AH, [ -tCmax tCmax ] );		% default assuming WavePlot
			set( gCortex.MH, 'FaceVertexCData', gCortex.InvM.( tInvNm ) * ( tYM( :, tiX ) * 1e6 ) );
		else
			caxis( gCortex.AH, [ 0 tCmax ] );
			set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( tInvNm ) * ( tYM( :, tiX ) * 1e6 ) ) );
		end
		set( gCortex.TH, 'string', get( gCurs.(tDom).Frame.TH, 'string' ) )
	end

	function tCYMx = mrCG_Cortex_GetClim(tY,tInvNm)
		% get global max for balanced color limits; for complex, max returns complex w/ largest amp.
		[ tCYMx, tCiXMx ] = max( max( tY ) );			% max over channels, then over x
% 		tCYMx = abs( max( gCortex.InvM.( tInvNm ) * ( tY( :, tCiXMx ) * 1e6 ) ) );		% max in source space; abs b/c max still may be complex.
		tCYMx = max( abs( gCortex.InvM.( tInvNm ) * ( tY( :, tCiXMx ) * 1e6 ) ) );		% this way handles negative extrema
	end

	function mrCG_Cortex_Play_CB( tH, tE )
		if isempty( gCortex )
			SetError( 'Need a cortex before playing animation.'  );
			return
		end

		tDom = GetOptSel( 'Domain' );
		if ~IsCursor || ~isfield( gCurs.(tDom), 'Start' ) || ~isfield( gCurs.(tDom), 'End' )
			SetError( 'Need to set start and end cursors before playing animation.'  );
			return			
		end

		% get mean sensor data for requested time/frequency points
		tCndNm = GetChartSel( 'Cnds' );
		tSbjNms = GetChartSels( 'Sbjs' );
		tSensMtgNm = GetSensMtgNm;
		tFltNm = GetChartSel( 'Flts' );
		tNsbj = numel( tSbjNms );
		switch tDom
			case 'Wave'
				tStepBy = round( gCurs.Wave.StepX / gVEPInfo.(tCndNm).dTms );
				iMovie = [ gCurs.(tDom).Start.iX,  (gCurs.(tDom).Start.iX+tStepBy):tStepBy:(gCurs.(tDom).End.iX-1) , gCurs.(tDom).End.iX ];
				tYM = gD.(tSbjNms{ 1 }).(tCndNm).(tSensMtgNm).Wave.(tFltNm)(iMovie,:);
				for iSbj = 2:tNsbj
					tYM = tYM + gD.(tSbjNms{ iSbj }).(tCndNm).(tSensMtgNm).Wave.(tFltNm)(iMovie,:);
				end
			case 'Spec'
				tStepBy = round( gCurs.Spec.StepX / gVEPInfo.(tCndNm).dFHz );
				iMovie = [ gCurs.(tDom).Start.iX,  (gCurs.(tDom).Start.iX+tStepBy):tStepBy:(gCurs.(tDom).End.iX-1) , gCurs.(tDom).End.iX ];
				tYM = gD.(tSbjNms{ 1 }).(tCndNm).(tSensMtgNm).Spec(iMovie,:);
				for iSbj = 2:tNsbj
					tYM = tYM + gD.(tSbjNms{ iSbj }).(tCndNm).(tSensMtgNm).Spec(iMovie,:);
				end
			otherwise
				SetWarningNoPause( 'Cortex Playback only works in Wave and Spec domains.'  );
				return							
		end
		tYM = (tYM.') * ( 1e6 / tNsbj ); % non-conjugate transposed to nCh x nX, for use as operand for max(max()) and inv multiplication.

		SetCortexFigColorMap
		SetWarningNoPause( 'Playing cortex animation.' );
% 		set( gCortex.MH, 'FaceLighting', 'gouraud' )
		tInvNm = GetChartSel( 'Invs' );
		tHprogL = line('parent',get(gCurs.(tDom).Start.LH,'parent'),'xdata',get(gCurs.(tDom).Start.LH,'xdata'),'ydata',get(gCurs.(tDom).Start.LH,'ydata'),'color','k','linewidth',1);
		tic
		if IsWavePlot
			for iFrame = 1:numel(iMovie)
				tX = gCurs.(tDom).XData( iMovie( iFrame ) );
				set( gCortex.MH, 'FaceVertexCData', gCortex.InvM.( tInvNm ) * tYM( :, iFrame ) );
				set( gCortex.TH, 'string', [ num2str(round(tX)), 'ms' ] )
				set( tHprogL, 'xdata', [ tX tX ] )
				drawnow
			end
		else
			for iFrame = 1:numel(iMovie)
				tX = gCurs.(tDom).XData( iMovie( iFrame ) );
				set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( tInvNm ) * tYM( :, iFrame ) ) );
				set( gCortex.TH, 'string', [ num2str(round(100*tX)/100), 'Hz' ] )
				set( tHprogL, 'xdata', [ tX tX ] )
				drawnow
			end
		end
		delete( tHprogL )
% 		set( gCortex.MH, 'FaceLighting', 'phong' )
		SetMessage( sprintf('Playback complete. (%0.1f sec)',toc) );
	end


	function makeCortexMosaic

		if isempty(gCortex)
			SetError( 'Load a cortex & set frame cursor before creating mosaic.' )
			return
		end
		tDomain = GetDomain;
		tSpecFlag = IsSpecPlot;
		if tSpecFlag
			tSpecCursorFlag = isfield( gCurs.(tDomain), 'Frame' );
			if tSpecCursorFlag
				tValid = { 'Cnds', 'Sbjs', 'Invs' };
			else
				tValid = { 'Cnds', 'Sbjs', 'Comps', 'Invs' };
			end
		else
			if ~isfield( gCurs.(tDomain), 'Frame' )
				SetError( 'Set frame cursor before creating mosaic.' )
				return
			end
			tValid = { 'Cnds', 'Sbjs', 'Flts', 'Invs' };
		end
		[tRowDim,tNrow] = testMosaicDim('row');
		[tColDim,tNcol] = testMosaicDim('col');
		[tCmpDim,tNcmp] = testMosaicDim('cmp');
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
		
		tMtg  = GetSensMtgNm;			% returns 1st thing in gChartFs.Mtgs.Items that ~= 'ROI' 
		tSbjs  = check4VectorPage( GetChartSels('Sbjs'), 'Sbjs' );
		tInvs  = check4VectorPage( GetChartSels('Invs'), 'Invs' );
		tCnds  = check4VectorPage( GetChartSels('Cnds'), 'Cnds' );
		if tSpecFlag
			tComps = check4VectorPage( GetChartSels('Comps'), 'Comps' );
		else
			tFlts  = check4VectorPage( GetChartSels('Flts'), 'Flts' );
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
				
		SetCortexFigColorMap;		% only needs update if ColorCutoff or Wave/Spec-type changed
		
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
		
		for iSbj = 1:numel(tSbjs)
			iRow = 1;
			iCol = 1;
			checkRowCol( 'Sbjs', tSbjs{iSbj} )
			if strcmp( tSbjs{iSbj}, gCortex.Name )
				set( gCortex.TH, 'string', '' )
			else
				SetOptSel( 'Cortex', tSbjs{iSbj} )
				ConfigureCortex
			end
			for iInv = 1:numel(tInvs)
				checkRowCol( 'Invs', tInvs{iInv} )
				if ~isfield( gCortex, 'InvM' ) || ~isfield( gCortex.InvM, tInvs{iInv} );
					SetMessage( [ 'Reading ' gCortex.Name '''s inverse for CortexFig...' ] );
					gCortex.InvM.( tInvs{iInv} ) = ReadInverse( fullfile( gProjPN, gCortex.Name, 'ROI', [ tInvs{iInv}, '.inv' ] ) );
				end
				for iCnd = 1:numel(tCnds)
					checkRowCol( 'Cnds', tCnds{iCnd} )					
					% gY already ordered by rows cols etc. but is all from ROI montage, use gD
					if tSpecFlag
						switch tCmaxMode
							case 'All'
								tCmax = mrCG_Cortex_GetClim( gD.(tSbjs{iSbj}).(tCnds{iCnd}).(tMtg).Spec.', tInvs{iInv} );
							case 'Cursor'
								tCmax = max( abs( gCortex.InvM.( tInvs{iInv} ) * ( 1e6 * gD.(tSbjs{iSbj}).(tCnds{iCnd}).(tMtg).Spec(gCurs.Spec.Frame.iX,:).' ) ) );
						end
						caxis( gCortex.AH, [ 0 tCmax ] );
						if tSpecCursorFlag	% use Cursor, not Comps
% 							checkRowCol( 'Comps', tComps{iComp} )
							set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( tInvs{iInv} ) * ( 1e6 * gD.(tSbjs{iSbj}).(tCnds{iCnd}).(tMtg).Spec(gCurs.Spec.Frame.iX,:).' ) ) )
							figure( gCortex.FH )
							tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gCortex.AH ) );
						else
							for iComp = 1:numel(tComps)
								checkRowCol( 'Comps', tComps{iComp} )
								set( gCortex.MH, 'FaceVertexCData', abs( gCortex.InvM.( tInvs{iInv} ) * ( 1e6 * gD.(tSbjs{iSbj}).(tCnds{iCnd}).(tMtg).Harm.(TranslateCompName(tComps{iComp})).' ) ) )
								figure( gCortex.FH )
								tMosaic( (1+(iRow-1)*tMosDim(1)):(iRow*tMosDim(1)), (1+(iCol-1)*tMosDim(2)):(iCol*tMosDim(2)), : ) = frame2im( getframe( gCortex.AH ) );
							end
						end
					else
						for iFlt = 1:numel(tFlts)
							checkRowCol( 'Flts', tFlts{iFlt} )
							switch tCmaxMode
								case 'All'
									tCmax = mrCG_Cortex_GetClim( gD.(tSbjs{iSbj}).(tCnds{iCnd}).(tMtg).Wave.(tFlts{iFlt}).', tInvs{iInv} );
								case 'Cursor'
									tCmax = max( abs( gCortex.InvM.( tInvs{iInv} ) * ( 1e6 * gD.(tSbjs{iSbj}).(tCnds{iCnd}).(tMtg).Wave.(tFlts{iFlt})(gCurs.Wave.Frame.iX,:).' ) ) );
							end
							caxis( gCortex.AH, [ -tCmax tCmax ] );
							set( gCortex.MH, 'FaceVertexCData', gCortex.InvM.( tInvs{iInv} ) * ( 1e6 * gD.(tSbjs{iSbj}).(tCnds{iCnd}).(tMtg).Wave.(tFlts{iFlt})(gCurs.Wave.Frame.iX,:).' ) )
							figure( gCortex.FH )		% cortex figure should be on top
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
		function [tDimName,tDimN] = testMosaicDim(dim2test)
			tDimName = gDFs.(dim2test);
			if any( strcmp( tDimName, tValid ) )
				tDimN = numel( gChartFs.( tDimName ).Sel );
			else
				tDimN = 1;
				SetWarningNoPause( [dim2test,' dimension ',tDimName,' is irrelevant for Cortex Mosaic.'] )
				tDimName = '';
			end
		end

		function tOutCell = check4VectorPage( tInCell, tField )
			tOutCell = tInCell;
			if ~any( strcmp( tField, { tRowDim, tColDim, tCmpDim } ) ) && numel( tInCell )>1
				tOutCell = tOutCell(1);
				SetWarningNoPause( [ 'Vector page dimension ',tField,' being scalarized for cortex mosaic'] )
			end
		end

		function checkRowCol( tField, tValue )
			if strcmp( tField, tRowDim )
				iRow = find (strcmp( gChartFs.(tField).Items( gChartFs.(tField).Sel ), tValue ) );
			elseif strcmp( tField, tColDim )
				iCol = find (strcmp( gChartFs.(tField).Items( gChartFs.(tField).Sel ), tValue ) );
			end
		end
	end



%% -- Mesh Manipulation
	% these three functions can be consolidated into one callback with conditonals and nesting.
	function mrCG_Cortex_Rotate( tH, tED )		
		tView = get( gCortex.AH, 'view' );
		switch get( tH, 'Tag' )
			case 'mrCG_Cortex_Move_R_pushbutton'
				tView(1) = tView(1) + str2double( get( findtag( 'mrCG_Cortex_Move_By_edit' ), 'string' ) );
			case 'mrCG_Cortex_Move_L_pushbutton'
				tView(1) = tView(1) - str2double( get( findtag( 'mrCG_Cortex_Move_By_edit' ), 'string' ) );
			case 'mrCG_Cortex_Move_V_pushbutton'
				tView(2) = tView(2) - str2double( get( findtag( 'mrCG_Cortex_Move_By_edit' ), 'string' ) );
			case 'mrCG_Cortex_Move_D_pushbutton'
				tView(2) = tView(2) + str2double( get( findtag( 'mrCG_Cortex_Move_By_edit' ), 'string' ) );
		end
		set( gCortex.AH, 'view', tView )
		mrCG_Cortex_CamLights
	end
	function mrCG_Cortex_View( tH, tED )
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

	function ResizeMrCG( tH, tE )
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
			tSFH = figure( 'position', get( 0, 'screensize' ), 'units', 'characters' );
			tScrPos = get( tSFH, 'position' );
			close( tSFH );
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
% 			% the following are obtained by get( 0, 'defaultaxescolororder' )
% 			tDefaultColorOrderNames = { 'Blue', 'Green', 'Red', 'Cyan', 'Magenta', 'Black' };
		% modified for ergonomics
		tDefaultColorOrderNames = { ...
			'Blue', 'LtGrn', 'Red', 'Cyan', 'Yellow', 'Magenta', 'Black', 'Orange', 'White', ...
			'Blue2', 'LtGrn2', 'Red2', 'Cyan2', 'Yellow2', 'Magenta2', 'Black2', 'Orange2', 'White2', ...
			'Blue3', 'LtGrn3', 'Red3', 'Cyan3', 'Yellow3', 'Magenta3', 'Black3', 'Orange3', 'White3', ...
			};
	end

	function tColorOrderMat = DefaultColorOrderMat
		tColorOrderMat = get( 0, 'defaultaxescolororder' );
		% modified for ergonomics...
		tColorOrderMat( 2, : ) = [ 0 1 0 ]; % LtGrn
		tColorOrderMat( 4, : ) = [ 0 1 1 ]; % Cyan
		tColorOrderMat( 5, : ) = [ 1 1 0 ]; % Yellow
		tColorOrderMat( 6, : ) = [ 1 0 1 ]; % Magenta
		% some useful extras...
		tColorOrderMat( end + 1, : ) = [ 1 .6 0 ]; % Orange
		tColorOrderMat( end + 1, : ) = [ 1 1 1 ]; % White
		% repeat in case of lots of comparisons; eventually should implement smarter recyling of colors in plot methods.
		tColorOrderMat = repmat( tColorOrderMat, 3, 1 ); 
	end

	function tStr = GetPopupSelection( tH )
		if ischar( tH ), tH = findtag( tH ); end
		tStr = char( GetListSelection( tH ) ); end

	function tInv = ReadInverse(filename)
		% based on emseReadInverse, modified to fread nRows x nCols bytes
		% beginning at (assumed) end of header rather than by fseeking back from EOF.
		% Thus, this implementation should read .inv files with or without the xml-ish footer.

		fid=fopen(filename,'rb','ieee-le');
		if (fid==-1) % Not, as you might think, the same thing as ~fid
            disp([ 'Could not open file ' filename ]);
 			error([ 'Could not open file ' filename ]);
		end
		% Get the magic number
        magicNum = fscanf( fid, '%c', 8 );
		if (strcmp(upper(magicNum),'454D5345')) % Magic number is OK, we're reading a real inverse file
			% Next read in the major and minor revs, and other header fields.
			% Based on the file format description in Appendix A of EMSE's help file,
			% we expect exactly ten elements in tHeader, with the dimensions of the inverse
			% matrix in the 9th and 10th position.  Here's what can go wrong:
			% 1) SSI might revise inverse file header field structure without warning us.
			% 2) There will be two extra fields if "cortical thinning was used", whatever that means.
			% For now, this implementation simply checks whether fscanf returns less than expected number of
			% tHeader elements, otherwise throwing an error.  It falls to you, dear reader,
			% to implement handling of the remaining possibilities listed above should they ever occur.
 			[ tHeader, tNHeader ] = fscanf(fid,'%d',9);
			% fscanf is not robust to bytes following the last header field that have degenerate ASCII values;
			% so we use fgetl, which seems to behave correctly;
			tHeader( end + 1 ) = str2num(fgetl( fid ));
			tNHeader = tNHeader + 1;
			if tNHeader < 10
				SetError( 'Malformed inverse file header. Cross check inverse against EMSE.' );
				disp( [ 'Expected 10 header elements, but found ' tNHeader '.' ] )
				error( [ 'Header malformed in ' filename '.'] );
			end
			nRows=tHeader(9);
			nCols=tHeader(10);
			if nCols ~= 128
				SetError( [ 'Inverse has ' nCols ' columns, not 128.  Remove subject from project' ] );
				disp( [ 'Inverse in ' filename 'has ' nCols ' columns, not 128.' ]  );
				error( [ 'Inverse has ' nCols ' columns, not 128.' ]  );
			end
			[ tInv, tNInv ] = fread( fid, nCols*nRows, 'float64', 0, 'ieee-le' );
			if tNInv ~= nCols*nRows
				SetError( 'Size of inverse does not match dimensions in file header' );
				disp( [ 'Size of inverse in ' filename ' does not match dimensions in header' ] );
				disp( [ nCols ' * ' nRows ' = ' nCols*nRows ' ~= ' tNInv ] );
				error( 'Size of inverse does not match dimensions in file header' );
			else
				tInv = reshape( tInv, nCols, nRows )';
			end
			fclose(fid);
		else
			SetError( [ filename ' has a mangled magic number.' ] );
			disp( [ filename ' has a mangled magic number.' ] );
			disp( [ 'file''s ' upper(magicNum) ' does not equal expected magic number 454D5345' ] );
			error( [ filename ' has a mangled magic number.' ] )
		end
	end

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

	function NewCndNames
% 			% reset chart listbox selection
		% revise names
		SetMessage( 'Changing Cnd names may take a few moments...' );
		tNewCndNames = inputdlg( gChartFs.Cnds.Items, 'Enter new Cnd names', 1, gChartFs.Cnds.Items );
		if isempty( tNewCndNames ), return; end
		for iCnd = 1:numel( gChartFs.Cnds.Items )
			if strcmpi( gChartFs.Cnds.Items{ iCnd }, tNewCndNames{ iCnd } )
				if ~strcmp( gChartFs.Cnds.Items{ iCnd }, tNewCndNames{ iCnd } )
					SetError( 'Renaming condition files is not case-sensitive' );
					return;
				end
			end
		end
		for iCnd = 1:numel( gChartFs.Cnds.Items )
			tOldCndNm = gChartFs.Cnds.Items{ iCnd };
			tNewCndNm = tNewCndNames{ iCnd };
			if strcmpi( tOldCndNm, tNewCndNm ), continue; end
			for iSbj = 1:numel( gChartFs.Sbjs.Items )
				for iMtg = 1:numel( gChartFs.Mtgs.Items )
					tMtgNm = gChartFs.Mtgs.Items{ iMtg };
					tIsROI = strcmp( tMtgNm, 'ROI' );
					for iInv = 1:numel( gChartFs.Invs.Items )
						tInvNm = gChartFs.Invs.Items{ iInv };
						if ~tIsROI, tInvNm = ''; end % Sensor mtg doesn't have inverse subfolders.
						tPN = fullfile( gProjPN, gChartFs.Sbjs.Items{ iSbj }, tMtgNm, tInvNm );
						if ~isempty( dir( tPN ) ) % prevents renaming ROI data files that haven't been created yet.
							movefile( fullfile( tPN, [ tOldCndNm '.mat' ] ), fullfile( tPN, [ tNewCndNm '.mat' ] ) );
						end
						if ~tIsROI, break; end % Sensor mtg doesn't need more than one pass
					end
				end
				if ~isempty( gD )
					gVEPInfo.(tNewCndNm) = gVEPInfo.(tOldCndNm);
					gVEPInfo = rmfield( gVEPInfo, tOldCndNm ); 
					gD.(gChartFs.Sbjs.Items{ iSbj }).(tNewCndNm) = gD.(gChartFs.Sbjs.Items{ iSbj }).(tOldCndNm);
					gD.(gChartFs.Sbjs.Items{ iSbj }) = rmfield( gD.(gChartFs.Sbjs.Items{ iSbj }), tOldCndNm ); 
				end
			end
		end
		gCharFs.Cnds.Items = tNewCndNames;
		SetMessage( 'Done renaming Cnds.' );
% 			UpdatePivotListBox( 'mrCG_Pivot_Chart_listbox' );
% 			SendFieldToPivotItemsListBox( tCndsPF )
% 			% some additional UI housekeeping would be nice here.
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

	function tSS = CAS2SS( tCAS1, tCAS2 )
		% takes two cell arrays of strings tCAS1, and tCAS2 and returns the
		% subscripts in tCAS2 corresponding to the items in tCAS1
		% unlike function intersect, order of tCAS1 is preserved
		tSS = [];
		for iCAS1 = 1:numel( tCAS1 )
			for iCAS2 = 1:numel( tCAS2 )
				if strmatch( tCAS1{ iCAS1 }, tCAS2{ iCAS2 }, 'exact' ), tSS( end + 1 ) = iCAS2; end
			end
		end
	end % function CAS2SS

	function tComp = GetComp( varargin )
		% tComp = GetComp( tCompName, tVEPFS ), or  tCompNames = GetComp( 'getcomplist' )
		% where
		% tCompName is a string corresponding to a particular harmonic component from the list tComps below, and
		% tVEPFS is a VEPFreqSpec returned by GetVEPFreqSpecs.
		% When called with 'getcomplist', tCompNames is simply the list, tComps;
		% Otherwise, tComp is the index of the requested harmonic given the frequency specifications.

		tComps = { ...
			'1f1' '1f2' '2f1' '3f1' '4f1' '5f1' '6f1' '7f1' '8f1' ...
			'2f2' '3f2' '4f2' '5f2' '6f2' '7f2' '8f2' ...
			'1f1+1f2' '2f1+2f2' ...
		}';

		if nargin < 1
			error( 'GetComp requires at least one argument');
		end

		tCompName = lower( varargin{ 1 } );
		if strmatch( tCompName, 'getcomplist', 'exact' )
			% special argument returns list of valid components for TFs in this project.
			tVI1 = gVEPInfo.( gChartFs.Cnds.Items{ 1 } ); % VEP Info from first Cnd.
			tComp = {}; % commandeer the return value to return a list.
			for iComp = 1:numel( tComps )
				try
					tCompNm = tComps{ iComp };
					tCompSS = GetComp( tCompNm, tVI1 );
					tComp{ end + 1 } = tCompNm;
				catch % do nothing, implicitly continue
				end
			end
		else
			tiF = strmatch( tCompName, tComps, 'exact' );
			if ~isempty( tiF )
				[ tFN, tVEPFS ] = deal( varargin{1:2} );
				tkF1 = 0;
				tkF2 = 0;
				tiF1 = findstr( 'f1', lower( tFN ) );
				tiF2 = findstr( 'f2', lower( tFN ) );
				if ~isempty( tiF1 ) && ~isempty( tiF2 )
					if tiF1 < tiF2
						tkF1 = str2num( tFN( 1:(tiF1-1) ) );
						tkF2 = str2num( tFN( (tiF1+2):(tiF2-1) ) );
					else
						tkF2 = str2num( tFN( 1:(tiF2-1) ) );
						tkF1 = str2num( tFN( (tiF2+2):(tiF1-1) ) );
					end
				elseif ~isempty( tiF1 )
					tkF1 = str2num( tFN( 1:(tiF1-1) ) );
				elseif ~isempty( tiF2 )
					tkF2 = str2num( tFN( 1:(tiF2-1) ) );
				else
					% this handles ill-formed harmonic names that might appear in list above...
					disp( [ 'Cannot parse harmonic component name: ' tFN ] );
					error( [ 'Cannot parse harmonic component name: ' tFN ] );
				end
				tComp = tVEPFS.i1F1 * tkF1 + tVEPFS.i1F2 * tkF2;
				if tComp > tVEPFS.nFr || tComp <= 0
					disp( [ 'Requested harmonic component' tFN ' exceeds limit of spectrum.' ] );
					error( [ 'Requested harmonic component' tFN ' exceeds limit of spectrum.' ] );
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
			'none' 'lo20' 'nf1' 'nf2' 'f2band' 'nf1clean' 'nf2clean' 'nf1low10' ...
			'nf1low15' 'nf1low20' 'nf1_odd3to15' 'rbtx_nf1' 'rbtx_nf2' 'rbtx_im' ...
		}';

		if nargin < 1
			error( 'GetFilter requires at least one argument');
		end

		tFilterName = lower( varargin{ 1 } );
		if strmatch( tFilterName, 'getfilterlist', 'exact' )
% 			tFilter = tFilters;
			% special argument returns list of valid filters for TFs in this project.
			tVI1 = gVEPInfo.( gChartFs.Cnds.Items{ 1 } ); % VEP Info from first Cnd.
			tFilter = {}; % commandeer the return value to return a list.
			for iFlt = 1:numel( tFilters )
				try
					tFltNm = tFilters{ iFlt };
					tFltSS = GetFilter( tFltNm, tVI1 );
					tFilter{ end + 1 } = tFltNm;
				catch % do nothing, implicitly continue
				end
			end
		else
			tiF = strmatch( tFilterName, tFilters, 'exact' );
			if ~isempty( tiF )
				% we need tVEPFS, if not...
				if nargin < 2, error( 'GetFilter requires VEP frequency specification.' ); end
				tVEPFS = varargin{2};
				iF = [ tVEPFS.i1F1 tVEPFS.i1F2 ];
				tNFr = tVEPFS.nFr;
				tOrder = round( tNFr / min( iF ) ); % default value for optional third argument
				if nargin == 3
					tOrder = varargin{ 3 };
				end
				switch lower( tFilterName )
					case 'none'
						tFilter = ( 1:tNFr )';
					case 'lo20'
						tCutFr = round( 20.0 / tVEPFS.dFHz );
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
						error( 'Unknown filter name' );
				end
				if isempty( tFilter ) || any( tFilter > tVEPFS.nFr ) || any( tFilter <= 0 )
					error( 'Requested filter exceeds limit of spectrum.' );
				end
			else
				disp( [ 'Attempt to get unknown filter ' tFilterName ] );
				error( [ 'Attempt to get unknown filter ' tFilterName ] );
			end
		end
	end

	function SetFilteredWaveforms( tH, tE )
		% Determine which control is caller so we can decide whether to
		% filter sensor data for cortex painting, or ROIs.
		tTag = get( tH, 'tag' );
		tIsROI = strcmp( tTag, 'mrCG_Pivot_NewPlot_pushbutton' ) ...
			|| strcmp( tTag, 'mrCG_Pivot_RevisePlot_pushbutton' ); % all other controls use sensor data.
		tSbjNms = GetChartSels( 'Sbjs' );
		tNSbjs = numel( tSbjNms );
		tCndNms = GetChartSels( 'Cnds' );
		tNCnds = numel( tCndNms );
		tFltNms = GetChartSels( 'Flts' );
		tNFlts = numel( tFltNms );
		tInvNms = GetChartSels( 'Invs' );
		tNInvs = numel( tInvNms );
		tHemNms = GetChartSels( 'Hems' );
% 		tHemNms = { 'Bilat', 'Left', 'Right' };		% set up filter for all hemis at once rather than on demand
		tNHems = numel( tHemNms );
		tROINms = GetChartSels( 'ROIs' );
		tNROIs = numel( tROINms );
		tSensMtgNm = GetSensMtgNm;
		tFltSS = []; tFBCos = []; tFBSin = []; tNT = []; tNRC = []; % force outer scope for variables to be set by nested function SetFourierBasisMatrices.
		for iFlt = 1:tNFlts
			tFltNm = tFltNms{ iFlt };
			tFltSS = []; tFBCos = []; tFBSin = []; tNT = []; tNRC = []; % reinitialize for this filter
			tIsFourierBasisEmpty = true;
			if strcmp( tFltNm, 'none' ), continue; end % 'none' always exists, so skip it
			for iSbj = 1:tNSbjs
				tSbjNm = tSbjNms{ iSbj };
				for iCnd = 1:tNCnds
					tCndNm = tCndNms{ iCnd };
					if tIsROI
						for iInv = 1:tNInvs
							tInvNm = tInvNms{ iInv };
							if isfield( gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave, tFltNm )
								tExistFltHem = isfield( gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.(tFltNm), tHemNms' );
							else
								tExistFltHem = false( 1, tNHems );
							end
							if ~all( tExistFltHem )
								if tIsFourierBasisEmpty
									SetFourierBasisMatrices;
									SetMessage( [ 'Reconstructing ' tFltNm ' for ROIs' ] );
								end
								for iHem = find( ~tExistFltHem )
									tHemNm = tHemNms{ iHem };
									for iROI = 1:tNROIs
										tROINm = tROINms{ iROI };
										gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.(tFltNm).(tHemNm).(tROINm) = ...
											tFBCos * real( gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec.(tHemNm).(tROINm)( tFltSS ) ) + ...
											tFBSin * imag( gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Spec.(tHemNm).(tROINm)( tFltSS ) );
										if tNRC > 1 % if length of FB mats are more than one repeat cycle...
											gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.(tFltNm).(tHemNm).(tROINm) = ...
												mean( reshape( gD.(tSbjNm).(tCndNm).ROI.(tInvNm).Wave.(tFltNm).(tHemNm).(tROINm), tNT / tNRC, tNRC ), 2 );
										end
									end
								end
							end
						end
					else
						if ~isfield( gD.(tSbjNm).(tCndNm).(tSensMtgNm).Wave, tFltNm )
							if tIsFourierBasisEmpty
								SetFourierBasisMatrices;
								SetMessage( [ 'Reconstructing ' tFltNm ' for sensors' ] );
							end
							gD.(tSbjNm).(tCndNm).(tSensMtgNm).Wave.(tFltNm) = ...
								tFBCos * real( gD.(tSbjNm).(tCndNm).(tSensMtgNm).Spec( tFltSS, : ) ) + ...
								tFBSin * imag( gD.(tSbjNm).(tCndNm).(tSensMtgNm).Spec( tFltSS, : ) );
							if tNRC > 1 % if length of FB mats are more than one repeat cycle...
								gD.(tSbjNm).(tCndNm).(tSensMtgNm).Wave.(tFltNm) = ...
									squeeze( mean( reshape( gD.(tSbjNm).(tCndNm).(tSensMtgNm).Wave.(tFltNm), tNT / tNRC, tNRC, [] ), 2 ) ); % collapse over repeat cycles...
							end
						end
					end
				end
			end
		end
		
		function SetFourierBasisMatrices % Set up variables declared in outer scope of SetFilteredWaveforms.

			% Get VEPInfo for first selected cnd
			tVI1 = gVEPInfo.( tCndNms{ 1 } );
			% Create vector of harmonic subscripts for selected filters to:
			%	1) retrieve coefficients from spec data matrices; and,
			%	2) construct fourier basis functions.
			tFltSS = GetFilter( tFltNm, tVI1 );
			SetRepeatCycle;
			% ...its transpose will be used first here, for fourier basis functions.
			tIT = ( [ 1:tNT ] - 1 )'; % for math, we need zero-based time index vector
			tT = tIT / tNT; % normalize to make time points
			tFBCos = cos( 2 * pi * tT ); % fundamental Fourier basis functions
			tFBSin = sin( 2 * pi * tT );
			% Build nT x nFltSS matrix of indices into tFB for each harmonic
			% and time point by computing outer product of tFltSS
			% with the time index vector, tIT. E.g., the column 
			% for 1F simply iterates through each time point, 2F
			% iterates through every other time point, 3F through
			% every third point, &c. Modulus by number of time points makes
			% any index in tIT * tFltSS  greater than tNT wrap around properly.
			% Adding 1 returns indices to 1-based matlab indexing
			tIH = mod( tIT * tFltSS', tNT ) + 1;
			tFBCos = tFBCos( tIH ); % apply subscript to produce desired matrices of harmonic basis functions
			tFBSin = tFBSin( tIH );
			tIsFourierBasisEmpty = false;

			function SetRepeatCycle % Emulate PowerDIVA Fourier Transform resolution algorithm
				
				tNT = tVI1.nT;
				tNRC = gcd( tVI1.i1F1, tVI1.i1F2 ); % number of repeat cycles per fundamental wave period...
				if tNRC > 1, tNT = tNT * tNRC; end % the number of time points must be multiplied to match the fundamental wave period.
				tFNs = { 'i1F1', 'i1F2' }; % input frequency index names
				for iF = 1:2 % for each possible input...
					tF = tVI1.( tFNs{ iF } ); % input freqency index
					% if there are more input cycles than repeat cycles and the filter includes
					% only harmonics of this input, we re-calc the repeat cycle
					if tF > tNRC && ~any( rem( tFltSS, tF ) )
						tNRC = tF;
						break;
					end
				end
			end
		end
	end

	function tDomain = GetDomain, tDomain = GetOptSel( 'Domain' ); end
	function tIsOffsetPlot = IsOffsetPlot, tIsOffsetPlot = IsWavePlot || IsSpecPlot; end
	function tIsWavePlot = IsWavePlot, tIsWavePlot = strcmp( GetDomain, 'Wave' ); end
	function tIsSpecPlot = IsSpecPlot, tIsSpecPlot = strcmp( GetDomain, 'Spec' ); end
		
	function tCMap = flow( tNC, varargin )
		% tCMap = flow( tNC, [ tThrFrac ] )
		% works like hsv, bone, & other color map functions
		% tNC: number of elements in the colormap
		% tCutFrac: Fractional distance from extrema to gray cutoff, default 1/3

		tNCF = round( tNC / 2 ); % fraction of tNC
		tCMap = zeros( tNC, 3 );
		[ iR, iG, iB ] = deal( 1, 2, 3 );
		tCMap( 1:tNCF, iB ) = linspace( 1.0, 0.0, tNCF )';
		tCMap( (end-tNCF+1):end, iR ) = linspace( 0.0, 1.0, tNCF )';
		% The following line sets the fractional cutoff for the colormap...
		tCutFrac = 1/3;
		if nargin == 2
			tCutFrac = varargin{ 1 };
		end
		tNCF = round( tNC * ( 1 - tCutFrac ) / 2 ); % fraction of tNC
		tCMap( (tNCF+1):(end-tNCF), : ) = 0.5;
	end

	function SpecToXL
		tgYSize = size( gY );
		if IsOffsetPlot
			SetError( 'SpecToXL needs 2DPhase or Bar chart' );
			return;
		end
		PivotPlot_CB( findtag( 'mrCG_Pivot_RevisePlot_pushbutton' ), [] ); % forces recreation of data if it wasn't the last chart made
		tiLevels = fullfact( tgYSize );
		tData =  cat( 1,	{ gDFs.row gDFs.col gDFs.cmp }, ...
							cat( 2, gPM.row( tiLevels( :, 1 ) ), gPM.col( tiLevels( :, 2 ) ), gPM.cmp( tiLevels( :, 3 ) ) )...
					);
		if IsSbjPage
			tSbjNms = GetChartSels( 'Sbjs' )';
			tData = cat( 2,	tData, ...
							cat( 1, { 'Sbj' }, tSbjNms( tiLevels( :, 4 ) ) ) ...
						);
		end
		switch GetDomain
			case '2DPhase'
				tData = cat( 2,	tData, ...
								cat( 1, { 'SReal' 'SImag' }, cat( 2, num2cell( [ real( gY(:) ) imag( gY(:) ) ] ) ) )...
							);
			case 'Bar'
				tData = cat( 2,	tData, ...
								cat( 1, { 'SAmp' }, num2cell( gY(:) ) ) ...
							);
		end
		xlswrite( GetOptSel( 'XLBookName' ), tData, GetOptSel( 'XLSheetName' ) );
	end

%% Task
	function ConfigureTaskControls
		tTask.ExportData = @mrCG_Task_ExportData;
		tTask.ExportPFs = @mrCG_Task_ExportPFs;
		tTask.SetAnatFold = @mrCG_Task_SetAnatFold;
		tTask.SpecToXL = @mrCG_Task_SpecToXL;
		tTask.NewCndNames = @mrCG_Task_NewCndNames;
		tTask.ReConfig = @mrCG_Task_ReConfig;
		tTask.ReOption = @mrCG_Task_ReOption;
		tTask.TestDebug = @mrCG_Task_TestDebug;
		tTask.PaintROIs = @mrCG_Task_PaintROIs;
		tTask.CortexMosaic = @makeCortexMosaic;
		set( findtag( 'mrCG_Task_Go_pushbutton' ), 'callback', @mrCG_Task_Go_CB );
		set( findtag( 'mrCG_Task_Function_popupmenu' ), 'string', fieldnames( tTask ) );
		function mrCG_Task_Go_CB( tH, tE ), tTask.( GetPopupSelection( 'mrCG_Task_Function_popupmenu' ) )(); end
		function mrCG_Task_ExportData
			assignin( 'base', 'gD', gD );
			assignin( 'base', 'gSbjROIFiles', gSbjROIFiles );
			assignin( 'base', 'gChartFs', gChartFs );
			assignin( 'base', 'gY', gY );
			assignin( 'base', 'gPM', gPM );
			assignin( 'base', 'gDFs', gDFs );
			assignin( 'base', 'gCortex', gCortex );
			assignin( 'base', 'gVEPInfo', gVEPInfo );
			assignin( 'base', 'gOptFs', gOptFs );
			assignin( 'base', 'gCurs', gCurs );
			assignin( 'base', 'gChartL', gChartL );
		end
		function mrCG_Task_ExportPFs, assignin( 'base', 'gPFs', gPFs ); end
		function mrCG_Task_SetAnatFold, setpref( 'mrCurrent', 'AnatomyFolder', uigetdir( '', 'Browse to Anatomy folder' ) ); end
		function mrCG_Task_SpecToXL, SpecToXL; end
		function mrCG_Task_ReConfig, ConfigureTaskControls; end
		function mrCG_Task_ReOption, ConfigureOptionControls; end
		function mrCG_Task_TestDebug, disp( 'TestDebug' ); end
		function mrCG_Task_NewCndNames, NewCndNames; end
		function mrCG_Task_PaintROIs, PaintROIsOnCortex; end
	end

end