function gui = mrC_BuildGUI

gui = struct;
UD.tOldPos = [ 40 15 178 54 ];

defUnits = get( 0, 'Units' );
set( 0, 'Units', 'characters' )
screenChars = get( 0, 'MonitorPosition' );
set( 0, 'Units', defUnits )
nScreen = size( screenChars, 1 );
if nScreen > 1
	iScreen = screenChars(:,1) > 0;
	if any( iScreen )
		iScreen = find( screenChars(:,1) == min( screenChars(iScreen,1) ), 1 );
	else
		[junk,iScreen] = max( screenChars(:,1) );
	end
else
	iScreen = 1;
end
UD.tOldPos(1:2) = ( screenChars(iScreen,3:4) - UD.tOldPos(3:4) ) / 2;
UD.tOldPos(1:2) = ceil( UD.tOldPos(1:2) );
UD.tOldPos(1:2) = max( UD.tOldPos(1:2), 1 );

fontSize = 12;
gui.Figure = figure( 'Tag', 'mrC_GUI', 'Units','characters', 'Position', UD.tOldPos , 'UserData', UD, 'MenuBar', 'none', 'Color', [0 0.3 0.3],...
	'defaultuipanelunits', 'characters', 'defaultuipanelfontsize', fontSize, 'defaultuicontrolunits', 'characters', 'defaultuicontrolfontsize', fontSize );

gui.PlotPanel    = uipanel( gui.Figure, 'Position', [   2 22.5 174  31 ], 'Title', 'Plot',    'Tag', 'Level1' );
gui.ProjectPanel = uipanel( gui.Figure, 'Position', [   2   14  57   8 ], 'Title', 'Project', 'Tag', 'Level1' );
gui.TaskPanel    = uipanel( gui.Figure, 'Position', [   2    6  57 7.5 ], 'Title', 'Task',    'Tag', 'Level1' );
gui.CursorPanel  = uipanel( gui.Figure, 'Position', [  61    6  65  16 ], 'Title', 'Cursor',  'Tag', 'Level1' );
gui.CortexPanel  = uipanel( gui.Figure, 'Position', [ 128    6  48  16 ], 'Title', 'Cortex',  'Tag', 'Level1' );
gui.MessagePanel = uipanel( gui.Figure, 'Position', [   2  0.5 174   5 ], 'Title', 'Message', 'Tag', 'Level1' );

