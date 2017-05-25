

%% within-subject variability for presentation
%

load('kl_analysis.mat'); % as output by kl_structure_learning.m

r_means = [];
r_sems = [];

% for group-level analysis
all_rs = nan(size(kl_betas, 3), n_subjects); % for each voxel, a list of correlation coefficients for each subject (for group-level stats)

% for Figure 4B
slopes = nan(size(kl_betas, 3), n_subjects); % for each voxel, a list of slopes for least squares line (lsline) each subject (= correlation coefficient * SD(Y) / SD(X) -- see https://stats.stackexchange.com/questions/32464/how-does-the-correlation-coefficient-differ-from-regression-slope)
intercepts = nan(size(kl_betas, 3), n_subjects); % same but intercept
std_x = nan(size(kl_betas, 3), n_subjects); % for each voxel for each subject, SD(X), X = structure learning effect or test choice likelihoods or whatever we're correlating with
std_y = nan(size(kl_betas, 3), n_subjects); % for each voxel for each subject, SD(Y), Y = KL betas

figure;


for roi = 1:size(kl_betas, 3)
    kl_betas_roi = kl_betas(:, :, roi);
    rs = [];
    for subj_idx = 1:n_subjects
        %x = structure_learnings(:, subj_idx);   <-- not good with timeouts
        x = test_liks(:, subj_idx);        
        y = kl_betas_roi(:, subj_idx);
        
        % z-score for Figure 4B        
        x = zscore(x);
        y = zscore(y);
        
        r = corrcoef(x, y);
        r = r(1,2);
        % fprintf('       subj = %d, r = %f, p = %f\n', roi, r(1,2), p(1,2));
        rs = [rs, r];
        all_rs(roi, subj_idx) = r;
        
        % plot stuff
        if roi == 1
            % for Figure 4B
            fit = polyfit(x, y, 1);
            slopes(roi, subj_idx) = fit(1);
            intercepts(roi, subj_idx) = fit(2);
            std_x(roi, subj_idx) = std(x);
            std_y(roi, subj_idx) = std(y);
            yfit = polyval(fit, x);
            
            % plot KL beta correlations for each ROI
            subplot(4, n_subjects / 4, subj_idx);
            scatter(x, y);
            
            hold on;
            %lsline;
            plot(x, yfit, 'Color', 'black', 'LineWidth', 2);
            hold off;
            
            set(gca, 'XTick', []);
            set(gca, 'YTick', []);
            xlabel(['Subj ', num2str(subj_idx)]);
            if roi == 1 && subj_idx == 3
                title('Test choices log likelihood (x-axis) vs. AG KL betas (y-axis):  within-subject analysis');
            end
            %}
        end
    end
    % average correlation across subjects
    if roi < numel(rois)
        fprintf(' within-subject: ROI = %25s, avg r = %f\n', rois{roi}, mean(rs));
    end
    
    r_means = [r_means; mean(rs) 0];
    r_sems = [r_sems; sem(rs) 0];
end



%% for presentation -- true choice probs for model
%

%
% TRUE Choice probabilities in test phase for MODEL
%

figure;

Ms = [];
SEMs = [];
for context = contextRoles
    which = which_rows & isTrain == 0 & strcmp(contextRole, context);
    
    x1c1 = model.pred(which & cueId == 0 & contextId == 0);
    x1c2 = model.pred(which & cueId == 0 & contextId == 2);
    x2c1 = model.pred(which & cueId == 2 & contextId == 0);
    x2c2 = model.pred(which & cueId == 2 & contextId == 2);

    %M = mean([x1c1 x1c2 x2c1 x2c2]);
    %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    M = get_means(x1c1, x1c2, x2c1, x2c2);
    SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end
    
barweb(Ms, SEMs, 1, contextRoles, 'Model');
ylabel('True choice probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});


%% for presentation -- choice probs for model
%

%
% Choice probabilities in test phase for MODEL (based on the actual
% decisions the model made)
% This is the final figure we care about
%

figure;

Ms = [];
SEMs = [];
for context = contextRoles
    which = which_rows & isTrain == 0 & strcmp(contextRole, context);
    
    
    x1c1 = strcmp(model.keys(which & cueId == 0 & contextId == 0), 'left');
    x1c2 = strcmp(model.keys(which & cueId == 0 & contextId == 2), 'left');
    x2c1 = strcmp(model.keys(which & cueId == 2 & contextId == 0), 'left');
    x2c2 = strcmp(model.keys(which & cueId == 2 & contextId == 2), 'left');
    
    %M = mean([x1c1 x1c2 x2c1 x2c2]);
    %SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    M = get_means(x1c1, x1c2, x2c1, x2c2);
    SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end

barweb(Ms, SEMs, 1, contextRoles, 'Model');
ylabel('Choice probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});


%% for presentation -- choice probs for subjects
%

%
% Choice probabilities in test phase for SUBJECTS
% This is the final figure we care about
%

figure;
Ms = [];
SEMs = [];
for context = contextRoles
    which = which_rows & isTrain == 0 & strcmp(contextRole, context);
    
    x1c1 = strcmp(response.keys(which & cueId == 0 & contextId == 0), 'left');
    x1c2 = strcmp(response.keys(which & cueId == 0 & contextId == 2), 'left');
    x2c1 = strcmp(response.keys(which & cueId == 2 & contextId == 0), 'left');
    x2c2 = strcmp(response.keys(which & cueId == 2 & contextId == 2), 'left');

%    M = mean([x1c1 x1c2 x2c1 x2c2]);
%    SEM = std([x1c1 x1c2 x2c1 x2c2]) / sqrt(length(x1c1));
    M = get_means(x1c1, x1c2, x2c1, x2c2);
    SEM = get_sems(x1c1, x1c2, x2c1, x2c2);
    Ms = [Ms; M];
    SEMs = [SEMs; SEM];
end
    
barweb(Ms, SEMs, 1, contextRoles, 'Human subjects');
ylabel('Choice probability');
legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});





%% for presentation -- softmax
%
figure;
predict = @(V_n, inv_softmax_temp) 1 ./ (1 + exp(-2 * inv_softmax_temp * V_n + inv_softmax_temp));

plot(x, predict(x, 1), 'LineWidth', 2);
hold on;
plot(x, predict(x, 2), 'LineWidth', 2);
plot(x, predict(x, 10), 'LineWidth', 2);
plot(x, predict(x, 0.1), 'LineWidth', 2);
hold off;
xlabel('V_n');
ylabel('P(a_n = 1)');
legend({'inv temp = 1', 'inv temp = 2', 'inv temp = 10', 'inv temp = 0.1'})

%--Distributions contain more information than boxplot can capture
%{
r = rand(1000,1);
rn = randn(1000,1)*0.38+0.5;
rn2 = [randn(500,1)*0.1+0.27;randn(500,1)*0.1+0.73];
rn2=min(rn2,1);rn2=max(rn2,0);
figure
ah(1)=subplot(3,4,1:2);
boxplot([r,rn,rn2])
ah(2)=subplot(3,4,3:4);
distributionPlot([r,rn,rn2],'histOpt',2); % histOpt=2 works better for uniform distributions than the default
set(ah,'ylim',[-1 2])
%}

%representational_similarity_part2('visual.nii', 'euclidean');
%representational_similarity_part2('motor.nii', 'euclidean');
%representational_similarity_part2('sensory.nii', 'euclidean');

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

