function [choices, values, valuess, predict] = test(x, k, P_n, ww_n, inv_softmax_temp)
% Apply what 
%

% constants
%
N = size(x, 1); % # of trials
D = size(x, 2); % # of stimuli
K = 3;          % # of contexts

% predict
predict = @(V_n) 1 ./ (1 + exp(-2 * inv_softmax_temp * V_n + inv_softmax_temp)); % predicts by mapping the expectation to an outcome

value = @(x_n, xx_n, xb_n, k_n, c_n) (x_n' * ww_n{1}) * P_n(1) + ... % M1 
                                     (xb_n' * ww_n{2}(:, k_n)) * P_n(2) + ... % M2
                                     (xx_n' * ww_n{3}) * P_n(3) + ... % M3   
                                     (c_n' * ww_n{4}) * P_n(4); % M4

choices = []; % history of choices
values = []; % history of predicted outcomes, weighted sum across all models (causal structures)
valuess = []; % history of predicted outcomes, one for each model (causal structure)

                    
for n = 1:N
    x_n = x(n, :)'; % stimulus at trial n
    k_n = k(n); % context idx at trial n
    c_n = zeros(K, 1);
    c_n(k_n) = 1; % context vector like x_n
    xb_n = [x_n; 1]; % stim vec + bias
    xx_n = [x_n; c_n]; % augmented stimulus + context vector
    
    
    V_n = value(x_n, xx_n, xb_n, k_n, c_n);
    out = predict(V_n);
    choices = [choices; out];
    values = [values; V_n];
    valuess = [valuess; x_n' * ww_n{1}, xb_n' * ww_n{2}(:, k_n), xx_n' * ww_n{3}, c_n' * ww_n{4}];    
end
