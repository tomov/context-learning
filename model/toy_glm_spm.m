clear all;
rng default;

% generative
%
T = 900; % # data points
scale = 1;
beta_0 = 16;
beta_1 = 10;
x = rand(T, 1) * scale;
y = cos(x * 8) * beta_1 + beta_0 + rand(T, 1) * 30;  % normrnd(0, 10, T, 1);

% model 1: one "sessions"
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
design_matrix{3} = @(x) [[ones(round(length(x)/2),1); zeros(round(length(x)/2),1)], ...
                         [zeros(round(length(x)/2),1); ones(round(length(x)/2),1)], ...
                         x];
                     
% model 4: SPM-style design matrix w/ 9 sessions                     
design_matrix{4} = @(x) design_matrix_spm(x, 9);
                     
M = length(design_matrix); % # models

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
    plot(x1, y_pred{m});
    hold off;

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

% compare b1 from the first model with b2+b3 from the second model
% they should have the same statistics
%
p1_sanity = 2 * (1 - tcdf(stats{1}.t(2), length(x) - 2));
assert(abs(p1_sanity - stats{1}.p(2)) < 1e-13);

con{2} = [0 0 1 1];
con{4} = [0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1];
for m = [2 4]
    b_cum{m} = con{m} * stats{m}.beta;
    se_cum{m} = sqrt(con{m} * (stats{m}.se.^2));
    t_cum{m} = (b_cum{m} - 0) / se_cum{m};
    p_cum{m} = 2 * (1 - tcdf(t_cum{m}, 2));
end

fprintf('t-stat of beta1 of model 1 = %.4f\n   vs. beta2+beta3 from model 2 = %.4f\n   vs. beta2 from model 3 = %.4f\n   vs. beta10 + .. + beta18 from model 4 = %.4f\n', ...
        stats{1}.t(2), t_cum{2}, stats{3}.t(3), t_cum{4});

fprintf('p-value of beta1 of model 1 = %e\n   vs. beta2+beta3 from model 2 = %e\n   vs. beta2 from model 3 = %e\n   vs. beta10+...+beta18 from model 4 = %e\n', ...
        stats{1}.p(2), p_cum{2}, stats{3}.p(3), p_cum{4});

figure;
% calculate the t-statistic with the actual sample size n & total beta
% but plot beta / 2 & the error bar for beta / 2, for comparison with the others
%
barweb([stats{1}.beta(2), b_cum{2} / sum(con{2}), stats{3}.beta(3), b_cum{4} / sum(con{4})], ...
       [stats{1}.se(2), se_cum{2} / sqrt(sum(con{2})), stats{3}.se(3), se_cum{4} / sqrt(sum(con{4}))]);
legend({'slope for model 1', 'avg slope for model 2', 'slope for model 3', 'avg slope for model 4'});

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
