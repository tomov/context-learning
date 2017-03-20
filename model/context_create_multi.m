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
    
    fprintf('glm %d, subj %d, run %d\n', glmodel, subj, run);
    
    load_data;
    
    is_timeout = cellfun(@isempty, actualChoiceOffset);
    no_response = strcmp(response.keys, 'None');
    assert(sum(is_timeout ~= no_response) == 0); % these should be the same
    
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
    which_models = [1 1 1 0];
    [choices, P_n, ww_n, P, ww, values, valuess, likelihoods] = train(x, c, r, prior_variance, inv_softmax_temp, which_models, false);    
    
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
        case 1 % <------------- GOOD
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

        % M2 posterior pmod @ outcome + extra stuff for test trials ZOMG
        %
        case 2 % <------------- GOOD
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
        % TODO WTFFFFFFFFFFFFFFFFFFFFFFFFFF
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
        % WRONG! choices != expected outcome
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
        case 5 % GOOD
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
        case 6 % GOOD
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
        % WRONG! choices != expected outcome
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
        case 8 % GOOD
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
        case 9 % GOOD
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
        case 10 % OKAY
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
            
        % M2 & M1 posterior pmods @ outcome
        %
        case 18
            % M2 (modulatory) & M1 (irrelevant) posteriors @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M2_posterior';
            multi.pmod(1).param{1} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        

            multi.pmod(1).name{2} = 'M1_posterior';
            multi.pmod(1).param{2} = P(:,1)'; % entropy of P(M1 | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{2} = 1; % first order
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M3 & M1 posterior pmods @ outcome
        %
        case 19
            % M3 (additive) & M1 (irrelevant) posteriors @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M3_posterior';
            multi.pmod(1).param{1} = P(:,3)'; % posterior P(M3 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        

            multi.pmod(1).name{2} = 'M1_posterior';
            multi.pmod(1).param{2} = P(:,1)'; % entropy of P(M1 | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{2} = 1; % first order
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M3 & M2 posterior pmods @ outcome
        %
        case 20
            % M3 (additive) & M2 (modulatory) posteriors @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M3_posterior';
            multi.pmod(1).param{1} = P(:,3)'; % posterior P(M3 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        

            multi.pmod(1).name{2} = 'M2_posterior';
            multi.pmod(1).param{2} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{2} = 1; % first order
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % Response @ reaction onset 
        %
        case 21
            % button press @ reaction onset (trials 1..20)
            % 
            multi.names{1} = 'keypress';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOffset(which_train & ~no_response))';
            multi.durations{1} = zeros(size(contextRole(which_train & ~no_response)));
            
            multi.pmod(1).name{1} = 'pressed_sick';
            multi.pmod(1).param{1} = strcmp(response.keys(which_train & ~no_response), 'left')'; % whether subject pressed "sick", for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        

            % const @ outcome / feedback onset (trials 1..20)
            % 
            multi.names{2} = 'feedback';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train & ~no_response))';
            multi.durations{2} = zeros(size(contextRole(which_train & ~no_response)));
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train & ~no_response))';
            multi.durations{3} = zeros(size(contextRole(which_train & ~no_response)));
       
            
        % Blocked M2 & M1 posterior pmods @ outcome
        %
        case 22
            % M2 (modulatory) & M1 (irrelevant) posteriors @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = strcat('M2_posterior_', condition);
            multi.pmod(1).param{1} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        

            multi.pmod(1).name{2} = strcat('M1_posterior_', condition);
            multi.pmod(1).param{2} = P(:,1)'; % entropy of P(M1 | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{2} = 1; % first order
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % Blocked M3 & M1 posterior pmods @ outcome
        %
        case 23
            % M3 (additive) & M1 (irrelevant) posteriors @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = strcat('M3_posterior_', condition);
            multi.pmod(1).param{1} = P(:,3)'; % posterior P(M3 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        

            multi.pmod(1).name{2} = strcat('M1_posterior_', condition);
            multi.pmod(1).param{2} = P(:,1)'; % entropy of P(M1 | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{2} = 1; % first order
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % Blocked M3 & M2 posterior pmods @ outcome
        %
        case 24
            % M3 (additive) & M2 (modulatory) posteriors @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = strcat('M3_posterior_', condition);
            multi.pmod(1).param{1} = P(:,3)'; % posterior P(M3 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        

            multi.pmod(1).name{2} = strcat('M2_posterior_', condition);
            multi.pmod(1).param{2} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20, excluding M4
            multi.pmod(1).poly{2} = 1; % first order
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % Expected outcome @ RT
        % Actual outcome @ feedback
        %
        case 25
            % Expected outcome @ RT
            %
            multi.names{1} = 'expected_outcome';
            RTs = actualChoiceOffset(which_train);
            feedback_time = actualFeedbackOnset(which_train);
            % for the TIMEOUTs, use the time 1 second before feedback (i.e.
            % ISI onset)
            %
            RTs(strcmp(RTs, '')) = cellfun(@num2str, num2cell(cellfun(@str2num, feedback_time(strcmp(RTs, ''))) - 1), 'uniformoutput', 0);
            multi.onsets{1} = cellfun(@str2num,RTs)';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'expected';
            multi.pmod(1).param{1} = values'; % expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  

            % Actual outcome @ feedback
            %
            multi.names{2} = 'actual_outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'actual';
            multi.pmod(2).param{1} = r'; % outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order  
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{3} = zeros(size(contextRole(which_train)));
            
        % Prediction error @ feedback
        %
        case 26
            % Prediction error @ feedback
            %
            multi.names{1} = 'prediction_error';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'actual';
            multi.pmod(1).param{1} = r' - values'; % outcome - expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % M2 posterior pmod @ outcome
        %
        case 27 % <------------- GOOD
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
            
            

        % context role @ trial onset
        % WRONG! cannot have 2 params with the same onset!
        %
        case 28
            % context role @ trial onset
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            % const @ trial onset
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % context role @ trial onset, no separate trial_onset regressor
        % (almost same as 28)
        %
        case 29
            % context role @ trial onset
            % 
            multi.names{1} = condition;
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));            
            
            
        % --------------- PREDICTED VALUES, multiple models ------------
            
            
        % M1, M2 & M3 value pmod s @ trial onset (before updated)
        % WRONG -- duplicate onsets...
        %
        case 30
            % M1 (irrelevant), M2 (modulatory) & M3 (additive) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M1_value';
            multi.pmod(1).param{1} = valuess(:,1)'; % values predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            multi.pmod(1).name{2} = 'M2_value';
            multi.pmod(1).param{2} = valuess(:,2)'; % values predicted by M2 for trials 1..20
            multi.pmod(1).poly{2} = 1; % first order
            
            multi.pmod(1).name{3} = 'M3_value';
            multi.pmod(1).param{3} = valuess(:,3)'; % values predicted by M3 for trials 1..20
            multi.pmod(1).poly{3} = 1; % first order        

            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M1, M2 & M3 value pmods @ trial onset
        % without the separate trial_onset regressor
        % (almost same as 30)
        %
        case 31
            % M1 (irrelevant), M2 (modulatory) & M3 (additive) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M1_value';
            multi.pmod(1).param{1} = valuess(:,1)'; % values predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            multi.pmod(1).name{2} = 'M2_value';
            multi.pmod(1).param{2} = valuess(:,2)'; % values predicted by M2 for trials 1..20
            multi.pmod(1).poly{2} = 1; % first order
            
            multi.pmod(1).name{3} = 'M3_value';
            multi.pmod(1).param{3} = valuess(:,3)'; % values predicted by M3 for trials 1..20
            multi.pmod(1).poly{3} = 1; % first order        

        % M1, M2 & M3 value pmods @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % WRONG -- duplicate onsets...
        %
        case 32
            % M1 (irrelevant), M2 (modulatory) & M3 (additive) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M1_value';
            multi.pmod(1).param{1} = valuess(:,1)'; % values predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            multi.pmod(1).name{2} = 'M2_value';
            multi.pmod(1).param{2} = valuess(:,2)'; % values predicted by M2 for trials 1..20
            multi.pmod(1).poly{2} = 1; % first order
            
            multi.pmod(1).name{3} = 'M3_value';
            multi.pmod(1).param{3} = valuess(:,3)'; % values predicted by M3 for trials 1..20
            multi.pmod(1).poly{3} = 1; % first order        
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - values'; % PE = outcome - expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order  

            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{3} = zeros(size(contextRole(which_train)));

        % M1, M2 & M3 value pmods @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 32; also look a 30/31)
        %
        case 33
            % M1 (irrelevant), M2 (modulatory) & M3 (additive) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M1_value';
            multi.pmod(1).param{1} = valuess(:,1)'; % values predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            multi.pmod(1).name{2} = 'M2_value';
            multi.pmod(1).param{2} = valuess(:,2)'; % values predicted by M2 for trials 1..20
            multi.pmod(1).poly{2} = 1; % first order
            
            multi.pmod(1).name{3} = 'M3_value';
            multi.pmod(1).param{3} = valuess(:,3)'; % values predicted by M3 for trials 1..20
            multi.pmod(1).poly{3} = 1; % first order        
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - values'; % PE = outcome - expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order      
            
         
        % ---------------- PREDICTED VALUES + PREDICTION ERRORS, single model ----------------
            
            
        % M1 value pmod @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % WRONG -- duplicate onsets...
        %
        case 34
            % M1 (irrelevant) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M1_value';
            multi.pmod(1).param{1} = valuess(:,1)'; % values predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - valuess(:,1)'; % PE = outcome - expected outcome by M1 for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order      
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{3} = zeros(size(contextRole(which_train)));

        % M2 value pmod @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % WRONG -- duplicate onsets...
        %
        case 35
            % M2 (modulatory) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M2_value';
            multi.pmod(1).param{1} = valuess(:,2)'; % values predicted by M2 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - valuess(:,2)'; % PE = outcome - expected outcome by M2 for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order      
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{3} = zeros(size(contextRole(which_train)));

        % M3 value pmod @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % WRONG -- duplicate onsets...
        %
        case 36
            % M3 (additive) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M3_value';
            multi.pmod(1).param{1} = valuess(:,3)'; % values predicted by M3 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - valuess(:,3)'; % PE = outcome - expected outcome by M3 for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order      
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{3} = zeros(size(contextRole(which_train)));

            
        % M1 value pmod @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 34)
        %
        case 37
            % M1 (irrelevant) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M1_value';
            multi.pmod(1).param{1} = valuess(:,1)'; % values predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - valuess(:,1)'; % PE = outcome - expected outcome by M1 for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order      

        % M2 value pmod @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 35)
        %
        case 38
            % M2 (modulatory) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M2_value';
            multi.pmod(1).param{1} = valuess(:,2)'; % values predicted by M2 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - valuess(:,2)'; % PE = outcome - expected outcome by M2 for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order      

        % M3 value pmod @ trial onset (before updated)
        % + PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 36)
        %
        case 39
            % M3 (additive) predicted values @ trial onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M3_value';
            multi.pmod(1).param{1} = valuess(:,3)'; % values predicted by M3 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            % Prediction error @ feedback
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - valuess(:,3)'; % PE = outcome - expected outcome by M3 for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order   
            
            
        % --------------- LIKELIHOODS ---------------------
            
        
        % M1, M2 & M3 likelihood pmods @ feedback (outcome) onset (before updated)
        %
        case 40
            % M1 (irrelevant), M2 (modulatory) & M3 (additive) outcome likelihood @ feedback (outcome) onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M1_lik';
            multi.pmod(1).param{1} = likelihoods(:,1)'; % outcome likelihoods predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            multi.pmod(1).name{2} = 'M2_lik';
            multi.pmod(1).param{2} = likelihoods(:,2)'; % outcome likelihoods predicted by M2 for trials 1..20
            multi.pmod(1).poly{2} = 1; % first order
            
            multi.pmod(1).name{3} = 'M3_lik';
            multi.pmod(1).param{3} = likelihoods(:,3)'; % outcome likelihoods predicted by M3 for trials 1..20
            multi.pmod(1).poly{3} = 1; % first order        

            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % M1, M2 & M3 likelihood pmods @ feedback (outcome) onset (before updated)
        % without the separate trial_onset regressor
        % (almost same as 40)
        %
        case 41
            % M1 (irrelevant), M2 (modulatory) & M3 (additive) outcome likelihood @ feedback (outcome) onset (trials 1..20)
            % 
            multi.names{1} = 'trial';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.orth{1} = 0; % do NOT orthogonalize them!
            
            multi.pmod(1).name{1} = 'M1_lik';
            multi.pmod(1).param{1} = likelihoods(:,1)'; % outcome likelihoods predicted by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order
            
            multi.pmod(1).name{2} = 'M2_lik';
            multi.pmod(1).param{2} = likelihoods(:,2)'; % outcome likelihoods predicted by M2 for trials 1..20
            multi.pmod(1).poly{2} = 1; % first order
            
            multi.pmod(1).name{3} = 'M3_lik';
            multi.pmod(1).param{3} = likelihoods(:,3)'; % outcome likelihoods predicted by M3 for trials 1..20
            multi.pmod(1).poly{3} = 1; % first order        
            
        
        % --------------- PREDICTION ERRORS, multi-model ----------------
        

        % PE @ feedback (outcome) onset
        % (also look at 32, 30/31)
        %
        case 42
            % Prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - values'; % PE = outcome - expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  

            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 42; also look a 33, 32, 30/31)
        %
        case 43
            % Prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - values'; % PE = outcome - expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order      
            
            
                
        % ----------- PREDICTION ERRORS, single model ---------------    
           
        
        
        % M1 only PE @ feedback (outcome) onset
        %
        case 44
            % M1 prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - valuess(:,1)'; % PE = outcome - expected outcome by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order      
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M2 only PE @ feedback (outcome) onset
        %
        case 45
            % M2 prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - valuess(:,2)'; % PE = outcome - expected outcome by M2 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order      
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M3 only PE @ feedback (outcome) onset
        %
        case 46
            % M3 prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - valuess(:,3)'; % PE = outcome - expected outcome by M3 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order      
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % M1 only PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 44)
        %
        case 47
            % M1 prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - valuess(:,1)'; % PE = outcome - expected outcome by M1 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order      

        % M2 only PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 45)
        %
        case 48
            % M2 prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - valuess(:,2)'; % PE = outcome - expected outcome by M2 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order      

        % M3 only PE @ feedback (outcome) onset
        % without the separate trial_onset regressor
        % (almost same as 46)
        %
        case 49
            % M3 prediction error @ feedback
            %
            multi.names{1} = 'outcome';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'prediction_error';
            multi.pmod(1).param{1} = r' - valuess(:,3)'; % PE = outcome - expected outcome by M3 for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order      
            
        % Value (expected outcome) @ trial onset
        % Prediction error @ feedback (outcome) onset
        %
        case 50
            % Value (expected outcome) @ trial onset
            %
            multi.names{1} = 'stimulus';
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'value';
            multi.pmod(1).param{1} = values'; % expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  

            % Prediction error @ feedback (outcome) onset
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - values'; % outcome - expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order  
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{3} = 'trial_onset';
            multi.onsets{3} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{3} = zeros(size(contextRole(which_train)));
            
        % Value (expected outcome) @ trial onset
        % Prediction error @ feedback (outcome) onset
        % w/o the visual stimulus regressor
        % (almost same as 50)
        %
        case 51
            % Value (expected outcome) @ trial onset
            %
            multi.names{1} = 'stimulus';
            multi.onsets{1} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'value';
            multi.pmod(1).param{1} = values'; % expected outcome for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order  

            % Prediction error @ feedback (outcome) onset
            %
            multi.names{2} = 'outcome';
            multi.onsets{2} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).name{1} = 'prediction_error';
            multi.pmod(2).param{1} = r' - values'; % outcome - expected outcome for trials 1..20
            multi.pmod(2).poly{1} = 1; % first order  
            
        % M3 posterior - M2 posterior pmod @ outcome
        %
        case 52
            % M3 - M2 posterior @ feedback / outcome onset (trials 1..20)
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'M3_minus_M2_posterior';
            multi.pmod(1).param{1} = P(:,3)' - P(:,2)';
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % Bayesian surprise = Kullback?Leibler divergence @ feedback
        % (outcome) onset
        % https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence
        %
        case 53
            % Q(t,:) = prior distribution over causal structures (models)
            % at trial t (i.e. before update)
            % P(t,:) = posterior (i.e. after update)
            % Note that Q(t+1,:) = P(t,:)
            % surprise(t) = D_KL(P(t,:) || Q(t,:)) = sum P(t,i) log( P(t,i) / Q(t,i) )
            % 
            priors = which_models / sum(which_models);
            Q = [priors; P(1:end-1,:)];
            logs = log(P ./ Q); 
            logs(isnan(logs)) = 0; % lim_{x->0} x log(x) = 0
            surprise = sum(P .* logs, 2);
            surprise(isnan(surprise)) = 0; % weird things happen when P --> 0 TODO FIXME
            
            multi.names{1} = 'feedback';
            multi.onsets{1} = cellfun(@str2num,actualFeedbackOnset(which_train))';
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).name{1} = 'surprise';
            multi.pmod(1).param{1} = surprise';
            multi.pmod(1).poly{1} = 1; % first order        
            
            % const @ trial onset (trials 1..20)
            % 
            multi.names{2} = 'trial_onset';
            multi.onsets{2} = cellfun(@str2num, actualChoiceOnset(which_train))';
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
        % One regressor for each trial onset (for classifier)
        % http://ufldl.stanford.edu/tutorial/supervised/ExerciseConvolutionalNeuralNetwork/
        % 
        %
        case 54
            trial_onsets = actualChoiceOnset(which_train);
            for t=1:20
                multi.names{t} = ['trial_onset_', num2str(t)];
                multi.onsets{t} = [str2double(trial_onsets(t))];
                multi.durations{t} = [0];
            end            
    end

end 
            

