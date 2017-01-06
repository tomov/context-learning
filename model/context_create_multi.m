function multi = context_create_multi(glmodel, subj, run)

    % Create multi structure, helper function for creating EXPT in
    % imageryExpt.m
    %
    % USAGE: multi = imagery_create_multi(model,subj,run)
    %
    % INPUTS:
    %   glmodel - positive integer indicating general linear model
    %   subj - integer specifying which subject is being analyzed
    %   run - integer specifying the run
    %
    % OUTPUTS:
    %   multi - a structure with the folloowing fields
    %        .names{i}
    %        .onsets{i}
    %        .durations{i}
    %        optional:
    %        .pmod(i).name
    %        .pmod(i).param
    %        .pmod(i).poly
    %
    % Cody Kommers, July 2016
    
    load_data;
    
    [subjects, subjdirs, nRuns] = contextGetSubjectsDirsAndRuns();
    assert(isequal(subjects',unique(participant)));
        
    % pick the trials that correspond to that subject & run
    %
    which_train = ~drop & isTrain & strcmp(participant, subjects{subj}) & roundId == run;
    which_test = ~drop & ~isTrain & strcmp(participant, subjects{subj}) & roundId == run;
    
    % condition = context role for the run
    %
    condition = contextRole(which_train);
    condition = condition{1};
    
    % Run model on training trials
    %
    cues = cueId(which_train);
    N = length(cues); % # of trials
    D = 3; % # of stimuli
    x = zeros(N, D);
    x(sub2ind(size(x), 1:N, cues' + 1)) = 1;
    c = contextId(which_train) + 1;
    r = strcmp(sick(which_train), 'Yes');
    [choices, P_n, ww_n, P, ww] = train(x, c, r, prior_variance, inv_softmax_temp, false);    
    
    % Run model on test trials
    %
    test_cues = cueId(which_test);
    test_N = length(test_cues); % # of trials
    D = 3; % # of stimuli
    test_x = zeros(test_N, D);
    test_x(sub2ind(size(test_x), 1:test_N, test_cues' + 1)) = 1;
    test_c = contextId(which_test) + 1;
    [test_choices] = test(test_x, test_c, P_n, ww_n, inv_softmax_temp);

    % Parametric modulators
    %
    switch glmodel
        
        % cue and outcome regressor for each model
        
        % Simple. Contrast conditions at feedback time
        %
        %
        % neural correlate of latent structure prob
        % show it's predictive of the test performance
        % posterior over structures in OFC and vmPFC
        % hippo encodes context sensitity
        % e.g. hippo only active in modulatory condition -- 
        %     or hippo just codes context, regardless of functional
        %     role
        %     whether there's significant info in hippo re context
        %    option -- classify which context based on hippo activity
        %        separate GLM --
        %           regressor for each context at time of stimulus 
        %           to avoid collinearity, no stimulus event regressor
        %           just events, no pmods
        %           and a feedback event
        %           for each subject, pull out voxel activity in hippo
        %           leave 1 of 9 runs out
        %           gives you 1 beta map for each context per run
        %           have 16 training examples 
        %           train a classifier on 16 examples 
        %           
        %           simple thing -- is context activated selectively in
        %           modulatory condition
        %               vs. irrelevant and additive
        %           modulatory - irrelevant
        %           additive - irrelevant
        %           modulatory - additive
        %           
        %
        case 1
            % context role @ feedback onset
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            % ... @ trial onset
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % Regress with M2 posterior (feedback onset)
        % and expected outcome (stimulus onset)
        %
        case 2
            % M2 (modulatory) posterior @ feedback onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M2_posterior';
            multi.pmod(1).param{1} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'expected_outcome';
            multi.pmod(2).param{1} = choices'; % expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order        
            
            % Events 3, 4, 5, 6: Test stimulus, one per
            % condition-cue-context tuple
            %
            % name = test_{condition}_x{cueId + 1}c{contextId + 1}
            %   e.g. test_irrelevant_x1c3
            % onset = stimulus onset
            % duration = 0
            %
            % identify voxels that predict expected outcome purely on training
            % on test trials, at stimulus onset, do they show the pattern
            % of modulation that we see in behavior
            % just look at the betas then (no pmods for test trials)
            %
            test_cueIds = cueId(which_test);
            test_contextIds = contextId(which_test);
            test_actualChoiceOnsets = cellfun(@str2num, actualChoiceOnset(which_test))';
            for i=1:length(test_actualChoiceOnsets)
                multi.names{2 + i} = sprintf('test_%s_x%dc%d', condition, test_cueIds(i) + 1, test_contextIds(i) + 1);
                multi.onsets{2 + i} = test_actualChoiceOnsets(i);
                multi.durations{2 + i} = 0;
            end
            
        case 3
            % context role @ feedback onset (trials 1..20)
            % SAME AS 1 but no trial_onset regressor
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));

        case 4
            % context role @ trial onset (trials 1..20)
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));            

        % TODO DOESN'T WORK -- need at least 1 wrong trial...
        case 5
            % correct vs. wrong @ feedback onset (trials 1..20)
            % 
            multi.names{1} = 'correct';
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train & response.corr))';
            multi.durations{1} = zeros(size(contextRole(which_train & response.corr)));            
            
            multi.names{2} = 'wrong';
            multi.onsets{2} = cellfun(@str2num, actualFeedbackOnset(which_train & ~response.corr))';
            multi.durations{2} = zeros(size(contextRole(which_train & ~response.corr)));                        

        case 6
            % prediction error @ feedback onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction error';
            multi.pmod(1).param{1} = r' - choices'; % outcome - expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  
            
        case 7
            % expected outcome @ trial onset (trials 1..20)
            %
            multi.names{1} = 'trial_onset';
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'expected_outcome';
            multi.pmod(1).param{1} = choices'; % expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order

        case 8
            % sick vs. not sick @ feedback onset (trials 1..20)
            %
            multi.names{1} = 'sick';
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train & strcmp(sick, 'Yes')))';
            multi.durations{1} = zeros(size(contextRole(which_train & strcmp(sick, 'Yes'))));            
            
            multi.names{2} = 'not sick';
            multi.onsets{2} = cellfun(@str2num, actualFeedbackOnset(which_train & ~strcmp(sick, 'Yes')))';
            multi.durations{2} = zeros(size(contextRole(which_train & ~strcmp(sick, 'Yes'))));                        
            
        case 9
            % outcome (sick = 1, not sick = 0) @ feedback onset (trials 1..20)
            % should be same as 8
            %
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'outcome';
            multi.pmod(1).param{1} = r'; % outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
        % SAME AS case 2 but with different context roles
        % Regress with M2 posterior (feedback onset)
        % and expected outcome (stimulus onset)
        %
        case 10
            % M2 (modulatory) posterior @ feedback onset (trials 1..20)
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M2_posterior';
            multi.pmod(1).param{1} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'expected_outcome';
            multi.pmod(2).param{1} = choices'; % expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order        
            
            % Events 3, 4, 5, 6: Test stimulus, one per
            % condition-cue-context tuple
            %
            % name = test_{condition}_x{cueId + 1}c{contextId + 1}
            %   e.g. test_irrelevant_x1c3
            % onset = stimulus onset
            % duration = 0
            %
            % identify voxels that predict expected outcome purely on training
            % on test trials, at stimulus onset, do they show the pattern
            % of modulation that we see in behavior
            % just look at the betas then (no pmods for test trials)
            %
            test_cueIds = cueId(which_test);
            test_contextIds = contextId(which_test);
            test_actualChoiceOnsets = cellfun(@str2num, actualChoiceOnset(which_test))';
            for i=1:length(test_actualChoiceOnsets)
                multi.names{2 + i} = sprintf('test_%s_x%dc%d', condition, test_cueIds(i) + 1, test_contextIds(i) + 1);
                multi.onsets{2 + i} = test_actualChoiceOnsets(i);
                multi.durations{2 + i} = 0;
            end
            
        % SAME AS 6 but different context roles
        case 11
            % prediction error @ feedback onset (trials 1..20)
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction error';
            multi.pmod(1).param{1} = r' - choices'; % outcome - expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  
            
        % same as 7 but different context roles
        case 12
            % expected outcome @ trial onset (trials 1..20)
            %
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'expected_outcome';
            multi.pmod(1).param{1} = choices'; % expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order

        % SAME AS 9 but diff context roles
        case 13
            % outcome (sick = 1, not sick = 0) @ feedback onset (trials 1..20)
            % should be same as 8
            %
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'outcome';
            multi.pmod(1).param{1} = r'; % outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
                   
        % Regress with M3 posterior @ feedback onset
        % and expected outcome @ stimulus onset
        % (same as 2 but for additive context)
        %
        case 14
            % M3 (additive) posterior @ feedback onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M3_posterior';
            multi.pmod(1).param{1} = P(:,3)'; % posterior P(M3 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'expected_outcome';
            multi.pmod(2).param{1} = choices'; % expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order        
            
            % Events 3, 4, 5, 6: Test stimulus, one per
            % condition-cue-context tuple
            %
            % name = test_{condition}_x{cueId + 1}c{contextId + 1}
            %   e.g. test_irrelevant_x1c3
            % onset = stimulus onset
            % duration = 0
            %
            % identify voxels that predict expected outcome purely on training
            % on test trials, at stimulus onset, do they show the pattern
            % of modulation that we see in behavior
            % just look at the betas then (no pmods for test trials)
            %
            test_cueIds = cueId(which_test);
            test_contextIds = contextId(which_test);
            test_actualChoiceOnsets = cellfun(@str2num, actualChoiceOnset(which_test))';
            for i=1:length(test_actualChoiceOnsets)
                multi.names{2 + i} = sprintf('test_%s_x%dc%d', condition, test_cueIds(i) + 1, test_contextIds(i) + 1);
                multi.onsets{2 + i} = test_actualChoiceOnsets(i);
                multi.durations{2 + i} = 0;
            end
            
        % SAME AS 15 but with context role
        % i.e. 15:14 == 10:2
        %
        case 15
            % M3 (additive) posterior @ feedback onset (trials 1..20)
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M3_posterior';
            multi.pmod(1).param{1} = P(:,3)'; % posterior P(M3 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'expected_outcome';
            multi.pmod(2).param{1} = choices'; % expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order        
            
            % Events 3, 4, 5, 6: Test stimulus, one per
            % condition-cue-context tuple
            %
            % name = test_{condition}_x{cueId + 1}c{contextId + 1}
            %   e.g. test_irrelevant_x1c3
            % onset = stimulus onset
            % duration = 0
            %
            % identify voxels that predict expected outcome purely on training
            % on test trials, at stimulus onset, do they show the pattern
            % of modulation that we see in behavior
            % just look at the betas then (no pmods for test trials)
            %
            test_cueIds = cueId(which_test);
            test_contextIds = contextId(which_test);
            test_actualChoiceOnsets = cellfun(@str2num, actualChoiceOnset(which_test))';
            for i=1:length(test_actualChoiceOnsets)
                multi.names{2 + i} = sprintf('test_%s_x%dc%d', condition, test_cueIds(i) + 1, test_contextIds(i) + 1);
                multi.onsets{2 + i} = test_actualChoiceOnsets(i);
                multi.durations{2 + i} = 0;
            end
            
    end

end
