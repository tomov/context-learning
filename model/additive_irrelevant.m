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


%{

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
    
    irrelevant_regressors_idxs = find(~cellfun('isempty', strfind(SPM.xX.name, 'irrelevant')));
    assert(numel(irrelevant_regressors_idxs) == n_runs_per_condition);
    assert(sum(cell2mat(strfind(SPM.xX.name(irrelevant_regressors_idxs), 'irrelevant'))) == 7 * n_runs_per_condition);
    
    modulatory_regressors_idxs = find(~cellfun('isempty', strfind(SPM.xX.name, 'modulatory')));
    assert(numel(modulatory_regressors_idxs) == n_runs_per_condition);
    assert(sum(cell2mat(strfind(SPM.xX.name(modulatory_regressors_idxs), 'modulatory'))) == 7 * n_runs_per_condition);

    % it is crucial to sort them! otherwise we'll get the wrong betas
    regressors_idxs = sort([irrelevant_regressors_idxs, modulatory_regressors_idxs]);
    
    run_idx = 0; % = which of the 3 additive runs it is
    for run = 1:9
        fprintf(' RUN %d (index %d)\n', run, run_idx);
        run_test_trials = subj_trials & roundId == run & ~isTrain;
        condition = contextRole(run_test_trials);
        condition = condition{1};
        
        if strcmp(condition, 'additive')
            continue
        end
        run_idx = run_idx + 1;

        %
        % look at choice on x3c1
        %
        
        % ONLY look at x3c1
        choice = strcmp(response.keys(run_test_trials & cueId == 2 & contextId == 0), 'left');
        chose_sick_on_x3c1(run_idx, subj_idx) = choice;
        
        %
        % calculate likelihood of test choices given model posterior
        % relies on context_create_multi GLM 124 (NOT 123...)
        %
        
        multi = EXPT.create_multi(124, subj, run);
        load('context_create_multi.mat'); % WARNING WARNING WARNING: MASSIVE COUPLING. This relies on context_create_multi saving its state into this file. I just don't wanna copy-paste or abstract away the code that load the data from there
        
        x3c1_liks(run_idx, subj_idx) = test_log_lik(3);
                                
        %
        % get the betas for the peak voxels and other voxels of interest
        % TODO dedupe with kl_divergence.m
        %
        
        beta_idx = regressors_idxs(run_idx);
        assert(~isempty(strfind(SPM.xX.name{beta_idx}, 'irrelevant')) || ~isempty(strfind(SPM.xX.name{beta_idx}, 'modulatory')));
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
            kl_betas(run_idx, subj_idx, roi) = value;
        end
        % also find the activation in some random voxels
        % for sanity check
        %
        for j = 1:numel(rand_vox_x)
            value = Y(rand_vox_x(j), rand_vox_y(j), rand_vox_z(j));
            assert(~isnan(value));
            kl_betas(run_idx, subj_idx, j + numel(peak_voxels)) = value;
        end 
    end
end


save('additive_irrelevant_betas.mat');

%}

load('additive_irrelevant_betas.mat');

%% within-subject analysis
%
% In the within-subject analysis, you would split the pairs into N lists and report the average 
% correlation across subjects
%
r_means = [];
r_sems = [];

all_rs = nan(size(kl_betas, 3), n_subjects); % for each voxel, a list of correlation coefficients (for group-level stats)

figure;

% TODO HACKSAUCE FIXME -- this is how you get log likelihoods instead of
% structure learning for the correlations
% TODO also rename structure_learnings
% (if you uncomment this line)
%structure_learnings = chose_sick_on_x3c1;
structure_learnings = x3c1_liks;

for roi = 1:size(kl_betas, 3)
    kl_betas_roi = kl_betas(:, :, roi);
    rs = [];
    for subj_idx = 1:n_subjects
        x = structure_learnings(:, subj_idx);
        y = kl_betas_roi(:, subj_idx);
        [r, p] = corrcoef(x, y);
        r = r(1,2);
        p = p(1,2);

        if isnan(r)
            continue % exclude subjects with no variability
        end
        all_rs(roi, subj_idx) = r;
        
        % fprintf('       subj = %d, r = %f, p = %f\n', roi, r(1,2), p(1,2));
        rs = [rs, r];
        
        
        % plot stuff
        if roi <= numel(rois)
            subplot(numel(rois), n_subjects, (roi - 1) * n_subjects + subj_idx);
            scatter(x, y);
            lsline;
            %set(gca, 'XTick', []);
            %set(gca, 'YTick', []);
            if subj_idx == 1
                ylabel(rois{roi}, 'Interpreter', 'none');
            end
            if roi == numel(rois)
                xlabel(['Subj ', num2str(subj_idx)]);
            end
            if roi == 1 && subj_idx == 10
                title('structure learning effect (x-axis) vs. KL betas from ''surprise - wrong'' contrast (y-axis):  within-subject analysis');
            end
        end
    end
    % average correlation across subjects
    % TODO is it okay to average the p's?
    if roi < numel(rois)
        fprintf(' within-subject: ROI = %25s, avg r = %f\n', rois{roi}, mean(rs));
    end
    
    r_means = [r_means; mean(rs) 0];
    r_sems = [r_sems; sem(rs) 0];
end


% exclude subjects with no variability
all_rs = all_rs(~isnan(all_rs));
all_rs = reshape(all_rs, size(kl_betas, 3), numel(all_rs) / size(kl_betas, 3));

% group-level analysis
%
% For the within-subject analysis, 
% to get the group-level stats you should Fisher z-transform the correlation coefficients 
% (atanh function in matlab) and then do a one-sample t-test against 0.
%
all_rs = atanh(all_rs);
[h, ps] = ttest(all_rs');
assert(numel(ps) == size(kl_betas, 3));

figure;

subplot(2, 1, 1);
barweb(r_means, r_sems);
ylabel('average r across subjects');
xticklabels([strrep(rois, '_', '\_'), repmat({'random'}, 1, numel(rand_vox_x))]);
xtickangle(60);
xlabel('voxel');
%set(gca, 'XTick', []);
title('KL betas correlated with structure learning effect: within-subject analysis', 'Interpreter', 'none');

subplot(2, 1, 2);
barweb([ps' zeros(size(ps))'], [zeros(size(ps))' zeros(size(ps))']); % hack to make it pretty
hold on;
plot([0 100],[0.05 0.05],'k--');
hold off;
ylabel('one-sample t-test, p-value');
xticklabels([strrep(rois, '_', '\_'), repmat({'random'}, 1, numel(rand_vox_x))]);
xtickangle(60);
xlabel('voxel');
%title('KL betas correlated with structure learning effect: within-subject analysis', 'Interpreter', 'none');
