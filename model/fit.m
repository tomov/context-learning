% Find optimal parameters for Kalman filter based on behavioral pilot data
%

clear all;

results_idx = 0; % which version of the model we're fitting now
results_names = {};

% fit behavioral (0) or fMRI (1) data
%
for fmri_data = [0 1]
    load_data; % fmri_data ise used in load_data TODO coupling -- make load_data a method

    % ---------- get behavioral data ----------%

    % Fixed effects -- one set of parameters for all subjects
    % use 1 "supersubject": put data from all subjects in 1 array & use that
    %
    fixed_effects_data = struct([]);
    fixed_effects_data(1).N = 0; % = # trials for all subjects
    fixed_effects_data(1).subjects = []; % = data for all subjects

    % Random effects -- a separate set of params for each subject
    % note that b/c kalman_lik is designed to support the fixed effects case
    % where we give it a list of subjects, here we need to have a cell array
    % where each cell is a struct that also has a 'subjects' field but that
    % contains only 1 subject
    %
    random_effects_data = struct([]);

    % Get all subjects' choices for all runs
    % Most of this logic is borrowed from analyze.m
    %
    subj_idx = 0;
    for who = subjects
        subj_idx = subj_idx + 1;

        which_runs = strcmp(participant, who);
        runs = unique(roundId(which_runs))';

        subject_data.N = 0;
        subject_data.runs = [];

        for run = runs
            % note they include 20 train + 4 test trials
            % we separate them when we compute the likelihood
            which_trials = which_runs & roundId == run;

            % TODO handle None (i.e. TIMEOUT) trials
            run_data.human_choices = strcmp(response.keys(which_trials), 'left');
            run_data.cues = cueId(which_trials);
            run_data.N = length(run_data.cues);
            run_data.contexts = contextId(which_trials) + 1;
            run_data.sick = strcmp(sick(which_trials), 'Yes');

            subject_data.runs = [subject_data.runs; run_data];
            subject_data.N = subject_data.N + run_data.N;

        end

        % append to fixed_effects "supersubject"
        fixed_effects_data(1).N = fixed_effects_data.N + subject_data.N;
        fixed_effects_data(1).subjects = [fixed_effects_data.subjects; subject_data];

        % append to random effects list of subjects
        % since the kalman_lik function expects a list of subjects (to support
        % the fixed_effects case), we need to give it a list of 1 subject in
        % each cell #hack
        random_effects_data(subj_idx).N = subject_data.N;
        random_effects_data(subj_idx).subjects = [subject_data];

    end
    
    
    % fixed effects (1) or random effects (0)
    % fixed effects = have one "supersubject" and fit one set of parameters for her, 
    % random effects = fit each individual subject separately with her own set of parameters
    %
    for fixed_effects = [0 1]
        if fixed_effects
            data = fixed_effects_data; % put it in cell array -- it's important for consistency w/ the random effects case and what mfit_optimize expects
        else
            data = random_effects_data;
        end
        
        fprintf('\n\n ------- fmri_data? %d, fixed effects? %d ----------\n\n', fmri_data, fixed_effects);
    
        % ------------ fit models --------------------%

        % create parameter structure
        %
        param = [];

        param(1).name = 'prior variance';
        param(1).logpdf = @(x) 1;  % log density function for prior
        param(1).lb = 0; % lower bound
        param(1).ub = 1; % upper bound TODO more?

        param(2).name = 'inverse softmax temperature'; 
        param(2).logpdf = @(x) 1;  % log density function for prior
        param(2).lb = 0;
        param(2).ub = 10; % can't make it too large b/c you get prob = 0 and -Inf likelihiood which fmincon doesn't like

        which_structuress = {[1 1 1 0], [1 0 0 0], [0 1 0 0], [0 0 1 0]};
    
        % try out differnt hypothesis spaces of prior structures
        %
        for which_structures = which_structuress
            % run optimization
            %
            nstarts = 5;    %  TODO change = number of random parameter initializations 
            results_idx = results_idx + 1;
            name = sprintf('fmri data? %d fixed effects? %d which structs [%d %d %d %d]', ...
                fmri_data, fixed_effects, which_structures{1});
            fprintf('... Fitting model %d (%s)\n', results_idx, name);
            results(results_idx) = mfit_optimize(@(params, data) kalman_lik(params, data, which_structures{1}), param, data, nstarts);
            results_names{results_idx} = name;

            fprintf('    Prior variance = %.4f, inverse softmax temp = %.4f, bic = %.4f\n', ...
                results(results_idx).x(1), results(results_idx).x(2), results(results_idx).bic);        
        end
    end
end

save('fit.mat');

