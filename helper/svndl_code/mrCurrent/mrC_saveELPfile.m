function mrC_saveELPfile(fiducialCoords,sensorCoords,sensorTypes,sensorNames,fileStr,kNaN)
% Save data in elp-format for use with mrCurrent
%
% SYNTAX:	mrC_saveELPfile(fiducialCoords,sensorCoords,sensorTypes,sensorNames,[elpFileStr])
% 
% fiducialCoords = 3x3 matrix of cartesian fiducial coordinates
%                  rows are [ NZ; LA; RA ]
%                  cols are [  X,  Y,  Z ]
% sensorCoords   = Nx3 matrix of cartesian sensor coordinates
% sensorTypes    = N-element cell vector of sensor type strings.
%                  e.g. '1C00' for REF electrode, '400' for everything else
% sensorNames    = N-element cell vector of sensor name strings.
%                  e.g.  '400' for REF electrode, int2str(#) for everything else
% elpFileStr     = optional name of file to save to avoid GUI dialog
%
% SKERI Polhemus elp-file conventions:
% +X = anterior (m)
% +Y = left (m)
% +Z = superior (m)
% fiducials on Z=0 plane
% origin at midpoint of LA-RA
% NZ on +X axis


if ~exist('fileStr','var') || isempty(fileStr)
	[elpFile,elpPath] = uiputfile('*.elp','Save elp-file');
	if isnumeric(elpFile)
		return
	end
	fileStr = [elpPath,elpFile];
end

nSensor = size(sensorCoords,1);
if ~exist('kNaN','var') || isempty(kNaN)
	kNaN = false(nSensor,1);	% flag for commenting sensor as "edited"
end

fid = fopen(fileStr,'w');
if fid == -1
	error('Error opening %s',fileStr)
end
fprintf(fid,'3\t2\r\n//Probe file\r\n//Minor revision number\r\n1\r\n');
fprintf(fid,'//ProbeName\r\n%%N\tName    \r\n//Probe type, number of sensors\r\n0\t%d\r\n',nSensor);
fprintf(fid,'//Position of fiducials X+, Y+, Y- on the subject\r\n');
fprintf(fid,'%%F\t%0.4f\t%0.4f\t%0.4f\r\n',fiducialCoords(1,:));
fprintf(fid,'%%F\t%0.4f\t%0.4f\t%0.4f\r\n',fiducialCoords(2,:));
fprintf(fid,'%%F\t%0.4f\t%0.4f\t%0.4f\r\n',fiducialCoords(3,:));
for i = 1:nSensor
	fprintf(fid,'//Sensor type\r\n%%S\t%s\r\n',sensorTypes{i});
	if kNaN(i)
		fprintf(fid,'//Sensor name and edited data for sensor # %d\r\n',i-1);
	else
		fprintf(fid,'//Sensor name and data for sensor # %d\r\n',i-1);
	end
	fprintf(fid,'%%N\t%-8s\r\n%0.4f\t%0.4f\t%0.4f\r\n',sensorNames{i},sensorCoords(i,:));
end
if fclose(fid) == -1
	error('Problem closing %s',fileStr)
else
	disp(['Wrote ',fileStr])
end
