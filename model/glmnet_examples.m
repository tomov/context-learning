% glmnet
% fit = glmnet(x, y, family)
%{
 x           Input matrix, of dimension nobs x nvars; each row is an
              observation vector. Can be in sparse matrix format.

y           Response variable. Quantitative (column vector) for family =
              'gaussian', or family = 'poisson'(non-negative counts). For
              family = 'binomial' should be either a column vector with two 
              levels, or a two-column matrix of counts or proportions. For
              family = 'multinomial', can be a column vector of nc>=2
              levels, or a matrix with nc columns of counts or proportions.
              For family = 'cox', y should be a two-column matrix with the
              first column for time and the second for status. The latter
              is a binary variable, with 1 indicating death, and 0
              indicating right censored. For family = 'mgaussian', y is a
              matrix of quantitative responses. 
  family      Reponse type. (See above). Default is 'gaussian'.


glmnetPredict(object, newx, s, type, exact, offset)

pred=glmnetPredict(fit,[],[],'coefficients')

 object      Fitted "glmnet" model object.
  s           Value(s) of the penalty parameter lambda at which predictions
              are required. Default is the entire sequence used to create
              the model.
  newx        Matrix of new values for x at which predictions are to be
              made. Must be a matrix; can be sparse. This argument is not 
              used for type='coefficients' or type='nonzero'.
  type        Type of prediction required. Type 'link' gives the linear
              predictors for 'binomial', 'multinomial', 'poisson' or 'cox'
              models; for 'gaussian' models it gives the fitted values.
              Type 'response' gives the fitted probabilities for 'binomial'
              or 'multinomial', fitted mean for 'poisson' and the fitted
              relative-risk for 'cox'; for 'gaussian' type 'response' is
              equivalent to type 'link'. Type 'coefficients' computes the
              coefficients at the requested values for s. Note that for
              'binomial' models, results are returned only for the class
              corresponding to the second level of the factor response.
              Type 'class' applies only to 'binomial' or 'multinomial'
              models, and produces the class label corresponding to the
              maximum probability. Type 'nonzero' returns a matrix of
              logical values with each column for each value of s, 
              indicating if the corresponding coefficient is nonzero or not.
  exact       If exact=true, and predictions are to made at values of s not
              included in the original fit, these values of s are merged
              with object.lambda, and the model is refit before predictions
              are made. If exact=false (default), then the predict function
              uses linear interpolation to make predictions for values of s
              that do not coincide with those used in the fitting
              algorithm. Note that exact=true is fragile when used inside a
              nested sequence of function calls. glmnetPredict() needs to
              update the model, and expects the data used to create it in
              the parent environment.
  offset      If an offset is used in the fit, then one must be supplied
              for making predictions (except for type='coefficients' or
              type='nonzero')

%}  
  

%{
% Gaussian
     x=randn(100,20);
     y=randn(100,1);
     fit1 = glmnet(x,y);
     glmnetPrint(fit1);
     glmnetPredict(fit1,[],0.01,'coef')  %extract coefficients at a single value of lambda
     glmnetPredict(fit1,x(1:10,:),[0.01,0.005]')  %make predictions
     
% Multinomial:
 g4=randsample(4,100,true);
 fit3=glmnet(x,g4,'multinomial');
 opts=struct('mtype','grouped');
 fit3a=glmnet(x,g4,'multinomial',opts);
%}



% This POTENTIALLY does the same things as
% https://www.mathworks.com/help/stats/lassoglm.html#inputarg_Lambda
% 
% rng default % For reproducibility
% X = randn(100,20);
% mu = exp(X(:,[5 10 15])*[.4;.2;.3] + 1);
% y = poissrnd(mu);
% [B, FitInfo] = lassoglm(X,y,'poisson','CV',10);
% lassoPlot(B,FitInfo,'plottype','CV');
%
% except glmnet supports multinomials

x = rand(100, 10);
y = x(:,[1 2 6]) * [100 10 1]' + 23 + randn([size(x, 1) 1]) * 10; % no noise TODO add noise
fitObj = glmnet(x, y);
glmnetPrint(fitObj);


[mses, msesems] = glmnetKFoldCrossValidation(x, y, fitObj, 10);

errorbar(fitObj.lambda, mses, msesems, 'o-');
set(gca,'XScale','log', 'XDir', 'reverse'); % set the X axis in reversed log scale.
xlabel('Lambda');
ylabel('MSE');
title('Cross-validated mean squared error');
%errorbarlogx();

% scatter(x(:,1), y);

%xnew = rand(20, 10);

%ynew = pred(:,1);

