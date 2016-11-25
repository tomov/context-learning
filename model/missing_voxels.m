function missing_voxels(EXPT,subj)

    % Check co-registration of structural and functional images. For the
    % functional image, this uses the mean of the first run following
    % normalization.
    %
    % USAGE: check_registration(EXPT,subj)

    S = EXPT.subject(subj);
    mdir = sprintf('/ncf/gershman/Lab/ConLearn/glmOutput/model1/subj%d/', subj);
    P{1} = fullfile(mdir,'mask.nii');
    P{2} = fullfile(S.datadir,'wBrain.nii');
    spm_check_registration(char(P));
