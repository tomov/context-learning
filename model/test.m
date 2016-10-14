function [choices] = test(x, k, P_n, ww_n, softmax_temp)

% constants
%
N = size(x, 1); % # of trials
D = size(x, 2); % # of stimuli
K = 3;          % # of contexts

% predict
predict = @(V_n) 1 ./ (1 + exp(-2 * softmax_temp * V_n + softmax_temp)); % predicts by mapping the expectation to an outcome

value = @(x_n, xx_n, k) (x_n' * ww_n{1}) * P_n(1) + ... % M1 
                        (x_n' * ww_n{2}(:, k)) * P_n(2) + ... % M2
                        (xx_n' * ww_n{3}) * P_n(3); % M3

choices = [];
                    
for n = 1:N
    x_n = x(n, :)'; % stimulus at trial n
    k_n = k(n); % context idx at trial n
    c_n = zeros(K, 1);
    c_n(k_n) = 1; % context vector like x_n
    xx_n = [x_n; c_n]; % augmented stimulus + context vector
    
    
    V_n = value(x_n, xx_n, k_n);
    out = predict(V_n);
    choices = [choices; out];
end
