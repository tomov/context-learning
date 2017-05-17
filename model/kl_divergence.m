% get the voxel statistics of the D_KL model
%
close all;
clear all;

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
n_trials_per_run = 20; % NOTE: 20 for model59, 24 for model60
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

load('kl_divergence_59.mat');

which_prev_trials = which_rows & isTrain & trialId ~= 20;
which_next_trials = which_rows & isTrain & trialId ~= 1;
assert(sum(which_next_trials) == sum(which_prev_trials));
assert(sum(which_prev_trials) == size(prev_trials_act, 1)); % this is crucial
next_trials_corr = response.corr(which_next_trials);
assert(size(prev_trials_act, 1) == size(next_trials_corr, 1));
% so now, both next_trials_corr and prev_trials_act
% contain 20 subjects x 9 runs x 19 trials (2..20 or 1..19, respectively)

prev_trial_surprise = model.surprise(which_prev_trials); %  for sanity check
assert(size(prev_trials_act, 1) == size(prev_trial_surprise, 1));
prev_trials_corr = response.corr(which_prev_trials);


% only look at trials 10..19
%
cutoff = 10;
which_pattern = [zeros(cutoff, 1); ones(19-cutoff, 1)];
which_10_19 = logical(repmat(which_pattern, size(prev_trials_act, 1)/19, 1));
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

% top 20
means = [means; mean(mean(prev_trials_act(next_trials_corr == 1 & which_10_19, 8:end), 2)), ...
                mean(mean(prev_trials_act(next_trials_corr == 0 & which_10_19, 8:end), 2))];
sems = [sems; sem(mean(prev_trials_act(next_trials_corr == 1 & which_10_19, 8:end), 2)), ...
              sem(mean(prev_trials_act(next_trials_corr == 0 & which_10_19, 8:end), 2))];


figure;
barweb(means, sems);
legend({'correct', 'wrong'});
ylabel('activation ~ D_{KL} on previous trial');
xticklabels([rois, {'top 20 voxels'}]);



%
% by trial
%
roi_id = 1;

% plot activation in given ROI, or D_KL from the model
plot_what = {prev_trials_act, prev_trial_surprise};
y_labels = {'activation ~ D_{KL}', 'D_{KL}'};
% separated by whether it's correct on the next trial, or the current trial
plot_wrt_what = {next_trials_corr, prev_trials_corr};
legends = {{'correct on next', 'wrong on next'}, {'correct on cur', 'wrong on cur'}};

for plot_what_idx = 1:numel(plot_what)
    y = plot_what{plot_what_idx};
    for plot_wrt_what_idx = 1:numel(plot_wrt_what)
        x = plot_wrt_what{plot_wrt_what_idx};

        labels = {};

        means = [];
        sems = [];
        sem = @(x) std(x) / sqrt(length(x));
        blah1 = [];
        blah0 = [];

        for trial = cutoff+1:19 
            which_pattern = zeros(19, 1);
            which_pattern(trial) = 1;
            % note that these are logicals in the prev_trials_act space, where one
            % trial is missing (the last one)
            which_trials = logical(repmat(which_pattern, size(prev_trials_act, 1)/19, 1));
            assert(size(which_trials, 1) == size(prev_trials_act, 1));

            blah1 = [blah1; y(x == 1 & which_trials, roi_id)];
            blah0 = [blah0; y(x == 0 & which_trials, roi_id)];
            means = [means; mean(y(x == 1 & which_trials, roi_id)) mean(y(x == 0 & which_trials, roi_id))];
            sems = [sems; sem(y(x == 1 & which_trials, roi_id)) mean(y(x == 0 & which_trials, roi_id))];

            labels = [labels; {sprintf('#%d', trial)}];
        end

        means = [means; mean(blah1) mean(blah0)];
        sems = [sems; sem(blah1) sem(blah0)];
        labels = [labels; {'total'}];

        figure;
        barweb(means, sems);
        title(rois{roi_id});
        legend(legends{plot_wrt_what_idx});
        xlabel('trial');
        xticklabels(labels);
        ylabel(y_labels{plot_what_idx});
    end
end




% load('DKL.mat');
%bla = prev_trials_surprise > 0.2;
%scatter(prev_trials_surprise(bla), prev_trials_act(bla, 6));

% scatter(prev_trials_surprise, mean(prev_trials_act, 2))
