% single-subject RDMs
% for reference, consult DEMO1_RSA_ROI_simulatedAndRealData from the rsa
% toolbox
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



subj_idx = 0;
for subj = beta_subjs
    disp(subj);
    subj_idx = subj_idx + 1;
    % beta_vecs{subj} = trials x voxels vector; for the given subject,
    %                   for each trial, what's her activation pattern look
    %                   like
    % pdist computes pair-wise distance between these voxel activation patterns
    % for all pairs of trials for the subject
    % i.e. for each pair of trials (t1, t2), it computes the distance
    %        e.g. correlation distance = 1 - correlation coefficient
    %             so this is the same as 1 - corrcoef(beta_vecs{subj}', ...) <-- notice, must transpose
    %             except pdist returns a vector; transform to matrix using
    %             squareform(...)
    % and this is the RDM essentially
    %
    subjectRDMs(:,:,subj_idx) = squareRDMs(pdist(beta_vecs{subj}, distance_measure));
end

disp('averaging!');
avgSubjectRDM = mean(subjectRDMs, 3);

all = cat(3, subjectRDMs, avgSubjectRDM); % TODO why does concatRDMs_unwrapped not work properly?

clear beta_vecs; % too big; don't need any longer
save(['rsa_rdms_', m{1}, '_', distance_measure, '.mat'], '-v7.3');

