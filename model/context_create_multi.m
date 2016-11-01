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
    assert(isequal(subjects',unique(participant)));
    
    assert(glmodel == 1); % GLM == 1
    
    which_rows = isTrain & strcmp(participant, subjects{subj}) & roundId == run;
    
    multi.names{1} = contextRole(which_rows);
    multi.onsets{1} = actualFeedbackOnset(which_rows);
    multi.durations{1} = ones(size(contextRole(which_rows)));

end