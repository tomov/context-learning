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

sem(x)
sqrt(sum((sems * sqrt(length(x)/10)).^2)) / sqrt(10) / sqrt(length(x))
sqrt(sum((sems * sqrt(length(x)/10)).^2)) / sqrt(length(x) * 10)
sqrt(sum(sems.^2)) / 10


std(x)
sqrt(sum(stds.^2)) / sqrt(10)

var(x)
sum(vars) / 10
