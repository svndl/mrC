function [amplBounds,errorEllipse] = fitErrorEllipse(xyData,ellipseType,makePlot)
%[amplBounds,errorEllipse] = fitErrorEllipse(xyData,[withinSubj],[ellipseType],[makePlot])
%   user provides xyData, an Nx2 matrix of 2D data of N samples
%   opt. input ellipseType can be 'SEM' '95CI' or a string specifying

%       a different percentage CI formated following: '%.1fCI'. Default is
%       'SEM'.
%   opt. input makePlot is a logical specifying whether or not to
%       generate a plot of the data & ellipse & eigen vectors (draw at
%       length of 1 std dev, i.e. sqrt(corresponding eigenvalue))
%
%   *NOTE: For EEG measurements in the Fourier domain, xyData rows should
%   be: [real,imag].
%
%   The function uses the eigen value decomposition to find the two
%   perpandicular axes aligned with the data in xyData, where the
%   eigenvalues of each eigen vector correspond to the variances along each
%   direction. An ellipse is then fit to this data, at a distance from the
%   mean datapoint depending on the type of ellipseType specified.
%
%   Calculations for the error ellipses based on alpha-specified confidence
%   regions (e.g. 95%CI or 68%CI) are calculated following information from
%   Chapter 5 of Johnson & Wickern (2007) Applied Multivariate Statistical
%   Analysis, Pearson Prentice Hall.
%
%   Dependency: eigFourierCoefs.m which is also in functions/helper/

xyData = double(xyData); 

if nargin<2 || isempty(ellipseType)
    ellipseType = 'SEM';
end
if nargin<3
    makePlot = false;
end

dims = size(xyData);
N = dims(1);
if dims(2) ~= 2
    error('input data must be a matrix of 2D row samples');
end
if N < 2
    error('input data must contain at least 2 samples');
end

srIx = 1;
siIx = 2;

try
    [meanXy,~,smaller_eigenvec,smaller_eigenval,larger_eigenvec,larger_eigenval,phi] = eigFourierCoefs(xyData);
catch
    fprintf('The eigen value decomposition of xyData could not be run, probably your data do not contain >1 sample.');
end

theta_grid = linspace(0,2*pi);

switch ellipseType
    case '1STD'
        a = sqrt(larger_eigenval); 
        b = sqrt(smaller_eigenval);
    case '2STD'
        a = 2*sqrt(larger_eigenval); 
        b = 2*sqrt(smaller_eigenval);
    case 'SEMarea'
        a = sqrt(larger_eigenval/sqrt(N)); % scales the ellipse's area by sqrt(N)
        b = sqrt(smaller_eigenval/sqrt(N));
    case {'SEMellipse' 'SEM'} % default
        a = sqrt(larger_eigenval)/sqrt(N); % contour at stdDev/sqrt(N)
        b = sqrt(smaller_eigenval)/sqrt(N);
    case '95CI'
        % following Eqn. 5-19 of Johnson & Wichern (2007):
        t0_sqrd = ( (N-1)*2 ) / ( N*(N-2) ) * finv( 0.95, 2, N - 2 ); 
        a = sqrt(larger_eigenval*t0_sqrd);
        b = sqrt(smaller_eigenval*t0_sqrd);
    otherwise
        if strcmp(ellipseType(end-1:end),'CI')
            critVal = str2double(ellipseType(1:end-2))./100;
            if critVal < 1 && critVal > 0                
                % following Eqn. 5-19 of Johnson & Wichern (2007):
                t0_sqrd = ( (N-1)*2 )/( N*(N-2) ) * finv( critVal, 2, N - 2 ); 
                a = sqrt(larger_eigenval*t0_sqrd);
                b = sqrt(smaller_eigenval*t0_sqrd);
            else
                error('CI range must be on the interval (0, 100). Please see the help!')
            end
        else
            error('You entered an invalid error ellipse type. Please see the help!')
        end
end

% the ellipse in x and y coordinates
ellipse_x_r  = a*cos( theta_grid );
ellipse_y_r  = b*sin( theta_grid );

%Define a rotation matrix
R = [ cos(phi) sin(phi); -sin(phi) cos(phi) ];

%let's rotate the ellipse to some angle phi
errorEllipse = [ellipse_x_r;ellipse_y_r]' * R;

%Shift to be centered on mean coordinate
errorEllipse = bsxfun(@plus,errorEllipse,meanXy);

