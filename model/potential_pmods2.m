% run after analyze
%
%analyze

%% D_KL vs. next trial RT
%
which_prev_trials = which_rows & isTrain & trialId ~= 20;
which_next_trials = which_rows & isTrain & trialId ~= 1;

prev_trial_surprise = model.surprise(which_prev_trials);
next_trial_rt = response.rt(which_next_trials);

figure;
scatter(prev_trial_surprise, next_trial_rt);


%% RTs by trial
%
no_response = strcmp(response.keys, 'None');

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
blah1 = [];
blah0 = [];
for trial = 1:24
    if trial <= 20
        which_trials = which_rows & isTrain & trialId == trial & ~no_response;
    else
        which_trials = which_rows & ~isTrain & trialId == trial - 20 & ~no_response;
    end
    %surprise = model.surprise(which_trials);
    %next_trial_correct = response.corr(which_rows & isTrain & trialId == trial + 1);
    rt = response.rt(which_trials);

    %blah1 = [blah1; surprise(next_trial_correct == 1)];
    %blah0 = [blah0; surprise(next_trial_correct == 0)];
    %means = [means; mean(surprise(next_trial_correct == 1)) mean(surprise(next_trial_correct == 0))];
    %sems = [sems; sem(surprise(next_trial_correct == 1)) sem(surprise(next_trial_correct == 0))];
    means = [means; mean(rt)];
    sems = [sems; sem(rt)];

    labels = [labels; {sprintf('#%d', trial)}];
end

%means = [means; mean(blah1) mean(blah0)];
%sems = [sems; sem(blah1) sem(blah0)];
%labels = [labels; {'total'}];

figure;
barweb(means, sems);
%legend({'correct on next', 'wrong on next'});
xlabel('trial');
xticklabels(labels);
ylabel('RT (s)');


%% other plots
%

%{
%
% response / value cross-correlation
%

figure;
next_subplot_idx = 1;

which_trials = which_rows & isTrain;

x = model.values(which_trials);
y = strcmp(response.keys(which_trials), 'left');

[acor,lags] = xcorr(x, y);
plot(lags, acor);

%}


%{
%
% Per-run accuracy across all subjects splits by run groups (training only)
%

human_corrects = [];
human_corrects_sems = [];
for run_group = 1:3:9
    human_correct = [];
    human_correct_sems = [];
    %model_correct = [];

    for n = 1:N
        which = which_rows & isTrain & trialId == n & roundId >= run_group & roundId < run_group + 3 & strcmp(contextRole, 'additive');

        human_corr_n = strcmp(response.keys(which), corrAns(which));
    %    model_corr_n = strcmp(model.keys(which), corrAns(which));
        human_correct = [human_correct mean(human_corr_n)];
        human_correct_sems = [human_correct_sems sem(human_corr_n)];
    %    model_correct = [model_correct mean(model_corr_n)];
    end
    
    human_corrects = [human_corrects; human_correct];
    human_corrects_sems = [human_corrects_sems; human_correct_sems];
end

%plot(model_correct, 'o-', 'LineWidth', 2); % == mean(human_correct_all_runs)
hold on;
errorbar(human_corrects', human_corrects_sems', 'o-', 'LineWidth', 2); % == mean(model_correct_all_runs)
hold off;
legend({'Runs 1-3', 'Runs 4-6', 'Runs 7-9'});
title('Per-trial accuracy');
xlabel('trial #');
ylabel('accuracy');


%}


%
% Per-run accuracy across all subjects splits by run groups, sliced by condition (training only)
%

%{
condition_groups = {{'irrelevant', 'modulatory', 'additive'}, {'irrelevant'}, {'modulatory'}, {'additive'}};
condition_group_labels = {'Per-run accuracy (all conditions)', 'irrelevant', 'modulatory', 'additive'};
subfig_idx = 1;

for condition_group = condition_groups

    trial_groups = {1:5, 1:10, 1:20};
    trial_group_labels = {'Trials 1-5', 'Trials 1-10', 'Trials 1-20'};

    means = [];
    sems = [];
    for trial_group = trial_groups
        first_3_runs = which_rows & isTrain & roundId >= 1 & roundId <= 3 & ismember(trialId, trial_group{1}) & ismember(contextRole, condition_group{1});
        last_3_runs = which_rows & isTrain & roundId >= 7 & roundId <= 9 & ismember(trialId, trial_group{1}) & ismember(contextRole, condition_group{1});

        first_3_corr_n = strcmp(response.keys(first_3_runs), corrAns(first_3_runs));
        last_3_corr_n = strcmp(response.keys(last_3_runs), corrAns(last_3_runs));

        means = [means; mean(first_3_corr_n) mean(last_3_corr_n)];
        sems = [sems; sem(first_3_corr_n) sem(last_3_corr_n)];
    end

    subplot(2, 2, subfig_idx);
    subfig_idx = subfig_idx + 1;
    barweb(means, sems);
    legend({'Runs 1-3', 'Runs 7-9'});
    ylabel('%');
    xticklabels(trial_group_labels);
    
    
    title(condition_group_labels{subfig_idx - 1});
end
%}


%{
%
% RT when subject chose sick vs. not sick, wrong trials only
%

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
blah1 = [];
blah0 = [];
for trial = 1:19 
    which_trials = which_rows & isTrain & trialId == trial;
    RTs = response.rt(which_trials);
    cur_trial_correct = response.corr(which_trials);
    
    blah1 = [blah1; RTs(cur_trial_correct == 1)];
    blah0 = [blah0; RTs(cur_trial_correct == 0)];
    means = [means; mean(RTs(cur_trial_correct == 1)) mean(RTs(cur_trial_correct == 0))];
    sems = [sems; sem(RTs(cur_trial_correct == 1)) sem(RTs(cur_trial_correct == 0))];
    labels = [labels; {sprintf('#%d', trial)}];
end

means = [means; mean(blah1) mean(blah0)];
sems = [sems; sem(blah1) sem(blah0)];
labels = [labels; {'total'}];

%subplot(2, 3, next_subplot_idx);
%next_subplot_idx = next_subplot_idx + 1;
barweb(means, sems);
legend({'correct', 'wrong'});
xlabel('trial');
xticklabels(labels);
ylabel('RT');


%}



%{
which_trials = which_rows & isTrain & [model.surprise; 0;0;0;0] > 0.1;
RTs = response.rt(circshift(which_trials, -1));
surprise = model.surprise(which_trials);

scatter(surprise, RTs);
%}