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
    [choices, P_n, ww_n, P, ww] = train(x, c, r, prior_variance, inv_softmax_temp, [1 1 1 0], false);    
    
    % entropy -- exclude M4 which has P = 0
    %
    H = - sum(P(:,1:3) .* log(P(:, 1:3)), 2);
    H(isnan(H)) = 0; % if a posterior is 0, the entropy is 0
    
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
            % context role @ feedback/outcome onset
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            % const @ trial onset
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M2 posterior pmod @ outcome
        %
        case 2
            % M2 (modulatory) posterior @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M2_posterior';
            multi.pmod(1).param{1} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
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

        % correct vs. wrong pmod @ outcome
        %
        case 3
            % correct vs. wrong (1/0) @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'correct';
            multi.pmod(1).param{1} = response.corr(which_train)'; % correct (1 or 0) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % prediction error pmod @ outcome
        %
        case 4
            % prediction error @ feedback onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - choices'; % outcome - expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % outcome (sick vs. not sick) @ outcome
        %
        case 5
            % sick vs. not sick @ feedback / outcome onset (trials 1..20)
            %
            multi.names{1} = 'sick';
            multi.onsets{1} = cellfun(@str2num, actualFeedbackOnset(which_train & strcmp(sick, 'Yes')))';
            multi.durations{1} = zeros(size(contextRole(which_train & strcmp(sick, 'Yes'))));            
            
            multi.names{2} = 'not sick';
            multi.onsets{2} = cellfun(@str2num, actualFeedbackOnset(which_train & ~strcmp(sick, 'Yes')))';
            multi.durations{2} = zeros(size(contextRole(which_train & ~strcmp(sick, 'Yes'))));                        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{3} = zeros(size(contextRole(which_train)));
            
        % outcome pmod @ outcome -- sanity check
        %
        case 6
            % sick vs. not sick @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            assert(isequal(strcmp(sick(which_train), 'Yes'), r));
            multi.pmod(1).name{1} = 'outcome';
            multi.pmod(1).param{1} = r'; % outcome == sick (1 or 0) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % expected outcome pmod @ start
        %
        case 7
            % expected outcome @ trial onset (trials 1..20)
            %
            multi.names{1} = 'trial_onset';
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'expected_outcome';
            multi.pmod(1).param{1} = choices'; % expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            % const @ feedback onset
            %
            multi.names{2} = 'feedback';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M3 posterior pmod @ outcome
        %
        case 8
            % M3 (additive) posterior @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M3_posterior';
            multi.pmod(1).param{1} = P(:,3)'; % posterior P(M3 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % M1 posterior pmod @ outcome
        %
        case 9
            % M1 (irrelevant) posterior @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M1_posterior';
            multi.pmod(1).param{1} = P(:,1)'; % posterior P(M1 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % posterior entropy @ outcome
        %
        case 10
            % posterior entropy @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'posterior_entropy';
            multi.pmod(1).param{1} = H'; % entropy of P(M | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % posterior entropy + context role / condition @ outcome
        %
        case 11
            % posterior entropy @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = strcat(condition, '_posterior_entropy');
            multi.pmod(1).param{1} = H'; % entropy of P(M | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % flipped posterior entropy @ outcome
        %
        case 12
            % flipped posterior entropy @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'flipped_posterior_entropy';
            multi.pmod(1).param{1} = max(H') - H'; % flipped entropy of P(M | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % flipped posterior entropy + context role / condition @ outcome
        %
        case 13
            % flipped posterior entropy @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = strcat(condition, '_flipped_posterior_entropy');
            multi.pmod(1).param{1} = max(H') - H'; % flipped entropy of P(M | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % posterior std @ outcome
        %
        case 14
            % posterior std @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'posterior_std';
            multi.pmod(1).param{1} = std(P(:, 1:3)'); % std of P(M | h_1:n) for trials 1..20, exluding M4
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % posterior std + context role / condition @ outcome
        %
        case 15
            % posterior std @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = strcat(condition, '_posterior_std');
            multi.pmod(1).param{1} = std(P(:, 1:3)'); % std of P(M | h_1:n) for trials 1..20, exluding M4
            multi.pmod(1).poly{1} = 1; % first order        
            
            % expected outcome @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % M2 posterior - M1 posterior pmod @ outcome
        %
        case 16
            % M2 - M1 posterior @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M2_minus_M1_posterior';
            multi.pmod(1).param{1} = P(:,2)' - P(:,1)';
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % M3 posterior - M1 posterior pmod @ outcome
        %
        case 17
            % M3 - M1 posterior @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M3_minus_M1_posterior';
            multi.pmod(1).param{1} = P(:,3)' - P(:,1)';
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
    end

end 
            

