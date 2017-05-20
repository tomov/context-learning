% kalman filter RDM
%
% for reference, consult DEMO1_RSA_ROI_simulatedAndRealData from the rsa
% toolbox
%
function representational_similarity_rdm_kalman(distance_measure)
%distance_measure = 'correlation';

%analyze;
%save('analyze.mat');
load('analyze.mat');

% addpath('rsatoolbox/Engines/'); % RSA toolbox <------- for NCF / CBS

sss = getGoodSubjects();
[all_subjects, ~, ~] = contextGetSubjectsDirsAndRuns();
subjects = all_subjects(sss);
which_rows = which_rows & ismember(participant, subjects);


kalman_subjs = sss;
n_runs = 9;
n_subjects = length(kalman_subjs);
n_trials_per_run = 24;
kalmanRDMs = nan(n_runs * n_trials_per_run, n_runs * n_trials_per_run, n_subjects);

% massage the features a little bit
%

% copy P's from last training trial for test trials
%{
%model.P1 = [model.P1; zeros(4,1)];
%model.P2 = [model.P2; zeros(4,1)];
%model.P3 = [model.P3; zeros(4,1)];

x = repmat(model.P1(trialId == 20), 1, 4);
x = x';
x = x(:);
model.P1(isTrain == 0) = x;
x = repmat(model.P2(trialId == 20), 1, 4);
x = x';
x = x(:);
model.P2(isTrain == 0) = x;
x = repmat(model.P3(trialId == 20), 1, 4);
x = x';
x = x(:);
model.P3(isTrain == 0) = x;
%}


% which features from the kalman filter to use to compute the RDM
%
%{
all_subj_feature_vecs = [model.P(:,1:3), model.values, model.valuess(:,1:3), model.surprise, ...
                         model.likelihoods(:,1:3), model.new_values, model.new_valuess(:,1:3), ...
                         model.ww1, model.ww2, model.ww3, model.ww4, ...
                         model.Sigma1, model.Sigma2, model.Sigma3, model.Sigma4];
%}
%all_subj_feature_vecs = [model.P(:,1:3)];                     
%all_subj_feature_vecs = [model.Sigma1, model.Sigma2, model.Sigma3, model.Sigma4];
all_subj_feature_vecs = [model.ww1, model.ww2, model.ww3, model.ww4];
all_subj_feature_vecs = [all_subj_feature_vecs; zeros(4, size(all_subj_feature_vecs, 2))];

subj_idx = 0;
for subj = kalman_subjs
    subject = all_subjects(subj);
    subj_trials = which_rows & strcmp(participant, subject);
    
    % trials x feature vector for given subject
    %
    feature_vecs = all_subj_feature_vecs(subj_trials, :);
    
    subj_idx = subj_idx + 1;
    kalmanRDMs(:,:,subj_idx) = squareRDMs(pdist(feature_vecs, distance_measure));
end

disp('averaging!');
avgKalmanRDM = mean(kalmanRDMs, 3);

all_kalman = cat(3, kalmanRDMs, avgKalmanRDM); % TODO why does concatRDMs_unwrapped not work properly?

showRDMs(avgKalmanRDM, 1);

save(['rsa_rdms_kalman_ww_', distance_measure, '.mat'], 'avgKalmanRDM');

