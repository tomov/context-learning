% Find optimal parameters for Kalman filter based on behavioral pilot data
%

clear;

fmri_data = false; % use the behavioral pilot data
load_data;

% ---------- get behavioral data ----------%

% Get all subjects' choices for all runs
% Most of this logic is borrowed from analyze.m
%
data = [];
fake_data.N = 0;
fake_data.subjects = []; % hack -- use 1 "subject"; b/c we want one set of params for all subjects
for who = subjects
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
        
        fake_data.N = fake_data.N + subject_data.N;
    end
    
    fake_data.subjects = [fake_data.subjects; subject_data];
end

data = [fake_data];

% ------------ fit models --------------------%


% create parameter structure
%
param = [];

param(1).name = 'prior variance';
param(1).logpdf = @(x) 1;  % log density function for prior
param(1).lb = 0;
param(1).ub = 1; % TODO more?

param(2).name = 'inverse softmax temperature'; 
param(2).logpdf = @(x) 1;  % log density function for prior
param(2).lb = 0;
param(2).ub = 20; % can't make it too large b/c you get prob = 0 and -Inf likelihiood which fmincon doesn't like

% run optimization
%
nstarts = 2;    % number of random parameter initializations
disp('... Fitting model 1');
results(1) = mfit_optimize(@kalman_lik, param, data, nstarts);

fprintf('Prior variance = %.4f, inverse softmax temp = %.4f\n', results(1).x(1), results(1).x(2));
