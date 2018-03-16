function xy = FlattenZ(xyz,eFlat)
    % xy = mrC.FlattenZ(xyz, eFlat)
    % Flatten a set of 3-D Cartesian coords in the 3rd dimension
    % 1. find best fitting sphere
    % 2. subtract origin
    % 3. tranform to spherical coords [theta,phi,r]
    % 4. flatten to 2-D polar coords using:
    %		theta = theta
    %		rho = (1-sin(phi))^eFlat
    % 5. transform back to cartesian coords
    %
    % SYNTAX:	xy = flattenZ(xyz,eFlat)
    % xyz   = [n x 3] matrix of 3D locations
    % eFlat = flattening exponent.  (optional, default = 0.6)
    % xy    = [n x 2] matrix of flattened locations

    n = size(xyz);
    if numel(n)~=2
        error('input xyz must be a 2-D matrix')
    end
    if n(2)==3
        transposed = false;
    elseif n(1)==3
        xyz = xyz';
        n(1) = n(2);
        transposed = true;
    else
        error('input xyz must have either 3 columns or rows')
    end

    if nargin<2
        eFlat = 0.6;
    end

    xyz0 = sphereFit(xyz);
    [xyz(:,1),xyz(:,2)] = cart2sph( xyz(:,1)-xyz0(1), xyz(:,2)-xyz0(2), xyz(:,3)-xyz0(3) );

    xy = zeros(n(1),2);
    [xy(:,1),xy(:,2)] = pol2cart( xyz(:,1), (1-sin(xyz(:,2))).^eFlat );

    if transposed
        xy = xy';
    end
end

function [o,r] = sphereFit(p,oInit)
    % Spherical fit to a matrix of Cartesian data points
    %
    % [origin,radius] = sphereFit(p,oInit)
    % p     = n x 3 matrix of cartesian data points [x y z]
    % oInit = initial coords of origin for optimization.  (optional, defaults to median)

    if ~exist('oInit','var') || isempty(oInit)
        oInit = median(p);
    end

    n = size(p,1);
    % 	opts = optimset;
    % 	o = fminunc(@objFcn,oInit,opts);
    % 	o = fminsearch(@objFcn,oInit,opts);
    o = fminsearch(@objFcn,oInit);
    [f,r] = objFcn(o);

    function [F,r] = objFcn(x)
        dp = p - repmat(x,n,1);
        u = dp ./ repmat( hypot( hypot( dp(:,1), dp(:,2) ), dp(:,3) ), 1, 3 );
        r = u(:) \ dp(:);
        F = norm(u*r-dp,'fro');
    end
end

		
		
		

