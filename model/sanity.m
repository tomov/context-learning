% Make sure that we didn't fuck up anything
%

% Load all the subject data and some constants
%
load_data;

if ~exist('analyze_with_gui') || ~analyze_with_gui % for the GUI; normally we always create a new figure
    figure;
end

next_subplot_idx = 1; % so you can reorder them by simply rearranging the code

%
% Outcome probabilities in training phase
%

Ms = [];
SEMs = [];

for context = contextRoles
    which = which_rows & isTrain == 1 & strcmp(contextRole, context);
    
    x1c1 = strcmp(corrAns(which & cueId == 0 & contextId == 0), 'left');
    x1c2 = strcmp(corrAns(which & cueId == 0 & contextId == 1), 'left');
    x2c1 = strcmp(corrAns(which & cueId == 1 & contextId == 0), 'left');
    x2c2 = strcmp(corrAns(which & cueId == 1 & contextId == 1), 'left');

    if ~exist('analyze_with_gui') || ~analyze_with_gui
        assert(length(x1c1) == roundsPerContext * trialsNReps * length(subjects));
        assert(length(x1c2) == roundsPerContext * trialsNReps * length(subjects));
        assert(length(x2c1) == roundsPerContext * trialsNReps * length(subjects));
        assert(length(x2c2) == roundsPerContext * trialsNReps * length(subjects));
    end

    M = get_means(x1c1, x1c2, x2c1, x2c2);
    SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
    %M = mean([x1c1 x1c2 x2c1 x2c2]);
    %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

subplot(3, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'P(sick outcome) in training');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_2', 'x_2c_1', 'x_2c_2'});




%
% Cue-context occurences in training phase
%

Ms = [];
SEMs = [];

for context = contextRoles
    which = which_rows & isTrain == 1 & strcmp(contextRole, context);
    
    x1c1 = which & cueId == 0 & contextId == 0;
    x1c2 = which & cueId == 0 & contextId == 1;
    x2c1 = which & cueId == 1 & contextId == 0;
    x2c2 = which & cueId == 1 & contextId == 1;

    if ~exist('analyze_with_gui') || ~analyze_with_gui
        assert(sum(x1c1) == roundsPerContext * trialsNReps * length(subjects));
        assert(sum(x1c2) == roundsPerContext * trialsNReps * length(subjects));
        assert(sum(x2c1) == roundsPerContext * trialsNReps * length(subjects));
        assert(sum(x2c2) == roundsPerContext * trialsNReps * length(subjects));
    end

    M = sum([x1c1, x1c2, x2c1, x2c2]) / sum(which);
    SEM = [0 0 0 0];
    %M = mean([x1c1 x1c2 x2c1 x2c2]);
    %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

subplot(3, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'Cue-context occurence in training');
ylabel('Trial probability');
legend({'x_1c_1', 'x_1c_2', 'x_2c_1', 'x_2c_2'});


%
% Cue-context occurences in test phase
%

Ms = [];
SEMs = [];

for context = contextRoles
    which = which_rows & isTrain == 0 & strcmp(contextRole, context);
    
    x1c1 = which & cueId == 0 & contextId == 0;
    x1c3 = which & cueId == 0 & contextId == 2;
    x3c1 = which & cueId == 2 & contextId == 0;
    x3c3 = which & cueId == 2 & contextId == 2;

    if ~exist('analyze_with_gui') || ~analyze_with_gui
        assert(sum(x1c1) == roundsPerContext * length(subjects));
        assert(sum(x1c3) == roundsPerContext * length(subjects));
        assert(sum(x3c1) == roundsPerContext * length(subjects));
        assert(sum(x3c3) == roundsPerContext * length(subjects));
    end

    M = sum([x1c1, x1c3, x3c1, x3c3]) / sum(which);
    SEM = [0 0 0 0];
    %M = mean([x1c1 x1c2 x2c1 x2c2]);
    %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

subplot(3, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'Cue-context occurence in test');
ylabel('Trial probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});



%
% Per-subject accuracy & timeouts for sanity check (training only)
%

subjects_perf = [];
subjects_perf_sem = [];
subjects_captions = {};

i = 0;
for who = subjects
    which = which_rows & isTrain & strcmp(participant, who);
    
    corr = strcmp(response.keys(which), corrAns(which));
    timeout = strcmp(response.keys(which), 'None');
    wrong = ~strcmp(response.keys(which), corrAns(which)) & ~timeout;
    subjects_perf = [subjects_perf; mean([corr wrong timeout])];
    subjects_perf_sem = [subjects_perf_sem; std([corr wrong timeout]) / sqrt(length(corr))];
    i = i + 1;
    subjects_captions{i} = who{1}(5:end);
end

subplot(3, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(subjects_perf, subjects_perf_sem, 1, subjects_captions, 'Subject performance in training');
ylabel('Fraction of trials');
legend({'Correct', 'Wrong', 'Timeout'});



%
% Per-subject response rate & timeouts (test phase only)
%

subjects_perf = [];
subjects_perf_sem = [];
subjects_captions = {};

i = 0;
for who = subjects
    which = which_rows & ~isTrain & strcmp(participant, who);
    
    timeout = strcmp(response.keys(which), 'None');
    subjects_perf = [subjects_perf; mean([~timeout timeout])];
    subjects_perf_sem = [subjects_perf_sem; std([~timeout timeout]) / sqrt(length(timeout))];
    i = i + 1;
    subjects_captions{i} = who{1}(5:end);
end

subplot(3, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(subjects_perf, subjects_perf_sem, 1, subjects_captions, 'Subject responsiveness in test');
ylabel('Fraction of trials');
legend({'Responded', 'Timeout'});


%
% Per-run accuracy & timeouts (across all subjects) for training only
%

runs_perf = [];
runs_perf_sem = [];
runs_captions = {};

for run = unique(roundId)';
    which = which_rows & isTrain & roundId == run;
    
    corr = strcmp(response.keys(which), corrAns(which));
    timeout = strcmp(response.keys(which), 'None');
    wrong = ~strcmp(response.keys(which), corrAns(which)) & ~timeout;
    runs_perf = [runs_perf; mean([corr wrong timeout])];
    runs_perf_sem = [runs_perf_sem; std([corr wrong timeout]) / sqrt(length(corr))];
    runs_captions{run} = strcat('#', int2str(run));
end

subplot(3, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(runs_perf, runs_perf_sem, 1, runs_captions, 'Per-run performance in training');
ylabel('Fraction of trials');
legend({'Correct', 'Wrong', 'Timeout'});


%
% Per-run responsitveness & timeouts (across all subjects) for test phase
%

runs_perf = [];
runs_perf_sem = [];
runs_captions = {};

for run = unique(roundId)';
    which = which_rows & ~isTrain & roundId == run;
    
    timeout = strcmp(response.keys(which), 'None');
    runs_perf = [runs_perf; mean([~timeout timeout])];
    runs_perf_sem = [runs_perf_sem; std([~timeout timeout]) / sqrt(length(timeout))];
    runs_captions{run} = strcat('#', int2str(run));
end

subplot(3, 3, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(runs_perf, runs_perf_sem, 1, runs_captions, 'Per-run responsiveness in test');
ylabel('Fraction of trials');
legend({'Responded', 'Timeout'});

