function [InvMean,InvSVD] = mrC_GetROIinv(ROIpath,ROIfiles,InvM,saveFile)
% Get vectors for converting sensor data to ROI data from Inverse matrix
%
% SYNTAX:	[InvROImean,InvROIsvd] = mrC_GetROIinv(ROIpath,ROIfiles,InverseMatrix)
% InvROImean,InvROIsvd = #Channels x #ROIs x 3 arrays, where 3rd dimension = left,right,bilateral
% ROIpath = path string to load ROIs from
% ROIfiles = cell array of base ROI names, w/o -L & -R hemisphere tags
% InverseMatrix = #Channels x #Sensors

% optional 4th input argument = path string for saving outputs as mat-file

nCh  = size( InvM, 1 );
nROI = numel( ROIfiles );
[ InvMean, InvSVD ] = deal( zeros( nCh, nROI, 3 ) );
for iROI = 1:nROI
	
	ROIbase = fullfile( ROIpath, ROIfiles{iROI} );

	ROIdata = load( [ ROIbase, '-L.mat' ] );
	iLeft = unique( ROIdata.ROI.meshIndices( ROIdata.ROI.meshIndices ~= 0 ) );
	if isempty( iLeft )
		disp(['WARNING: ',ROIbase,'-L.mat has no non-zero mesh indices.'])
	else
		[U,S,V] = svd( InvM(:,iLeft), 'econ' );
		InvSVD(:,iROI,1)  = U(:,1) * S(1,1) * ( mean(abs(V(:,1))) * sign(sum(V(:,1))) );
		InvMean(:,iROI,1) = mean( InvM(:,iLeft), 2 );
	end

	ROIdata = load( [ ROIbase, '-R.mat' ] );
	iRight = unique( ROIdata.ROI.meshIndices( ROIdata.ROI.meshIndices ~= 0 ) );
	if isempty( iRight )
		disp(['WARNING: ',ROIbase,'-R.mat has no non-zero mesh indices.'])
	else
		[U,S,V] = svd( InvM(:,iRight), 'econ' );
		InvSVD(:,iROI,2)  = U(:,1) * S(1,1) * ( mean(abs(V(:,1))) * sign(sum(V(:,1))) );
		InvMean(:,iROI,2) = mean( InvM(:,iRight), 2 );
	end

% 	iLR = cat( 2, iLeft, iRight );		% duplicate overlapping vertices?
	iLR = union( iLeft, iRight );			% or not?
	if ~isempty( iLR )
		[U,S,V] = svd( InvM(:,iLR), 'econ' );
		InvSVD(:,iROI,3)  = U(:,1) * S(1,1) * ( mean(abs(V(:,1))) * sign(sum(V(:,1))) );
		InvMean(:,iROI,3) = mean( InvM(:,iLR), 2 );
	end
end

if exist( 'saveFile', 'var' ) && ~isempty( saveFile )
	save( saveFile, 'InvMean', 'InvSVD' )
end


