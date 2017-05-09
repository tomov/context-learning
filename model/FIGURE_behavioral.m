%
% Figure summarizing the behavioral results + the model
% run after analyze.m (make sure to only run using the used subjects --
% getGoodSubjects()
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
    
subplot(1, 2, 1);
barweb(Ms, SEMs, 1, contextRoles, 'Subject test choices');
ylabel('Choice probability');
legend1 = legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});

%set(legend1,...
%    'Position',[0.327511990473767 0.727042979130365 0.0631253279563593 0.269642857142857]);


%
% Choice probabilities in test phase for MODEL (based on the actual
% decisions the model made)
% This is the final figure we care about
%

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
    
subplot(1, 2, 2);
next_subplot_idx = next_subplot_idx + 1;
barweb(Ms, SEMs, 1, contextRoles, 'Model test choices');

yticklabels({});
%ylabel('Choice probability');
%legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'});



