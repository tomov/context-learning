% TODO show posterior in all conditions (see todo below)
% TODO plot prediction certainty Sigma
% TODO plot learning rates g
% TODO checkboxes for subject (+ all), condition (+ all), run (+ all)
%         -- radio button -- either runs 1,2,3,4,5... OR conditions + 1st,
%         2nd, 3rd run of each condition
%

% load data from file with all subjects
% generated using parse.py (see snippets/parse.py)

format = '%s %s %s %d %s %s %s %d %d %s %s %s %f %d %s %s %d %d %d';

[participant, session, mriMode, isPractice, restaurantsReshuffled, foodsReshuffled, contextRole, contextId, cueId, sick, corrAns, response.keys, response.rt, response.corr, restaurant, food, isTrain, roundId, trialId] = ...
    textread('pilot-with-hayley.csv', format, 'delimiter', ',', 'headerlines', 1);

roundsPerContext = 3; % = blocks per context = runs per context = runs / 3
trialsNReps = 5; % = trials per run / 4

if ~exist('analyze_with_gui') || ~analyze_with_gui % for the GUI; normally we always reload the data
    which_rows = logical(true(size(participant))); % which rows to include/exclude. By default all of them
    subjects = unique(participant(which_rows))'; % the unique id's of all subjects
    
    contextRoles = {'irrelevant', 'modulatory', 'additive'}; % should be == unique(contextRole)'

    make_optimal_choices = true;
end


%
% Simulate
%

human_correct_all_runs = [];
model_correct_all_runs = [];

model.keys = {}; % equivalent to response.keys but for the model (i.e. the responses)
model.pred = []; % the choice probability (not the actual choice) for each trial
model.P1 = []; % posterior P(M1 | ...) at each trial
model.P2 = []; % posterior P(M2 | ...) at each trial
model.P3 = []; % posterior P(M3 | ...) at each trial

