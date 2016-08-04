% constants
sigma_r = 0.0001;
sigma_w = 1;

% initialize Kalman filter
ww{1} = zeros(1, D);
ww{2} = zeros(K, D);
ww{3} = zeros(1, D + K);

Sigma{1} = sigma_w^2 * eye(D);
Sigma{2} = repmat(sigma_w^2 * eye(D), 1, 1, K); % note the third dimension is the context
Sigma{3} = sigma_w^2 * eye(D + K);

gain = @(x_n, SSigma_n) x_n * SSigma_n / (x_n * SSigma_n * x_n' + sigma_r^2); % TODO tomfool

for g = 1:3 % for each group
    for n = 1:N
        x_n = x{g}(n, :);
        c_n = c{g}(n, :);
        r_n = r{g}(n, :);

        
    end
end


