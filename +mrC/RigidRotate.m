function movedPoints = RigidRotate(params,movablePoints)
% mrC.RigidRotate - performs a rigid body transformation
% movedPoints = mrC.RigidRotate(params,movablePoints)

%   This function that performs a rigid body transformation on movablePoints
%   that is specified as follows:
%   
%   movablePoints - Nx3 matrix
%
%	xShift = params(1);
%	yShift = params(2);
%	zShift = params(3);
%	Rx   = params(4); rotation around x axis
%	Ry   = params(5); rotation around y
%	Rz   = params(6); rotation around z

	xShift = params(1);
	yShift = params(2);
	zShift = params(3);
	ang1   = params(4);
	ang2   = params(5);
	ang3   = params(6);

	movedPoints =  rotate(movablePoints,ang1,'x');
 	movedPoints =  rotate(movedPoints,ang2,'y');
 	movedPoints =  rotate(movedPoints,ang3,'z');

    movedPoints = 	[movedPoints(:,1)+xShift, ...
 					 movedPoints(:,2)+yShift, ...
					 movedPoints(:,3)+zShift];
end
                 
function [XYZ] = rotate(XYZ,angle,axis,units)
    % rx - Rotate 3D Cartesian coordinates around the X, Y or Z axis
    %
    % Useage: [XYZ] = rx(XYZ,alpha,units)
    %
    % XYZ is a [3,N] or [N,3] matrix of 3D Cartesian coordinates
    %
    % 'angle' - angle of rotation
    % 'axis'  - axis to rotate about
    % 'units' - angle is either 'degrees' or 'radians'
    %           the default is alpha in radians
    % 
    % If input XYZ = eye(3), the XYZ returned is
    % the rotation matrix.
    
    % $Revision: 1.10 $ $Date: 2004/04/16 18:49:10 $

    % Licence:  GNU GPL, no express or implied warranties
    % History:  04/2002, Darren.Weber_at_radiology.ucsf.edu
    %                    Developed after example 3.1 of
    %                    Mathews & Fink (1999), Numerical
    %                    Methods Using Matlab. Prentice Hall: NY.
    %           03/2018, pjkohler combined Rx, Ry and Rz functions            
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%  UNITS
    if ( nargin < 4 ) || ( isempty(units) )
        units = 'radians';
    else
    end
    
    % convert degrees to radians
    if isequal(units,'degrees'),
        angle = angle*pi/180;
    else
    end
    
    switch lower(axis)
        case {'x','x-axis','rx'}
            Rot = [1 0 0; 0 cos(angle) -sin(angle); 0 sin(angle) cos(angle) ];
        case {'y','y-axis','ry'}
            Rot = [ cos(angle) 0 sin(angle); 0 1 0; -sin(angle) 0 cos(angle) ]; 
        case {'z','z-axis','rz'}
            Rot = [ cos(angle) -sin(angle) 0;  sin(angle) cos(angle) 0;  0 0 1 ];
        otherwise
            msg = sprintf('/n Unknown rotation axis provided %s',axis);
            error(msg);
    end
    if isequal(size(XYZ,1),3),
        XYZ = Rot * XYZ;
    else
        XYZ = XYZ';
        if isequal(size(XYZ,1),3),
            XYZ = [Rot * XYZ]';
        else
            error('mrC.RigidRotate: Input XYZ must be [N,3] or [3,N] matrix.\n');
        end
    end
end