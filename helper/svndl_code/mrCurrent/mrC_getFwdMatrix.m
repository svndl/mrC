function Fwd = mrC_getFwdMatrix(fwdFile,subjid)
% Get #sensors x #sources forward solution matrix from mrCurrent project
%
% SYNTAX:   Fwd = mrC_getFwdMatrix(mrCprojDir,subjid)
%     or    Fwd = mrC_getFwdMatrix(fwdFileName,subjid)

% check for MNE toolbox
% if ~exist('mne_read_source_spaces','file')
% 	MNEtoolbox = fullfile(getpref('mrCurrent','AnatomyFolder'),'..','toolbox','MNESuite','mne','matlab','toolbox');
% 	if isdir(MNEtoolbox)
% 		addpath(MNEtoolbox,0)
% 	else
% 		error('MNE toolbox not on path, and\n%s\nis not a directory',MNEtoolbox)
% 	end
% end

% check for getFwdMatrix(mrCprojDir,subjid) syntax
if isdir(fwdFile)
	mrCfwdDir = fullfile(fwdFile,subjid,'_MNE_');
	if isdir(mrCfwdDir)
		% check for forward file
		fwdFiles = dir(fullfile(mrCfwdDir,'*-fwd.fif'));
		if numel(fwdFiles) == 1
			fwdFile = fullfile(mrCfwdDir,fwdFiles.name);
		elseif numel(fwdFiles) == 0
			error('no *-fwd.fif file(s) found in %s',mrCfwdDir)
		else
			fwdFile = fullfile(mrCfwdDir,fwdFiles(menu('Pick forward solution',{fwdFiles.name})).name);
		end
	else
		error('Directory %s does not exist.',mrCfwdDir)
	end
end

% get source space file
%srcFile = fullfile(getpref('mrCurrent','AnatomyFolder'),'FREESURFER_SUBS',[subjid,'_fs4'],'bem',[subjid,'_fs4-ico-5-src.fif']);
 srcFile = fullfile(getpref('mrCurrent','AnatomyFolder'),'FREESURFER_SUBS',[subjid,'_fs4'],'bem',[subjid,'_fs4-ico-5p-src.fif']);

% READ SOURCE SPACES & FORWARD SOLUTION
ss  = mne_read_source_spaces(srcFile);
fwd = mne_read_forward_solution(fwdFile);

	% check for matching # vertices (full freesurfer mesh, not decimations)
	if (size(fwd.src(1).rr,1)~=size(ss(1).rr,1)) || (size(fwd.src(2).rr,1)~=size(ss(2).rr,1))
		error('forward model solution has more different # vertices than chosen source space')
	end

% COMBINE 3 ORIENTATIONS IN FORWARD SOLUTION USING NORMALS
ns = fwd.sol.nrow;		% #sensors
if fwd.source_ori == 2	% 1 = normal to cortex only, 2 = all 3 source orientations
	% fwd.sol.data = [128 x 3*fwd.nsource] forward solution at 3 orientations per source
	% fwd.src(#).nn = [fwd.src(#).np x 3] components of unit normals.
	for o = 1:3							% orientations
		% component of surface normal at each orientation [1 x fwd.nsource]
		nn = [ fwd.src(1).nn(fwd.src(1).vertno,o); fwd.src(2).nn(fwd.src(2).vertno,o) ]';		% [LH,RH]
		% columns of fwd.sol corresponding to each orientation
		k = o:3:fwd.sol.ncol;
		for i = 1:ns
			fwd.sol.data(i,k) = fwd.sol.data(i,k) .* nn;
		end
	end
	fwd.sol.data = fwd.sol.data(:,1:3:fwd.sol.ncol)...
					 + fwd.sol.data(:,2:3:fwd.sol.ncol)...
					 + fwd.sol.data(:,3:3:fwd.sol.ncol);
end

% ZERO-MEAN REFERENCE FOR FOWARD MATRIX
fwd.sol.data = fwd.sol.data - repmat(mean(fwd.sol.data),ns,1);

% ADD ZERO COLUMNS FOR UNUSED VERTICES FROM SOURCE SPACE
Fwd = zeros(ns,sum([ss.nuse]));			% sensors x sources
Fwd(:,[ ismember(ss(1).vertno,fwd.src(1).vertno), ismember(ss(2).vertno,fwd.src(2).vertno) ],:) = fwd.sol.data;

