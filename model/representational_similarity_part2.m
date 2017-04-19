% single-subject RDMs
%
function representational_similarity_part2(mask, distance_measure)
%clear all;
%close all;
%distance_measure = 'correlation';

% addpath('rsatoolbox/Engines/'); % RSA toolbox <------- for NCF / CBS

% as output by representational_similarity.m
m = regexp(mask,'\.','split');
load(['rsa_beta_vecs_', m{1}, '.mat']);


beta_subjs = sss;
n_runs = 9;
n_subjects = length(beta_subjs);
subjectRDMs = nan(n_runs * n_trials_per_run, n_runs * n_trials_per_run, n_subjects);


rdm = zeros(size(beta_vecs, 1));

subj_idx = 0;
for subj = beta_subjs
    disp(subj);
    subj_idx = subj_idx + 1;
    subjectRDMs(:,:,subj_idx) = squareRDMs(pdist(beta_vecs{subj}, distance_measure));
end

disp('averaging!');
avgSubjectRDM = mean(subjectRDMs, 3);

all = cat(3, subjectRDMs, avgSubjectRDM); % TODO why does concatRDMs_unwrapped not work properly?

clear beta_vecs; % too big; don't need any longer
save(['rsa_rdms_', m{1}, '_', distance_measure, '.mat'], '-v7.3');

