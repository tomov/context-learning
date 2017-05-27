function log_lik = kalman_lik( params, multisubject_data, which_structures )
% Likelihood function for Kalman filter given a prior variance and an
% inverse softmax temperature
%
% multisubject_data is a 'supersubject' that contains two fields -- N is the total
% number of trials, subjects is a cell array that actually has all the
% subjects' data
% this is to do a fixed effects analysis where we get one set of params for
% all subjects
%
% which_models = binary vector of which causal structures to use, e.g. 
%    [1 1 1 0] for M1, 2, 3 (but not M4)

prior_variance = params(1);
inv_softmax_temp = params(2);

log_lik = 0;

for s = 1:numel(multisubject_data.subjects)
    subject_data = multisubject_data.subjects(s);
    for i = 1:numel(subject_data.runs)
        run_data = subject_data.runs(i);  
        train_trials = 1:20;
        test_trials = 21:24;
       
        % get training choice probabilities
        %
        % which_models = [1 1 1 0]; -- parameter
        cues = run_data.cues(train_trials);
        N = length(cues); % # of trials
        D = 3; % # of stimuli
        x = zeros(N, D);
        x(sub2ind(size(x), 1:N, cues' + 1)) = 1;
        c = run_data.contexts(train_trials);
        r = run_data.sick(train_trials);
        [P_choose_sick_train, P_n, ww_n, P, ww, values] = train(x, c, r, prior_variance, inv_softmax_temp, which_structures, false);

        % get test choice probabilities
        test_cues = run_data.cues(test_trials);
        test_N = length(test_cues); % # of trials
        D = 3; % # of stimuli
        test_x = zeros(test_N, D);
        test_x(sub2ind(size(test_x), 1:test_N, test_cues' + 1)) = 1;
        test_c = run_data.contexts(test_trials);
        [P_choose_sick_test] = test(test_x, test_c, P_n, ww_n, inv_softmax_temp);

        % concatenate them
        P_choose_sick = [P_choose_sick_train; P_choose_sick_test];
        human_choices = run_data.human_choices; % 1 = sick, 0 = not sick

        % add to log likelihood
        log_lik = log_lik + sum(log(P_choose_sick .* (human_choices == 1) + (1 - P_choose_sick) .* (human_choices == 0)));

        % Same as above but unoptimized
        %
        %for i = 1:N
        %    if human_choices(i) == 1
        %        lik = lik + log(P_choose_sick(i));
        %    else
        %        lik = lik + log(1 - P_choose_sick(i));        
        %    end
        %end
    end
end

%params
%lik
