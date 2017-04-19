sss = getGoodSubjects();

%sss = sss(1:5);
fitObj = classify_train('glmnet', 1:19, 1:9, sss, 'hippocampus.nii', 'condition', true);
classify_test('glmnet', fitObj, 20:20, 1:9, sss, 'hippocampus.nii', 'condition', true);

%[inputs, targets] = classify_get_inputs_and_targets(1:2, 1:4, sss(1:2), 'hippocampus.nii', 'roundId', true);