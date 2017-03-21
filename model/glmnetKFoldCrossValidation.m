function [mse_means, mse_sems] = glmnetKFoldCrossValidation(x, y, fitObj, family, type, K)
    % perform k-fold cross validation with a model trained to predict y
    % from x.
    % x = independent variables
    % y = dependent / response / random variables
    % fitObj = result from glmnet(x, y)
    % family = distribution, e.g. gaussian, poisson, etc -- 'help glmnet'
    %    this is the distribution of the dependent variables I think
    % type = see type in 'help glmnetPredict'
    %    for family = gaussian, type = link
    %    for family = poisson, type = response
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
        kfit = glmnet(x_train, y_train, family, options);
        assert(immse(fitObj.lambda, kfit.lambda) < 1e-9); % should be the same lambdas
        y_pred = glmnetPredict(kfit, x_test, fitObj.lambda, type); % == glmnetPredict(fitObj, x_test);
        if strcmp(family, 'poisson') || strcmp(family, 'normal')
            % get mean squared error (predicted vs. actual) for each lambda
            % in the case of poisson / gaussian / etc
            % 
            mse = mean((y_pred - repmat(y_test, [1 size(y_pred, 2)])) .^ 2, 1);
        elseif strcmp(family, 'multinomial')
            % this is sort of like a MSE but with a flavor of chi-squared #HACKSAUCE...
            % for each observation, I just sum the squared errors
            % and count this as the "squared error" for the observation
            % then take the mean across all observations (for the given
            % lambda)
            % dimensions = observations x categories x lambda
            %
            y_expected = repmat(y_test, [1 1 size(y_pred, 3)]);
            mse = mean(sum((y_pred - y_expected) .^ 2, 2), 1);
            mse = reshape(mse, [1 size(mse, 3)]); % for consistency
        else
            assert(false); % not supported
        end
        
        mses = [mses; mse]; % add to list of MSEs for the different buckets
    end
    % average the MSEs
    %
    mse_means = mean(mses, 1);
    mse_sems = std(mses, 1) / sqrt(size(mses, 1));
end
