% visualize the RDMs, compute RDM correlation for differnet models, plot
% stuff
%
close all;
clear all;

mask = 'striatum.nii';
distance_measure = 'correlation';

% as output by representational_similarity_part2.m
m = regexp(mask,'\.','split');
load(['rsa_rdms_', m{1}, '_', distance_measure, '.mat']);


% subjectRDMs(11) = []; -- outlier???

%load('rsa_rdms_euclidean.mat');
%load('rsa_rdms_correlation.mat');

avgRDM.RDM = avgSubjectRDM;
avgRDM.name = 'subject-averaged RDM';
avgRDM.color = [0 1 0];


%showRDMs(all, 2);
showRDMs(avgRDM, 1);


%% construct models
%
n_trials_per_run = 24;
n_runs = 9;

trial = repmat(1:n_trials_per_run, 1, n_runs);
runInCond = repmat([ones(1,n_trials_per_run), 2*ones(1,n_trials_per_run), 3*ones(1,n_trials_per_run)], 1, 3);
runNotReal = reshape(repmat(1:n_runs, n_trials_per_run, 1), 1, n_runs * n_trials_per_run);
condition = [ones(1, n_trials_per_run * 3), 2*ones(1, n_trials_per_run * 3), 3*ones(1, n_trials_per_run * 3)];

assert(length(trial) == n_trials_per_run * n_runs);
assert(length(runInCond) == n_trials_per_run * n_runs);
assert(length(runNotReal) == n_trials_per_run * n_runs);
assert(length(condition) == n_trials_per_run * n_runs);

[trial_row, trial_col] = meshgrid(1:n_runs*n_trials_per_run);

conditionRDM = condition(trial_row) ~= condition(trial_col);
runInCondRDM = runInCond(trial_row) ~= runInCond(trial_col);
runNotRealRDM = runNotReal(trial_row) ~= runNotReal(trial_col);
firstRunInCondRDM = ~((runInCond(trial_row) == 1 & runInCond(trial_col) == 1) | (trial_row == trial_col));

clear Model;

Model(1).RDM = conditionRDM;
Model(1).name = 'condition';
Model(1).color = [0 1 0];

Model(2).RDM = runInCondRDM;
Model(2).name = 'run in condition group';
Model(2).color = [0 1 0];

Model(3).RDM = runNotRealRDM;
Model(3).name = 'run';
Model(3).color = [0 1 0];

Model(4).RDM = firstRunInCondRDM;
Model(4).name = 'first run in group';
Model(4).color = [0 1 0];

Model(5).RDM = runNotRealRDM + conditionRDM;
Model(5).name = 'run + condition';
Model(5).color = [0 1 0];

Model(6).RDM = runNotRealRDM + runInCondRDM + conditionRDM;
Model(6).name = 'run + run in group + condition';
Model(6).color = [0 1 0];

Model(7).RDM = runNotRealRDM + firstRunInCondRDM + conditionRDM;
Model(7).name = 'run + first run in group + condition';
Model(7).color = [0 1 0];

Model(8).RDM = runNotRealRDM + runInCondRDM + firstRunInCondRDM + conditionRDM;
Model(8).name = 'run + run in group + first run in group + condition';
Model(8).color = [0 1 0];

showRDMs(Model, 2);

%% RDM correlation matrix
%
%userOptions.RDMcorrelationType='Kendall_taua';
userOptions.RDMcorrelationType='Spearman';
userOptions.analysisName='blah';
userOptions.rootPath = '~/Downloads/'; % TODO how to turn off saving the figure?
pairwiseCorrelateRDMs({avgRDM, Model}, userOptions, struct('figureNumber', 3,'fileName',[]));


%% aggregates
%

conditions = {'irr', 'mod', 'add'};

figure;

sem = @(x) std(x) / sqrt(length(x));

% all pairs of conditions
%
means1 = [];
sems1 = [];
labels = {};
cond_pairs = [1 2; 1 3; 2 3; 1 1; 2 2; 3 3];

bla = [];
for i = 1:size(cond_pairs, 1)
    cond1 = cond_pairs(i, 1);
    cond2 = cond_pairs(i, 2);
    subRDM = avgRDM.RDM(condition(trial_row) == cond1 & condition(trial_col) == cond2 & runNotReal(trial_row) ~= runNotReal(trial_col));
    mean_dissim = mean(subRDM(:));
    sem_dissim = sem(subRDM(:));
    if i <= 3
        bla = [bla, subRDM];
    end
    means1 = [means1, mean_dissim];
    sems1 = [sems1, sem_dissim];
    labels = [labels; [conditions{cond1}, '-', conditions{cond2}]];
