clear all;

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

% x -> x~ for M3
x{3} = [x{3} zeros(N, K)];
x{3}(sub2ind(size(x{3}), [1:length(c{3})]', c{3} + D)) = 1;


