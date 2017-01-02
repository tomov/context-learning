function missing_voxels()

    % find missing voxels
    % everything is hardcoded 

    %S = EXPT.subject(subj);
    %mdir = sprintf('/ncf/gershman/Lab/ConLearn/glmOutput/model1/subj%d/', subj);
    %P{1} = fullfile(mdir,'mask.nii');
    %P{2} = fullfile(S.datadir,'wBrain.nii');
    P{1} = '/Users/memsql/Dropbox/research/context/glmOutput/model1/con2/mask.nii';
    P{2} = '/Users/memsql/Dropbox/research/context/glmOutput/mean.nii';
    spm_check_registration(char(P));
