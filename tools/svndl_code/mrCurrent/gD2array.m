function [Y,Ydim] = gD2array(gD,gVEPInfo,gSbjROIFiles,SourceSpace,Domain,Filter)
% [Y,Ydim] = gD2array(gD,gVEPInfo,gSbjROIFiles,SourceSpaceFlag,Domain,Filter)
% INPUTS: gD,gVEPInfo,gSbjROIFiles = workspace variables exported by mrCurrent
%         SourceSpaceFlag = true for source space, false for sensor space
%         Domain = 'Wave', 'Spec', or 'Harm'
%         Filter = name of filter.  default = 'none'.  (only applies to 'Wave' Domain).
% OUTPUTS: Y = N-dimensional data array
%          Ydim = Nx1 cell array labeling what's in each dimension of Y
%
% 1st dimension of Y = time for 'Wave' domain, frequency for 'Spec', component for 'Harm'
% 2nd dimension of Y = ROIs for source space, electrode channels for sensor space
% 3rd dimesions of Y = Subjects
% 4th dimension of Y = Conditions
% 5th dimension of Y = Inverses (source space only)
% 6th dimension of Y = Inverse types (source space only)
% 7th dimension of Y = Hemisphere (source space only)
%
% NOTE: CalcItems are not included in Y

Sbjs = fieldnames(gD)';
Cnds = fieldnames(gD.(Sbjs{1}))';
Cnds = Cnds( ~( strcmp(Cnds,'ROI') | strcmp(Cnds,'SsnHeader') ) );
nSbj = numel(Sbjs);
nCnd = numel(Cnds);
if nargin < 6
	Filter = 'none';
end

Mtg = 'Exp_MATL_HCN_128_Avg';		% *** smartly detect this, mrCurrent looks for Exp_MATL*, only allow 1 montage

if SourceSpace
	Invs = fieldnames(gD.(Sbjs{1}).ROI)';
	nInv = numel(Invs);
	InvTypes = fieldnames(gD.(Sbjs{1}).ROI.(Invs{1}))';
	nInvType = numel(InvTypes);
	Hems = {'Left','Right','Bilateral'};
	nHem = numel(Hems);
	% only getting ROIs that exist in all subjects & both hemispheres
	ROIs = gSbjROIFiles.(Sbjs{1}).Name( gSbjROIFiles.(Sbjs{1}).Hem == 3 );
	for i = 2:nSbj
		ROIs = intersect( ROIs, gSbjROIFiles.(Sbjs{i}).Name( gSbjROIFiles.(Sbjs{i}).Hem == 3 ) );
	end
	nCol = numel(ROIs);
else
	nCol = 128;
end


switch Domain
case 'Wave'
	nRow = numel( gD.(Sbjs{1}).(Cnds{1}).(Mtg).Wave.(Filter)(:,1) );
	if SourceSpace
		Y =                          zeros( nRow , nCol, nSbj, nCnd, nInv, nInvType, nHem );
		Ydim = { gVEPInfo.(Cnds{1}).dTms*(1:nRow); ROIs; Sbjs; Cnds; Invs; InvTypes; Hems };
		for i3 = 1:nSbj
			[junk,kROI] = ismember( ROIs, gSbjROIFiles.(Sbjs{i3}).Name );
			for i4 = 1:nCnd
				if isfield( gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Wave, Filter )
					for i5 = 1:nInv
						for i6 = 1:nInvType
							for i7 = 1:nHem
								Y(:,:,i3,i4,i5,i6,i7) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Wave.(Filter)...
															 * gD.(Sbjs{i3}).ROI.(Invs{i5}).(InvTypes{i6})(:,kROI,i7);
							end
						end
					end
				else
					error('Filter %s isn''t populated in gD for all Subjects & Conditions, e.g. %s %s.',Filter,Sbjs{i3},Cnds{i4})
				end
			end
		end
	else
		Y =                          zeros( nRow ,   nCol, nSbj, nCnd );
		Ydim = { gVEPInfo.(Cnds{1}).dTms*(1:nRow); 1:nCol; Sbjs; Cnds };
		for i3 = 1:nSbj
			for i4 = 1:nCnd
				if isfield( gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Wave, Filter )
					Y(:,:,i3,i4) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Wave.(Filter);
				else
					error('Filter %s isn''t populated in gD for all Subjects & Conditions, e.g. %s %s.',Filter,Sbjs{i3},Cnds{i4})
				end
			end
		end
	end
