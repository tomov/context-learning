function [choices, P_n, ww_n, P, ww] = train(x, c, r)

predict = @(V_n) 1 / (1 + exp(-2 * V_n + 1)); % predicts by mapping the expectation to an outcome

% constants
%
N = size(x, 1); % # of trials
D = size(x, 2); % # of stimuli
K = 3;          % # of contexts

sigma_r = sqrt(0.01);
sigma_w = sqrt(1);
tau = sqrt(0.001);

% initialize Kalman filter
%
ww_n{1} = zeros(D, 1); % M1 weights: one per stimulus
ww_n{2} = zeros(D, K); % M2 weights: one per stimulus-context pair
ww_n{3} = zeros(D + K, 1); % M3 weights: one per stimulus + one per context

Sigma_n{1} = sigma_w^2 * eye(D);
Sigma_n{2} = repmat(sigma_w^2 * eye(D), 1, 1, K); % note the third dimension is the context
Sigma_n{3} = sigma_w^2 * eye(D + K);

P_n = [1 1 1] / 3; % posterior P(M | h_1:n)

% make a prediction based on h_1:n-1
%
value = @(x_n, xx_n, k) (x_n' * ww_n{1}) * P_n(1) + ... % M1 
                        (x_n' * ww_n{2}(:, k)) * P_n(2) + ... % M2
                        (xx_n' * ww_n{3}) * P_n(3); % M3

% Store history for plotting and analysis
%
P = []; % history of posterior P(M | h_1:n)
ww{1} = []; % history of ww_1:n for M1
ww{2} = []; % history of ww_1:n for M2
ww{3} = []; % history of ww_1:n for M3
choices = []; % history of choices

% train
%
for n = 1:N % for each trial
    x_n = x(n, :)'; % stimulus at trial n
    c_n = c(n, :); % context at trial n
    r_n = r(n, :); % reward at trial n
    k = c_n;
    xx_n = [x_n; zeros(K, 1)]; % augmented stimulus + context vector
    xx_n(D + k) = 1;

    V_n = value(x_n, xx_n, k);
    out = predict(V_n);
    choices = [choices; out];
    fprintf('\npredction for x = %d, c = %d is %f (actual is %f)\n\n', find(x_n), c_n, out, r_n);

    % get reward and update state
    %
    SSigma_n{1} = Sigma_n{1} + tau^2 * eye(D);
    SSigma_n{2} = Sigma_n{2}(:,:,k) + tau^2 * eye(D);
    SSigma_n{3} = Sigma_n{3} + tau^2 * eye(D + K);

    gain = @(x_n, SSigma_n) SSigma_n * x_n / (x_n' * SSigma_n * x_n + sigma_r^2);
    g_n{1} = gain(x_n, SSigma_n{1});    
    g_n{2} = gain(x_n, SSigma_n{2});    
    g_n{3} = gain(xx_n, SSigma_n{3}); 

    fprintf('    g_ns = %.4f %.4f %.4f | %.4f %4.f %.4f | %.4f %.4f %.4f %.4f %.4f %.4f\n', g_n{1}, g_n{2}, g_n{3});        

    Sigma_n{1} = SSigma_n{1} - g_n{1} * x_n' * SSigma_n{1};
    Sigma_n{2}(:,:,k) = SSigma_n{2} - g_n{2} * x_n' * SSigma_n{2};
    Sigma_n{3} = SSigma_n{3} - g_n{3} * xx_n' * SSigma_n{3};

    ww_n{1} = ww_n{1} + g_n{1} * (r_n - ww_n{1}' * x_n);
    ww_n{2}(:,k) = ww_n{2}(:,k) + g_n{2} * (r_n - ww_n{2}(:,k)' * x_n);
    ww_n{3} = ww_n{3} + g_n{3} * (r_n - ww_n{3}' * xx_n);

    disp('    ww_n{1} =');
    disp(ww_n{1});
    disp('    ww_n{2} =');
    disp(ww_n{2});
    disp('    ww_n{3} =');
    disp(ww_n{3});

    P_n(1) = P_n(1) * normpdf(r_n, x_n' * ww_n{1}, x_n' * SSigma_n{1} * x_n + sigma_r^2);
    P_n(2) = P_n(2) * normpdf(r_n, x_n' * ww_n{2}(:,k), x_n' * SSigma_n{2} * x_n + sigma_r^2);
    P_n(3) = P_n(3) * normpdf(r_n, xx_n' * ww_n{3}, xx_n' * SSigma_n{3} * xx_n + sigma_r^2);
    P_n = P_n / sum(P_n);

    fprintf('    P = %.4f %.4f %.4f', P_n);   

    P = [P; P_n];
    ww{1} = [ww{1}; ww_n{1}(1:2)'];
    ww{2} = [ww{2}; reshape(ww_n{2}(1:2,1:2), [1 4])];
    ww{3} = [ww{3}; ww_n{3}([1:2 4:5])'];

 %   fprintf('            new Ps = %f %f %f\n', P(1), P(2), P(3));
end

fprintf('\n\n');
