

%{
context_create_multi(1, 2, 2); % <-- 1 = additive , 2 = modulatory, 3 = irrelevant
load('context_create_multi.mat')
condition

strcmp(response.keys(strcmp(contextRole, 'modulatory') & contextId == 0 & cueId == 2) , 'left')

sum(strcmp(response.keys(strcmp(contextRole, 'modulatory') & contextId == 0 & cueId == 2) , 'left')) / 73
%}


%{
figure;
which = which_rows & isTrain;
scatter(surprise(which), response.rt(which));
%}


%
%  sanity check that it's the right pixels
%
%{
EXPT = contextExpt();
modeldir = EXPT.modeldir;
%V = spm_vol(fullfile(modeldir, ['model59'], ['subj1'], sprintf('beta_%04d.nii',1)));
%V = spm_vol(fullfile(modeldir, ['model53'], ['con1'], sprintf('con_%04d.nii',1)));
V = spm_vol(fullfile(modeldir, ['model53'], ['con1'], 'spmT_0001.nii'));
Y = spm_read_vols(V);
cor = mni2cor([34 -64 48],V.mat)
Y(cor(1), cor(2), cor(3))
%}


%{
clear P;
P{1} = fullfile(modeldir, ['model53'], ['con1'], sprintf('beta_%04d.nii',1));
P{2} = fullfile(modeldir, ['model53'], ['con1'], 'spmT_0001.nii');
spm_check_registration(char(P));
%}


% ccnl_view(contextExpt(), 53, 'surprise');

%
% betas diverging between 54 and 60, esp towards test
%

%{
EXPT = contextExpt();
mask = 'mask.nii';
for x = 1:20
    beta_vec54 = ccnl_get_beta(EXPT, 54, x + 2 * (20 + 6), mask, 1);
    beta_vec60 = ccnl_get_beta(EXPT, 60, x + 2 * (24 + 6), mask, 1);
    immse(beta_vec54, beta_vec60)
end
%}

