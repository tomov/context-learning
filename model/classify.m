sss = getGoodSubjects();


sss = sss(1:5);
fitObj = classify_train('glmnet', [4:5 23], 7:8, sss, 'hippocampus.nii', 'condition', true);
classify_test('glmnet', fitObj, [1 24], 9:9, sss, 'hippocampus.nii', 'condition', true);