function lik = kalman_lik( params, fake_data )
% Likelihood function for Kalman filter given a prior variance and an
% inverse softmax temperature
%
prior_variance = params(1);
inv_softmax_temp = params(2);

lik = 0;

for s = 1:numel(fake_data.subjects)
    subject_data = fake_data.subjects(s);
    for i = 1:numel(subject_data.runs)
        run_data = subject_data.runs(i);  
        train_trials = 1:20;
        test_trials = 21:24;
       
        % get training choice probabilities
        cues = run_data.cues(train_trials);
        N = length(cues); % # of trials
        D = 3; % # of stimuli
        x = zeros(N, D);
        x(sub2ind(size(x), 1:N, cues' + 1)) = 1;
        c = run_data.contexts(train_trials);
        r = run_data.sick(train_trials);
        [P_choose_sick_train, P_n, ww_n, P, ww] = train(x, c, r, prior_variance, inv_softmax_temp, false);

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
        lik = lik + sum(log(P_choose_sick .* (human_choices == 1) + (1 - P_choose_sick) .* (human_choices == 0)));

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
