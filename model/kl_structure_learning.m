% run after kl_divergence.m
%kl_divergence.m

% activity ~ D_KL vs. structure learning effect from test trial choices
%
% That's great. In terms of linking this to behavior, we should try to address the more interesting aspects of the task, namely the test trials. 
% If these regions are computing Bayesian updates, then their activity during training trials should be related to behavioral performance at test. 
% For each condition, there is a key contrast:
% irrelevant: c = [1 1 -1 -1]
% modulatory: c = [1 -1/3 -1/3 -1/3]
% additive: c = [1 -1 1 - 1]
% where the components are [x1c1, x1c3, x3c1, x3c3].
% When you take the dot product between c and the choice probability at test, you get a measure of the "structure learning effect".
% So the idea would be to first estimate a separate KL regressor for each block, and then correlate this beta
% (e.g., peak voxels from lateral OFC and angular gyrus based on your previous GLM) with the structure learning 
% effect on each block. You can also try this at the subject level with the analysis you already ran, looking at the 
% correlation between beta and the structure learning effect across subjects.


% sanity check max voxel from 'surprise - wrong' contrast
% to make sure our method of extracting these is correct
EXPT = contextExpt();
modeldir = EXPT.modeldir;
V = spm_vol(fullfile(modeldir, ['model123'], ['con6'], 'spmT_0001.nii')); % T-value map
Y = spm_read_vols(V);
cor = mni2cor([34  -68 52],V.mat)
Y(cor(1), cor(2), cor(3)) % sanity check -- should be 6.9122 (as seen in ccnl_view Show Results Table)
assert(abs(Y(cor(1), cor(2), cor(3)) - 6.9122) < 1e-3);

%% load the KL betas and compute the structure learning effect
%
%{

% peak_voxels = peak voxel from each interesting cluster
% obtained from Show Results Table from ccnl_view(contextExpt(), 123,
% 'surprise - wrong');
% note that we're overriding the max_voxels from kl_divergence.m TODO coupling
%
rois = {'Angular_R', 'Parietal_Inf_R', 'Frontal_Mid_2_L', 'Location not in atlas', 'Frontal_Mid_2_R', 'OFCmed_R', 'Frontal_Mid_2_R'};
peak_voxels = {[34  -68 52], [40  -46 38], [-42 54  2], [-30 62  22], [36  54  0], [18  42  -16], [52  32  32]};


structure_learnings = nan(n_runs, n_subjects); % structure learning effect (SLE) for each run for each subject
kl_betas = nan(n_runs, n_subjects, numel(peak_voxels)); % beta KL for each subject for each run, in each voxel we're interested in 

sl_sanity = nan(n_runs, n_subjects, 3); % structure learning effect (SLE), sanity check -- one for each condition
run_conditions = nan(n_runs, n_subjects); % 1 = irrelevant, 2 = modulatory, 3 = additive

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
            run_conditions(run, subj_idx) = 1;
        elseif strcmp(condition, 'modulatory')
            c = [1 -1/3 -1/3 -1/3];
            run_conditions(run, subj_idx) = 2;
        else
            assert(strcmp(condition, 'additive'));
            c = [1 -1 1 -1];
            run_conditions(run, subj_idx) = 3;
        end
        % structure learning effect = contrast * test choice probabilities
        s = c * choices';
        structure_learnings(run, subj_idx) = s;
        
        sl_sanity(run, subj_idx, 1) = [1 1 -1 -1] * choices';
        sl_sanity(run, subj_idx, 2) = [1 -1/3 -1/3 -1/3] * choices';
        sl_sanity(run, subj_idx, 3) = [1 -1 1 -1] * choices';
        
        % get the betas for the peak voxels and other voxels of interest
        % TODO dedupe with kl_divergence.m
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
        for roi = 1:numel(peak_voxels)
            voxel = peak_voxels{roi};
            cor = mni2cor(voxel, V.mat);
            value = Y(cor(1), cor(2), cor(3));
            fprintf('     max voxel %d = %f\n', roi, value);
            kl_betas(run, subj_idx, roi) = value;
        end
        % also find the activation in some random voxels
        % for sanity check
        %
        for j = 1:numel(rand_vox_x)
            value = Y(rand_vox_x(j), rand_vox_y(j), rand_vox_z(j));
            assert(~isnan(value));
            kl_betas(run, subj_idx, j + numel(peak_voxels)) = value;
        end 
    end
end

save('kl_structure_learning_effect.mat');
%}

load('kl_structure_learning_effect.mat');

%% sanity check
%

% take the SLE for the corresponding run only, compare to the used SLE
% (sanity check for the sanity check; should by definition be equal)
[c, r] = meshgrid(1:n_subjects, 1:n_runs); % TODO why should they be flipped?
ind = sub2ind(size(sl_sanity), r(:), c(:), run_conditions(:));
x = reshape(sl_sanity(ind), size(structure_learnings));
assert(immse(x, structure_learnings) < 1e-20);

