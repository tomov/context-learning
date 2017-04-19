% simple scripts that emulates SPM's GLM
% generates synthetic data, then fits it using different design matrices
% goal is to see what happens if we split the same data across different
% "sessions" a-la the different fMRI sessions
% and see how well we can do "contrasts" across the sessions
%

clear all;
rng default;
sem = @(x) std(x)  / sqrt(length(x));

%% generate some random data that is definitely not linear
%

T = 900 / 10; % # data points ~= # TRs
scale = 1;
beta_0 = 16;
beta_1 = 10;
x = rand(T, 1) * scale;
y = (x * 0.5 + cos(x * 8)) * beta_1 + beta_0 + rand(T, 1) * 40; % rand(T, 1) * 30;  % normrnd(0, 15, T, 1);


%% design matrices
%

% model 1: one "session"
% x0 = constant
% x1 = regressor
design_matrix{1} = @(x) [ones(length(x),1) * scale, x];

% model 2: two "sessions" a-la SPM
% x0 = constant for Sn(1)
% x1 = constant for Sn(2)
% x2 = regressor for Sn(1)
% x3 = regressor for Sn(2)
design_matrix{2} = @(x) design_matrix_spm(x, 2);
                     
% model 3: two "sessions" but shared regressor (slope)                     
design_matrix{3} = @(x) design_matrix_shared_slope(x, 2);
                     
% model 4: SPM-style design matrix w/ 9 sessions                     
design_matrix{4} = @(x) design_matrix_spm(x, 9);
                     
% model 5: 9 "sessions" but shared regressor (slope)                     
design_matrix{5} = @(x) design_matrix_shared_slope(x, 9);


M = length(design_matrix); % # models

%% fit & plot the data
%

figure;
for m = 1:M
    X{m} = design_matrix{m}(x);
    x1 = [0:0.001:max(x)]';
    if mod(length(x1),2) ~= 0
        x1 = x1(1:end-1); % must be even length
    end
    x_pred{m} = design_matrix{m}(x1);
    
    [b{m}, dev{m}, stats{m}] = glmfit(X{m}, y, 'normal', 'constant', 'off');
    y_pred{m} = glmval(b{m}, x_pred{m}, 'identity', 'constant', 'off');

    subplot(3, M, m);
    imagesc(X{m});
    if m == M
        colorbar;
    end
    title(['model ', num2str(m)]);
    
    subplot(3, M, m + M);
    scatter(x, y);
    hold on;
    plot(x1, y_pred{m}, 'LineWidth', 2);
    hold off;
    xlabel('x (predictor)');
    ylabel('y (activation)');

    subplot(3, M, m + 2*M);
    barweb(stats{m}.beta, stats{m}.se);
    leg = {};
    tit = '';
    for i = 1:size(b{m})
        leg = [leg, {['\beta_{', num2str(i-1), '}']}];
        %tit = [tit, ' p_', num2str(i-1), '=', num2str(stats{m}.p(i))];
    end
    ylim([min(stats{m}.beta - stats{m}.se), max(stats{m}.beta + stats{m}.se)]);
    legend(leg);
    %title(tit);
end

%% compare the slopes from the different models
% see how different their statistics are
%

% sanity check to make sure we're claculating t-stats & p-values correctly
t1_sanity = (stats{1}.beta(2) - 0) / stats{1}.se(2);
assert(abs(t1_sanity - stats{1}.t(2)) < 1e-13);
p1_sanity = 2 * (1 - tcdf(stats{1}.t(2), length(x) - 2));
assert(abs(p1_sanity - stats{1}.p(2)) < 1e-13);

% create contrasts that aggregate the beta values
% similarly to how we would aggregate them with SPM
%
con{2} = [0 0 1 1];
con{4} = [0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1];
for m = [2 4]
    b_cum{m} = con{m} * stats{m}.beta / sum(con{m}); % actually average them
    se_cum{m} = sqrt(con{m} * (stats{m}.se.^2)) / sum(con{m});
    t_cum{m} = (b_cum{m} - 0) / se_cum{m}; % H0: beta = 0
    p_cum{m} = 2 * (1 - tcdf(t_cum{m}, length(x) - 2));
end

fprintf('t-stat of beta1 of model 1                  = %.4f\n', stats{1}.t(2));
fprintf('t-stat of beta2+beta3 from model 2          = %.4f\n', t_cum{2});
fprintf('t-stat of beta2 from model 3                = %.4f\n', stats{3}.t(3));
fprintf('t-stat of beta10 + .. + beta18 from model 4 = %.4f\n', t_cum{4});
fprintf('t-stat of beta10 from model 5               = %.4f\n', stats{5}.t(10));


fprintf('p-value of  beta1 of model 1               = %e\n', stats{1}.p(2));   
fprintf('p-value of  beta2+beta3 from model 2       = %e\n', p_cum{2});
fprintf('p-value of  beta2 from model 3             = %e\n', stats{3}.p(3));
fprintf('p-value of  beta10+...+beta18 from model 4 = %e\n', p_cum{4});
fprintf('p-value of  beta10 from model 5            = %e\n', stats{5}.p(10));

figure;
title('slopes & CIs from the different design matrices');
barweb([stats{1}.beta(2), b_cum{2}, stats{3}.beta(3), b_cum{4}, stats{5}.beta(10)], ...
       [stats{1}.se(2), se_cum{2}, stats{3}.se(3), se_cum{4}, stats{5}.se(10)]);
legend({'slope for model 1 (\beta_1)', ...
        'avg slope for model 2 (\beta_2 & \beta_3)', ...
        'slope for model 3 (\beta_2)', ...
        'avg slope for model 4 (\beta_{10}..\beta_{18})', ...
        'slope for model 5 (\beta_{10})'});



% split regressors into a design matrix with a given # of sessions
% but with a shared slope (i.e. only the y-intercepts vary)
%
function X = design_matrix_shared_slope(x, sessions)
    X = zeros(length(x), sessions + 1);
    interval = floor(length(x) / sessions);
    
    for session = 1:sessions
        r = (session - 1) * interval + 1 : session * interval;
        if session == sessions
            r = r(1) : length(x);
        end
        X(r, session) = 1;
    end
    X(:, sessions + 1) = x;
end

% split regressors into a design matrix with a given # of sessions
%
function X = design_matrix_spm(x, sessions)
    X = zeros(length(x), sessions * 2);
    interval = floor(length(x) / sessions);
    
    for session = 1:sessions
        r = (session - 1) * interval + 1 : session * interval;
        if session == sessions
            r = r(1) : length(x);
        end
        X(r, session) = 1;
        X(r, session + sessions) = x(r);
    end
end
