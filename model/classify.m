sss = getGoodSubjects();
sss(sss == 5) = [];

classify_train('glmnet', 1:19, 1:9, sss, 'mask.nii', 'classify_glmnet_fitObj_only_1-19_mask_w00t.mat');
classify_test('glmnet', 20:20, 1:9, sss, 'mask.nii', 'classify_glmnet_fitObj_only_1-19_mask_w00t.mat', 'classify_glmnet_fitObj_only_1-19_mask_20_w00t.mat');
