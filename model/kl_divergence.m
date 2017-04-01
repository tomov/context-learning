% get the voxel statistics of the D_KL model
%
EXPT = contextExpt();
modeldir = EXPT.modeldir;
%V = spm_vol(fullfile(modeldir, ['model59'], ['subj1'], sprintf('beta_%04d.nii',1)));
%V = spm_vol(fullfile(modeldir, ['model53'], ['con1'], sprintf('con_%04d.nii',1)));
V = spm_vol(fullfile(modeldir, ['model53'], ['con1'], 'spmT_0001.nii'));
Y = spm_read_vols(V);

cor = mni2cor([34 -64 48],V.mat)
Y(cor(1), cor(2), cor(3)) % sanity check -- should be 8.8376

% find the actual max voxels for the D_KL model
%
[~, i] = sort(Y(:), 'descend');
[max_vox_x, max_vox_y, max_vox_z] = ind2sub(size(Y), i(1:20)); % pick top 20 voxels

% max_voxels = max voxel from each interesting cluster
% obtained from Show Results Table from ccnl_view(contextExpt(), 53,
% 'surprise');
%
rois = {'Angular\_R', 'Frontal\_Inf\_Oper\_R', 'Frontal\_Mid\_2\_R\_dorsal', ...
        'Frontal\_Mid\_2\_R\_ventral', 'OFCant\_R', 'Frontal\_Mid\_2\_L', ...
        'Frontal\_Sup\_2\_L', 'Frontal\_Inf\_Tri\_L'};
max_voxels = {[34 -64 48], [48 20 34], [34 12 54], ...
              [36 56 -2],  [20 48 -16], [-42 56 2], ...
              [-24 60 -10], [-44 20 22]};
rois_max_voxels = containers.Map(rois, max_voxels);

% sanity check -- compare with ccnl_view(contextExpt(), 53, 'surprise'),
% particularly the last column (= Stat in Show Results Table)
%
for j = 1:numel(max_voxels)
    roi = rois{j};
    voxel = max_voxels{j};
    cor = mni2cor(voxel,V.mat);
    fprintf('%s --> %.4f %.4f %.4f = %.4f\n', roi, voxel(1), voxel(2), voxel(3), Y(cor(1), cor(2), cor(3)));
end
            
sss = getGoodSubjects();


%{
n_trials_per_run = 20;
EXPT = contextExpt();
prev_trials = zeros(numel(sss) * 9 * 19, numel(max_voxels) + numel(max_vox_x)); % col = ROI, row = activation of max voxel for given trial
idx = 0;
% the order here is essential -- it needs to match the way it's loaded by
% load_data i.e. the way it's stored in fmri.csv
%
for subj = sss
    modeldir = fullfile(EXPT.modeldir,['model59'],['subj',num2str(subj)]);
    fprintf('subj = %d\n', subj);
    for run = 1:9
        fprintf('     run = %d\n', run);
        for i = (1:19) + (run - 1) * (n_trials_per_run + 6)
            % for each feedback onset on trials 1..19
            %
            V = spm_vol(fullfile(modeldir, sprintf('beta_%04d.nii', i)));
            Y = spm_read_vols(V);
            idx = idx + 1;
            % for each ROI, get the activation at the max voxel
            %
            for j = 1:numel(max_voxels)
                voxel = max_voxels{j};
                cor = mni2cor(voxel, V.mat);
                value = Y(cor(1), cor(2), cor(3));
                prev_trials(idx, j) = value;
            end
            % also find the activation in the max voxels we found
            % separately, as a sanity check
            %
            for j = 1:numel(max_vox_x)
                value = Y(max_vox_x(j), max_vox_y(j), max_vox_z(j));
                prev_trials(idx, j + numel(max_voxels)) = value;
            end
        end
    end
end
prev_trials_act = prev_trials;

analyze;
%}


load('prev_trials.mat');

which_prev_trials = which_rows & isTrain & trialId ~= 20;
which_next_trials = which_rows & isTrain & trialId ~= 1;
assert(sum(which_next_trials) == sum(which_prev_trials));
assert(sum(which_prev_trials) == size(prev_trials_act, 1)); % this is crucial
next_trials_corr = response.corr(which_next_trials);
% so now, both next_trials_corr and prev_trials_act
% contain 20 subjects x 9 runs x 19 trials (1..19)

% only look at trials 10..19
%
cutoff = 10;
which_10_19 = logical(repmat([zeros(cutoff, 1); ones(19-cutoff, 1)], size(prev_trials_act, 1)/19, 1));
assert(size(which_10_19, 1) == size(prev_trials_act, 1));



means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
for i = 1:numel(rois)
    means = [means; mean(prev_trials_act(next_trials_corr == 1 & which_10_19, i)), ...
                    mean(prev_trials_act(next_trials_corr == 0 & which_10_19, i))];
    sems = [sems; sem(prev_trials_act(next_trials_corr == 1 & which_10_19, i)), ...
                  sem(prev_trials_act(next_trials_corr == 0 & which_10_19, i))];
end

means = [means; mean(mean(prev_trials_act(next_trials_corr == 1 & which_10_19, 8:end), 2)), ...
                mean(mean(prev_trials_act(next_trials_corr == 0 & which_10_19, 8:end), 2))];
sems = [sems; sem(mean(prev_trials_act(next_trials_corr == 1 & which_10_19, 8:end), 2)), ...
              sem(mean(prev_trials_act(next_trials_corr == 0 & which_10_19, 8:end), 2))];


figure;
barweb(means, sems);
legend({'correct', 'wrong'});
ylabel('activation ~ D_{KL} on previous trial');
xticklabels([rois, {'top 20 voxels'}]);


% load('DKL.mat');
%bla = prev_trials_surprise > 0.2;
%scatter(prev_trials_surprise(bla), prev_trials_act(bla, 6));

% scatter(prev_trials_surprise, mean(prev_trials_act, 2))
