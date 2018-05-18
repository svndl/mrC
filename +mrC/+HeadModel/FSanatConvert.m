function success = FSanatConvert(subj_id,nifti_folder)
    % success = mrC.Headmodel.FSanatConvert(subj_id)

    if ~isempty(strfind(subj_id,'_fs4'));
        subj_id = subj_id(1:end-4); % get rid of FS suffix, if given by user
    else
    end

    [fs_dir,anat_dir] = mrC.SystemSetup;
    if nargin < 2
        nifti_folder = sprintf('%s/%s/nifti',anat_dir,subj_id);
        if ~exist(nifti_folder,'dir')
            mkdir(nifti_folder);
        else
        end
    else
    end
    
    fs_files = {'orig.mgz','nu.mgz','brain.mgz','T2.mgz','ribbon.mgz'};
    
    for f = 1:length(fs_files);
        in_file = sprintf('%s/%s_fs4/mri/%s',fs_dir,subj_id,fs_files{f});
        if exist(in_file,'file')
            [~,out_name] = fileparts(fs_files{f});
            out_file = sprintf('%s/%s_FS4_%s.nii.gz',nifti_folder,subj_id,out_name);
            cmd_list{1} = 'source ~/.bashrc';
            cmd_list{2} = sprintf('mri_convert %s %s',in_file,out_file);
            cmd_list{3} = sprintf('fslswapdim %s x z -y %s',out_file,out_file);
            if strcmp(fs_files{f},'ribbon.mgz')
                cmd_list{4} = sprintf('fslmaths %s -thr 2 -uthr 2 %s/tmpWhiteL',out_file,nifti_folder);
                cmd_list{5} = sprintf('fslmaths %s -thr 41 -uthr 41 %s/tmpWhiteR',out_file,nifti_folder);
                cmd_list{6} = sprintf('fslmaths %s/tmpWhiteL.nii.gz -add %s/tmpWhiteR.nii.gz -bin %s/%s_FS4_wm.nii.gz',nifti_folder,nifti_folder,nifti_folder,subj_id);
                cmd_list{7} = sprintf('rm %s/tmpWhiteL.nii.gz',nifti_folder);
                cmd_list{8} = sprintf('rm %s/tmpWhiteR.nii.gz',nifti_folder);
            elseif strcmp(fs_files{f},'nu.mgz')
                cmd_list{4} = sprintf('cp %s %s/../vAnatomy.nii.gz',out_file,nifti_folder);
            end
        else
            msg = sprintf('\n ... %s does not exist, so not copied \n',in_file);
            warning(msg);
        end
        % execute the commands
        cmd_ready = strjoin(cmd_list,'; ');
        status(f) = system(cmd_ready);
    end
    success = all(status==0);
end