% find vector lengths of each point on the ellipse
norms = nan(1,length(errorEllipse));
for pt = 1:length(errorEllipse)
    norms(pt) = norm(errorEllipse(pt,:));
end
[minNorm,minNormIx] = min(norms);
[maxNorm,maxNormIx] = max(norms);
ellipseExtremes = [minNorm,maxNorm];

if (sign(max(errorEllipse(:,1))) ~= sign(min(errorEllipse(:,1)))) && (sign(max(errorEllipse(:,2))) ~= sign(min(errorEllipse(:,2))))
    % the ellipse overlaps with the origin
    amplBounds = [0, maxNorm];
else
    amplBounds = ellipseExtremes;
end


if makePlot
    figure;
    subplot(1,2,1);
    hold on;
    plot(xyData(:,srIx),xyData(:,siIx),'ko','MarkerFaceColor','k') 
    axis equal;
    line([0 meanXy(1)],[0 meanXy(2)],'Color','k','LineWidth',1);    
    plot(errorEllipse(:,1), errorEllipse(:,2),'b-','LineWidth',1);   
    hold on;
    plot([meanXy(1) sqrt(smaller_eigenval).*smaller_eigenvec(1)+meanXy(1)],[meanXy(2) sqrt(smaller_eigenval).*smaller_eigenvec(2)+meanXy(2)],'g-','LineWidth',1); 
    plot([meanXy(1) sqrt(larger_eigenval).*larger_eigenvec(1)+meanXy(1)],[meanXy(2) sqrt(larger_eigenval).*larger_eigenvec(2)+meanXy(2)],'m-','LineWidth',1); 
    line([0 0],[min(ylim) max(ylim)],'Color','k')
    line([min(xlim) max(xlim)],[0 0],'Color','k')
    text(.9*min(xlim),.7*min(ylim),[ellipseType ' ellipse'],'FontSize',14,'Color','b');
    text(.9*min(xlim),.6*min(ylim),'larger eigen vec','FontSize',14,'Color','m');
    text(.9*min(xlim),.5*min(ylim),'smaller eigen vec','FontSize',14,'Color','g');
    
    subplot(1,2,2);
    hold on;
    axis equal; 
    
    plot(errorEllipse(:,1), errorEllipse(:,2),'k-','LineWidth',1)
    plot([0 errorEllipse(minNormIx,1)],[0 errorEllipse(minNormIx,2)],'r:','LineWidth',1);
    plot([0 errorEllipse(maxNormIx,1)],[0 errorEllipse(maxNormIx,2)],'r:','LineWidth',1);
    
    line([0 meanXy(1)],[0 meanXy(2)],'Color','k','LineWidth',1); % mean vector 
    
    plot([meanXy(1) a.*larger_eigenvec(1)+meanXy(1)],[meanXy(2) a.*larger_eigenvec(2)+meanXy(2)],'m-','LineWidth',1) % half major axis (1)
    plot([meanXy(1) -a.*larger_eigenvec(1)+meanXy(1)],[meanXy(2) -a.*larger_eigenvec(2)+meanXy(2)],'m-','LineWidth',1) % half major axis (2)
    plot([meanXy(1) b.*smaller_eigenvec(1)+meanXy(1)],[meanXy(2) b.*smaller_eigenvec(2)+meanXy(2)],'g-','LineWidth',1) % half minor axis (1)
    plot([meanXy(1) -b.*smaller_eigenvec(1)+meanXy(1)],[meanXy(2) -b.*smaller_eigenvec(2)+meanXy(2)],'g-','LineWidth',1) % half minor axis (2)
    
    text(errorEllipse(minNormIx,1),errorEllipse(minNormIx,2),sprintf('%.2f',minNorm),'FontSize',18,'Color','r')
    text(errorEllipse(maxNormIx,1),errorEllipse(maxNormIx,2),sprintf('%.2f',maxNorm),'FontSize',18,'Color','r')
    
    text(meanXy(1),meanXy(2),sprintf('%.2f',norm(meanXy)),'FontSize',18)
    text(.9*min(xlim),.7*min(ylim),'bounds','FontSize',14,'Color','r');
    text(.9*min(xlim),.6*min(ylim),'mean ampl.','FontSize',14,'Color','k');

    line([0 0],[min(ylim) max(ylim)],'Color','k','LineWidth',1)
    line([min(xlim) max(xlim)],[0 0],'Color','k','LineWidth',1)    
end












