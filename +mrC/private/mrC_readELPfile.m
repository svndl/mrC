function [Epos,Ename,Etype,Fpos,kSort] = mrC_readELPfile(fileName,sortByName,xfmFid,swapDim)
% reads elp-format electrode position files
% [Epos,Ename,Etype,Fpos] = mrC_readELPfile(fileName,sortByName,xfmFid,swapDim)
% Epos        = nx3 numeric array of electrode positions.  zero @ origin (m)
%               columns = [anterior, left, superior] ?
% Ename,Etype = nx1 cell arrays of electrode name and type strings
% Fpos        = nx3 numeric array of fiducial positions
% fileName    = path string to elp-file
% sortByName  = boolean flag for sorting Epos rows by Ename values.  (optional, default = false)
%               In SKERI files: the REF electrode is 1st followed by 1:128
%                               sortByName = true puts the REF electrode ( Ename = '400' ) last
% xfmFid      = boolean flag for transforming coordinates so LA & RA fiducials are on y-axis, NZ still on +x
% swapDim     = 1x3 integer vector indicating change of dimension order/direction.  (optional, default = [1 2 3])
%               e.g. if native dimensions were ALS, swapDim = [ -2 1 3 ] 
%                    would yield RAS columns for Epos and Fpos.

% based on found SKERI unsnapped & snapped polhemus files
% and filespec in http://www.sourcesignal.com/formats_probe.html

if ~exist('fileName','var') || isempty(fileName)
	[fileStr,pathStr] = uigetfile('*.elp','Polhemus elp-file');
	if isnumeric(fileStr)
		return
	end
	fileName = [pathStr,fileStr];
end

fid = fopen(fileName,'r');
if fid == -1
	error('can''t open %s',fileName)
end

% read prolog
c = textscan(fid,'%n',3,'commentstyle','//');
% read header
c = textscan(fid,'%s',2,'commentstyle','//');
if strcmp(c{1}{1},'%N')
	c = textscan(fid,'%n',2,'commentstyle','//');
% 	typecode = c{1}(1);
	channels = c{1}(2);
else
% 	typecode = eval(c{1}{1});
	channels = eval(c{1}{2});
end
% check for fiducials
c = textscan(fid,'%s',1,'commentstyle','//');
Fpos = [];
while strcmp(c{1},'%F')
	c = textscan(fid,'%n',3,'commentstyle','//');
	Fpos = cat(1,Fpos,c{1}');		% presumably [ NZx NZy NZz; LAx LAy LAz; RAx RAy RAz ]
	c = textscan(fid,'%s',1,'commentstyle','//');
end
Ename = cell(channels,1);
Etype = cell(channels,1);
Epos = zeros(channels,3);		% position (m), orientation
i = 0;
while strcmp(c{1},'%S')
	i = i+1;
	% read Type Code
	c = textscan(fid,'%s',1,'commentstyle','//');
	Etype{i} = c{1}{1};
	fpos = ftell(fid);
	% check for Name [optional]
	c = textscan(fid,'%s',2,'commentstyle','//');
	if strcmp(c{1}{1},'%N')
		Ename{i} = c{1}{2};
	else
		if fseek(fid,fpos,-1)~=0
			error('problem setting file position indicator.')
		end
	end
	fpos = ftell(fid);
	% check for "sphere origin" ???not in spec???
	c = textscan(fid,'%s',1,'commentstyle','//');
	if strcmp(c{1}{1},'%O')
		c = textscan(fid,'%n',3,'commentstyle','//');
	else
		if fseek(fid,fpos,-1)~=0
			error('problem setting file position indicator.')
		end
	end
	% read electrode position
	c = textscan(fid,'%n',3,'commentstyle','//');
	Epos(i,1:3) = c{1}(:)';
	% check for orientation???
	
	% look for next electrode
	c = textscan(fid,'%s',1,'commentstyle','//');
	if isempty(c{1})
		if fclose(fid)~=0
			warning('problem closing %s',fileName)
		end
		break
	end
end	

if i ~= channels
	fprintf(1,'\nWarning: %d channels found, %d expected.\n',i,channels)
end

if exist('sortByName','var') & sortByName			% don't use &&, won't work with non-logical zero or empty
	try
		% put reference electrode 400 @ end
		[junk,kSort] = sort(cellfun(@eval,Ename));
		Epos = Epos(kSort,:);
		Ename = Ename(kSort);
		Etype = Etype(kSort);
	catch
		warning('Unable to sort names in %s',fileName)
	end
else
	kSort = [];
end

if exist('xfmFid','var') & xfmFid
	rLA = hypot( Fpos(2,1), Fpos(2,2) );
	cosa = Fpos(2,2) / rLA;
	sina = Fpos(2,1) / rLA;
	yNZ  = Fpos(1,1)*sina; % + Fpos(1,2)*cosa;		% Fpos(1,2) = 0, NZy
	Fpos(:,1:2) = [ Fpos(:,1)*cosa-Fpos(:,2)*sina, Fpos(:,1)*sina+Fpos(:,2)*cosa-yNZ ];
	Epos(:,1:2) = [ Epos(:,1)*cosa-Epos(:,2)*sina, Epos(:,1)*sina+Epos(:,2)*cosa-yNZ ];
end

if exist('swapDim','var')
	if isnumeric(swapDim) && (numel(swapDim)==3)
		kSwap = abs(swapDim);
		if all(sort(kSwap(:))==[1;2;3])
			Epos = Epos(:,kSwap);
			Fpos = Fpos(:,kSwap);
			kFlip = swapDim < 0;
			if any(kFlip)
				Epos(:,kFlip) = -Epos(:,kFlip);
				Fpos(:,kFlip) = -Fpos(:,kFlip);
			end
			return
		end
	end
	error('Invalid swapDim input to mrC_readELPfile.  Valid inputs satisfy: sort(abs(swapDim)) = [1 2 3]')
end
