% Similar to glmnet_examples but with a multinomial
%

clear all;

% some multinomial datas
%
x = rand(100,10);
p = [x(:,1) * 3, x(:,2) * 10 + 2, x(:,5)];
p = p ./ sum(p, 2);
y = mnrnd(1, p);

% Fit 'em
%
fitObj = glmnet(x, y, 'multinomial');
%glmnetPrint(fitObj);

% find best lambda
%
[mses, msesems] = glmnetKFoldCrossValidation(x, y, fitObj, 'multinomial', 'response', 10);
[~, lambda_idx] = min(mses); % pick lambda with smallest MSE
lambda = fitObj.lambda(lambda_idx);

% Make some predictions
x_new = rand(100,10);
p_new = [x_new(:,1) * 3, x_new(:,2) * 10 + 2, x_new(:,5)];
p_new = p_new ./ sum(p_new, 2);
y_new = mnrnd(1, p_new);

y_pred_glmnet = glmnetPredict(fitObj, x_new, lambda, 'response');

% so y_pred_glmnet is a distribution -- but we only want to make a single
% prediction for each y
% so we treat this as p in the data generation code above (see top of file)
% and generate random variables according to it, and compare that with y
% TODO is this legit?
%
y_guesses = mnrnd(1, y_pred_glmnet);

correct = sum(y_guesses == y, 2) == 3;

fprintf('On average, %.2f%% correct\n', mean(correct * 100));