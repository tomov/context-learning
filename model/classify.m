model = 54; % the model with the classifier betas
EXPT = contextExpt();
is_local = 1; % 1 = Momchil's dropbox; 0 = NCF
method = 'glmnet'; % patternnet or glmnet

if is_local
    sss = [1 2];
else
    sss = getGoodSubjects();
end

% which betas to get for each run -- see SPM.xX.name' in any one of the subjects model
% directories
%
betas = [];
for run = 1:9
    idx = [1:20] + (run - 1) * 26;
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
for subj = sss
    modeldir = fullfile(EXPT.modeldir,['model',num2str(model)],['subj',num2str(subj)]);
   
    for run = 1:9
        multi = context_create_multi(1, subj, run);
        condition = multi.names{1};
        for i = betas(run,:)
            beta_file = fullfile(modeldir, ['beta_', sprintf('%04d', i), '.nii'])
            beta_nii = load_untouch_nii(beta_file);
            beta_nii.img(isnan(beta_nii.img)) = 0; % NaNs... TODO
            beta_vec = reshape(beta_nii.img, [1, numel(beta_nii.img)]); % reshape to 1D array. Lame
            %beta_vec = beta_vec(1:20);
            
            if numel(inputs) == 0
                inputs = zeros(numel(sss) * numel(betas), numel(beta_vec));
            end
            idx = idx + 1;
            inputs(idx,:) = beta_vec;
            targets(idx,:) = labels(condition);
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
    
    save('classify_patternnet_w000t.mat', '-v7.3');

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
    
    [mses, msesems] = glmnetKFoldCrossValidation(inputs, targets, fitObj, 'multinomial', 'response', 10);
    [~, lambda_idx] = min(mses); % pick lambda with smallest MSE
    lambda = fitObj.lambda(lambda_idx);
    
    save('classify_glmnet_w000t.mat', '-v7.3');
else
    assert(false); % no other methods supported
end


