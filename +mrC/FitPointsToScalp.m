function [rotationMtx, movedPoints] = FitPointsToScalp(scalp,fiducials,electrodes,headshape)

% mrC.fitPointsToScalp  - Find a rigid transformation the best fits 2 sets of points
%function [rotationMtx, movedPoints] = mrC.fitPointsToScalp(scalp,fiducials,electrodes,headshape)

% Uses function: rigidRotate
% 
% scalp = face vertex hi res scalp surface
% fiducials = 3x3 set of fiducial
% electrodes = nx3 electrode coordinates
% headshape  = nx3 set of points taken from the scalp 
%
% rotationMtx - The best fit set of params used by rigidRotate()
% movedPoints - movablePoints with the transformation applied
%
optns = optimset(@lsqnonlin);
optns = optimset(optns,'display', 'iter', 'maxfunevals', 1000, 'MaxIter', 100, ...
    'LargeScale','on','TolX',1e-5,'TolFun',1e-5,'TypicalX',[0.05   0.05    0.05   0.1    0.1   0.1]);

disp('fitpoints')
sf = 1/100; % Scale factor for making mm units similar to radians, this improves the nonlinear search
stationaryPoints = scalp.rr*sf;
fiducials = fiducials*sf;
electrodes = electrodes*sf;

if nargin<4,
    headshape = [];
end
headshape = headshape*sf;

if ~isempty(headshape)
    [K,D] = nearpoints(headshape', stationaryPoints');
    %throw out points farther than 3 cm from scalp
    npointsRem = sum(full(sqrt(D)>(30*sf)));
    disp([num2str(npointsRem) ' removed because they are further than 3 cm from inital scalp']); 
    headshape = headshape(sqrt(D)<(sf*30),:);
end

if ~isempty(electrodes)
    [K,D] =     nearpoints(electrodes', stationaryPoints');
    %throw out points farther than 3 cm from scalp
    npointsRem = sum(full(sqrt(D)>(30*sf)));
    disp([num2str(npointsRem) ' removed because they are further than 3 cm from inital scalp']); 
    electrodes = electrodes(sqrt(D)<(sf*30),:);
end


% stationaryCenter = mean(stationaryPoints);
% movableCenter    = mean(movablePoints);

%initialTranslation = [movableCenter - stationaryCenter];

lowlim = [ -100*sf -100*sf -100*sf -pi/2 -pi/2 -pi/2];
uplim  = [  100*sf  100*sf  100*sf  pi/2  pi/2  pi/2];

% T = delaunay3(stationaryPoints(:,1),stationaryPoints(:,2),stationaryPoints(:,3))
% initial = [initialTranslation 0 0 0];
initial = [0 0 0 0 0 0];

fig = figure;
N = get(patch('vertices',scalp.rr,'faces',scalp.tris(:,[3 2 1])),'vertexnormals')';
close(fig)
N = N ./ repmat(sqrt(sum(N.^2)),3,1);


%[params fval] = fminsearch(@translate,[0 0 0 0],optns,v1fMRI,VEP);
%[params fval EXITFLAG, OUTPUT,LAMBDA,GRAD,HESSIAN] = fmincon(@rotcostfunc2,initial,[],[],[],[],lowlim,uplim,[],optns, ...
%						 stationaryPoints,electrodes,headshape,N);


% %Constrained, uses large scale algorithm
% [X,RESNORM,RESIDUAL,EXITFLAG,OUTPUT,LAMBDA,JACOBIAN] = lsqnonlin(@rotcostfunclsq,initial,lowlim,uplim,optns, ...
% 						 stationaryPoints,electrodes,headshape,N);

                     %Unconstrained uses line-search
[X,RESNORM,RESIDUAL,EXITFLAG,OUTPUT,LAMBDA,JACOBIAN] = lsqnonlin(@rotcostfunclsq,initial,[],[],optns, ...
						 stationaryPoints,electrodes,headshape,N);
params = X;

sigmaHat = RESNORM*length(RESIDUAL); %Sigma^2 estimator of measurement noise from data

