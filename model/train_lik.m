function lik = train_lik( params, fake_data )
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
        
        cues = run_data.cues;
        N = length(cues); % # of trials
        D = 3; % # of stimuli
        x = zeros(N, D);
        x(sub2ind(size(x), 1:N, cues' + 1)) = 1;
        c = run_data.contexts;
        r = run_data.sick;
        [P_choose_sick, P_n, ww_n, P, ww] = train(x, c, r, prior_variance, inv_softmax_temp, false);

        human_choices = run_data.human_choices; % 1 = sick, 0 = not sick

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