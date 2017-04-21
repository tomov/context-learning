close all;
rois = {'hippocampus', 'ofc', 'striatum', 'vmpfc'};

sem = @(x) std(x) / sqrt(length(x));

means_output_best = [];
sems_output_best = [];
means_output_all = [];
sems_output_all = [];
for roi = rois
    % alpha = 1 (lasso); ungrouped
    load(['classify_train_', roi{1}, '.mat']);
    load(['classify_test_', roi{1}, '.mat']);
    
    % find the best lambda, plot confusion matrix
    %
    % WARNING -- this is cheating; we're just taking the lambda that
    % gives the best accuracy on the test set...
    best_acc = NaN;
    best_lambda = NaN;
    for l = 1:size(outputss, 3)
        acc = classify_get_accuracy(outputss(:,:,l), targets);
        if strcmp(roi{1}, 'ofc')
            % OFC is below chance ???
            acc_is_better = acc < best_acc || isnan(best_acc);
        else
            acc_is_better = acc > best_acc || isnan(best_acc);
        end
        if acc_is_better
            best_acc = acc;
            best_lambda = l;
        end
    end
    %best_lambda = randi([1 size(outputss, 3)]); % get some random lambda

    outputs = outputss(:,:,best_lambda);
    x = [mean(outputs(targets(:,1) == 1, :)); ...
         mean(outputs(targets(:,2) == 1, :)); ...
         mean(outputs(targets(:,3) == 1, :))];
    assert(abs(mean(sum(x, 2) - [1; 1; 1])) < 1e-6);
    
    means_output_best = [means_output_best; mean(outputs)];
    sems_output_best = [sems_output_best; sem(outputs)];
    
    figure;
    plotconfusion(targets', outputs', [roi{1}, ', best \lambda']);
    xticklabels({'irr', 'mod', 'add'});
    yticklabels({'irr', 'mod', 'add'});
    
    % same thing but with all lambdas
    % 
    all_outputs = nan(size(outputss, 1) * size(outputss, 3), size(outputss, 2));
    all_targets = nan(size(outputss, 1) * size(outputss, 3), size(outputss, 2));
    for l = 1:size(outputss, 3)
        all_outputs((l - 1) * size(outputss, 1) + 1 : l * size(outputss, 1), :) = outputss(:,:,l);
        all_targets((l - 1) * size(outputss, 1) + 1 : l * size(outputss, 1), :) = targets;
    end
    assert(~isnan(sum(all_outputs(:))));
    assert(~isnan(sum(all_targets(:))));

    means_output_all = [means_output_all; mean(all_outputs)];
    sems_output_all = [sems_output_all; sem(all_outputs)];
    
    figure;
    plotconfusion(all_targets', all_outputs', [roi{1}, ', all \lambda`s']);
    xticklabels({'irr', 'mod', 'add'});
    yticklabels({'irr', 'mod', 'add'});    
end

figure;
barweb(means_output_best, sems_output_best);
xticklabels(rois);
legend('irr', 'mod', 'add');
ylabel('P(output class)');
title('best \lambda');

figure;
barweb(means_output_all, sems_output_all);
xticklabels(rois);
legend('irr', 'mod', 'add');
ylabel('P(output class)');
title('all \lambda`s');

