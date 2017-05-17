% representational similarity analysis
% get the beta vectors from each subject (to be used for the single-subject
% RDM)
% mask must be nifti file, e.g. 'visual.nii'
%
function representational_similarity(mask)
%clear all;

subj = 1;
trials = 1:24;


model = 60; % the model with the classifier for all trials betas
EXPT = contextExpt();
is_local = 1; % 1 = Momchil's dropbox; 0 = NCF
n_trials_per_run = 24;
sss = getGoodSubjects();
%mask = 'hippocampus.nii';


% which betas to get for each run -- see SPM.xX.name' in any one of the subjects model
% directories
%
betas = [];
%bla = [1 0 0; 0 1 0; 0 0 1];
for run = 1:9
    idx = trials + (run - 1) * (n_trials_per_run + 6);
    betas(run,:) = idx;
end


load_data;
[subjects, ~, ~] = contextGetSubjectsDirsAndRuns();
assert(isequal(subjects',unique(participant)));


idx = 0;
beta_vecs = {};
beta_runs = {};
beta_subjs = sss;
for subj = sss
    beta_vecs{subj} = [];
    beta_runs{subj} = [];
    
    modeldir = fullfile(EXPT.modeldir,['model',num2str(model)],['subj',num2str(subj)]);
    load(fullfile(modeldir,'SPM.mat'));
    
    irr_runs = unique(roundId(strcmp(participant, subjects{subj}) & strcmp(contextRole, 'irrelevant')));
    mod_runs = unique(roundId(strcmp(participant, subjects{subj}) & strcmp(contextRole, 'modulatory')));
    add_runs = unique(roundId(strcmp(participant, subjects{subj}) & strcmp(contextRole, 'additive')));
    
    runs = [irr_runs; mod_runs; add_runs]';
    assert(length(runs) == 9);
    assert(length(unique(runs)) == 9);
    
    fprintf('--------- Subject %s ------------\n', subjects{subj});
   
    for run = runs
        trial_idx = 0;
        for i = betas(run,:)
            disp(SPM.xX.name{i});
            trial_idx = trial_idx + 1;
            
            beta_vec = ccnl_get_beta(EXPT, model, i, mask, [subj]);
            beta_vec(isnan(beta_vec)) = 0;
            
            idx = idx + 1;
            beta_vecs{subj} = [beta_vecs{subj}; beta_vec];
            beta_runs{subj} = [beta_runs{subj}; run];
        end

    end
end

m = regexp(mask,'\.','split');
save(['rsa_beta_vecs_', m{1}, '.mat'], '-v7.3');
