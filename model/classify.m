sss = getGoodSubjects();

%sss = sss(1:5); 
sss = sss(1:3);
fitObj = classify_train('glmnet', 1:20, 1:8, sss, 'hippocampus.nii', 'condition', true, true);
classify_test('glmnet', fitObj, 1:20, 9:9, sss, 'hippocampus.nii', 'condition', true, true);

%[inputs, targets] = classify_get_inputs_and_targets(1:2, 1:4, sss(1:2), 'hippocampus.nii', 'roundId', true);

%% ROC curve

%outputs = outputss(:,:,1);
%[X, Y, T, AUC] = perfcurve(targets, outputs);