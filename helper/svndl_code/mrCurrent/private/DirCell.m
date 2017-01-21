function Names = DirCell( SearchStr, Options )
% Returns 1xN cell array of file &/or folder names in specified location
% excluding those with leading "."
DirStruct = dir( SearchStr );
Names = { DirStruct.name };
k = ~strncmp( Names, '.', 1 );
switch lower(Options)
case 'folders'
	Names = Names( k &  [ DirStruct.isdir ] );
case 'files'
	Names = Names( k & ~[ DirStruct.isdir ] );
case 'filenames'
	[ DirNames, Names ] = cellfun( @fileparts, Names( k & ~[ DirStruct.isdir ] ), 'UniformOutput', false );
otherwise
	Names = Names( k );
end