covMat = sigmaHat*inv(JACOBIAN'*JACOBIAN); %Estimated Covariance Matrix;
                     
if ~isempty(headshape)
    movedPoints = mrC.RigidRotate(params,headshape)./sf;
else
    movedPoints = [];
end
 
movedElec = mrC.RigidRotate(params,electrodes);
 
params(1:3) = params(1:3)./sf;
rotationMtx = makeRotMtx(params);

%  
%  xShift = params(1);
%  yShift = params(2);
%  zShift = params(3);
%  a   = params(4);
%  b   = params(5);
%  g   = params(6);
% 
%  Rx = [1 0 0; 0 cos(a) -sin(a); 0 sin(a) cos(a) ];
%  Ry = [ cos(b) 0 sin(b); 0 1 0; -sin(b) 0 cos(b) ];
%  Rz = [ cos(g) -sin(g) 0;  sin(g) cos(g) 0;  0 0 1 ];
% 
% 
%  newR = Rx*Ry*Rz;
% 
% 
%  newtrans = [newR, [xShift yShift zShift]'./sf; 0 0 0 1];
% 
%  rotationMtx = newtrans;

[kE,dE] = nearpoints(movedElec', stationaryPoints');

signedDist = dot(  (movedElec - stationaryPoints(kE,:))', N(:,kE));
elec2plot = 1:size(electrodes,1); 1:128;[17 75];

CI = nlparci(X,RESIDUAL,'jacobian',.5*JACOBIAN);
nP=10;
idx = 1;
fig = gcf;

for iPar =1:length(CI),
    
    thisParLo = CI(iPar,1);
    thisParHi = CI(iPar,2);
    %    parSamp(iPar,:) = linspace(CI(iPar,1),CI(iPar,2),nP);

    
    thisXLo = X;
    thisXHi = X;

    thisXLo(iPar) = thisParLo;
    thisXHi(iPar) = thisParHi;

    movedElecLo = mrC.RigidRotate(thisXLo,electrodes);
    movedElecHi = mrC.RigidRotate(thisXHi,electrodes);

    dist(iPar) = max(sqrt(sum((movedElecLo(:,:)-movedElecHi(:,:)).^2,2)))./sf;
    
    for iElec = elec2plot,
        
        line2plot = [ movedElecLo(iElec,:); ...
            movedElecHi(iElec,:)]./sf./1000;
    
       
        line(line2plot(:,1),line2plot(:,2),line2plot(:,3),'linewidth',2,'color',[.8 .4 0]);
    end
%    allResid(iPar,iPar2,iSamp,iSamp2) = sum(rotcostfunclsq(thisX,stationaryPoints,electrodes,headshape,N).^2);

end

axLim = axis;

%title(['Electrodes fit to within: ' num2str(max(dist/2)) ' mm'])
text(axLim(2),axLim(3),axLim(6),['Electrodes fit to within: ' num2str(max(dist/2),2) ' mm']);

%disp('test')
%rotationMtx = params;
%{
xShift = params(1);
yShift = params(2);
zShift = params(3);



clf;
scatter3(fMRI(:,1)+xShift,fMRI(:,2)+yShift,fMRI(:,3)+zShift,'r')
hold on;

scatter3(VEP(:,1),VEP(:,2),VEP(:,3),'b')
%}

end

function dist = rotcostfunc(params,stationaryPoints,movablePoints)
    movedPoints = mrC.RigidRotate(params,movablePoints);
    %[K,D] = nearpoints(src, dest) 

    [K,D] = nearpoints(movedPoints', stationaryPoints'); 
    % [K,D] = nearpoints(stationaryPoints',movedPoints'); 


    %[K,D] = dsearchn(stationaryPoints,movedPoints);


    %dist = sum(D(sqrt(D)<20));
    dist = sum(D);

    %dist = sum(sum((stationaryPoints - movedPoints).^2));
end

    
function dist = rotcostfunc2(params,stationaryPoints,electrodes,headshape,N)

    movedElec = mrC.RigidRotate(params,electrodes);


    [kE,dE] = nearpoints(movedElec', stationaryPoints');

    signedDist = dot(  (movedElec - stationaryPoints(kE,:))', N(:,kE));
    %    SSE = sum(signedDist-mean(signedDist)).^2;


    dE = sqrt(dE);
    dE(dE<30) = 30;
    dE = (dE-30).^2; 

    % figure(1);
    % hold on;
    % plot(signedDist)
    % 
    % figure(2);
    % hold on;
    % plot(dE)
    % 
    % figure(3)
    % hold on;
    % scatter3(movedElec(:,1),movedElec(:,2),movedElec(:,3),'k')
    %[K,D] = dsearchn(stationaryPoints,movedPoints);

    if ~isempty(headshape)
        movedHead = mrC.RigidRotate(params,headshape);
        [kH,dH] = nearpoints(movedHead', stationaryPoints');
       % [mean(dH) var(signedDist)]
        dist = mean(dH)+var(signedDist);
    else

        dist = var(signedDist) +sum(dE);
    end



        %dist = sum(sum((stationaryPoints - movedPoints).^2));


    %{
        hold off;
        clf;
        scatter3(stationaryPoints(:,1),stationaryPoints(:,2),stationaryPoints(:,3),'r')
        hold on
        scatter3(movedPoints(:,1),movedPoints(:,2),movedPoints(:,3),'k')
        scatter3(movablePoints(:,1),movablePoints(:,2),movablePoints(:,3),'b')
        drawnow;
    pause

    %}
end
    
function [dist meanDist] = rotcostfunclsq(params,stationaryPoints,electrodes,headshape,N)
    movedElec = mrC.RigidRotate(params,electrodes);
    [kE,dE] = nearpoints(movedElec', stationaryPoints');
    signedDist = dot(  (movedElec - stationaryPoints(kE,:))', N(:,kE));
    %    SSE = sum(signedDist-mean(signedDist)).^2;

    meanDist = mean(signedDist);

    % figure(1);
    % hold on;
    % plot(signedDist)
    % 
    % figure(2);
    % hold on;
    % plot(dE)
    % 
    % figure(3)
    % hold on;
    % scatter3(movedElec(:,1),movedElec(:,2),movedElec(:,3),'k')
    %[K,D] = dsearchn(stationaryPoints,movedPoints);

    if ~isempty(headshape)
        movedHead = mrC.RigidRotate(params,headshape);
        [kH,dH] = nearpoints(movedHead', stationaryPoints');
       % [mean(dH) var(signedDist)]
        dist = [dH [signedDist-mean(signedDist)]];
    else
        dE = sqrt(dE);
        dE(dE<30) = 30;
        dE = (dE-30);
        dist = [dE + [signedDist - meanDist]];
    end
end

function rotMtx = makeRotMtx(params)
    xShift = params(1);
    yShift = params(2);
    zShift = params(3);
    a   = params(4);
    b   = params(5);
    g   = params(6);

    Rx = [1 0 0; 0 cos(a) -sin(a); 0 sin(a) cos(a) ];
    Ry = [ cos(b) 0 sin(b); 0 1 0; -sin(b) 0 cos(b) ];
    Rz = [ cos(g) -sin(g) 0;  sin(g) cos(g) 0;  0 0 1 ];
    newR = Rx*Ry*Rz;
    rotMtx = [newR, [xShift yShift zShift]'; 0 0 0 1];
end