case 'Spec'
	if SourceSpace
		Y =                          zeros( gVEPInfo.(Cnds{1}).nFr , nCol, nSbj, nCnd, nInv, nInvType, nHem );
		Ydim = { gVEPInfo.(Cnds{1}).dFHz*(1:gVEPInfo.(Cnds{1}).nFr); ROIs; Sbjs; Cnds; Invs; InvTypes; Hems };
		for i3 = 1:nSbj
			[junk,kROI] = ismember( ROIs, gSbjROIFiles.(Sbjs{i3}).Name );
			for i4 = 1:nCnd
				for i5 = 1:nInv
					for i6 = 1:nInvType
						for i7 = 1:nHem
							Y(:,:,i3,i4,i5,i6,i7) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Spec...
								                   * gD.(Sbjs{i3}).ROI.(Invs{i5}).(InvTypes{i6})(:,kROI,i7);
						end
					end
				end
			end
		end
	else
		Y =                         zeros(  gVEPInfo.(Cnds{1}).nFr ,   nCol, nSbj, nCnd );
		Ydim = { gVEPInfo.(Cnds{1}).dFHz*(1:gVEPInfo.(Cnds{1}).nFr); 1:nCol; Sbjs; Cnds };
		for i3 = 1:nSbj
			for i4 = 1:nCnd
				Y(:,:,i3,i4) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Spec;
			end
		end
	end
case 'Harm'
	Comps = fieldnames(gD.(Sbjs{1}).(Cnds{1}).(Mtg).Harm)';
	CompNms = strrep( Comps, 'x', '' );
	CompNms = strrep( CompNms, 'p', '+' );
	CompNms = strrep( CompNms, 'm', '-' );
	nComp = numel(Comps);
	if SourceSpace
		Y = zeros(   nComp, nCol, nSbj, nCnd, nInv, nInvType, nHem );
		Ydim =   { CompNms; ROIs; Sbjs; Cnds; Invs; InvTypes; Hems };
		for i1 = 1:nComp
			for i3 = 1:nSbj
				[junk,kROI] = ismember( ROIs, gSbjROIFiles.(Sbjs{i3}).Name );
				for i4 = 1:nCnd
					for i5 = 1:nInv
						for i6 = 1:nInvType
							for i7 = 1:nHem
% 								Y(i1,:,i3,i4,i5,i6,i7) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Harm.(Comps{i1})...
% 									                    * gD.(Sbjs{i3}).ROI.(Invs{i5}).(InvTypes{i6})(:,kROI,i7);
								iSpec = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Harm.(Comps{i1});
								Y(i1,:,i3,i4,i5,i6,i7) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Spec(iSpec,:)...
									                    * gD.(Sbjs{i3}).ROI.(Invs{i5}).(InvTypes{i6})(:,kROI,i7);
							end
						end
					end
				end
			end
		end
	else
		Y = zeros(   nComp,   nCol, nSbj, nCnd );
		Ydim =   { CompNms; 1:nCol; Sbjs; Cnds };
		for i3 = 1:nSbj
			for i4 = 1:nCnd
				for i1 = 1:nComp
% 					Y(i1,:,i3,i4) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Harm.(Comps{i1});
					iSpec = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Harm.(Comps{i1});
					Y(i1,:,i3,i4) = gD.(Sbjs{i3}).(Cnds{i4}).(Mtg).Spec(iSpec,:);
				end
			end
		end
	end
end



