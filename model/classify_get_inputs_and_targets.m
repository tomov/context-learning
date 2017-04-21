function [inputs, targets] = classify_get_inputs_and_targets(trials, runs, sss, mask, predict_what, preload_betas, z_score)
% helper method that gets the input betas and the targets for the
% classifier to train / test on
%
% trials = which trials to use to train from each run e.g. 1:19 or 1:24
% runs = which runs to use, e.g. 1:9 or 1:8
% sss = subject indices in the subjects array returned by
%       contextGetSubjectsDirsAndRuns, e.g. getGoodSubjects()
% mask = .nii file name of which mask to use
% predict_what = 'condition' or 'responses' or 'roundId'
% preload_betas = whether to preload the betas from a .mat file WARNING --
%      this is DANGEROUS; assumes the .mat file was generated using
%      representational_similarity.m and other dangerous coupling things
% z_score = whether to z-score the betas

fprintf('classify_get_inputs_and_targets\n');
disp(trials)
disp(runs)
disp(mask)
disp(sss)
disp(predict_what);
disp(preload_betas);


model = 60; % the model with the classifier for all trials betas
EXPT = contextExpt();
is_local = 1; % 1 = Momchil's dropbox; 0 = NCF
n_trials_per_run = 24;
n_training_trials_per_run = 20;
%method = 'glmnet'; % patternnet or glmnet
%trials = 1:19;
%sss = getGoodSubjects();
%mask = 'mask.nii';
%outFilename = 'classify_glmnet_fitObj_only_1-19_mask.mat';

% which betas to get for each run -- see SPM.xX.name' in any one of the subjects model
% directories
%
betas = [];
%bla = [1 0 0; 0 1 0; 0 0 1];
for run = runs
    input_idx = trials + (run - 1) * (n_trials_per_run + 6);
    betas(run,:) = input_idx;
end

load_data;
[subjects, ~, ~] = contextGetSubjectsDirsAndRuns();
assert(isequal(subjects',unique(participant)));

isTest = ~isTrain;
newTrialId = trialId + isTest * n_training_trials_per_run; % number trials 1..24


% Get the input vector and labels from the betas
% goal is to infer the targets from the inputs
% assumption is that the targets underlie the inputs
%
labels = containers.Map({'irrelevant', 'modulatory', 'additive'}, ...
                        {[1 0 0], [0 1 0], [0 0 1]});

if preload_betas
    assert(model == 60);
    % assumes this includes all beta vectors as output by
    % representational_similarity.m -- for convenience; otherwise loading them
    % 1 by 1 is too slow
    m = regexp(mask,'\.','split');
    disp('preloading betas...')
    tic
    load(['rsa_beta_vecs_', m{1}, '.mat'], 'beta_vecs', 'beta_runs');
    toc
end
                    
n_observations = length(sss) * length(runs) * length(trials);
beta_vec = ccnl_get_beta(EXPT, model, 1, mask, sss(1)); % just to get the # of voxels
n_voxels = length(beta_vec);

inputs = nan(n_observations, n_voxels); % rows = x = observations, cols = voxels / dependent vars
targets = []; % rows = y = observations, cols = indep vars (condition as binary vector)
input_idx = 0;
%random_run_labels = [];
for subj = sss
    modeldir = fullfile(EXPT.modeldir,['model',num2str(model)],['subj',num2str(subj)]);
    load(fullfile(modeldir,'SPM.mat'));
   
    for run = runs        
        which_trials = ~drop & strcmp(participant, subjects{subj}) & roundId == run & ismember(newTrialId, trials);
        condition = contextRole(which_trials);
        condition = condition{1};
        this_run_responses = response.keys(which_trials);
        this_run_roundIds = roundId(which_trials);
        this_run_trialIds = newTrialId(which_trials);
        assert(length(this_run_responses) == length(trials));
        assert(length(this_run_roundIds) == length(trials));
        assert(length(this_run_trialIds) == length(trials));
        
        % for SANITY check -- make sure condition is the same
        %multi = context_create_multi(1, subj, run);
        %condition_sanity = multi.names{1};
        %assert(strcmp(condition, condition_sanity));
        fprintf('\n----subject %d, run %d\n', subj, run);
    
        %random_run_label = bla(randi(3,1),:);
        %random_run_labels = [random_run_labels; random_run_label];
        %remove_me = 0;
        this_run_trial_idx = 0;
        assert(length(betas(run,:)) == length(trials));
        run_input_idxs = [];
        for i = betas(run,:)
            disp(SPM.xX.name{i});
            this_run_trial_idx = this_run_trial_idx + 1;
            
            %remove_me = remove_me + 1;
            if preload_betas
                which_betas = beta_runs{subj} == run;
                beta_idxs = find(which_betas);
                beta_idx = beta_idxs(this_run_trialIds(this_run_trial_idx));
                beta_vec = beta_vecs{subj}(beta_idx,:);
            else
                beta_vec = ccnl_get_beta(EXPT, model, i, mask, [subj]);
            end
            beta_vec(isnan(beta_vec)) = 0;
            
            % SANITY check !!!! make sure preloaded betas are correct
            % ALWAYS RUN e.g. if change masks or
            % something
            %beta_vec1 = ccnl_get_beta(EXPT, model, i, mask, [subj]);
            %beta_vec1(isnan(beta_vec1)) = 0;
            %assert(sum((beta_vec1 - beta_vec).^2) < 1e-12);
            
            if strcmp(predict_what, 'condition')
                input_idx = input_idx + 1;
                run_input_idxs = [run_input_idxs, input_idx];
                inputs(input_idx,:) = beta_vec;
                targets(input_idx,:) = labels(condition);
            elseif strcmp(predict_what, 'responses')
                if strcmp(this_run_responses{this_run_trial_idx}, 'None')
                else
                    chose_sick = strcmp(this_run_responses{this_run_trial_idx}, 'left');
                    input_idx = input_idx + 1;
                    run_input_idxs = [run_input_idxs, input_idx];
                    inputs(input_idx,:) = beta_vec;
                    tar = [0 0];
                    tar(chose_sick + 1) = 1;
                    targets(input_idx,:) = tar;
                end
            elseif strcmp(predict_what, 'roundId')
                input_idx = input_idx + 1;
                run_input_idxs = [run_input_idxs, input_idx];
                inputs(input_idx,:) = beta_vec;
                tar = zeros(1, 9);
                tar(this_run_roundIds(this_run_trial_idx)) = 1;
                targets(input_idx,:) = tar;
            else
                assert(false);
            end
            % targets(idx,:) = labels(condition);
            
            % scramble the labels on the runs
            %targets(idx,:) = random_run_label;
            %{
            % scramble the labels on trials 1..19
            if remove_me < 20
                bla = [1 0 0; 0 1 0; 0 0 1];
                targets(idx,:) = bla(randi(3,1),:);
            end
            %}
        end
        
        if z_score
            run_mean_voxel = mean(reshape(inputs(run_input_idxs, :), 1, length(run_input_idxs) * n_voxels));
            run_std_voxel = std(reshape(inputs(run_input_idxs, :), 1, length(run_input_idxs) * n_voxels));
            inputs(run_input_idxs, :) = (inputs(run_input_idxs, :) - run_mean_voxel) / run_std_voxel;
        end
    end
end

inputs = inputs(1:size(targets,1), :);

assert(size(inputs, 1) == size(targets, 1));

%assert(size(targets, 1) >= length(sss) * length(runs) * 20 * 0.9);
