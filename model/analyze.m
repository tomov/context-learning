
% Load data from file with all subjects, as well as some constants.
%
load_data;

% In case we're not using the GUI (i.e. analyze_gui2.m)
%
if ~exist('analyze_with_gui') || ~analyze_with_gui
    which_models = [1 1 1 0]; % consider M1, M2, and M3
end

DO_PLOT = false;

structures = {[1 1 1 0], [1 0 0 0], [0 1 0 0], [0 0 1 0], [1 1 0 0], [1 0 1 0], [0 1 1 0]};
struct_names = {'M1, ', 'M2, ', 'M3, ', 'M4, '};

table_rowNames = {};
table_colNames = {'corr_all', 'corr_test', 'test_log_lik'};
table = nan(numel(structures), numel(table_colNames));
table_row = 0;

for which_models = structures
    
which_models = which_models{1};
fprintf('\nstructures %s params = %f %f\n', strcat(struct_names{logical(which_models)}), prior_variance, inv_softmax_temp);
table_rowNames = [table_rowNames, {strcat(struct_names{logical(which_models)})}];
table_row = table_row + 1;

%
% Simulate
%

human_correct_all_runs = [];
model_correct_all_runs = [];

clear model;
model.keys = {}; % equivalent to response.keys but for the model (i.e. the responses)
model.pred = []; % the choice probability (not the actual choice) for each trial
model.P1 = []; % posterior P(M1 | ...) at each trial
model.P2 = []; % posterior P(M2 | ...) at each trial
model.P3 = []; % posterior P(M3 | ...) at each trial
model.P4 = []; % posterior P(M4 | ...) at each trial
model.P = []; % concatenated posteriors
model.ww1 = []; % weights for M1 
model.ww2 = []; % weights for M2
model.ww3 = []; % weights for M3
model.ww4 = []; % weights for M4
model.values = []; % values at each trial
model.valuess = []; % values for each sturcture at each trial
model.surprise = []; % D_KL at each trial
model.likelihoods = []; % likelihoods for each causal structure
model.new_values = []; % updated values AFTER the trial
model.new_valuess = []; % updated values for each sturcture AFTER each trial
model.Sigma1 = []; % Sigma for M1 at each trial
model.Sigma2 = []; % Sigma for M2 at each trial
model.Sigma3 = []; % Sigma for M3 at each trial
model.Sigma4 = []; % Sigma for M4 at each trial

% HACKSAUCE TODO FIXME
% to predict stuff based on the classifier
%
% use only "good" subjects
%
sss = getGoodSubjects();
[all_subjects, ~, ~] = contextGetSubjectsDirsAndRuns();
subjects = all_subjects(sss);
which_rows = which_rows & ismember(participant, subjects);
%load('classify_glmnet_outputss_1-19_mask_scramble_runs_20.mat');
%ppp = outputss(:,:,end);


%make_optimal_choices = true;