sl_max = max(sl_sanity, [], 3); % take the max SLE 
which_runs_had_max_SLEs = abs(sl_max - structure_learnings) < 1e-6; % which runs had the max SLE from the 3 possible conditions
% H0 = we fucked up and assigned them randomly i.e. for a given run of a given subject, the probability that the max
% SLE across conditions corresponds to the SLE for the actual condition is 1/3. So H0 says each
% element of which_runs_had_max_SLEs is ~ Bern(1/3)
% So # of 1's in which_runs_had_max_SLEs is ~ Binom(n, 1/3) with n = 9 * 20 (runs * subjects)
% see how likely (P(# of 1's in which_runs_had_max_SLEs | H0)) this is
k = sum(which_runs_had_max_SLEs(:));
n = n_runs * n_subjects;
P = (1/3)^k * (2/3)^(n-k) * nchoosek(n, k);
assert(P < 1e-30);
% TODO is this real hypothesis testing???


%% within-subject analysis
%
% In the within-subject analysis, you would split the pairs into N lists and report the average 
% correlation across subjects
%
r_means = [];
r_sems = [];
p_means = [];
p_sems = [];

figure;

for roi = 1:size(kl_betas, 3)
    kl_betas_roi = kl_betas(:, :, roi);
    rs = [];
    ps = [];
    for subj_idx = 1:n_subjects
        x = structure_learnings(:, subj_idx);
        y = kl_betas_roi(:, subj_idx);
        [r, p] = corrcoef(x, y);
        r = r(1,2);
        p = p(1,2);
        % fprintf('       subj = %d, r = %f, p = %f\n', roi, r(1,2), p(1,2));
        rs = [rs, r];
        ps = [ps, p];
        
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
        fprintf(' within-subject: ROI = %25s, avg r = %f, avg p = %f\n', rois{roi}, mean(r), mean(p));
    end
    
    r_means = [r_means; mean(rs) 0];
    r_sems = [r_sems; sem(rs) 0];
    p_means = [p_means; mean(ps) 0];
    p_sems = [p_sems; sem(ps) 0];
end


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
barweb(p_means, p_sems);
ylabel('average p across subjects');
xticklabels([strrep(rois, '_', '\_'), repmat({'random'}, 1, numel(rand_vox_x))]);
xtickangle(60);
xlabel('voxel');
%title('KL betas correlated with structure learning effect: within-subject analysis', 'Interpreter', 'none');

%% between-subject
% In the between-subjects analysis, you would have one pair per subject: 
% (KL beta, average structure learning effect).
% The structure learning effect is averaged across all blocks for a given subject,
% which is equivalent to computing the effect on the choice probabilities. Note that in this version you don't need to estimate a new GLM, you just use the subject-specific betas from the GLM you already estimated.
%

for roi = 1:numel(rois)
    kl_betas_roi = kl_betas(:, :, roi);
    % average kl_beta and structure learning across runs
    avg_kl_betas = mean(kl_betas_roi, 1);
    avg_structure_learnings = mean(structure_learnings, 1);
    
    [r, p] = corrcoef(avg_kl_betas, avg_structure_learnings);
    r = r(1,2);
    p = p(1,2);
    fprintf(' between-subject: ROI = %25s, r = %f, p = %f\n', rois{roi}, r, p);
end



%% all -- this is WRONG but just for funzies
%
for roi = 1:numel(rois)
    kl_betas_roi = kl_betas(:, :, roi);
    % list all kl_beta and structure learning (subjects and runs lumped together)
    all_kl_betas = kl_betas_roi(:);
    all_structure_learnings = structure_learnings(:);
    
    [r, p] = corrcoef(all_kl_betas, all_structure_learnings);
    r = r(1,2);
    p = p(1,2);
    fprintf(' overall (WRONG): ROI = %25s, avg r = %f, avg p = %f\n', rois{roi}, r, p);
end

%% sanity check -- make sure betas from peak voxels are > 0 and betas from random voxels are random
%
means = [];
sems = [];
for v_idx = 1:size(kl_betas, 3)
    x = kl_betas(:,:,v_idx);
    
    means = [means; mean(x(:)) 0]; % TODO this is wrong again; between- vs. within-subjects
    sems = [sems; sem(x(:)) 0];
end

figure;
barweb(means, sems);
ylabel('average beta across runs and subjects');
xticklabels([strrep(rois, '_', '\_'), repmat({'random'}, 1, numel(rand_vox_x))]);
xtickangle(60);
xlabel('voxel');
title('Betas from ccnl_view(EXPT, 123, ''surprise - wrong'')', 'Interpreter', 'none');