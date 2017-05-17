%representational_similarity_part2('visual.nii', 'correlation');
%representational_similarity_part2('motor.nii', 'correlation');
%representational_similarity_part2('sensory.nii', 'correlation');

%{
contrasts = {'M2_value', 'M1_value', 'M2_value - M1_value', ...
     'M2_update', 'M1_update', 'M2_update - M1_update', ...
     'irrelevantxM2_value', 'irrelevantxM1_value', 'irrelevantxM2_value - irrelevantxM1_value', ...
     'irrelevantxM2_update', 'irrelevantxM1_update', 'irrelevantM2_update - irrelevantM1_update', ...
     'modulatoryxM2_value', 'modulatoryxM1_value', 'modulatoryxM2_value - modulatoryxM1_value', ...
     'modulatoryxM2_update', 'modulatoryxM1_update', 'modulatoryM2_update - modulatoryM1_update', ...
     'additivexM2_value', 'additivexM1_value', 'additivexM2_value - additivexM1_value', ...
     'additivexM2_update', 'additivexM1_update', 'additiveM2_update - additiveM1_update', ...
     'modulatory - irrelevant', 'modulatory - additive', 'additive - irrelevant'};
convec = zeros(size(SPM.xX.name));
C = [1 -1];
for j = 1:length(contrasts)
    con = regexp(contrasts{j},'-','split');
    for c = 1:length(con)
        con{c} = strtrim(con{c});
        for i = 1:length(SPM.xX.name)
            if ~isempty(strfind(SPM.xX.name{i},[con{c},'*'])) || ~isempty(strfind(SPM.xX.name{i},[con{c},'^']))
                convec(j,i) = C(c);
            end
        end        
    end
end
%}



%{
l = 0;
for i=1:1000
    x = rand(1, 100) > 0.5;
    y = x(1:end-1) + x(2:end) * 10;
    f = 1 + find(y == 11);
    l = l + f(1);
end
disp(l / 1000);
%}

%{
    % lame
    for i = 1:size(beta_vecs,1)
        for j = 1:size(beta_vecs,1)
            dist = sum((beta_vecs(i,:) - beta_vecs(j,:)).^2);
            rdm(i, j) = dist;
        end    
    end
%}


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

