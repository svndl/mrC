function sol = MakeInvMne(fname_inv,lambda2,srcSpace,srcCor)
    % function [sol] = mrC.ReadMneInverse(fname_inv,lambda2,srcSpace,srcCov)
    %
    % Read MNE inverse operator from .fif file and use it to compute inverse in EMSE format
    %
    % fname_inv  - Name of the inverse file
    %
    % lambda2    - The regularization factor. lambda^2 ~ 1/SNR (POWER!)
    %              ex. 10/1 Power SNR -> lambda2 = .1;
    %              ex. 10/1 Amplitude SNR -> lambda2 = .01;
    %
    % srcSpace   - MNE source space structure that corresponds to the source
    %              space that was used to create the defaultCortex.mat
    % [srcCor]   - Optional srcCorrelation matrix. NOT COVARIANCE.
    %              The reason is that this matrix gets rescaled to the variance
    %              computed in the MNE src variance vector

    %
    %   $Header: /raid/CVS/ales/mneInv2EMSE.m,v 1.6 2008/10/02 23:14:47 ales Exp $
    %   $Log: mneInv2EMSE.m,v $
    %   Revision 1.6  2008/10/02 23:14:47  ales
    %   New added things.
    %
    %   Revision 1.5  2008/09/16 18:41:46  ales
    %   more fixes/changes to the MNE pipeline
    %
    %   Revision 1.4  2008/09/08 23:55:56  ales
    %   Fixed bugs
    %
    %   Revision 1.3  2008/08/20 20:39:28  ales
    %   Added a function to output 1 raw powerdiva matrix
    %
    %   Revision 1.2  2008/06/18 17:23:49  ales
    %   modified bits in generating the inverse.
    %
    %   Revision 1.1  2008/06/12 19:43:37  ales
    %   added a whole bunch of stuff used for getting into/out of MNE
    %   As well as L1 stuff:
    %   mrcPrepateL1.m: This file reads mrCurrent data and does L1 localization on it
    %   invokeCVX.m : This function does a complex frequency domain L1 localization
    %
    %   Revision 1.1  2006/05/05 03:50:40  msh
    %   Added routines to compute L2-norm inverse solutions.
    %   Added mne_write_inverse_sol_stc to write them in stc files
    %   Several bug fixes in other files
    %
    
    % read inverse operator
    inv = mne_read_inverse_operator(fname_inv);

    % set up the inverse according to the parameters

    nave = 1; % number of averages (scales the noise covariance)
    dSPM = false; % compute the noise-normalization factors for dSPM?
    % dSPM used to be an option, but I took it out as I was not sure how it
    % was implemented below - pjk
    inv = mne_prepare_inverse_operator(inv,nave,lambda2,dSPM);

    % calculating transformations to the total src space stored in default    
    % left hemisphere
    newDx = [];
    idx=1;
    for iHi=inv.src(1).vertno,
        newDx(idx) = find(srcSpace(1).vertno == iHi);
        idx=idx+1;
    end
    newDxLeft =newDx;
    
    % right hemisphere
    newDx = [];
    idx=1;
    for iHi=inv.src(2).vertno,
        newDx(idx) = find(srcSpace(2).vertno == iHi);
        idx=idx+1;
    end

    newDxRight =newDx;

    totalDx = [newDxLeft (newDxRight+double(srcSpace(1).nuse))];

    %   Pick the correct channels from the data
    %
    % data = fiff_pick_channels_evoked(data,inv.noise_cov.names);
    % fprintf(1,'Picked %d channels from the data\n',data.info.nchan);
    % fprintf(1,'Computing inverse...');
    %
    %   Simple matrix multiplication followed by combination of the 
    %   three current components
    %
    %   This does all the data transformations to compute the weights for the
    %   eigenleads
    %   
    %trans = diag(sparse(inv.reginv))*inv.eigen_fields.data*inv.whitener*inv.proj*double(data.evoked(1).epochs);
    
    inv.reginv = inv.sing./(inv.sing.*inv.sing + lambda2);

    trans = diag(sparse(inv.reginv))*inv.eigen_fields.data*inv.whitener*inv.proj;

    %A = inv.eigen_fields.data'*diag(inv.sing)*inv.eigen_leads.data';


    %   Transformation into current distributions by weighting the eigenleads
    %   with the weights computed above
    %
    %   JMA: I'm not sure if I'm doing this right, this step is tricky
    if ~exist('srcCor','var') || isempty(srcCor)
        srcCov=diag(sparse(sqrt(inv.source_cov.data)));
    else
        srcVar = mean(inv.source_cov.data(3:3:end));
        %Nead to map the srcCor to the set of valid vertices in this inverse:       
        srcCor = srcCor(totalDx,totalDx);

        %Next construct the sparse covariance matrix, in a form that allows the
        %kludged loose orientation constraint format to get the fixed orient.
        %we need to triple the size for the colomns that refer to the 3
        %orientations.
        nSrcs = length(totalDx);
        [i,j,s] = find(srcCor);
        
        srcCovDiag = inv.source_cov.data;
        srcCovDiag(i) = 0;

        %scaling the src cov is important for keeping the regularizer to have
        %the same meaning. Basically we want to keep the sources projecting to the same
        %power on the scalp relative to the noise

        s = sqrt(srcVar*s);%<- Scaling step, THIS IS TRICKY, important scaling, and it's probably wrong here

        srcCov = sparse(3*i,3*j,s,3*nSrcs,3*nSrcs);   %This reconstructs the full
                                                      %cov as a sparse matrix
        srcCov = srcCov + .1*diag(sparse(sqrt(srcCovDiag)));


        oldDiagPow = sum(inv.source_cov.data);
        newDiagPow = sum(diag(srcCov).^2);

        scaler = sqrt(oldDiagPow/newDiagPow);
        srcCov = scaler*srcCov;
    end
    
    %fprintf(1,'combining the current components...');
    %sol1 = zeros(inv.src.np,size(sol,2));

    %idx = 1;
    %for iX = 1:3: size(sol,1),

    %    iVert = inv.src.vertno(idx);
    %    sol1(iVert,:) = (inv.src.nn(iVert,:)*sol(iX:iX+2,:));

    %    This line depth weights the inverse:
    %    sol1(iVert,:) = (inv.src.nn(iVert,:)*sol(iX:iX+2,:))*inv.depth_prior.data(iX);
    %    idx = idx+1;
    %end

    %sol = sol1;

    sol   = srcCov*inv.eigen_leads.data*trans;

    % %if inv.source_ori == FIFF.FIFFV_MNE_FREE_ORI
    %     fprintf(1,'combining the current components...');
    %     sol1 = zeros(size(sol,1)/3,size(sol,2));
    %     for k = 1:size(sol,2)
    %         sol1(:,k) = sqrt(mne_combine_xyz(sol(:,k)));
    %     end
    %     sol = sol1;
    %    
    % end

    sol = sol(3:3:end,:);

    totalVerts = srcSpace(1).nuse + srcSpace(2).nuse;

    sol1 = zeros(totalVerts,size(sol,2));

    sol1(totalDx,:) = sol;

    sol = sol1;

    %if dSPM
    %    fprintf(1,'(dSPM)...');
    %    sol(inv.src.vertno,:) = inv.noisenorm*sol(inv.src.vertno,:);
    %end
end



