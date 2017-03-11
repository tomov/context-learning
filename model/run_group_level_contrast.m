sss = getGoodSubjects(); % which subjects to use

%{
ccnl_fmri_con(contextExpt(), 1, ...
    {'modulatory - irrelevant', 'additive - irrelevant', 'modulatory - additive'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 2, ...
    {'M2_posterior'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 3, ...
    {'correct'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 4, ...
    {'prediction_error'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 5, ...
    {'sick - not sick'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 6, ...
    {'outcome'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 7, ...
    {'expected_outcome'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 8, ...
    {'M3_posterior'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 9, ...
    {'M1_posterior'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 10, ...
    {'posterior_entropy'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 11, ...
    {'modulatory_posterior_entropy - irrelevant_posterior_entropy', ...
    'additive_posterior_entropy - irrelevant_posterior_entropy', ...
    'modulatory_posterior_entropy - additive_posterior_entropy'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 12, ...
    {'flipped_posterior_entropy'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 13, ...
    {'modulatory_flipped_posterior_entropy - irrelevant_flipped_posterior_entropy', ...
    'additive_flipped_posterior_entropy - irrelevant_flipped_posterior_entropy', ...
    'modulatory_flipped_posterior_entropy - additive_flipped_posterior_entropy'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 14, ...
    {'posterior_std'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 15, ...
    {'modulatory_posterior_std - irrelevant_posterior_std', ...
    'additive_posterior_std - irrelevant_posterior_std', ...
    'modulatory_posterior_std - additive_posterior_std'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 16, ...
    {'M2_minus_M1_posterior'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 17, ...
    {'M3_minus_M1_posterior'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 18, ...
    {'M2_posterior - M1_posterior'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 19, ...
    {'M3_posterior - M1_posterior'}, ...
    sss);
ccnl_fmri_con(contextExpt(), 20, ...
    {'M3_posterior - M2_posterior'}, ...
    sss);
%}

%ccnl_mean(contextExpt(), sss); % group-level structural

% ccnl_check_mask(contextExpt(), 1, 'modulatory - irrelevant')

%ccnl_view(contextExpt(), 1, 'additive - irrelevant'); %  !!!!  <-- L hippo, L/R parahippo
%ccnl_view(contextExpt(), 3, 'additive - irrelevant'); % <-- similar to 1 but shittier
%ccnl_view(contextExpt(), 4, 'additive - irrelevant'); % <-- nothing
%ccnl_view(contextExpt(), 10, 'additive - irrelevant'); % <-- !! L hippo, L/R parahippo
%ccnl_view(contextExpt(), 15, 'additive - irrelevant'); % <-- !! L hippo, L/R parahippo

%ccnl_view(contextExpt(), 1, 'modulatory - additive'); % <-- SNc? OFC -- reliable?
%ccnl_view(contextExpt(), 11, 'modulatory - irrelevant'); % <-- SNc? vlPFC? mPFC?
%ccnl_view(contextExpt(), 12, 'modulatory - irrelevant'); % <-- nothing

%ccnl_view(contextExpt(), 16, 'posterior_entropy');

%ccnl_view(contextExpt(), 2, 'M2_posterior'); 
%ccnl_view(contextExpt(), 14, 'M3_posterior');

%ccnl_view(contextExpt(), 7, 'expected_outcome');

%ccnl_view(contextExpt(), 6, 'feedback'); % <-- L / R posterior hippo? P = 1e-7 => FWE?
%ccnl_view(contextExpt(), 7, 'trial_onset'); % <-- L putamen? P = 1e-7
%ccnl_view(contextExpt(), 8, 'sick - not sick'); % <-- big neg in V1
%ccnl_view(contextExpt(), 9, 'feedback'); % <-- bilateral posterior to putamen? P = 1e-7


%ccnl_view_x(contextExpt(), 1, 'additive - irrelevant')


% ------------------ for Jan 26 meeting ---------------

%ccnl_view(contextExpt(), 18, 'M2_posterior - M1_posterior'); % <-- nothing

%ccnl_view(contextExpt(), 1, 'modulatory - irrelevant');

%ccnl_view(contextExpt(), 19, 'M3_posterior - M1_posterior'); % <-- post hippo negative!
%ccnl_view(contextExpt(), 20, 'M3_posterior - M2_posterior'); % <-- hippo, striatum

%ccnl_view(contextExpt(), 18, 'M1_posterior - M2_posterior');
%ccnl_view(contextExpt(), 19, 'M1_posterior - M3_posterior'); % <-- post hippo W.T.F.
%ccnl_view(contextExpt(), 20, 'M2_posterior - M3_posterior');


ccnl_view(contextExpt(), 21, 'pressed_sick'); % <-- sanity check, V1


% ccnl_bic.m
% model comparison
% e.g. all the hippocampal voxels
%
% take AAL atlas and do model comparison in each parcel -- select voxels to
% enter into model comparison
% just do cortical regions and hippocampus -- need to convert to nii files
%
% model comparison score --- look at wiki
% can do for each subject separately
%
% bms function in mfit -- has reference. Giving an excedence probability
% feed mfit a transformed version of the relative BIC's
% assumes that diff people are explained by different models; estimate
% frequency of each model in the population
% estimates excedence probability -- the probability that a given model is
% best explained
%
% run the BIC for each model for each subject
% then feed the BIC into BMS -- it's on the ccnl fmri github wiki
%
% one number per ROI
%



% model comparison in striatum for PE's
% for different models -- PE at time of outcome,
% 1) pmod at RT -- expected value
% 2) pmod at outcome time -- actual reward
% vmPFC -- value signal
%
% !!!!!!!!!! use orthogonalization for all of these
% sanity check
%
%
%

% TODO -- look at value V_n NOT of choices or PE's -- PE's don't make sense
% look at V_n at time of choice
% 



% TODO -- ROI -- anatomical of the hippocampus
% 



%ccnl_view(contextExpt(), 4, 'prediction_error');

% weird

%ccnl_view(contextExpt(), 22, 'M2_posterior_irrelevant - M1_posterior_irrelevant');
%ccnl_view(contextExpt(), 22, 'M1_posterior_modulatory - M2_posterior_modulatory');

%ccnl_view(contextExpt(), 23, 'M3_posterior_irrelevant - M1_posterior_irrelevant');
%ccnl_view(contextExpt(), 23, 'M1_posterior_additive - M3_posterior_additive');

%ccnl_view(contextExpt(), 24, 'M2_posterior_modulatory - M3_posterior_modulatory');
%ccnl_view(contextExpt(), 24, 'M3_posterior_additive - M2_posterior_additive');