s_id = 0;
for who = subjects
    s_id = s_id + 1;
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
            [choices, P_n, ww_n, P, ww, values, valuess, likelihoods, new_values, new_valuess, Sigma] = train(x, c, r, prior_variance, inv_softmax_temp, which_models, false);

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
            model.P4(which_train) = P(:,4);
            model.P(which_train, :) = P;
            priors = which_models / sum(which_models);
            Q = [priors; P(1:end-1,:)];
            model.Q1(which_train) = Q(:,1);
            model.Q2(which_train) = Q(:,2);
            model.Q3(which_train) = Q(:,3);
            model.Q4(which_train) = Q(:,4);
            model.ww1(which_train, :) = ww{1};
            model.ww2(which_train, :) = ww{2};
            model.ww3(which_train, :) = ww{3};
            model.ww4(which_train, :) = ww{4};
            model.values(which_train, :) = values;
            model.valuess(which_train, :) = valuess;
            logs = log2(P ./ Q); 
            logs(isnan(logs)) = 0; % lim_{x->0} x log(x) = 0
            surprise = sum(P .* logs, 2);
            surprise(isnan(surprise)) = 0; % weird things happen when P --> 0 TODO FIXME
            model.surprise(which_train, :) = surprise;
            model.likelihoods(which_train, :) = likelihoods;
            model.new_values(which_train, :) = new_values;
            model.new_valuess(which_train, :) = new_valuess;
            model.Sigma1(which_train, :) = Sigma{1};
            model.Sigma2(which_train, :) = Sigma{2};
            model.Sigma3(which_train, :) = Sigma{3};
            model.Sigma4(which_train, :) = Sigma{4};
            

            % See what the model predicts for the test trials of that run
            %
            test_cues = cueId(which_test);
            test_N = length(test_cues); % # of trials
            D = 3; % # of stimuli
            test_x = zeros(test_N, D);
            test_x(sub2ind(size(test_x), 1:test_N, test_cues' + 1)) = 1;
            test_c = contextId(which_test) + 1;
            
            %P_n = [ppp((s_id - 1) * 9 + run,:) 0]; % HACKSAUCE TODO FIXME -- this is to predict based on the classifier
            [test_choices] = test(test_x, test_c, P_n, ww_n, inv_softmax_temp);

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
model.P4 = model.P4';
model.Q1 = model.Q1';
model.Q2 = model.Q2';
model.Q3 = model.Q3';
model.Q4 = model.Q4';


% HACKSAUCE -- for the classifier TODO FIXME
%
%{
which = which_rows & ~isTrain;
fprintf('MSE for behavioral prediction based on classifier: %.4f\n', ...
    immse(model.pred(which), double(strcmp(response.keys(which), 'left'))));
%}


%
% Do some plotting
%

if DO_PLOT
          
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

        M = get_means(x1c1, x1c2, x2c1, x2c2);
        SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
        %M = mean([x1c1 x1c2 x2c1 x2c2]);
        %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
        Ms = [Ms; M];
        SEMs = [SEMs; SEM];
    end

    subplot(3, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    barweb(Ms, SEMs, 1, contextRoles, 'P(sick outcome) in training');
    ylabel('Sick probability');
    legend({'x_1c_1', 'x_1c_2', 'x_2c_1', 'x_2c_2'});


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

    %    M = mean([x1c1 x1c2 x2c1 x2c2]);
    %    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
        M = get_means(x1c1, x1c2, x2c1, x2c2);
        SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
        Ms = [Ms; M];
        SEMs = [SEMs; SEM];
    end

    subplot(3, 5, next_subplot_idx);
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

        %M = mean([x1c1 x1c2 x2c1 x2c2]);
        %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
        M = get_means(x1c1, x1c2, x2c1, x2c2);
        SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
        Ms = [Ms; M];
        SEMs = [SEMs; SEM];
    end

    subplot(3, 5, next_subplot_idx);
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

        %M = mean([x1c1 x1c2 x2c1 x2c2]);
        %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
        M = get_means(x1c1, x1c2, x2c1, x2c2);
        SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
        Ms = [Ms; M];
        SEMs = [SEMs; SEM];
    end

    subplot(3, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    barweb(Ms, SEMs, 1, contextRoles, 'Ideal model P(choose sick) in test');
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

    subplot(3, 5, next_subplot_idx);
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
            P4_n = model.P4(which);

            P_n = [];  % only include the posteriors from models we care about
            if which_models(1), P_n = [P_n mean(P1_n)]; end
            if which_models(2), P_n = [P_n mean(P2_n)]; end
            if which_models(3), P_n = [P_n mean(P3_n)]; end
            if which_models(4), P_n = [P_n mean(P4_n)]; end
            P = [P; P_n];
        end

        subplot(3, 5, next_subplot_idx);
        next_subplot_idx = next_subplot_idx + 1;
        plot(P, 'o-', 'LineWidth', 2);
        xlabel('n (trial #)');
        ylabel('P(M | h_{1:n})');
        title(strcat('Posterior after each trial for ', {' '}, condition));

        Ms = {}; % only include models we care about
        if which_models(1), Ms = [Ms, {'M1'}]; end
        if which_models(2), Ms = [Ms, {'M2'}]; end
        if which_models(3), Ms = [Ms, {'M3'}]; end
        if which_models(4), Ms = [Ms, {'M4'}]; end
        legend(Ms);

    end


    %
    % Model per-trial weight matrix ww for each condition
    %
    for condition = contextRoles

        ww = [];
        for n = 1:N
            which = which_rows & isTrain & strcmp(contextRole, condition) & trialId == n;

            ww1_n = model.ww1(which, :);
            ww2_n = model.ww2(which, :);
            ww3_n = model.ww3(which, :);
            ww4_n = model.ww4(which, :);

            ww_n = []; % only include the weights from models we care about
            if which_models(1), ww_n = [ww_n mean(ww1_n)]; end
            if which_models(2), ww_n = [ww_n mean(ww2_n)]; end
            if which_models(3), ww_n = [ww_n mean(ww3_n)]; end
            if which_models(4), ww_n = [ww_n mean(ww4_n)]; end
            ww = [ww; ww_n];
        end

        subplot(3, 5, next_subplot_idx);
        next_subplot_idx = next_subplot_idx + 1;
        plot(ww, 'o-', 'LineWidth', 1);
        xlabel('n (trial #)');
        ylabel('ww_n');
        title(strcat('Weights after each trial for ', {' '}, condition));

        Ms = {}; % only include models we care about
        if which_models(1), Ms = [Ms, {'M1, x1'}, {'M1, x2'}]; end
        if which_models(2), Ms = [Ms, {'M2, x1c1'}, {'M2, x2c1'}, {'M2, x1c2'}, {'M2, x2c2'}]; end
        if which_models(3), Ms = [Ms, {'M3, x1'}, {'M3, x2'}, {'M3, c1'}, {'M3, c2'}]; end
        if which_models(4), Ms = [Ms, {'M4, c1'}, {'M4, c2'}]; end
        legend(Ms);

    end

    %
    % D_KL == bayesian surprise on each training trial, by whether trial was
    % correct
    %
    P = [model.P1 model.P2 model.P3 model.P4];
    Q = [model.Q1 model.Q2 model.Q3 model.Q4];

    means = zeros(1,2);
    sems = zeros(1,2);
    sem = @(x) std(x) / sqrt(length(x));
    for correct = 1:-1:0
        which = which_rows & isTrain & response.corr == correct;

        means(1, 2 - correct) = mean(model.surprise(which)); 
        sems(1, 2 - correct) = sem(model.surprise(which));
    end

    subplot(3, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    barweb(means, sems);
    legend({'correct', 'wrong'});
    ylabel('D_{KL} on current trial');

    %
    % D_KL == bayesian surprise on each training trial, by whether next trial
    % was correct
    %

    which_next_trials = which_rows & isTrain & trialId ~= 1;
    which_prev_trials = which_rows & isTrain & trialId ~= 20;
    prev_trials_surprise = model.surprise(which_prev_trials);
    next_trials_corr = response.corr(which_next_trials);


    means = [mean(prev_trials_surprise(next_trials_corr == 1)) mean(prev_trials_surprise(next_trials_corr == 0))];
    sems = [sem(prev_trials_surprise(next_trials_corr == 1)) sem(prev_trials_surprise(next_trials_corr == 0))];

    subplot(3, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    barweb(means, sems);
    legend({'correct', 'wrong'});
    ylabel('D_{KL} on previous trial');




    %
    % value in sick vs. not sick
    %
    %{
    outcomes = strcmp(sick(which_rows & isTrain), 'Yes');
    values = model.values(which_rows & isTrain);

    means = [mean(values(outcomes == 1)) mean(values(outcomes == 0))];
    sems = [sem(values(outcomes == 1)) sem(values(outcomes == 0))];

    subplot(3, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    barweb(means, sems);
    legend({'sick', 'not sick'});
    ylabel('value');
    %}


    %
    % value in chose sick vs. chose not sick, on wrong trials
    %

    wrong_trials = which_rows & isTrain & response.corr == 0;
    subject_choices = strcmp(response.keys(wrong_trials), 'left');
    values = model.values(wrong_trials);

    means = [mean(values(subject_choices == 1)) mean(values(subject_choices == 0))];
    sems = [sem(values(subject_choices == 1)) sem(values(subject_choices == 0))];

    subplot(3, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    barweb(means, sems);
    title('Wrong Trials');
    legend({'chose sick', 'chose not sick'});
    ylabel('value');

    %
    % value in chose sick vs. chose not sick, on correct trials
    %

    correct_trials = which_rows & isTrain & response.corr == 1;
    subject_choices = strcmp(response.keys(correct_trials), 'left');
    values = model.values(correct_trials);

    means = [mean(values(subject_choices == 1)) mean(values(subject_choices == 0))];
    sems = [sem(values(subject_choices == 1)) sem(values(subject_choices == 0))];

    subplot(3, 5, next_subplot_idx);
    next_subplot_idx = next_subplot_idx + 1;
    barweb(means, sems);
    title('Correct Trials');
    legend({'chose sick', 'chose not sick'});
    ylabel('value');

end


%
% more analysis
%

no_response = strcmp(response.keys, 'None');

%
% Get correlation between predicted and actual choices
%
%which = which_rows & ~isTrain;
which = which_rows & ~no_response;
x = strcmp(response.keys(which), 'left');
y = model.pred(which);
[r, p] = corrcoef(x, y);
r = r(1,2);
p = p(1,2);
fprintf('correlation between model and subject choices = %f (p = %e)\n', r, p);
table(table_row, 1) = r;

% Get correlation between predicted and actual choices, but for test trials only
%
which = which_rows & ~isTrain & ~no_response;
x = strcmp(response.keys(which), 'left');
y = model.pred(which);
[r, p] = corrcoef(x, y);
r = r(1,2);
p = p(1,2);
fprintf('correlation between model and subject choices (test trials only) = %f (p = %e)\n', r, p);
table(table_row, 2) = r;

% Get test choice log likelihood
%
which = which_rows & ~isTrain & ~no_response;
x = strcmp(response.keys(which), 'left');
y = model.pred(which);

test_liks = binopdf(x, 1, y);
total_test_log_lik = sum(log(test_liks));
fprintf('test choice log likelihood = %f\n', total_test_log_lik);
table(table_row, 3) = total_test_log_lik;

end

T = array2table(table, 'RowNames', table_rowNames, 'VariableNames', table_colNames)