% plot panel
gui.ChartPane      = uipanel( 'Parent', gui.PlotPanel,      'Position', [   2  4.5  72  25 ], 'Title', 'Chart', 'Tag', 'Level2' );
gui.ChartList      = uicontrol(         gui.ChartPane,      'Position', [   2    1  58  22 ], 'Style', 'listbox',    'String', { 'None...' }, 'Max', 1 );
gui.ChartPivot     = uicontrol(         gui.ChartPane,      'Position', [  61    1   9  22 ], 'Style', 'pushbutton', 'String', 'Pivot' );
gui.ItemsPane      = uipanel( 'Parent', gui.PlotPanel,      'Position', [  75  4.5  40  25 ], 'Title', 'Items', 'Tag', 'Level2' );
gui.ItemsList      = uicontrol(         gui.ItemsPane,      'Position', [   2    8  36  15 ], 'Style', 'listbox',    'String', { 'None...' }, 'Max', 1, 'ListboxTop', 1 );
gui.ItemsUp        = uicontrol(         gui.ItemsPane,      'Position', [   2  5.5   6   2 ], 'Style', 'pushbutton', 'String', 'Up' );
gui.ItemsDown      = uicontrol(         gui.ItemsPane,      'Position', [   9  5.5  10   2 ], 'Style', 'pushbutton', 'String', 'Down' );
gui.ItemsTop       = uicontrol(         gui.ItemsPane,      'Position', [  20  5.5   8   2 ], 'Style', 'pushbutton', 'String', 'Top' );
gui.ItemsFlip      = uicontrol(         gui.ItemsPane,      'Position', [  29  5.5   9   2 ], 'Style', 'pushbutton', 'String', 'Flip' );
gui.ItemsUserPanel = uipanel( 'Parent', gui.ItemsPane,      'Position', [   2  0.5  36 4.5 ], 'Title', 'UserDefined', 'Tag', 'Level3' );
gui.ItemsUserEdit  = uicontrol(         gui.ItemsUserPanel, 'Position', [   2  0.5  32   2 ], 'Style', 'edit',       'String', '' );
gui.OptionsPane    = uipanel( 'Parent', gui.PlotPanel,      'Position', [ 116  4.5  56  25 ], 'Title', 'Options', 'Tag', 'Level2' );
gui.OptionsPivot   = uicontrol(         gui.OptionsPane,    'Position', [   2    1   9  22 ], 'Style', 'pushbutton', 'String', 'Pivot' );
gui.OptionsList    = uicontrol(         gui.OptionsPane,    'Position', [  12    1  42  22 ], 'Style', 'listbox',    'String', { 'None...' }, 'Max', 1 );
gui.PlotNew        = uicontrol(         gui.PlotPanel,      'Position', [   2    1  84 2.5 ], 'Style', 'pushbutton', 'String', 'New Plot' );
gui.PlotRevise     = uicontrol(         gui.PlotPanel,      'Position', [  88    1  84 2.5 ], 'Style', 'pushbutton', 'String', 'Revise Plot' );
% project panel
gui.ProjectText = uicontrol( gui.ProjectPanel, 'Position', [ 2 3.5 53 2 ], 'Style', 'text',       'String', { 'None...' }, 'FontSize', round( 1.25 * fontSize ), 'Tag', 'LiveText' );
gui.ProjectNew  = uicontrol( gui.ProjectPanel, 'Position', [ 2 0.5 53 2 ], 'Style', 'pushbutton', 'String', 'New' );
% task panel
gui.TaskPopup = uicontrol( gui.TaskPanel, 'Position', [ 2 3.5 53 2 ], 'Style', 'popupmenu',  'String', { 'None...' } );
gui.TaskGO    = uicontrol( gui.TaskPanel, 'Position', [ 2 0.5 53 2 ], 'Style', 'pushbutton', 'String', 'Go' );
% cursor panel
gui.FramePane      = uipanel( 'Parent', gui.CursorPanel, 'Position', [   2   5  19  9.5 ], 'Title', 'Frame', 'Tag', 'Level2' );
gui.FrameEdit      = uicontrol(         gui.FramePane,   'Position', [   2 5.5  15    2 ], 'Style', 'edit',       'String', '',     'Tag', 'Frame' );
gui.FramePick      = uicontrol(         gui.FramePane,   'Position', [   2   3  15    2 ], 'Style', 'pushbutton', 'String', 'Pick', 'Tag', 'Frame' );
gui.FrameDown      = uicontrol(         gui.FramePane,   'Position', [   2 0.5   7    2 ], 'Style', 'pushbutton', 'String', '<<' );
gui.FrameUp        = uicontrol(         gui.FramePane,   'Position', [  10 0.5   7    2 ], 'Style', 'pushbutton', 'String', '>>' );
gui.MoviePane      = uipanel( 'Parent', gui.CursorPanel, 'Position', [  23   5  40  9.5 ], 'Title', 'Movie', 'Tag', 'Level2' );
gui.MovieStartEdit = uicontrol(         gui.MoviePane,   'Position', [   2 5.5  15    2 ], 'Style', 'edit',       'String', '',     'Tag', 'MovieStart' );
gui.MovieStartPick = uicontrol(         gui.MoviePane,   'Position', [   2   3  15    2 ], 'Style', 'pushbutton', 'String', 'Pick', 'Tag', 'MovieStart' );
                     uicontrol(         gui.MoviePane,   'Position', [  18 5.5   4    2 ], 'Style', 'text',       'String', 'to' );
gui.MovieStopEdit  = uicontrol(         gui.MoviePane,   'Position', [  23 5.5  15    2 ], 'Style', 'edit',       'String', '',     'Tag', 'MovieStop' );
gui.MovieStopPick  = uicontrol(         gui.MoviePane,   'Position', [  23   3  15    2 ], 'Style', 'pushbutton', 'String', 'Pick', 'Tag', 'MovieStop' );
gui.MoviePlay      = uicontrol(         gui.MoviePane,   'Position', [   2 0.5  36    2 ], 'Style', 'pushbutton', 'String', 'Play' );
gui.CursorClear    = uicontrol(         gui.CursorPanel, 'Position', [   2 0.5  19    4 ], 'Style', 'pushbutton', 'String', 'Clear All' );
                     uicontrol(         gui.CursorPanel, 'Position', [  25 0.5  20    2 ], 'Style', 'text',       'String', 'Step by' );
