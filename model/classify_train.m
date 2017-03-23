function classify_train(method, trials, sss, mask, outFilename)
% Train classifier to predict condition based on neural activity at trial onset
%

% trials = which training trials to use to train from each run, e.g. 1:19 or 1:20
% sss = subject indices in the subjects array returned by
%       contextGetSubjectsDirsAndRuns, e.g. getGoodSubjects()
% mask = .nii file name of which mask to use
% method = 'glmnet' or 'patternnet'
% outFilename = .mat file name where to save the results

model = 54; % the model with the classifier for training trials betas
EXPT = contextExpt();
is_local = 1; % 1 = Momchil's dropbox; 0 = NCF
n_trials_per_run = 20;
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
for run = 1:9
    idx = trials + (run - 1) * (n_trials_per_run + 6);
    betas = [betas; idx];
end

% Get the input vector and labels from the betas
% goal is to infer the targets from the inputs
% assumption is that the targets underlie the inputs
%
labels = containers.Map({'irrelevant', 'modulatory', 'additive'}, ...
                        {[1 0 0], [0 1 0], [0 0 1]});

inputs = []; % rows = x = observations, cols = voxels / dependent vars
targets = zeros(numel(sss) * numel(betas), 3); % rows = y = observations, cols = indep vars (condition as binary vector)
idx = 0;
%random_run_labels = [];
for subj = sss
    modeldir = fullfile(EXPT.modeldir,['model',num2str(model)],['subj',num2str(subj)]);
   
    for run = 1:9
        multi = context_create_multi(1, subj, run);
        condition = multi.names{1};
    
        %random_run_label = bla(randi(3,1),:);
        %random_run_labels = [random_run_labels; random_run_label];
        %remove_me = 0;
        for i = betas(run,:)
            %remove_me = remove_me + 1;
            beta_vec = ccnl_get_beta(EXPT, model, i, mask, [subj]);
            beta_vec(isnan(beta_vec)) = 0;
            
            if numel(inputs) == 0
                inputs = zeros(numel(sss) * numel(betas), numel(beta_vec));
            end
            idx = idx + 1;
            inputs(idx,:) = beta_vec;
            targets(idx,:) = labels(condition);
            
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
    save(outFilename, 'net');

    [~, i] = max(targets, [], 1);
    [~, j] = max(outputs, [], 1);
    fprintf('Success rate = %.2f%%\n', 100 * mean(i == j));    
    
    % TODO these break for some reason...
    %
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
    
elseif strcmp(method, 'glmnet')
    
    % x = inputs
    % y = targets
    %
    fitObj = glmnet(inputs, targets, 'multinomial');
    glmnetPrint(fitObj);
    
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

else
    assert(false); % no other methods supported
end


