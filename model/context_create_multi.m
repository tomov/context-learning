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
    
    subjects = {'con001', 'con002'}; % TODO don't hardcode them
    subjdirs = {'161030_con001', '161030_con002'};
    %assert(isequal(subjects',unique(participant)));
    
    % GLM 1 => 
    % GLM 2 => 
    %
    assert(glmodel == 1 || glmodel == 2);
    
    % pick the trials that correspond to that subject & run
    %
    which_train = isTrain & strcmp(participant, subjects{subj}) & roundId == run;
    which_test = ~isTrain & strcmp(participant, subjects{subj}) & roundId == run;
    
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
    [choices, P_n, ww_n, P, ww] = train(x, c, r, learning_rate, softmax_temp, false);    
    
    % Run model on test trials
    %
    test_cues = cueId(which_test);
    test_N = length(test_cues); % # of trials
    D = 3; % # of stimuli
    test_x = zeros(test_N, D);
    test_x(sub2ind(size(test_x), 1:test_N, test_cues' + 1)) = 1;
    test_c = contextId(which_test) + 1;
    [test_choices] = test(test_x, test_c, P_n, ww_n, softmax_temp);

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
            % Event 1: feedback
            %
            % name = condition == context role
            % onsets = feedback onset
            % durations = 0 s
            % 
            multi.names{1} = condition;
            multi.onsets{1} = actualFeedbackOnset(which_train);
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            % Event 2: Stimulus
            %
            % name = stim_onset
            % onsets = stimulus onset
            % durations = 0 s
            % 
            multi.names{2} = 'stim_onset';
            multi.onsets{2} = actualChoiceOnset(which_train);
            multi.durations{2} = zeros(size(contextRole(which_train)));

        % Regress with M2 posterior (feedback onset)
        % and expected outcome (stimulus onset)
        %
        case 2
            % Event 1: feedback
            %
            % onsets = feedback onset
            % durations = 0 s
            % 
            multi.names{1} = 'feedback';
            multi.onsets{1} = actualFeedbackOnset(which_train);
            multi.durations{1} = zeros(size(contextRole(which_train)));
            
            multi.pmod(1).names{1} = 'M2_posterior';
            multi.pmod(1).param{1} = P(:,2)'; % posterior P(M2 | h_1:n) for trials 1..20
            multi.pmod(1).poly{1} = 1; % first order        
            
            % Event 2: stimulus onset (training)
            %
            % onsets = stimulus onset (after choice & ISI)
            % durations = 0 s
            % 
            multi.names{2} = 'stim_onset';
            multi.onsets{2} = actualChoiceOnset(which_train);
            multi.durations{2} = zeros(size(contextRole(which_train)));
            
            multi.pmod(2).names{1} = 'expected_outcome';
            multi.pmod(2).param{1} = choices; % expected outcome for trials 1..20
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
            test_actualChoiceOnsets = actualChoiceOnset(which_test);
            for i=1:4
                multi.names{2 + i} = sprintf('test_%s_x%dc%d', condition, test_cueIds(i) + 1, test_contextIds(i) + 1);
                multi.onsets{2 + i} = test_actualChoiceOnsets(i);
                multi.durations{2 + i} = 0;
            end
    end

end