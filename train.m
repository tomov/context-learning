clear all;

%
% Set up the experiment
%

% irrelevant context group = group 1
% set up stimuli vectors, contexts and rewards for x1c1, x2c1, x2c1, x2c2
%
x{1} = [1 0 0; 0 1 0; 1 0 0; 0 1 0]; % stimuli vectors x1 x2 x1 x2
c{1} = [1; 1; 2; 2]; % context indices c1 c1 c2 c2
r{1} = [1; 0; 1; 0]; % rewards

% modulatory context group = group 2
%
x{2} = x{1};
c{2} = c{1};
r{2} = [1; 0; 0; 1];

% additive context group = group 3
%
x{3} = x{1};
c{3} = c{1};
r{3} = [1; 1; 0; 0];

% repeat trials for each group
%
reps = 5; % = nTrials / 4
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

% test trials
% x1c1, x1c3, x3c1, x3c3
%
test_x = [1 0 0; 1 0 0; 0 0 1; 0 0 1]; % test stimuli: x1 x1 x3 x3
test_c = [1; 3; 1; 3]; % test contexts: c1 c3 c1 c3

%
% RUN THE TRIALS
%

% constants
%
sigma_r = sqrt(0.01);
sigma_w = sqrt(1);
tau = sqrt(0.001);

predict = @(V_n) 1 / (1 + exp(-2 * V_n + 1)); % predicts by mapping the expectation to an outcome

choices = zeros(3, 4); % predictions for each test trial (cols), for each group (rows)

for g=1:3 % for each group

    % initialize Kalman filter
    %
    ww_n{1} = zeros(D, 1); % M1 weights: one per stimulus
    ww_n{2} = zeros(D, K); % M2 weights: one per stimulus-context pair
    ww_n{3} = zeros(D + K, 1); % M3 weights: one per stimulus + one per context

    Sigma_n{1} = sigma_w^2 * eye(D);
    Sigma_n{2} = repmat(sigma_w^2 * eye(D), 1, 1, K); % note the third dimension is the context
    Sigma_n{3} = sigma_w^2 * eye(D + K);

    P_n = [1 1 1] / 3; % posterior P(M | h_1:n)
    
    P = []; % history of posterior P(M | h_1:n)
    ww{1} = []; % history of ww_1:n for M1
    ww{2} = []; % history of ww_1:n for M2
    ww{3} = []; % history of ww_1:n for M3
    
    fprintf('\n\n ---------------- GROUP %d ------------------\n\n', g);

    % train
    %
    for n = 1:N % for each trial
        x_n = x{g}(n, :)'; % stimulus at trial n
        c_n = c{g}(n, :); % context at trial n
        r_n = r{g}(n, :); % reward at trial n
        k = c_n;
        xx_n = [x_n; zeros(K, 1)]; % augmented stimulus + context vector
        xx_n(D + k) = 1;

        % make a prediction based on h_1:n-1
        %
        value = @(x_n, xx_n, k) (x_n' * ww_n{1}) * P_n(1) + ... % M1 
                                (x_n' * ww_n{2}(:, k)) * P_n(2) + ... % M2
                                (xx_n' * ww_n{3}) * P_n(3); % M3
        V_n = value(x_n, xx_n, k);
        out = predict(V_n);
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

    % testw
    %
    for n = 1:size(test_x, 1)
        x_n = test_x(n, :)';
        c_n = test_c(n, :);
        k = c_n;
        xx_n = [x_n; zeros(K, 1)];
        xx_n(D + k) = 1;

        % predict
        % TODO dedupe
        value = @(x_n, xx_n, k) (x_n' * ww_n{1}) * P_n(1) + ... % M1 
                                (x_n' * ww_n{2}(:, k)) * P_n(2) + ... % M2
                                (xx_n' * ww_n{3}) * P_n(3); % M3
        V_n = value(x_n, xx_n, k);
        out = predict(V_n);
        fprintf('TEST predction for x = %d, c = %d is %f\n', find(x_n), c_n, out);
        choices(g, n) = out;
    end
    
    % Plot posterior probability P(M | h_1:n)
    %
    figure;
    
    subplot(3, 2, 1);
    plot(P, 'o-', 'LineWidth', 2);
    xlabel('n (trial #)');
    ylabel('P(M | h_{1:n})');
    title('Posterior probability after each trial');
    legend({'M1', 'M2', 'M3'});

    % Plot weight matrix ww for M1
    %
    subplot(3, 2, 2);
    plot(ww{1}, 'o-', 'LineWidth', 2);
    xlabel('n (trial #)');
    ylabel('ww_n');
    title('Weight matrix on each trial for M1');
    legend({'x1', 'x2'});

    % Plot weight matrix ww for M2
    %
    subplot(3, 2, 3);
    plot(ww{2}, 'o-', 'LineWidth', 2);
    xlabel('n (trial #)');
    ylabel('ww_n');
    title('Weight matrix on each trial for M2');
    legend({'x1c1', 'x2c1', 'x1c2', 'x2c2'});
    
    % Plot weight matrix ww for M3
    %
    subplot(3, 2, 4);
    plot(ww{3}, 'o-', 'LineWidth', 2);
    xlabel('n (trial #)');
    ylabel('ww_n');
    title('Weight matrix on each trial for M3');
    legend({'x1', 'x2', 'c1', 'c2'});
end

