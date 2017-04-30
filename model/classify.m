sss = getGoodSubjects();

%sss = sss(1:5); 
sss = sss(1:3);
fitObj = classify_train('cvglmnet', 1:19, 1:9, sss, 'hippocampus.nii', 'condition', true, true);
classify_test('cvglmnet', fitObj, 20:20, 9:9, sss, 'hippocampus.nii', 'condition', true, true);

%[inputs, targets] = classify_get_inputs_and_targets(1:2, 1:4, sss(1:2), 'hippocampus.nii', 'roundId', true, true);

%% ROC curve

%outputs = outputss(:,:,1);
%[X, Y, T, AUC] = perfcurve(targets, outputs);