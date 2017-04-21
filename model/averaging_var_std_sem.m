% averaging variance, std and sems
%

rng default;

sem = @(x) std(x)  / sqrt(length(x));
x = normrnd(0, 20, 1, 100);

sems = [];
stds = [];
vars = [];
for i = 0:9
    xx = x(i*10+1:(i+1)*10);
    sems = [sems, sem(xx)];
    stds = [stds, std(xx)];
    vars = [vars, var(xx)];
end

% total # samples = length(x)
% # buckets = 10
% # samples (per bucket) = length(x) / 10
% assume same # samples in each bucket


% total variance = average variance
%                = sum of variances / # buckets
%
var(x)
sum(vars) / 10


%       std = sqrt(variance)
% total std = sqrt(total variance)
%           = sqrt(avg variance)
%           = sqrt(avg squared std)
%           = sqrt(sum of squared std / # buckets)
%           = sqrt(sum of squared std) / sqrt(# buckets)
%
std(x)
sqrt(sum(stds.^2)) / sqrt(10)



%       sem = std / sqrt(# samples)
% total sem = total std / sqrt(total # samples)
%           = sqrt(sum of squared std) / sqrt(# buckets) / sqrt(total # samples)
%           = sqrt(sum of squared sem * # samples) / sqrt(# buckets) / sqrt(total # samples)
%           = sqrt(sum of squared sem) * sqrt(# samples) / sqrt(# buckets) / sqrt(total # samples)
%           = sqrt(sum of squared sem) * sqrt(# samples) / sqrt(total # samples * # buckets)
%           = sqrt(sum of squared sem) * sqrt(# samples) / sqrt(# buckets * # samples * # buckets)
%           = sqrt(sum of squared sem) / # buckets
%
sem(x)
sqrt(sum((sems * sqrt(length(x)/10)).^2)) / sqrt(10) / sqrt(length(x))
sqrt(sum((sems * sqrt(length(x)/10)).^2)) / sqrt(length(x) * 10)
sqrt(sum(sems.^2)) / 10 % !!! easy as that



