function tSub = mrC_GetCellSub( Csearch, Cref )
% tSub = mrC_GetCellSub( Csearch, Cref )
% takes two cell arrays of strings (Csearch,Cref) and returns the subscripts of Cref
% corresponding to the items in Csearch that are members of Cref, preserving order of Csearch (unlinke intersect).
%
% if all Csearch are members of Cref, then
% Cref( mrC_GetCellSub(Csearch,Cref) ) = Csearch

[test,tSub] = ismember( Csearch, Cref );

tSub = tSub(test);

