function XYflat = mrC_flattenELPdata(XYZ)
% Flatten 3D Cartesian sensor locations for overhead display
%
% usage:   XYflat = mrC_flattenELPdata(XYZ)
% where:   XYZ  = n x 3 matrix of Cartesian sensor locations
%                 XYZ(:,3) is assumed to be the inferior<->superior dimension
%          XYflat = n x 2 matrix of flattened locations

nSensor = size(XYZ,1);

% best-fitting sphere origin
oSphere = fminsearch( @(o) mrC_SphereObjFcn(o,XYZ,nSensor), median(XYZ) );

% convert cartesian to spherical coords [theta,phi,radius]
[XYZ(:,1),XYZ(:,2),XYZ(:,3)] = cart2sph( XYZ(:,1)-oSphere(1), XYZ(:,2)-oSphere(2), XYZ(:,3)-oSphere(3) );

% flatten
eFlat = 0.6;		% flattening exponent
[XYZ(:,1),XYZ(:,2)] = pol2cart( XYZ(:,1), ( 1 - sin( XYZ(:,2) ) ).^eFlat );

XYflat = XYZ(:,1:2);



