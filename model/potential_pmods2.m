% run after analyze
%

figure;
next_subplot_idx = 1;

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


which_trials = which_rows & isTrain & [model.surprise; 0;0;0;0] > 0.1;
RTs = response.rt(circshift(which_trials, -1));
surprise = model.surprise(which_trials);

scatter(surprise, RTs);
