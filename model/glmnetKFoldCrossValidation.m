function [mse_means, mse_sems] = glmnetKFoldCrossValidation(x, y, fitObj, K)
    % perform k-fold cross validation with a model trained to predict y
    % from x.
    % x = independent variables
    % y = dependent / response / random variables
    % fitObj = result from glmnet(x, y)
    % K = k in k-fold cross validation, e.g. 10
    %
    % returns 1 MSE for each lambda, averaged over the K partitions

    % make sure we use the same lambdas for cross-validation
    %
    options = glmnetSet;
    options.nlambda = numel(fitObj.lambda);
    options.lambda = fitObj.lambda;
    
    bucket = crossvalind('Kfold', size(x, 1), K); % partition observations
    mses = [];
    for i = 1:K
        x_train = x(bucket ~= i, :);
        y_train = y(bucket ~= i, :);
        x_test = x(bucket == i, :);
        y_test = y(bucket == i, :);
        kfit = glmnet(x_train, y_train, [], options);
        assert(immse(fitObj.lambda, kfit.lambda) < 1e-9); % should be the same lambdas
        y_pred = glmnetPredict(kfit, x_test, fitObj.lambda); % == glmnetPredict(fitObj, x_test);
        % get mean squared error (predicted vs. actual) for each lambda
        % 
        mse = mean((y_pred - repmat(y_test, [1 size(y_pred, 2)])) .^ 2, 1);
        mses = [mses; mse];
    end
    % average the MSEs
    %
    mse_means = mean(mses, 1);
    mse_sems = std(mses, 1) / sqrt(size(mses, 1));
end