for who = subjects
    for condition = unique(contextRole)'
        which_runs = which_rows & strcmp(participant, who) & strcmp(contextRole, condition);
        runs = unique(roundId(which_runs))';
        for run = runs
            which_train = which_runs & isTrain & roundId == run;
            which_test = which_runs & ~isTrain & roundId == run;
            
            % For a given run of a given subject, run the model on the same
            % sequence of stimuli and see what it does.
            %
            cues = cueId(which_train);
            N = length(cues); % # of trials
            D = 3; % # of stimuli
            x = zeros(N, D);
            x(sub2ind(size(x), 1:N, cues' + 1)) = 1;
            c = contextId(which_train) + 1;
            r = strcmp(sick(which_train), 'Yes');
            [choices, P_n, ww_n, P, ww] = train(x, c, r, false);
            
            if make_optimal_choices
                model_choices = choices > 0.5;
            else
                model_choices = choices > rand;
            end
            model_response_keys = {};
            model_response_keys(model_choices) = {'left'};
            model_response_keys(~model_choices) = {'right'};
            model.keys(which_train) = model_response_keys;
            model.pred(which_train) = choices;
            model.P1(which_train) = P(:,1);
            model.P2(which_train) = P(:,2);
            model.P3(which_train) = P(:,3);
            
            % See what the model predicts for the test trials of that run
            %
            test_cues = cueId(which_test);
            test_N = length(test_cues); % # of trials
            D = 3; % # of stimuli
            test_x = zeros(test_N, D);
            test_x(sub2ind(size(test_x), 1:test_N, test_cues' + 1)) = 1;
            test_c = contextId(which_test) + 1;
            [test_choices] = test(test_x, test_c, P_n, ww_n);

            if make_optimal_choices
                model_test_choices = test_choices > 0.5;
            else
                model_test_choices = test_choices > rand;
            end
            model_test_response_keys = {};
            model_test_response_keys(model_test_choices) = {'left'};
            model_test_response_keys(~model_test_choices) = {'right'};
            model.keys(which_test) = model_test_response_keys;
            model.pred(which_test) = test_choices;
            
            % Get the subject's responses too.
            %
            resp = response.keys(which_train);
            human_choices = strcmp(resp, 'left'); % sick == 1            
        end
    end
end

model.keys = model.keys';
model.pred = model.pred';
model.P1 = model.P1';
model.P2 = model.P2';
model.P3 = model.P3';

%% Do some plotting
%
          
if ~exist('analyze_with_gui') || ~analyze_with_gui % for the GUI; normally we always create a new figure
    figure;
end

next_subplot_idx = 1; % so you can reorder them by simply rearranging the code

%
% Outcome probabilities training phase (sanity check to make sure we didn't
% fuck up the task)
%

Ms = [];
SEMs = [];


for context = contextRoles
    which = which_rows & isTrain == 1 & strcmp(contextRole, context);
    
    x1c1 = strcmp(corrAns(which & cueId == 0 & contextId == 0), 'left');
    x1c2 = strcmp(corrAns(which & cueId == 0 & contextId == 1), 'left');
    x2c1 = strcmp(corrAns(which & cueId == 1 & contextId == 0), 'left');
    x2c2 = strcmp(corrAns(which & cueId == 1 & contextId == 1), 'left');

    assert(length(x1c1) == roundsPerContext * trialsNReps * length(subjects));
    assert(length(x1c2) == roundsPerContext * trialsNReps * length(subjects));
    assert(length(x2c1) == roundsPerContext * trialsNReps * length(subjects));
    assert(length(x2c2) == roundsPerContext * trialsNReps * length(subjects));

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

subplot(2, 5, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'P(sick outcome) in training');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_2', 'x_2c_1', 'x_2c_2'});



%
% Per-subject accuracy & timeouts for sanity check (training only)
%

subjects_perf = [];

for who = subjects
    which = which_rows & isTrain & strcmp(participant, who);
    
    corr = strcmp(response.keys(which), corrAns(which));
    timeout = strcmp(response.keys(which), 'None');
    wrong = ~strcmp(response.keys(which), corrAns(which)) & ~timeout;
    subjects_perf = [subjects_perf; mean([corr wrong timeout])];
end

subplot(2, 5, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(subjects_perf, zeros(size(subjects_perf)), 1, subjects, 'Individual subject performance');
ylabel('Fraction of trials');
legend({'Correct', 'Wrong', 'Timeout'});


%
% Choice probabilities in test phase for SUBJECTS
% This is the final figure we care about
%

Ms = [];
SEMs = [];
for context = contextRoles
    which = which_rows & isTrain == 0 & strcmp(contextRole, context);
    
    x1c1 = strcmp(response.keys(which & cueId == 0 & contextId == 0), 'left');
    x1c2 = strcmp(response.keys(which & cueId == 0 & contextId == 2), 'left');
    x2c1 = strcmp(response.keys(which & cueId == 2 & contextId == 0), 'left');
    x2c2 = strcmp(response.keys(which & cueId == 2 & contextId == 2), 'left');

    assert(length(x1c1) == roundsPerContext * length(subjects));
    assert(length(x1c2) == roundsPerContext * length(subjects));
    assert(length(x2c1) == roundsPerContext * length(subjects));
    assert(length(x2c2) == roundsPerContext * length(subjects));

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
%    M = [mean(x1c1) mean(x1c2) mean(x2c1) mean(x2c2)];
%    SEM = [std(x1c1) / sqrt(length(x1c1)) std(x1c2) / sqrt(length(x1c2)) std(x2c1) / sqrt(length(x2c1)) std(x2c2) / sqrt(length(x2c2))];
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end
    
subplot(2, 5, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'Subject P(choose sick) in test');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});


%
% Choice probabilities in test phase for MODEL (based on the actual
% decisions the model made)
% This is the final figure we care about
%

Ms = [];
SEMs = [];
for context = contextRoles
    which = which_rows & isTrain == 0 & strcmp(contextRole, context);
    
    
    x1c1 = strcmp(model.keys(which & cueId == 0 & contextId == 0), 'left');
    x1c2 = strcmp(model.keys(which & cueId == 0 & contextId == 2), 'left');
    x2c1 = strcmp(model.keys(which & cueId == 2 & contextId == 0), 'left');
    x2c2 = strcmp(model.keys(which & cueId == 2 & contextId == 2), 'left');
    
    assert(length(x1c1) == roundsPerContext * length(subjects));
    assert(length(x1c2) == roundsPerContext * length(subjects));
    assert(length(x2c1) == roundsPerContext * length(subjects));
    assert(length(x2c2) == roundsPerContext * length(subjects));

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
%    M = [mean(x1c1) mean(x1c2) mean(x2c1) mean(x2c2)];
%    SEM = [std(x1c1) / sqrt(length(x1c1)) std(x1c2) / sqrt(length(x1c2)) std(x2c1) / sqrt(length(x2c1)) std(x2c2) / sqrt(length(x2c2))];
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end
    
subplot(2, 5, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'Model P(choose sick) in test');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});


%
% TRUE Choice probabilities in test phase for MODEL
%

Ms = [];
SEMs = [];
for context = contextRoles
    which = which_rows & isTrain == 0 & strcmp(contextRole, context);
    
    x1c1 = model.pred(which & cueId == 0 & contextId == 0);
    x1c2 = model.pred(which & cueId == 0 & contextId == 2);
    x2c1 = model.pred(which & cueId == 2 & contextId == 0);
    x2c2 = model.pred(which & cueId == 2 & contextId == 2);
    
    assert(length(x1c1) == roundsPerContext * length(subjects));
    assert(length(x1c2) == roundsPerContext * length(subjects));
    assert(length(x2c1) == roundsPerContext * length(subjects));
    assert(length(x2c2) == roundsPerContext * length(subjects));

    M = mean([x1c1 x1c2 x2c1 x2c2]);
    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
%    M = [mean(x1c1) mean(x1c2) mean(x2c1) mean(x2c2)];
%    SEM = [std(x1c1) / sqrt(length(x1c1)) std(x1c2) / sqrt(length(x1c2)) std(x2c1) / sqrt(length(x2c1)) std(x2c2) / sqrt(length(x2c2))];
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end
    
subplot(2, 5, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'Model P(choose sick) in test phase');
ylabel('Sick probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});




%
% Per-trial accuracy across all subjects & runs (training only)
% compared against the model
%

human_correct = [];
model_correct = [];

for n = 1:N
    which = which_rows & isTrain & trialId == n;
    
    human_corr_n = strcmp(response.keys(which), corrAns(which));
    model_corr_n = strcmp(model.keys(which), corrAns(which));
    human_correct = [human_correct mean(human_corr_n)];
    model_correct = [model_correct mean(model_corr_n)];
end

subplot(2, 5, next_subplot_idx);
next_subplot_idx = next_subplot_idx + 1;
plot(model_correct, 'o-', 'LineWidth', 2); % == mean(human_correct_all_runs)
hold on;
plot(human_correct, 'o-', 'LineWidth', 2); % == mean(model_correct_all_runs)
hold off;
legend({'model', 'subject'});
title('Per-trial accuracy');
xlabel('trial #');
ylabel('accuracy');


%
% Model per-trial posterior probability P(M | ...) for each condition
%

for condition = contextRoles

    P = [];
    for n = 1:N
        which = which_rows & isTrain & strcmp(contextRole, condition) & trialId == n;

        P1_n = model.P1(which);
        P2_n = model.P2(which);
        P3_n = model.P3(which);
        P = [P; mean([P1_n P2_n P3_n])];
    end

    subplot(2, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    plot(P, 'o-', 'LineWidth', 2);
    xlabel('n (trial #)');
    ylabel('P(M | h_{1:n})');
    title(strcat('Posterior after each trial for ', {' '}, condition));
    legend({'M1', 'M2', 'M3'});

end
