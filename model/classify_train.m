function [classifier] = classify_train(method, trials, runs, sss, mask, predict_what, preload_betas)
% Train classifier to predict stuff based on neural activity at trial onset
% returns a fitObj that you can pass to glmnetPredict
% or a petternnet net that you can use e.g. like net(inputs)
% for params descriptions, see classify_get_inputs_and_targets
%
% method = 'glmnet' or 'patternnet'

rng('shuffle');

fprintf('classify_train\n');
disp(method);

[inputs, targets] = classify_get_inputs_and_targets(trials, runs, sss, mask, predict_what, preload_betas);

outFilename = ['classify_train_', random_string()];

disp('training classifier...');

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

    accuracy = classify_get_accuracy(outputs, targets);
    fprintf('Success rate = %.2f%%\n', accuracy);    
    
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
    
    %save('classify_glmnet_fitObj_only_1-19_mask_scramble_runs.mat', 'fitObj', 'random_run_labels');
    
    %[mses, msesems] = glmnetKFoldCrossValidation(inputs, targets, fitObj, 'multinomial', 'response', 4);
    %[~, lambda_idx] = min(mses); % pick lambda with smallest MSE
    %lambda = fitObj.lambda(lambda_idx);
    
    %save('classify_glmnet_fitObj_only.mat', 'fitObj', 'mses', 'msesems', 'lambda');
    %save('classify_glmnet_w000t.mat', '-v7.3');
    
    outputss = glmnetPredict(fitObj, inputs, fitObj.lambda, 'response');
    
    for l = 1:size(outputss, 3) % for all lambdas
        outputs = outputss(:,:,l);
        accuracy = classify_get_accuracy(outputs, targets);
        fprintf('Success rate for %d (lambda = %.4f) = %.2f%%\n', l, fitObj.lambda(l), accuracy);
    end
    
    fprintf('SAVING fitObj to %s\n', outFilename);
    save(outFilename, 'fitObj', 'outputss', 'targets');

    classifier = fitObj;
    
else
    assert(false); % no other methods supported
end


