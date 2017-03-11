% For each mask (ROI),
%     computes BIC for each model for each subject
%     populates the log model evidences array (rows = subjects, columns =
%     models) which gets passed to BMS
%     which estimates the excedence probabilities (????)
% 
%

roi_masks = {'hippocampus.nii'}; % which ROIs to look at (one at a time) as paths to nifti files

subjects = getGoodSubjects(); % which subjects to analyze (as indices of the subjects array returned by contextGetSubjectsDirsAndRuns)

models = 1:26; % which models to consider (as the glmodel value passed to context_create_multi)

for roi=roi_masks
    lme = []; % log model evidence
    for model=models
        bic = ccnl_bic(contextExpt(), model, roi{1}, subjects);
        lme = [lme bic];
    end
    % [alpha,exp_r,xp,pxp,bor] = bms(lme);
end