end

res = rmanova1(bla, 0.05, 0, 1)
res.ttests(1)
res.ttests(2)
res.ttests(3)

subplot(1, 4, 1);
barweb(means1, sems1);
legend(labels);
ylabel('mean trial distance (from subject-average RDM)');
ylim([min(means1) * 0.95, max(means1) * 1.05]);

title(['ROI: ', m{1}]);



% pairs of trials form different conditions (3)
%
% remember, the RDM is flipped! 1 = diff conditions, 0 = same condition
% i.e. we're taking the yellow stuff from showRDMs(conditionRDM)
diff_cond_subRDM = avgRDM.RDM(conditionRDM);
mean_diff_cond = mean(diff_cond_subRDM(:));
sem_diff_cond = sem(diff_cond_subRDM(:));

% pairs of trials from the same condition, but different runs (2)
%
% remember, the RDM is flipped! 1 = diff conditions, 0 = same condition
% i.e. we're taking the yellow stuff from showRDMs(~conditionRDM & runNotRealRDM)
same_cond_subRDM = avgRDM.RDM(~conditionRDM & runNotRealRDM);
mean_same_cond = mean(same_cond_subRDM(:));
sem_same_cond = sem(same_cond_subRDM(:));

% pairs of trials from the same run (1)
%
% remember, the RDM is flipped! 1 = diff conditions, 0 = same condition
% i.e. we're taking the yellow stuff from showRDMs(~runNotRealRDM)
same_run_subRDM = avgRDM.RDM(~runNotRealRDM);
mean_same_run = mean(same_run_subRDM(:));
sem_same_run = sem(same_run_subRDM(:));

subplot(1, 4, 2);
means2 = [mean_diff_cond, mean_same_cond, mean_same_run];
sems2 = [sem_diff_cond,  sem_same_cond,  sem_same_run];
barweb(means2, sems2);
legend({'Different cond (e.g. Add/Mod)', 'Same cond, diff runs (e.g. Add/Add)', 'Same run'});
ylabel('mean trial distance (from subject-average RDM)');
ylim([min(means2) * 0.95, max(means2) * 1.05]);




% zoom in on pairs of trials from same condition vs. diff conditions
%
[p,tbl,stats] = anova1([diff_cond_subRDM; same_cond_subRDM], [ones(size(diff_cond_subRDM)); zeros(size(same_cond_subRDM))], 'off');

subplot(1, 4, 3);
means3 = [mean_diff_cond, mean_same_cond];
sems3 = [sem_diff_cond,  sem_same_cond];
barweb(means3, sems3);
legend({'Different cond (e.g. Add/Mod)', 'Same cond, diff runs (e.g. Add/Add)'});
ylabel('mean trial distance (from subject-average RDM)');
ylim([min(means3) * 0.995, max(means3) * 1.005]);
title(sprintf('p = %f', p));

%hist(same_run_subRDM);


% pairs of runs within each condition
%
means4 = [];
sems4 = [];
labels = {};
run_in_group_pairs = [1 2; 1 3; 2 3; 1 1; 2 2; 3 3];

for cond = 1:3
    m = [];
    s = [];
    for i = 1:size(run_in_group_pairs, 1)
        run1 = run_in_group_pairs(i, 1);
        run2 = run_in_group_pairs(i, 2);
        subRDM = avgRDM.RDM(condition(trial_row) == cond & condition(trial_col) == cond & runInCond(trial_row) == run1 & runInCond(trial_col) == run2);
        mean_dissim = mean(subRDM(:));
        sem_dissim = sem(subRDM(:));
        m = [m, mean_dissim];
        s = [s, sem_dissim];
        if cond == 1
            labels = [labels; ['Run ', num2str(run1), '-', 'Run ', num2str(run2)]];
        end
    end
    means4 = [means4; m];
    sems4 = [sems4; s];
end

subplot(1, 4, 4);
barweb(means4, sems4);
legend(labels);
ylabel('mean trial distance (from subject-average RDM)');
ylim([min(means4(:)) * 0.95, max(means4(:)) * 1.05]);
xticklabels(conditions);
