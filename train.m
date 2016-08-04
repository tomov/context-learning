clear all;

%
% Set up the experiment
%

% irrelevant context group
x{1} = [1 0 0; 0 1 0; 1 0 0; 0 1 0];
c{1} = [1; 1; 2; 2];
r{1} = [1; 0; 1; 0];

% modulatory context group
x{2} = x{1};
c{2} = c{1};
r{2} = [1; 0; 0; 1];

% additive context group
x{3} = x{1};
c{3} = c{1};
r{3} = [1; 1; 0; 0];

% repeat trials for each group
reps = 10;
for g = 1:3
    x{g} = repmat(x{g}, reps, 1);
    c{g} = repmat(c{g}, reps, 1);
    r{g} = repmat(r{g}, reps, 1);
    assert(size(x{g}, 1) == size(c{g}, 1));
    assert(size(x{g}, 1) == size(r{g}, 1));
end
N = size(x{1}, 1); % # of trials
D = size(x{1}, 2); % # of stimuli
K = 3;             % # of contexts

% test
test_x = [1 0 0; 1 0 0; 0 0 1; 0 0 1];
test_c = [1; 3; 1; 3];

%
% RUN THE TRIALS
%

% constants
sigma_r = sqrt(0.01);
sigma_w = sqrt(1);
tau = sqrt(0.001);

predict = @(V_n) 1 / (1 + exp(-2 * V_n + 1));

choices = zeros(3, 4);

for g=1:3 % for each group

    % initialize Kalman filter
    ww_n{1} = zeros(D, 1);
    ww_n{2} = zeros(D, K);
    ww_n{3} = zeros(D + K, 1);

    Sigma_n{1} = sigma_w^2 * eye(D);
    Sigma_n{2} = repmat(sigma_w^2 * eye(D), 1, 1, K); % note the third dimension is the context
    Sigma_n{3} = sigma_w^2 * eye(D + K);

    P = [1 1 1];

    fprintf('\n\n GROUP %d\n\n', g);

    % train
    %
    for n = 1:N % for each trial
        x_n = x{g}(n, :)';
        c_n = c{g}(n, :);
        r_n = r{g}(n, :);
        k = c_n;
        xx_n = [x_n; zeros(K, 1)];
        xx_n(D + k) = 1;

        % predict
        % TODO dedupe
        value = @(x_n, xx_n, k) (x_n' * ww_n{1}) * P(1) + ... % M1 
                                (x_n' * ww_n{2}(:, k)) * P(2) + ... % M2
                                (xx_n' * ww_n{3}) * P(3); % M3
        V_n = value(x_n, xx_n, k);
        out = predict(V_n);
        fprintf('predction for x = %d, c = %d is %f (actual is %f)\n', find(x_n), c_n, out, r_n);

        % get reward and update
        %
        SSigma_n{1} = Sigma_n{1} + tau^2 * eye(D);
        SSigma_n{2} = Sigma_n{2}(:,:,k) + tau^2 * eye(D);
        SSigma_n{3} = Sigma_n{3} + tau^2 * eye(D + K);
        
        gain = @(x_n, SSigma_n) SSigma_n * x_n / (x_n' * SSigma_n * x_n + sigma_r^2);
        g_n{1} = gain(x_n, SSigma_n{1});    
        g_n{2} = gain(x_n, SSigma_n{2});    
        g_n{3} = gain(xx_n, SSigma_n{3});    
        
        Sigma_n{1} = SSigma_n{1} - g_n{1} * x_n' * SSigma_n{1};
        Sigma_n{2}(:,:,k) = SSigma_n{2} - g_n{2} * x_n' * SSigma_n{2};
        Sigma_n{3} = SSigma_n{3} - g_n{3} * xx_n' * SSigma_n{3};
            
        ww_n{1} = ww_n{1} + g_n{1} * (r_n - ww_n{1}' * x_n);
        ww_n{2}(:,k) = ww_n{2}(:,k) + g_n{2} * (r_n - ww_n{2}(:,k)' * x_n);
        ww_n{3} = ww_n{3} + g_n{3} * (r_n - ww_n{3}' * xx_n);
            
        P(1) = P(1) * normpdf(r_n, x_n' * ww_n{1}, x_n' * SSigma_n{1} * x_n + sigma_r^2);
        P(2) = P(2) * normpdf(r_n, x_n' * ww_n{2}(:,k), x_n' * SSigma_n{2} * x_n + sigma_r^2);
        P(3) = P(3) * normpdf(r_n, xx_n' * ww_n{3}, xx_n' * SSigma_n{3} * xx_n + sigma_r^2);
        P = P / sum(P);
        
     %   fprintf('            new Ps = %f %f %f\n', P(1), P(2), P(3));
    end

    % test
    %
    for n = 1:size(test_x, 1)
        x_n = test_x(n, :)';
        c_n = test_c(n, :);
        k = c_n;
        xx_n = [x_n; zeros(K, 1)];
        xx_n(D + k) = 1;

        % predict
        % TODO dedupe
        value = @(x_n, xx_n, k) (x_n' * ww_n{1}) * P(1) + ... % M1 
                                (x_n' * ww_n{2}(:, k)) * P(2) + ... % M2
                                (xx_n' * ww_n{3}) * P(3); % M3
        V_n = value(x_n, xx_n, k);
        out = predict(V_n);
        fprintf('TEST predction for x = %d, c = %d is %f\n', find(x_n), c_n, out);
        choices(g, n) = out;
    end
end
