function representational_similarity_part2(mask, distance_measure)
%clear all;
%close all;
%distance_measure = 'correlation';

% addpath('rsatoolbox/Engines/'); % RSA toolbox <------- for NCF / CBS

%% compute the subject-average RDM
%

% as output by representational_similarity.m

m = regexp(mask,'\.','split');
load(['rsa_beta_vecs_', m{1}, '.mat']);


beta_subjs = sss;
n_runs = 9;
n_subjects = length(beta_subjs);
subjectRDMs = nan(n_runs * n_trials_per_run, n_runs * n_trials_per_run, n_subjects);


rdm = zeros(size(beta_vecs, 1));

subj_idx = 0;
for subj = beta_subjs
    disp(subj);
    subj_idx = subj_idx + 1;
    subjectRDMs(:,:,subj_idx) = squareRDMs(pdist(beta_vecs{subj}, distance_measure));
end

disp('averaging!');
avgSubjectRDM = mean(subjectRDMs, 3);

all = cat(3, subjectRDMs, avgSubjectRDM); % TODO why does concatRDMs_unwrapped not work properly?

clear beta_vecs; % too big; don't need any longer
save(['rsa_rdms_', m{1}, '_', distance_measure, '.mat'], '-v7.3');


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


%% aggregate
%

conditions = {'irr', 'mod', 'add'};


sem = @(x) std(x) / sqrt(length(x));

% e.g. Mod-Add
%
means1 = [];
sems1 = [];
labels = {};
cond_pairs = [1 2; 1 3; 2 3; 1 1; 2 2; 3 3];

for i = 1:size(cond_pairs, 1)
    cond1 = cond_pairs(i, 1);
    cond2 = cond_pairs(i, 2);
    subRDM = avgRDM.RDM(condition(trial_row) == cond1 & condition(trial_col) == cond2 & runNotReal(trial_row) ~= runNotReal(trial_col));
    mean_dissim = mean(subRDM(:));
    sem_dissim = sem(subRDM(:));
    means1 = [means1, mean_dissim];
    sems1 = [sems1, sem_dissim];
    labels = [labels; [conditions{cond1}, '-', conditions{cond2}]];
end
figure;
barweb(means1, sems1);
legend(labels);
ylabel('mean trial distance (from subject-average RDM)');
ylim([min(means1) * 0.9, max(means1) * 1.1]);

% pairs of trials form different conditions (3)
%
% remember, the RDM is flipped! 1 = diff conditions, 0 = same condition
% i.e. we're taking the yellow stuff from showRDMs(conditionRDM)
subRDM = avgRDM.RDM(conditionRDM);
mean_diff_cond = mean(subRDM(:));
sem_diff_cond = sem(subRDM(:));

% pairs of trials from the same condition, but different runs (2)
%
% remember, the RDM is flipped! 1 = diff conditions, 0 = same condition
% i.e. we're taking the yellow stuff from showRDMs(~conditionRDM & runNotRealRDM)
subRDM = avgRDM.RDM(~conditionRDM & runNotRealRDM);
mean_same_cond = mean(subRDM(:));
sem_same_cond = sem(subRDM(:));

% pairs of trials from the same run (1)
%
% remember, the RDM is flipped! 1 = diff conditions, 0 = same condition
% i.e. we're taking the yellow stuff from showRDMs(~runNotRealRDM)
subRDM = avgRDM.RDM(~runNotRealRDM);
mean_same_run = mean(subRDM(:));
sem_same_run = sem(subRDM(:));

figure;
means2 = [mean_diff_cond, mean_same_cond, mean_same_run];
sems2 = [sem_diff_cond,  sem_same_cond,  sem_same_run];
barweb(means2, sems2);
legend({'Different cond (e.g. Add/Mod)', 'Same cond, diff runs (e.g. Add/Add)', 'Same run'});
ylabel('mean trial distance (from subject-average RDM)');
ylim([min(means2) * 0.9, max(means2) * 1.1]);
