sss = getGoodSubjects();
sss(sss == 5) = [];

fitObj = classify_train('glmnet', 1:19, 1:9, sss, 'mask.nii', 'condition');
classify_test('glmnet', fitObj, 20:20, 1:9, sss, 'mask.nii', 'condition');
