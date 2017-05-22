% almost same as kl_divergence except looking at peak voxel from
% ccnl_view(contextExpt(), 1, 'additive - irrelevant')
% in additive condition only, see how much beta from peak voxel
% correlates with thinking that c1 makes you sick (choice probability on
% x3c1)
%
% run after kl_divergence.m 
%kl_divergence
%
% TODO dedupe with kl_structure_learning.m
%


EXPT = contextExpt();
modeldir = EXPT.modeldir;
%V = spm_vol(fullfile(modeldir, ['model59'], ['subj1'], sprintf('beta_%04d.nii',1)));
%V = spm_vol(fullfile(modeldir, ['model53'], ['con1'], sprintf('con_%04d.nii',1)));
V = spm_vol(fullfile(modeldir, ['model1'], ['con2'], 'spmT_0001.nii')); % T-value map
Y = spm_read_vols(V);

cor = mni2cor([-18 -16 -18],V.mat)
Y(cor(1), cor(2), cor(3)) % sanity check -- should be 5.7480 (as seen in ccnl_view Show Results Table)
assert(abs(Y(cor(1), cor(2), cor(3)) - 5.7480) < 1e-3);


%% load the KL betas and compute the structure learning effect
%

% peak_voxels = peak voxel from each interesting cluster
% obtained from Show Results Table from ccnl_view(contextExpt(), 1,
% 'additive - irrelevant');
% note that we're overriding the max_voxels from kl_divergence.m TODO coupling
%
rois = {'Hippocampus_L'};
peak_voxels = {[-18 -16 -18]};

n_runs_per_condition = 3;

chose_sick_on_x3c1 = nan(n_runs_per_condition, n_subjects); % structure learning effect (SLE) for each run for each subject
kl_betas = nan(n_runs_per_condition, n_subjects, numel(peak_voxels)); % beta KL for each subject for each run, in each voxel we're interested in 
x3c1_liks = nan(n_runs_per_condition, n_subjects); % log likelihood of test choices given the model posterior, for each run for each subject


subj_idx = 0;
for subj = sss
    subject = all_subjects(subj);
    subj_trials = which_rows & strcmp(participant, subject);
    subj_idx = subj_idx + 1;
    fprintf('subj %d (idx %d)\n', subj, subj_idx);

    % get the KL regressor idxs, so we can get the betas from our peak voxels 
    % GLM 1 = main effect
    %
    KL_glm = 1;
    subjdir = fullfile(EXPT.modeldir,['model',num2str(KL_glm)],['subj',num2str(subj)]);
    load(fullfile(subjdir,'SPM.mat'));
    additive_regressors_idxs = find(~cellfun('isempty', strfind(SPM.xX.name, 'additive')));
    assert(numel(additive_regressors_idxs) == n_runs_per_condition);
    assert(sum(cell2mat(strfind(SPM.xX.name(additive_regressors_idxs), 'additive'))) == 7 * n_runs_per_condition);
    
    additive_run_idx = 0; % = which of the 3 additive runs it is
    for run = 1:9
        fprintf(' RUN %d (index %d)\n', run, additive_run_idx);
        run_test_trials = subj_trials & roundId == run & ~isTrain;
        condition = contextRole(run_test_trials);
        condition = condition{1};
        
        if ~strcmp(condition, 'additive')
            continue
        end
        additive_run_idx = additive_run_idx + 1;

        %
        % look at choice on x3c1
        %
        
        % ONLY look at x3c1
        choice = strcmp(response.keys(run_test_trials & cueId == 2 & contextId == 0), 'left');
        chose_sick_on_x3c1(additive_run_idx, subj_idx) = choice;
        
        %
        % calculate likelihood of test choices given model posterior
        % relies on context_create_multi GLM 124 (NOT 123...)
        %
        
        multi = EXPT.create_multi(124, subj, run);
        load('context_create_multi.mat'); % WARNING WARNING WARNING: MASSIVE COUPLING. This relies on context_create_multi saving its state into this file. I just don't wanna copy-paste or abstract away the code that load the data from there
        
        x3c1_liks(additive_run_idx, subj_idx) = test_log_lik(3);
                                
        %
        % get the betas for the peak voxels and other voxels of interest
        % TODO dedupe with kl_divergence.m
        %
        
        beta_idx = additive_regressors_idxs(additive_run_idx);
        assert(~isempty(strfind(SPM.xX.name{beta_idx}, 'additive')));
        % this does not give you the full 3D volume, just the non-nan
        % betas in a linear vector. Instead, see right below
        %beta_vec = ccnl_get_beta(EXPT, KL_glm, idx, 'mask.nii', [subj]);       
        V = spm_vol(fullfile(subjdir, sprintf('beta_%04d.nii', beta_idx)));
        Y = spm_read_vols(V);
        % for each ROI, get the activation at the max voxel
        %
        for roi = 1:numel(peak_voxels)
            voxel = peak_voxels{roi};
            cor = mni2cor(voxel, V.mat);
            value = Y(cor(1), cor(2), cor(3));
            fprintf('     max voxel %d = %f\n', roi, value);
            kl_betas(additive_run_idx, subj_idx, roi) = value;
        end
        % also find the activation in some random voxels
        % for sanity check
        %
        for j = 1:numel(rand_vox_x)
            value = Y(rand_vox_x(j), rand_vox_y(j), rand_vox_z(j));
            assert(~isnan(value));
            kl_betas(additive_run_idx, subj_idx, j + numel(peak_voxels)) = value;
        end 
    end
end


save('additive_irrelevant_betas.mat');

%load('additive_irrelevant_betas.mat');
