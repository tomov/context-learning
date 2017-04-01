% run after analyze
%

figure;
next_subplot_idx = 1;

%
% value when subject chose sick vs. not sick, wrong trials only
%

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
for trial = 1:19 
    wrong_trials = which_rows & isTrain & response.corr == 0 & trialId == trial;
    subject_choices = strcmp(response.keys(wrong_trials), 'left');
    values = model.values(wrong_trials);
    
    means = [means; mean(values(subject_choices == 1)) mean(values(subject_choices == 0))];
    sems = [sems; sem(values(subject_choices == 1)) sem(values(subject_choices == 0))];
    labels = [labels; {sprintf('#%d', trial)}];
end

subplot(2, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(means, sems);
title('Wrong Trials');
legend({'chose sick', 'chose not sick'});
xlabel('trial');
xticklabels(labels);
ylabel('value');


%
% D_KL when subject chose sick vs not sick, wrong trials only
%

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
for trial = 1:19 
    wrong_trials = which_rows & isTrain & response.corr == 0 & trialId == trial;
    subject_choices = strcmp(response.keys(wrong_trials), 'left');
    surprise = model.surprise(wrong_trials);

    means = [means; mean(surprise(subject_choices == 1)) mean(surprise(subject_choices == 0))];
    sems = [sems; sem(surprise(subject_choices == 1)) sem(surprise(subject_choices == 0))];
    labels = [labels; {sprintf('#%d', trial)}];
end

subplot(2, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(means, sems);
title('Wrong Trials');
legend({'chose sick', 'chose not sick'});
xlabel('trial');
xticklabels(labels);
ylabel('D_{KL}');


%
% D_KL vs whether subject was right or wrong on the following trial
%

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
blah1 = [];
blah0 = [];
for trial = 1:19 
    which_trials = which_rows & isTrain & trialId == trial;
    surprise = model.surprise(which_trials);
    next_trial_correct = response.corr(which_rows & isTrain & trialId == trial - 1);

    blah1 = [blah1; surprise(next_trial_correct == 1)];
    blah0 = [blah0; surprise(next_trial_correct == 0)];
    means = [means; mean(surprise(next_trial_correct == 1)) mean(surprise(next_trial_correct == 0))];
    sems = [sems; sem(surprise(next_trial_correct == 1)) sem(surprise(next_trial_correct == 0))];

    labels = [labels; {sprintf('#%d', trial)}];
end

means = [means; mean(blah1) mean(blah0)];
sems = [sems; sem(blah1) sem(blah0)];
labels = [labels; {'total'}];

subplot(2, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(means, sems);
legend({'correct on next', 'wrong on next'});
xlabel('trial');
xticklabels(labels);
ylabel('D_{KL}');


%
% D_KL vs whether subject was right or wrong on the following trial
% for trials 10..20 only
%

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
blah1 = [];
blah0 = [];
for trial = 10:19 
    which_trials = which_rows & isTrain & trialId == trial;
    surprise = model.surprise(which_trials);
    next_trial_correct = response.corr(which_rows & isTrain & trialId == trial - 1);

    blah1 = [blah1; surprise(next_trial_correct == 1)];
    blah0 = [blah0; surprise(next_trial_correct == 0)];
    means = [means; mean(surprise(next_trial_correct == 1)) mean(surprise(next_trial_correct == 0))];
    sems = [sems; sem(surprise(next_trial_correct == 1)) sem(surprise(next_trial_correct == 0))];

    labels = [labels; {sprintf('#%d', trial)}];
end

means = [means; mean(blah1) mean(blah0)];
sems = [sems; sem(blah1) sem(blah0)];
labels = [labels; {'total'}];

subplot(2, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(means, sems);
legend({'correct on next', 'wrong on next'});
xlabel('trial');
xticklabels(labels);
ylabel('D_{KL}');




%
% |PE| vs whether subject was right or wrong on the current trial
%

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
blah1 = [];
blah0 = [];
for trial = 1:19 
    which_trials = which_rows & isTrain & trialId == trial;
    prediction_error = abs(strcmp(corrAns(which_trials), 'left') - model.pred(which_trials));
    cur_trial_correct = response.corr(which_rows & isTrain & trialId == trial);

    blah1 = [blah1; prediction_error(cur_trial_correct == 1)];
    blah0 = [blah0; prediction_error(cur_trial_correct == 0)];
    means = [means; mean(prediction_error(cur_trial_correct == 1)) mean(prediction_error(cur_trial_correct == 0))];
    sems = [sems; sem(prediction_error(cur_trial_correct == 1)) sem(prediction_error(cur_trial_correct == 0))];

    labels = [labels; {sprintf('#%d', trial)}];
end

means = [means; mean(blah1) mean(blah0)];
sems = [sems; sem(blah1) sem(blah0)];
labels = [labels; {'total'}];

subplot(2, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(means, sems);
legend({'correct', 'wrong'});
xlabel('trial');
xticklabels(labels);
ylabel('|PE|');


%
% |PE| vs whether subject was right or wrong on the following trial
%

labels = {};

means = [];
sems = [];
sem = @(x) std(x) / sqrt(length(x));
blah1 = [];
blah0 = [];
for trial = 1:19 
    which_trials = which_rows & isTrain & trialId == trial;
    prediction_error = abs(strcmp(corrAns(which_trials), 'left') - model.pred(which_trials));
    next_trial_correct = response.corr(which_rows & isTrain & trialId == trial - 1);

    blah1 = [blah1; prediction_error(next_trial_correct == 1)];
    blah0 = [blah0; prediction_error(next_trial_correct == 0)];
    means = [means; mean(prediction_error(next_trial_correct == 1)) mean(prediction_error(next_trial_correct == 0))];
    sems = [sems; sem(prediction_error(next_trial_correct == 1)) sem(prediction_error(next_trial_correct == 0))];

    labels = [labels; {sprintf('#%d', trial)}];
end

means = [means; mean(blah1) mean(blah0)];
sems = [sems; sem(blah1) sem(blah0)];
labels = [labels; {'total'}];

subplot(2, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(means, sems);
legend({'correct on next', 'wrong on next'});
xlabel('trial');
xticklabels(labels);
ylabel('|PE|');
