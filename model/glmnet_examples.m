% Generalized linear model comparsion
% (not to be confused with general linear model -- https://en.wikipedia.org/wiki/Comparison_of_general_and_generalized_linear_models
%
% Specifically, compare MATLAB's lassoglm vs. glmnet from the web --> http://web.stanford.edu/~hastie/glmnet_matlab/
% Mostly as a sanity check
%

clear all;

% generate some data
% x = the observations, or dependent variables
% y = the independent variables we are trying to infer/predict from x
%
x = randn(100,20);
mu = exp(x(:,[5 10 15])*[.4;.2;.3] + 1);
y = poissrnd(mu);


% fit using MATLAB generalized linear model lasso thing
% https://www.mathworks.com/help/stats/lassoglm.html
%
[B, FitInfo] = lassoglm(x,y,'poisson','CV',10);
lassoPlot(B,FitInfo,'plottype','CV');

% fit using the third party lib glmnet
% http://web.stanford.edu/~hastie/glmnet_matlab/
% 
%
fitObj = glmnet(x, y, 'poisson');
glmnetPrint(fitObj);

% plot the cross-validation (mimics lassoPlot) 
% family-type pairs:
% 'poisson', 'response'
% 'normal', 'link'
%
[mses, msesems] = glmnetKFoldCrossValidation(x, y, fitObj, 'poisson', 'response', 10);

figure;
errorbar(fitObj.lambda, mses, msesems, 'o-');
set(gca,'XScale','log', 'XDir', 'reverse'); % set the X axis in reversed log scale.
xlabel('Lambda');
ylabel('MSE');
title('Cross-validated mean squared error');

[~, lambda_idx] = min(mses); % pick lambda with smallest MSE
lambda = fitObj.lambda(lambda_idx);
hold on;
plot(lambda, mses(lambda_idx), 'or', 'MarkerSize', 5, 'LineWidth', 2);

yL = get(gca,'YLim');
line([lambda lambda], yL, 'LineStyle', '--', 'Color', [0.3 0.3 0.3]);
hold off;

% the betas
%
disp(fitObj.beta(:, lambda_idx));

% do some predicting with new data
%

x_new = randn(100,20);
mu_new = exp(x_new(:,[5 10 15])*[.4;.2;.3] + 1);
y_new = poissrnd(mu_new);

% predict with the lasso
% https://www.mathworks.com/help/stats/regularize-logistic-regression.html
%
indx = FitInfo.IndexMinDeviance; % alternatively use Index1SE
B0 = B(:,indx);
cnst = FitInfo.Intercept(indx);
B1 = [cnst;B0];
y_pred_matlab = glmval(B1,x_new,'log'); % link function for poisson is log -- https://www.mathworks.com/help/stats/glmfit.html

figure;
scatter(y_new, y_pred_matlab);
xlabel('True y');
ylabel('Predicted y');
title('Predictions by glmval (MATLAB)');

% predict with glmnet
%
y_pred_glmnet = glmnetPredict(fitObj, x_new, lambda, 'response');

figure;
scatter(y_new, y_pred_glmnet);
xlabel('True y');
ylabel('Predicted y');
title('Predictions by glmnet');


fprintf('Test set performance: MATLAB MSE = %.4f vs. glmnet MSE = %.4f\n', immse(y_new, y_pred_matlab), immse(y_new, y_pred_glmnet));
