function fval = mrC_SphereObjFcn( tOxyz, tEpos, tNE )
tDxyz = tEpos - repmat( tOxyz, tNE, 1 );
tUnit = tDxyz ./ repmat( hypot( hypot( tDxyz(:,1), tDxyz(:,2) ), tDxyz(:,3) ), 1, 3 );
fval = norm( tDxyz - tUnit * ( tUnit(:) \ tDxyz(:) ), 'fro' );
