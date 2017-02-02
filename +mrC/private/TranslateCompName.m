function CompName = TranslateCompName( CompName )
% translate component names to legal matlab structure field names
% can't start with # or have operators
%
% CompStr = TranslateCompName( CompName )
% string CompName returns string
% cell CompName(s) returns cell

if iscell( CompName )
	nComp = numel( CompName );
	for i = 1:nComp
		CompName{i} = TranslateCompName( CompName{i} );
	end
else
	CompName = [ 'x', strrep( strrep( CompName, '+', 'p' ), '-', 'm' ) ];
end