gui.CursorStep     = uicontrol(         gui.CursorPanel, 'Position', [  46 0.5  17    2 ], 'Style', 'edit',       'String', '');
% cortex panel
gui.ViewPane         = uipanel( 'Parent', gui.CortexPanel, 'Position', [  2    5 21  9.5 ], 'Title', 'Set View', 'Tag', 'Level2' );
gui.ViewP            = uicontrol(         gui.ViewPane,    'Position', [  2  5.5  8    2 ], 'Style', 'pushbutton', 'String', 'P' );
gui.ViewA            = uicontrol(         gui.ViewPane,    'Position', [ 11  5.5  8    2 ], 'Style', 'pushbutton', 'String', 'A' );
gui.ViewL            = uicontrol(         gui.ViewPane,    'Position', [  2    3  8    2 ], 'Style', 'pushbutton', 'String', 'L' );
gui.ViewR            = uicontrol(         gui.ViewPane,    'Position', [ 11    3  8    2 ], 'Style', 'pushbutton', 'String', 'R' );
gui.ViewD            = uicontrol(         gui.ViewPane,    'Position', [  2  0.5  8    2 ], 'Style', 'pushbutton', 'String', 'D' );
gui.ViewV            = uicontrol(         gui.ViewPane,    'Position', [ 11  0.5  8    2 ], 'Style', 'pushbutton', 'String', 'V' );
gui.RotatePane       = uipanel( 'Parent', gui.CortexPanel, 'Position', [ 25    5 21  9.5 ], 'Title', 'Rotate', 'Tag', 'Level2' );
gui.RotateL          = uicontrol(         gui.RotatePane,  'Position', [  2  5.5  8    2 ], 'Style', 'pushbutton', 'String', 'L' );
gui.RotateR          = uicontrol(         gui.RotatePane,  'Position', [ 11  5.5  8    2 ], 'Style', 'pushbutton', 'String', 'R' );
gui.RotateD          = uicontrol(         gui.RotatePane,  'Position', [  2    3  8    2 ], 'Style', 'pushbutton', 'String', 'D' );
gui.RotateV          = uicontrol(         gui.RotatePane,  'Position', [ 11    3  8    2 ], 'Style', 'pushbutton', 'String', 'V' );
                       uicontrol(         gui.RotatePane,  'Position', [  2  0.5  8    2 ], 'Style', 'text',       'String', 'by' );
gui.RotateEdit       = uicontrol(         gui.RotatePane,  'Position', [ 11  0.5  8    2 ], 'Style', 'edit',       'String', '15' );
gui.CortexPaint      = uicontrol(         gui.CortexPanel, 'Position', [  2  0.5 14    4 ], 'Style', 'pushbutton', 'String', 'Paint' );
gui.CortexScalp      = uicontrol(         gui.CortexPanel, 'Position', [ 18  2.5 19    2 ], 'Style', 'checkbox',   'String', 'Scalp' );
gui.CortexContour    = uicontrol(         gui.CortexPanel, 'Position', [ 18  0.5 19    2 ], 'Style', 'checkbox',   'String', 'Contours' );
gui.CortexContourNum = uicontrol(         gui.CortexPanel, 'Position', [ 38  0.5  8    2 ], 'Style', 'edit',       'String', '10' );
% message panel
gui.MessageText = uicontrol( gui.MessagePanel, 'Position', [ 2 0.5 170 2.5 ], 'Style', 'text', 'String', { 'None...' }, 'Tag', 'LiveText' );

set( [ gui.ProjectText, gui.MessageText ], 'horizontalalignment', 'left' );

% set( [ gui.ChartList, gui.ItemsList, gui.OptionsList, gui.TaskPopup, gui.FrameEdit, gui.MovieStartEdit, gui.MovieStopEdit, gui.CursorStep,...
% 	      gui.RotateEdit, gui.ContourNum, gui.ProjectText, gui.MessageText ], 'backgroundcolor', [ .85 .85 .85 ] )
% set( [ gui.ChartPane, gui.ItemsPane, gui.OptionsPane, gui.FramePane, gui.MoviePane, gui.ViewPane, gui.RotatePane ], 'TitlePosition', 'centertop' )

set( findobj( gui.Figure, 'Style', 'listbox', '-or', 'Style', 'popupmenu', '-or', 'Style', 'edit', '-or', 'Tag', 'LiveText' ), 'backgroundcolor', [ .85 .85 .85 ] )
set( findobj( gui.Figure, 'Type', 'uipanel', 'Tag', 'Level2' ), 'TitlePosition', 'centertop' )

set( [ gui.ItemsUserEdit,...
       gui.FrameEdit, gui.FramePick, gui.FrameDown, gui.FrameUp, gui.CursorStep, gui.CursorClear,...
       gui.MovieStartEdit, gui.MovieStartPick, gui.MovieStopEdit, gui.MovieStopPick, gui.MoviePlay,...
       gui.CortexPaint ], 'Enable', 'off' )

drawnow		% keeps ResizeFcn from running upon assignment in main function
[ gui.CortexFigure, gui.CortexAxis, gui.CortexPatch, gui.CortexLights, gui.CortexText, gui.CortexLines, gui.ScalpPatch ] = deal([]);
