function success = TriMaker(subj_id,headmodel_folder)
    % success = mrC.Headmodel.TriMaker(subj_id)
    if strfind(subj_id,'_fs4');
        subj_id = subj_id(1:end-4); % get rid of FS suffix, if given by user
    else
    end
    
    [fsDir,anatDir] = mrC.SystemSetup;
    if nargin < 2
        headmodel_folder = sprintf('%s/%s/headmodels',anatDir,subj_id);
    else
    end
    
    if ~exist(headmodel_folder,'dir');
        msg = sprintf('headmodel folder %s does not exist!',headmodel_folder);
        error(msg); 
    else
    end
    
    if exist(sprintf('%s/headmodel_inskull_mesh.vtk',headmodel_folder),'file');
        fprintf('\n ... reading vtk-files from %s \n',headmodel_folder);
        [V1,F1] = read_vtk(sprintf('%s/headmodel_inskull_mesh.vtk',headmodel_folder));
        [V2,F2] = read_vtk(sprintf('%s/headmodel_outskull_mesh.vtk',headmodel_folder));
        [V3,F3] = read_vtk(sprintf('%s/headmodel_outskin_mesh.vtk',headmodel_folder));
        V1 = V1'; V2 = V2'; V3 = V3';
        F1 = F1'; F2 = F2'; F3 = F3';
    else
        fprintf('\n ... reading off-files from %s \n',headmodel_folder);
        [V1,F1] = geomview_read_off(sprintf('%s/headmodel_inskull_mesh.off',headmodel_folder));
        [V2,F2] = geomview_read_off(sprintf('%s/headmodel_outskull_mesh.off',headmodel_folder));
        [V3,F3] = geomview_read_off(sprintf('%s/headmodel_outskin_mesh.off',headmodel_folder));
    end
    % LAS, columns, outward normals, 1-indexing faces, origin @ RPI volume corner
    % zero @ volume center, flip LR, (zero-index faces)
    V1 = V1 - 128;			V1(:,1) = -V1(:,1);			% F1 = F1 - 1;
    V2 = V2 - 128;			V2(:,1) = -V2(:,1);			% F2 = F2 - 1;
    V3 = V3 - 128;			V3(:,1) = -V3(:,1);			% F3 = F3 - 1;
    
    % PLOT
    figure;
    P = [ ...
            patch(struct('vertices',V1,'faces',F1),'FaceVertexCData',[0 0 1],'facecolor','flat','edgecolor','none'),...
            patch(struct('vertices',V2,'faces',F2),'FaceVertexCData',[1 1 0],'facecolor','flat','edgecolor','none','facealpha',0.5),...
            patch(struct('vertices',V3,'faces',F3),'FaceVertexCData',[1 0 0],'facecolor','flat','edgecolor','none','facealpha',0.25)...
        ];
    light('position',[0 0 256],'color',[1 1 1],'style','infinite');
    set(gca,'xlim',[-128 128],'xtick',-128:32:128,'xgrid','on',...
        'ylim',[-128 128],'ytick',-128:32:128,'ygrid','on',...
        'zlim',[-128 128],'ztick',-128:32:128,'zgrid','on',...
        'view',[90 0],'dataaspectratio',[1 1 1])
    set(P,'facelighting','gouraud')
    xlabel('+right'),ylabel('+anterior'),zlabel('+superior')
    drawnow;

    % SAVE
    triDir = sprintf('%s/%s_fs4/bem',fsDir,subj_id);
    status(1) = writeTriFile(V1,F1,fullfile(triDir,'inner_skull.tri'));	%,'betsurf mesh')
    status(2) = writeTriFile(V2,F2,fullfile(triDir,'outer_skull.tri'));	%,'betsurf mesh')
    status(3) = writeTriFile(V3,F3,fullfile(triDir,'outer_skin.tri'));	%,'betsurf mesh')
    success = all(status==0);
end

function status = writeTriFile(V,F,triFile,comment)
    % writes 3 column tri-files
    %
    % writeTriFile(vertices,faces,filename,comment)
    % vertices = vertex matrix [ +right, +anterior, +superior ] origin @ volume center
    % faces = triangular face matrix [ inward normals ] ???zero-indexed???

    [fid,msg] = fopen(triFile,'w');
    if fid == -1
        error(msg)
    end
    disp(['writing ',triFile])

    [mV,nV] = size(V);
    if nV == 3				% colums
        nV = mV;
        V = V';
        nF = size(F,1);
        F = F';
    elseif mV == 3			% rows
        nF = size(F,2);
    else
        error('vertex dimensions must be either Nx3 or 3xN')
    end
    
    % write data
    if exist('comment','var') && ~isempty(comment) && ischar(comment)
        if ~strcmp(comment(1),'#')
            fprintf(fid,'%s','# ');
        end
        fprintf(fid,'%s\n',comment);
    end
    
    fprintf(fid,'%g\n',nV);
    fprintf(fid,'%g %g %g\n',V);
    fprintf(fid,'%g\n',nF);
    fprintf(fid,'%g %g %g\n',F);
    status = fclose(fid);
end
