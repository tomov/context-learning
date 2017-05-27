% DEPRECATED -- see bottom of analyze.m
%
% find the log likelihood of the subject test responses
%
% TODO dedupe with analyze.m and context_create_multi.m glm 124
% and fit.m....
%

% Load data from file with all subjects, as well as some constants.
%
load_data;

% use only "good" subjects
%
sss = getGoodSubjects();
[all_subjects, ~, ~] = contextGetSubjectsDirsAndRuns();
subjects = all_subjects(sss);
which_rows = which_rows & ismember(participant, subjects);

which_structuress = {[1 1 1 0], [1 0 0 0], [0 1 0 0], [0 0 1 0], [1 1 0 0], [1 0 1 0], [0 1 1 0]};
struct_names = {'M1, ', 'M2, ', 'M3, ', 'M4, '};

% try out differnt hypothesis spaces of prior structures
%
for which_structures = which_structuress

    total_log_lik = 0;

    which_structures = which_structures{1};
    fprintf('\nstructures %s params = %f %f\n', strcat(struct_names{logical(which_structures)}), prior_variance, inv_softmax_temp);

    
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
                [P_choose_sick_train, P_n, ww_n, P, ww, values, valuess, likelihoods, new_values, new_valuess, Sigma] = train(x, c, r, prior_variance, inv_softmax_temp, which_structures, false);


                % See what the model predicts for the test trials of that run
                %
                test_cues = cueId(which_test);
                test_N = length(test_cues); % # of trials
                D = 3; % # of stimuli
                test_x = zeros(test_N, D);
                test_x(sub2ind(size(test_x), 1:test_N, test_cues' + 1)) = 1;
                test_c = contextId(which_test) + 1;

                [P_choose_sick_test] = test(test_x, test_c, P_n, ww_n, inv_softmax_temp);


                % TODO dedupe with context_create_multi.m GLM 124
                %
                which_trials = which_test & ~strcmp(response.keys, 'None');
                if sum(which_trials) > 0
                    subj_choices = strcmp(response.keys(which_trials), 'left');
                    trial_idxs = trialId(which_trials);

                    % FUCK doesn't work on NCF...
                    assert(numel(subj_choices) == numel(P_choose_sick_test(trial_idxs)));
                    test_liks = binopdf(subj_choices, 1, P_choose_sick_test(trial_idxs));

                    % take average log likelihood !!!
                    % this is to account for missing trials where subject timed
                    % out. Note that taking the sum would be wrong -- imagine
                    % if subject responded on only 1 trial
                    test_log_lik = sum(log(test_liks));

                    total_log_lik = total_log_lik + test_log_lik;
                end
            end
        end
    end
   
    fprintf('which structures = [%d %d %d %d], total log lik = %f\n', which_structures, total_log_lik);
end
