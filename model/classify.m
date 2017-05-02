sss = getGoodSubjects();

%sss = sss(1:5); 
sss = sss(1:2);
fitObj = classify_train('cvglmnet', [1:15 21:23], 1:9, sss, 'hippocampus.nii', 'contextId', true, true);
classify_test('cvglmnet', fitObj, [16:20 24:24], 1:9, sss, 'hippocampus.nii', 'contextId', true, true);

[inputs, targets, subjIds, runIds, trialIds] = classify_get_inputs_and_targets([1:15 21:23], 1:9, sss(1:2), 'hippocampus.nii', 'contextId', true, true);

%% ROC curve

%outputs = outputss(:,:,1);
%[X, Y, T, AUC] = perfcurve(targets, outputs);