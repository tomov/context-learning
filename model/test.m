function [choices] = test(x, c, P_n, ww_n)

% constants
%
N = size(x, 1); % # of trials
D = size(x, 2); % # of stimuli
K = 3;          % # of contexts

% predict
predict = @(V_n) 1 ./ (1 + exp(-6 * V_n + 3)); % predicts by mapping the expectation to an outcome

value = @(x_n, xx_n, k) (x_n' * ww_n{1}) * P_n(1) + ... % M1 
                        (x_n' * ww_n{2}(:, k)) * P_n(2) + ... % M2
                        (xx_n' * ww_n{3}) * P_n(3); % M3

choices = [];
                    
for n = 1:N
    x_n = x(n, :)';
    c_n = c(n, :);
    k = c_n;
    xx_n = [x_n; zeros(K, 1)];
    xx_n(D + k) = 1;

    V_n = value(x_n, xx_n, k);
    out = predict(V_n);
    choices = [choices; out];
end
