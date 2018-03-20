function [rotationMtx, movedPoints] = FitPointsToScalp(scalp,electrodes,headshape)
    % mrC.fitPointsToScalp  - Find a rigid transformation the best fits 2 sets of points
    % function [rotationMtx, movedPoints] = mrC.fitPointsToScalp(scalp,fiducials,electrodes,headshape)
    % Uses function: rigidRotate
    % 
    % scalp = face vertex hi res scalp surface
    % fiducials = 3x3 set of fiducial
    % electrodes = nx3 electrode coordinates
    % headshape  = nx3 set of points taken from the scalp 
    %
    % rotationMtx - The best fit set of params used by rigidRotate()
    % movedPoints - movablePoints with the transformation applied
    
    if nargin < 3
        headshape = [];
    else
    end
    
    sf = 1/100; % Scale factor for making mm units similar to radians, this improves the nonlinear search
    stationaryPoints = scalp.rr*sf;
    electrodes = electrodes*sf;
    
    % throw out points farther than 3 cm from scalp
    if ~isempty(headshape)
        % apply scaling to headshape
        headshape = headshape*sf;
        [K,D] = nearpoints(headshape', stationaryPoints');
        npointsRem = sum(full(sqrt(D)>(30*sf)));
        disp([num2str(npointsRem) ' removed because they are further than 3 cm from inital scalp']); 
        headshape = headshape(sqrt(D)<(sf*30),:);
    end

    if ~isempty(electrodes)
        [K,D] = nearpoints(electrodes', stationaryPoints');
        %throw out points farther than 3 cm from scalp
        npointsRem = sum(full(sqrt(D)>(30*sf)));
        disp([num2str(npointsRem) ' removed because they are further than 3 cm from inital scalp']); 
        electrodes = electrodes(sqrt(D)<(sf*30),:);
    end
    % get vertex normals
    fig = figure;
    N = get(patch('vertices',scalp.rr,'faces',scalp.tris(:,[3 2 1])),'vertexnormals')';
    close(fig)
    N = N ./ repmat(sqrt(sum(N.^2)),3,1);
    
    % unconstrained uses line-search
    optns = optimset(@lsqnonlin);
    optns = optimset(optns,'display', 'iter', 'maxfunevals', 1000, 'MaxIter', 100, ...
        'LargeScale','on','TolX',1e-5,'TolFun',1e-5,'TypicalX',[0.05   0.05    0.05   0.1    0.1   0.1]);
    initial = [0 0 0 0 0 0];
    [params,RESNORM,RESIDUAL,EXITFLAG,OUTPUT,LAMBDA,JACOBIAN] = lsqnonlin(@rotcostfunclsq,initial,[],[],optns, ...
        stationaryPoints,electrodes,headshape,N);

    sigmaHat = RESNORM*length(RESIDUAL); %Sigma^2 estimator of measurement noise from data
    
    CI = nlparci(params,RESIDUAL,'jacobian',.5*JACOBIAN);
    
    dist = 0;
    for p =1:length(CI),

        thisParLo = CI(p,1);
        thisParHi = CI(p,2);
        
        thisXLo = params;
        thisXHi = params;

        thisXLo(p) = thisParLo;
        thisXHi(p) = thisParHi;

        [~,movedElecLo] = mrC.RigidRotate(thisXLo,electrodes);
        [~,movedElecHi] = mrC.RigidRotate(thisXHi,electrodes);
        
        if dist < (max(sqrt(sum((movedElecLo(:,:)-movedElecHi(:,:)).^2,2)))/sf);
            dist = max(sqrt(sum((movedElecLo(:,:)-movedElecHi(:,:)).^2,2)))/sf;
        else
        end
        for e = 1:size(electrodes,1);
            line2plot = [ movedElecLo(e,:); movedElecHi(e,:)]./sf./1000;
            line(line2plot(:,1),line2plot(:,2),line2plot(:,3),'linewidth',2,'color',[0 0 1]);
        end
    end
    axLim = axis;
    text(axLim(2),axLim(3),axLim(6),['Electrodes fit to within: ' num2str(dist/2,2) ' mm']);
    
    % output headshape
    if ~isempty(headshape)
        [~,movedPoints] = mrC.RigidRotate(params,headshape);
        movedPoints = movedPoints./sf;
    else
        movedPoints = [];
    end
    % generate final translation fpr output
    params(1:3) = params(1:3)./sf;
    rotationMtx = mrC.RigidRotate(params);
end
    
function dist = rotcostfunclsq(params,stationaryPoints,electrodes,headshape,N)
    [~,movedElec] = mrC.RigidRotate(params,electrodes);
    [kE,dE] = nearpoints(movedElec', stationaryPoints');
    % get signed vector error
    signedDist = dot(  (movedElec - stationaryPoints(kE,:))', N(:,kE));
    if ~isempty(headshape)
        % use headshape to constrain solution
        [~,movedHead] = mrC.RigidRotate(params,headshape);
        [kH,dH] = nearpoints(movedHead', stationaryPoints');
        dist = (dH + (signedDist - mean(signedDist)));
    else
        % if the absolute electrode distance exceeds sqrt(30), 
        % use it to constrain solution, by increasing error (dist) 
        dE = sqrt(dE);
        dE(dE<30) = 30;
        dE = (dE-30);
        dist = (dE + (signedDist - mean(signedDist)));
    end
end
