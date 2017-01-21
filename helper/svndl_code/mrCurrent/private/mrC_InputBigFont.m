function ExprStr = mrC_InputBigFont(TitleStr,PromptStr,ExprStr,FontSize)
% similar to inputdlg but with char units & variable fontsize
% only takes 1 item at the moment

GAPw = 1;			% width,height gaps between uicontrols (chars)
GAPh = 0.5;

ButtonStr = { 'OK', 'Cancel' };
ButtonChars = cellfun( @numel, ButtonStr ) + 4;
UIw = max([ numel( ExprStr )+10*GAPw, numel( PromptStr ), sum( ButtonChars )+GAPw ]);
UIh = 1.5;

scaleBy = FontSize / get(0,'defaultuicontrolfontsize');
% scaleBy = FontSize / get(0,'FactoryUIControlFontSize');
if scaleBy ~= 1
	UIw = UIw * scaleBy;
	UIh = UIh * scaleBy;
	ButtonChars = ButtonChars * scaleBy;
	GAPw = GAPw * scaleBy;
	GAPh = GAPh * scaleBy;
end

defaultScreenUnits = get(0,'Units');
set(0,'Units','characters');
SSchar = get(0,'screensize');
set(0,'Units',defaultScreenUnits)

DLGw =   UIw + 2*GAPw;
DLGh = 3*UIh + 3*GAPh;
DLGl = max( ceil( ( SSchar(3) - DLGw ) / 2 ), 1 );
DLGb = max( ceil( ( SSchar(4) - DLGh ) / 2 ), 1 );
uiD = dialog('Name',TitleStr,'Units','characters','Position',[ DLGl DLGb DLGw DLGh ],'defaultuicontrolfontsize',FontSize,'defaultuicontrolunits','characters');
uiC = [...
	uicontrol(uiD,'Position',[  GAPw              2*GAPh+2*UIh UIw            UIh],'Style','text',      'String',PromptStr,'HorizontalAlignment','left')...
	uicontrol(uiD,'Position',[  GAPw              2*GAPh+  UIh UIw            UIh],'Style','edit',      'String',ExprStr,  'HorizontalAlignment','left')...
	uicontrol(uiD,'Position',[  GAPw                GAPh       ButtonChars(1) UIh],'Style','pushbutton','String',ButtonStr{1},'Callback','uiresume')...
	uicontrol(uiD,'Position',[2*GAPw+ButtonChars(1) GAPh       ButtonChars(2) UIh],'Style','pushbutton','String',ButtonStr{2},'Callback','close(gcf)')	];

uiwait(uiD)
if ishandle(uiD)
	ExprStr = get(uiC(2),'String');
	close(uiD)
else
	ExprStr = '';
end


