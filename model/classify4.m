%function classify(alpha, mtype, mask)
function classify4(mask, what, training_trials, training_runs, test_trials, test_runs)

sss = getGoodSubjects();

%sss = sss(1:5);
fitObj = classify_train('cvglmnet', training_trials, training_runs, sss, mask, what, true, true);
classify_test('cvglmnet', fitObj, test_trials, test_runs, sss, mask, what, true, true);

%[inputs, targets] = classify_get_inputs_and_targets(1:2, 1:4, sss(1:2), 'hippocampus.nii', 'roundId', true);

%% ROC curve

%outputs = outputss(:,:,1);
%[X, Y, T, AUC] = perfcurve(targets, outputs);
