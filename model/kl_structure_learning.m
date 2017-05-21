% run after kl_divergence.m
%kl_divergence.m

% activity ~ D_KL vs. structure learning effect from test trial choices
%
% That's great. In terms of linking this to behavior, we should try to address the more interesting aspects of the task, namely the test trials. If these regions are computing Bayesian updates, then their activity during training trials should be related to behavioral performance at test. For each condition, there is a key contrast:
% irrelevant: c = [1 1 -1 -1]
% modulatory: c = [1 -1/3 -1/3 -1/3]
% additive: c = [1 -1 1 - 1]
% where the components are [x1c1, x1c3, x3c1, x3c3].
% When you take the dot product between c and the choice probability at test, you get a measure of the "structure learning effect". So the idea would be to first estimate a separate KL regressor for each block, and then correlate this beta (e.g., peak voxels from lateral OFC and angular gyrus based on your previous GLM) with the structure learning effect on each block. You can also try this at the subject level with the analysis you already ran, looking at the correlation between beta and the structure learning effect across subjects.


% max_voxels = max voxel from each interesting cluster
% obtained from Show Results Table from ccnl_view(contextExpt(), 123,
% 'surprise - wrong');
%

rois = {'Angular_R', 'Parietal_Inf_R', 'Frontal_Mid_2_L', 'Location not in atlas', 'Frontal_Mid_2_R', 'OFCmed_R', 'Frontal_Mid_2_R'};
max_voxels = {[34  -68 52], [40  -46 38], [-42 54  2], [-30 62  22], [36  54  0], [18  42  -16], [52  32  32]};

structure_learnings = nan(n_runs, n_subjects); % structure learning effect for each run for each subject
kl_betas = nan(n_runs, n_subjects, numel(max_voxels)); % beta KL for each subject for each run, in each voxel we're interested in 

subj_idx = 0;
for subj = sss
    subject = all_subjects(subj);
    subj_trials = which_rows & strcmp(participant, subject);
    subj_idx = subj_idx + 1;
    fprintf('subj %d (idx %d)\n', subj, subj_idx);

    % get the KL regressor idxs, so we can get the betas from our peak voxels 
    % GLM 123 = surprise & wrong
    %
    KL_glm = 123;
    subjdir = fullfile(EXPT.modeldir,['model',num2str(KL_glm)],['subj',num2str(subj)]);
    load(fullfile(subjdir,'SPM.mat'));
    surprise_regressors_idxs = find(~cellfun('isempty', strfind(SPM.xX.name, 'surprise')));
    assert(numel(surprise_regressors_idxs) == n_runs);
    assert(sum(cell2mat(strfind(SPM.xX.name(surprise_regressors_idxs), 'surprise'))) == 16 * n_runs);
    
    for run = 1:9
        fprintf(' RUN %d\n', run);
        run_test_trials = subj_trials & roundId == run & ~isTrain;
        condition = contextRole(run_test_trials);
        condition = condition{1};
        
        % make sure to get them in the right order:
        % x1c1, x1c3, x3c1, x3c3
        cue_context_test_pairs = [0 0; 0 2; 2 0; 2 2];
        choices = [];
        for i = 1:4
            cue = cue_context_test_pairs(i, 1);
            context = cue_context_test_pairs(i, 2);
            % TODO handle no responses
            choice = strcmp(response.keys(run_test_trials & cueId == cue & contextId == context), 'left');
            choices = [choices choice];
        end
        % contrast
        c = [];
        if strcmp(condition, 'irrelevant')
            c = [1 1 -1 -1];
        elseif strcmp(condition, 'modulatory')
            c = [1 -1/3 -1/3 -1/3];
        else
            assert(strcmp(condition, 'additive'));
            c = [1 -1 1 -1];
        end
        % structure learning effect = contrast * test choice probabilities
        s = c * choices';
        structure_learnings(run, subj_idx) = s;
        
        % get the betas for the peak voxels
        %
        beta_idx = surprise_regressors_idxs(run);
        assert(~isempty(strfind(SPM.xX.name{beta_idx}, 'surprise')));
        % this does not give you the full 3D volume, just the non-nan
        % betas in a linear vector. Instead, see right below
        %beta_vec = ccnl_get_beta(EXPT, KL_glm, idx, 'mask.nii', [subj]);       
        V = spm_vol(fullfile(subjdir, sprintf('beta_%04d.nii', beta_idx)));
        Y = spm_read_vols(V);
        % for each ROI, get the activation at the max voxel
        %
        for roi = 1:numel(max_voxels)
            voxel = max_voxels{roi};
            cor = mni2cor(voxel, V.mat);
            value = Y(cor(1), cor(2), cor(3));
            fprintf('     max voxel %d = %f\n', roi, value);
            kl_betas(run, subj_idx, roi) = value;
        end
    end
end

%save('kl_structure_learning_effect.mat');




%load('kl_structure_learning_effect.mat');

%% within-subject
%
% In the within-subject analysis, you would split the pairs into N lists and report the average 
% correlation across subjects
%

for roi = 1:size(kl_betas, 3)
    kl_betas_roi = kl_betas(:, :, roi);
    avg_r = 0;
    avg_p = 0;
    for subj_idx = 1:n_subjects
        [r, p] = corrcoef(structure_learnings(:, subj_idx), kl_betas_roi(:, subj_idx));
        r = r(1,2);
        p = p(1,2);
       % fprintf('       subj = %d, r = %f, p = %f\n', roi, r(1,2), p(1,2));
        avg_r = avg_r + r;
        avg_p = avg_p + p;
    end
    % average correlation across subjects
    avg_r = avg_r / n_subjects;
    avg_p = avg_p / n_subjects; % TODO this is certainly wrong
    fprintf(' within-subject: ROI = %25s, avg r = %f, avg p = %f\n', rois{roi}, avg_r, avg_p);
end

%% between-subject
% In the between-subjects analysis, you would have one pair per subject: 
% (KL beta, average structure learning effect).
% The structure learning effect is averaged across all blocks for a given subject,
% which is equivalent to computing the effect on the choice probabilities. Note that in this version you don't need to estimate a new GLM, you just use the subject-specific betas from the GLM you already estimated.
%

for roi = 1:size(kl_betas, 3)
    kl_betas_roi = kl_betas(:, :, roi);
    % average kl_beta and structure learning across runs
    avg_kl_betas = mean(kl_betas_roi, 1);
    avg_structure_learnings = mean(structure_learnings, 1);
    
    [r, p] = corrcoef(avg_kl_betas, avg_structure_learnings);
    r = r(1,2);
    p = p(1,2);
    fprintf(' between-subject: ROI = %25s, avg r = %f, avg p = %f\n', rois{roi}, r, p);
end


%% all -- this is WRONG but just for funzies
%
for roi = 1:size(kl_betas, 3)
    kl_betas_roi = kl_betas(:, :, roi);
    % list all kl_beta and structure learning (subjects and runs lumped together)
    all_kl_betas = kl_betas_roi(:);
    all_structure_learnings = structure_learnings(:);
    
    [r, p] = corrcoef(all_kl_betas, all_structure_learnings);
    r = r(1,2);
    p = p(1,2);
    fprintf(' between-subject: ROI = %25s, avg r = %f, avg p = %f\n', rois{roi}, r, p);
end
