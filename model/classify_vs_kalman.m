%
%
% One thing that would be useful to know is whether the hippocampal classifier is related to 
% how consistent test trial behavior is with a modulatory structure. What you can do is generate
% test trial predictions for each single-structure model, and compute the likelihood of the test
% trials for each of these structures, normalized across the different structures. 
% Then you can take the normalized likelihood for the modulatory model (which expresses how 
% "modulatory" the behavior looks on each block) and correlate it with the probability of the 
% modulatory class from the hippocampal classifier on the (held-out) last training trial of 
% each block. So for each subject you'll compute a correlation (across blocks) and then report
% the average correlation. This tells us how much the hippocampal beliefs about structure 
% influence predict subsequent behavior. You can do the same thing with other ROIs and for 
% other classes (additive, irrelevant) but start with the hippocampus.

% obtained from classify_scp_from_ncf.m
%
close all;
clear all;
rois = {'hippocampus', 'ofc', 'striatum', 'vmpfc', 'rlpfc', 'bg', 'pallidum'};
folder = 'classify_test_trial_19';
train_files = {'classify_train_cvglmnet_hippocampus_condition_LUBGSMICBJ.mat', ...
    'classify_train_cvglmnet_ofc_condition_MSGHNNRZNE.mat', ...
    'classify_train_cvglmnet_striatum_condition_MSGHNNRZNE.mat', ...
    'classify_train_cvglmnet_vmpfc_condition_MSGHNNRZNE.mat', ...
    'classify_train_cvglmnet_rlpfc_condition_BJXGPGEKME.mat', ...
    'classify_train_cvglmnet_bg_condition_XSLBHVRBBC.mat' ...
    'classify_train_cvglmnet_pallidum_condition_BNGQOOQVXF.mat'};

held_out_runs = 1:9;
held_out_trials = [19]; % !!! HARDCODED FIXME TODO
n_training_trials_per_run = 20;
n_test_trials_per_run = 4;

load_data;
[subjects, ~, ~] = contextGetSubjectsDirsAndRuns();
assert(isequal(subjects',unique(participant)));
isTest = ~isTrain;
newTrialId = trialId + isTest * n_training_trials_per_run; % number trials 1..24
sss = getGoodSubjects();

% summary stats of corr_coefs for each ROI, collapsed across subjects
sem = @(x) std(x) / sqrt(length(x));
means = [];
sems = [];

for i = 1:length(rois)
    roi = rois{i};

    % for each subject, how well does the classifier's predition for each
    % condition (based on ROI activation) correlate with the Kalman filter's prediction
    % for the corresponding causal structure (based on test trial behavior)
    corr_coefs = []; % rows = subject, cols = causal structure / condition
    
    %
    % Get Y = P(condition), computed by the classifier on the held out trail
    % for all blocks / subjects
    % TODO dedupe with classify_test
    %
    
    train_file = fullfile(folder, train_files{i});
    load(train_file);
    
    disp(roi);

    % IMPORTANT -- the parameters here must correspond to the ones that the classifier
    % was trained with
    mask = [roi, '.nii'];
    [inputs, targets, subjIds, runIds, trialIds] = classify_get_inputs_and_targets(held_out_trials, held_out_runs, sss, mask, 'condition', true, true);

    load(train_file, 'CVfit');    

    outputs = cvglmnetPredict(CVfit, inputs, CVfit.lambda_1se, 'response');    
    accuracy = classify_get_accuracy(outputs, targets);
    % TODO sanity check with output frmo classify_scp_from_ncf
    fprintf('Success rate (lambda = %.4f) is %.2f%%\n', CVfit.lambda_1se, accuracy);

    for subj = unique(subjIds)'
        fprintf('Kalman for subj %s\n', subjects{subj});
        %
        % Get X = P(structure | test trials) = P(test trials | structure) / sum P(test trials | structure)
        %       = P(test trial 1 | structure) * P(test trial 2 | structure) * P(test trial 3 | structure) * P(test trial 4 | structure) / sum ... 
        % as given by the Kalman filter, assuming a uniform P(structure)
        % for each subject, for each block
        %
        P_structure_all_runs = []; % = X
        P_condition_all_runs = outputs(subjIds == subj,:); % = Y
        actual_conditions_all_runs = []; % sanity check
        
        for run = runIds(subjIds == subj)'
            which_train = strcmp(participant, subjects{subj}) & roundId == run & isTrain;
            which_test =  strcmp(participant, subjects{subj}) & roundId == run & ~isTrain;

            which_models = [1 1 1 0];
            
            actual_condition = contextRole(which_train);
            actual_conditions_all_runs = [actual_conditions_all_runs; actual_condition(1)];
            
            % TODO dedupe with analyze.m
            
            % For a given run of a given subject, run the model on the same
            % sequence of stimuli and see what it does.
            %
            cues = cueId(which_train);
            N = length(cues); % # of trials
            assert(N == n_training_trials_per_run);
            D = 3; % # of stimuli
            prev_trials_surprise = zeros(N, D);
            prev_trials_surprise(sub2ind(size(prev_trials_surprise), 1:N, cues' + 1)) = 1;
            c = contextId(which_train) + 1;
            r = strcmp(sick(which_train), 'Yes');
            [choices, P_n, ww_n, P, ww, values] = train(prev_trials_surprise, c, r, prior_variance, inv_softmax_temp, which_models, false);
            
            % See what the model predicts for the test trials of that run
            %
            test_cues = cueId(which_test);
            test_N = length(test_cues); % # of trials
            assert(test_N == n_test_trials_per_run);
            D = 3; % # of stimuli
            test_x = zeros(test_N, D);
            test_x(sub2ind(size(test_x), 1:test_N, test_cues' + 1)) = 1;
            test_c = contextId(which_test) + 1;
            
            [test_choices, test_values, test_valuess, predict] = test(test_x, test_c, P_n, ww_n, inv_softmax_temp);

            % Compute X for the given run
            %
            P_response_given_structure = nan(n_test_trials_per_run, 3);
            for m = 1:3
                response_probs = predict(test_valuess(:, m));
                assert(length(response_probs) == n_test_trials_per_run);
                % P_blabla(i, j) = P(test trial i | structure j)
                P_response_given_structure(:,m) = binopdf(strcmp(response.keys(which_test), 'left')', 1, response_probs');
            end
            % P_blabla(i) = P(test trials | structure i)
            P_test_trials_given_structure = prod(P_response_given_structure);
            P_structure = P_test_trials_given_structure / sum(P_test_trials_given_structure);
            
            P_structure_all_runs = [P_structure_all_runs; P_structure];            
        end
        
        % Correlate X and Y for all blocks for that subject
        % for each structure / condition
        % i.e. see how well the classifier's prediction for 'modulatory' on
        % that run correlates with the probability that the causal structure is M1 
        % according to the Kalman filter and the subject's responding on
        % the test trials.
        %
        cs = [];
        for m=1:3
            c = corrcoef(P_condition_all_runs(:,m), P_structure_all_runs(:,m));
            cs = [cs c(2,1)];
        end
        corr_coefs = [corr_coefs; cs];
        disp(cs);
    end
    
    means = [means; mean(corr_coefs)];
    sems = [sems; sem(corr_coefs)];
    
   % break; % TODO other ROIs too
end

figure;
barweb(means, sems);
xticklabels(rois);
legend('irr-M1', 'mod-M2', 'add-M3');
ylabel('correlation coefficient');
title('Corr(P_{classifier}(condition), P_{Kalman}(structure | test choices)), averaged across subjects');

save('classify_vs_kalman.mat');
