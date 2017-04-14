function [classifier] = classify_train(method, trials, runs, sss, mask, predict_what)
% Train classifier to predict stuff based on neural activity at trial onset
% returns a fitObj that you can pass to glmnetPredict
% or a petternnet net that you can use e.g. like net(inputs)
%

fprintf('classify_train\n');
disp(method)
disp(trials)
disp(runs)
disp(mask)
disp(sss)

outFilename = random_string();


% method = 'glmnet' or 'patternnet'
% trials = which trials to use to train from each run e.g. 1:19 or 1:24
% runs = which runs to use, e.g. 1:9 or 1:8
% sss = subject indices in the subjects array returned by
%       contextGetSubjectsDirsAndRuns, e.g. getGoodSubjects()
% mask = .nii file name of which mask to use
% predict_what = 'condition' or 'responses'

model = 60; % the model with the classifier for all trials betas
EXPT = contextExpt();
is_local = 1; % 1 = Momchil's dropbox; 0 = NCF
n_trials_per_run = 24;
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
    idx = trials + (run - 1) * (n_trials_per_run + 6);
    betas(run,:) = idx;
end

load_data;
[subjects, ~, ~] = contextGetSubjectsDirsAndRuns();
assert(isequal(subjects',unique(participant)));


% Get the input vector and labels from the betas
% goal is to infer the targets from the inputs
% assumption is that the targets underlie the inputs
%
labels = containers.Map({'irrelevant', 'modulatory', 'additive'}, ...
                        {[1 0 0], [0 1 0], [0 0 1]});

inputs = []; % rows = x = observations, cols = voxels / dependent vars
targets = []; % rows = y = observations, cols = indep vars (condition as binary vector)
idx = 0;
%random_run_labels = [];
for subj = sss
    modeldir = fullfile(EXPT.modeldir,['model',num2str(model)],['subj',num2str(subj)]);
   
    for run = runs        
        which_trials = ~drop & isTrain & strcmp(participant, subjects{subj}) & roundId == run & ismember(trialId, trials);
        condition = contextRole(which_trials);
        condition = condition{1};
        responses = response.keys(which_trials);
        assert(length(responses) == length(trials));
        
        % for sanity check
        multi = context_create_multi(1, subj, run);
        condition_sanity = multi.names{1};
        assert(strcmp(condition, condition_sanity));
    
        %random_run_label = bla(randi(3,1),:);
        %random_run_labels = [random_run_labels; random_run_label];
        %remove_me = 0;
        trial_idx = 0;
        for i = betas(run,:)
            trial_idx = trial_idx + 1;
            
            %remove_me = remove_me + 1;
            beta_vec = ccnl_get_beta(EXPT, model, i, mask, [subj]);
            beta_vec(isnan(beta_vec)) = 0;
            
            if strcmp(predict_what, 'condition')
                idx = idx + 1;
                inputs(idx,:) = beta_vec;
                targets(idx,:) = labels(condition);
            elseif strcmp(predict_what, 'responses')
                if strcmp(responses{trial_idx}, 'None')
                else
                    chose_sick = strcmp(responses{trial_idx}, 'left');
                    idx = idx + 1;
                    inputs(idx,:) = beta_vec;
                    targets(idx,:) = chose_sick;
                end
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
    end
end

%assert(size(targets, 1) >= length(sss) * length(runs) * 20 * 0.9);

%
% Fit them
%

if strcmp(method, 'patternnet')
    % patternnet wants column feature vectors. I.e. each data point is a column
    % so we have to rotate it ...
    %
    inputs = inputs'; % ugh MATLAB
    targets = targets';

    % from https://github.com/tomov/food-recognition/blob/master/neural_train.m

    % Create a Pattern Recognition Network
    hiddenLayerSize = 200; % TODO param
    net = patternnet(hiddenLayerSize);

    % Set up Division of Data for Training, Validation, Testing
    net.divideParam.trainRatio = 70/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 15/100;
    if ~is_local
        net.trainParam.showWindow = false; % don't show GUI on NCF
    end

    % Train the Network
    [net,tr] = train(net,inputs,targets);

    % Test the Network
    outputs = net(inputs);
    errors = gsubtract(targets,outputs);
    performance = perform(net,targets,outputs);

    % View the Network
    %view(net)

    % View confusion matrix
    [c,cm,ind,per] = confusion(targets,outputs);
    
    %save('classify_patternnet_w000t.mat', '-v7.3');
    fprintf('SAVING net to %s\n', outFilename);
    save(outFilename, 'net');

    [~, i] = max(targets, [], 1);
    [~, j] = max(outputs, [], 1);
    fprintf('Success rate = %.2f%%\n', 100 * mean(i == j));    
    
    classifier = net;
    
    % TODO these break for some reason...
    %
    %{
    A = cm';
    B = bsxfun(@rdivide,A,sum(A));
    C = imresize(1 - B, 15, 'method', 'box');
    imshow(C);
    xlabel('Targets');
    ylabel('Outputs');


    [b, ib] = sort(diag(B));
    sprintf('%.2f %% bottom 10', mean(b(1:10) * 100))
    sprintf('%.2f %% top 10', mean(b(41:50) * 100))
    sprintf('%.2f %% correct', (1 - c) * 100)
    %}
    
elseif strcmp(method, 'glmnet')
    
    % x = inputs
    % y = targets
    %
    fitObj = glmnet(inputs, targets, 'multinomial');
    glmnetPrint(fitObj);
    
    fprintf('SAVING fitObj to %s\n', outFilename);
    save(outFilename, 'fitObj');
    %save('classify_glmnet_fitObj_only_1-19_mask_scramble_runs.mat', 'fitObj', 'random_run_labels');
    
    %[mses, msesems] = glmnetKFoldCrossValidation(inputs, targets, fitObj, 'multinomial', 'response', 4);
    %[~, lambda_idx] = min(mses); % pick lambda with smallest MSE
    %lambda = fitObj.lambda(lambda_idx);
    
    %save('classify_glmnet_fitObj_only.mat', 'fitObj', 'mses', 'msesems', 'lambda');
    %save('classify_glmnet_w000t.mat', '-v7.3');
    
    outputss = glmnetPredict(fitObj, inputs, fitObj.lambda, 'response');
    
    for l = 1:size(outputss, 3) % for all lambdas
        outputs = outputss(:,:,l);
        [~, i] = max(targets, [], 2);
        [~, j] = max(outputs, [], 2);
        fprintf('Success rate for %d (lambda = %.4f) = %.2f%%\n', l, fitObj.lambda(l), 100 * mean(i == j));
    end

    classifier = fitObj;
    
else
    assert(false); % no other methods supported
end


