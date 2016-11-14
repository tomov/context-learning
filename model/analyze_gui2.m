function analyze_gui2

    % These are held constant
    %
    global all_subjects; % the unique id's of all subjects
    global all_contextRoles; % all unique contextRoles
    global participant; % the participant column from the data (for all rows)
    global contextRole; % the contextRole column from the data (for all rows)
    global roundId; % the roundId column from the data (for all rows)
    
    global make_optimal_choices;
    global roundsPerContext;
    global trialsPerRound;
    global inv_softmax_temp;
    global prior_variance;
    global what_to_plot;
    
    global analyze_with_gui; % so analyze.m knows not to do certain things

    % We change these
    %
    global which_subjects; % which rows correspond to the subjects we've selected for analysis
    global which_conditions; % which rows correspond to the conditions we've selected for analysis
    global which_runs; % which rows correspond to the runs we've selected for analysis
    global which_rows; % which rows of the data we've selected for analysis (computed)
    
    global subjects; % the unique id's of subjects we've selected for analysis (computed)
    global contextRoles; % the unique contextRoles we've selected for analysis (computed)
    
    % Initialize the state
    % IMPORTANT -- run this before load.m so it knows we're using the GUI
    %
    analyze_with_gui = true;
    make_optimal_choices = false;
    prior_variance = 0.2574;
    inv_softmax_temp = 2.0309;
    what_to_plot = 'analyze';

    % Load the data and some constants
    %
    load_data;
    
    all_subjects = unique(participant)';  
    all_contextRoles = {'irrelevant', 'modulatory', 'additive'}; % should be == unique(contextRole)'; listing explicitly here to preserve the order
    which_subjects = logical(true(size(participant))); % all subjects initially
    which_conditions = logical(true(size(contextRole))); % all conditions initially
    which_runs = logical(true(size(roundId))); % all runs initially
    contextRoles = unique(contextRole(which_conditions))'; % all; initially should be == {'irrelevant', 'modulatory', 'additive'}
    update_invariant;

    f = figure;

    % Check boxes for picking which subjects we're showing
    %
    subject_checkboxes = {};
    idx = 1;
    for who = all_subjects
        subject_checkboxes{idx} = uicontrol(f, 'Style', 'checkbox', 'String', who, ... % should be 'who' -- we use that in the callback
                          'Value', 1, 'Position', [10 10 + 20 * (idx - 1) 130 20], ...
                          'Callback', @participant_checkbox_callback);
        idx = idx + 1;
    end
    
    % Whether to make optimal choices. First one is picked by default
    %
    optimal_radiobutton_group = uibuttongroup(f,'Title','Optimal',...
            'Units','pixels', 'Position',[10 10 + 20 * idx 60 60]);
    optimal_radiobutton_no = uicontrol(optimal_radiobutton_group,'Style','radiobutton','String','No',...
            'Units','pixels', 'Position',[10 10 50 10], ...
            'Callback', @optimal_callback);
    optimal_radiobutton_yes = uicontrol(optimal_radiobutton_group,'Style','radiobutton','String','Yes',...
            'Units','pixels', 'Position',[10 30 50 10], ...
            'Callback', @optimal_callback);

    % Check boxes for picking which conditions
    %
    condition_checkboxes = {};
    for condition = contextRoles
        condition_checkboxes{idx} = uicontrol(f, 'Style', 'checkbox', 'String', condition, ... % should be 'who' -- we use that in the callback
                          'Value', 1, 'Position', [10 100 + 20 * (idx - 1) 130 20], ...
                          'Callback', @condition_checkbox_callback);
        idx = idx + 1;
    end        

    % Check boxes for picking which conditions
    %
    run_checkboxes = {};
    for run = 3:-1:1
        run_checkboxes{idx} = uicontrol(f, 'Style', 'checkbox', 'String', strcat('Context run #', int2str(run)), ... % should be 'who' -- we use that in the callback
                          'Value', 1, 'Position', [10 100 + 20 * (idx - 1) 130 20], ...
                          'UserData', run, ...
                          'Callback', @run_checkbox_callback);
        idx = idx + 1;
    end
    
    % Numeric parameter constants
    %
    prior_variance_caption = uicontrol(f, 'Style', 'text', 'String', 'Prior variance', ...
                         'Position', [0 100 + 20 * (idx - 1) 90 20]);
    prior_variance_editbox = uicontrol(f, 'Style', 'edit', 'String', num2str(prior_variance), ...
                         'Tag', 'prior_variance_editbox', 'Position', [90 100 + 20 * (idx - 1) 40 20]);
    idx = idx + 1;

    inv_softmax_temp_caption = uicontrol(f, 'Style', 'text', 'String', 'Inv softmax temp', ...
                         'Position', [0 100 + 20 * (idx - 1) 90 20]);
    inv_softmax_temp_editbox = uicontrol(f, 'Style', 'edit', 'String', num2str(inv_softmax_temp), ...
                         'Tag', 'inv_softmax_temp_editbox', 'Position', [90 100 + 20 * (idx - 1) 40 20]);
    idx = idx + 1;

    % What to plot
    %
    plot_radiobutton_group = uibuttongroup(f,'Title','Plot',...
            'Units','pixels', 'Position',[10 90 + 20 * idx 100 60]);
    plot_radiobutton_analyze = uicontrol(plot_radiobutton_group,'Style','radiobutton','String','Analysis',...
            'Units','pixels', 'Position',[10 10 80 10], ...
            'Callback', @plot_callback);
    plot_radiobutton_sanity = uicontrol(plot_radiobutton_group,'Style','radiobutton','String','Sanity',...
            'Units','pixels', 'Position',[10 30 80 10], ...
            'Callback', @plot_callback);

    
    
    % The Run button
    %
    rerun_button = uicontrol('Style', 'pushbutton', 'String', 'Run', ...
                             'Position', [100 10 70 20], ...
                             'Callback', @run_button_callback);

                         
% Call this every time something changes
%
function update_invariant
    global participant;
    global contextRole;
    global all_contextRoles;
    
    global which_subjects;
    global which_conditions;
    global which_runs;
    
    global which_rows;
    global subjects;
    global contextRoles;
    
    which_rows = which_subjects & which_conditions & which_runs;
    subjects = unique(participant(which_rows))';
    contextRoles = unique(contextRole(which_conditions))';
    if length(contextRoles) == length(all_contextRoles)
        contextRoles = all_contextRoles; % so they're in the right order
    end
    disp(subjects);
    disp(contextRoles);
    
    
% Pick whether to make optimal choices
%
function optimal_callback(hObject, eventdata, handles)
    global make_optimal_choices
    
    choice = get(hObject, 'String');
    if strcmp(choice, 'Yes')
        make_optimal_choices = true;
    else
        assert(strcmp(choice, 'No'));
        make_optimal_choices = false;
    end
    disp(make_optimal_choices);
    
% Pick what to plot
%
function plot_callback(hObject, eventdata, handles)
    global what_to_plot
    
    choice = get(hObject, 'String');
    if strcmp(choice, 'Analysis')
        what_to_plot = 'analyze';
    else
        assert(strcmp(choice, 'Sanity'));
        what_to_plot = 'sanity'
    end
    disp(what_to_plot);
    
        
% Re-render the analysis with the selected options
%
function run_button_callback(hObject, eventdata, handles)
    global analyze_with_gui;
    global subjects;
    global which_rows;
    global make_optimal_choices;
    global contextRoles;    
    global inv_softmax_temp;
    global prior_variance;
    global what_to_plot;
    
    inv_softmax_temp = str2double(get(findobj('Tag', 'inv_softmax_temp_editbox'), 'String'))
    prior_variance = str2double(get(findobj('Tag', 'prior_variance_editbox'), 'String'))
    
    % Only what is "global" here will be declared for the stuff in analyze
    % it's like you're copy-pasting the code here/
    % So you need to declare all the stuff you need as global here
    %
    if strcmp(what_to_plot, 'analyze')
        analyze;
    else
        assert(strcmp(what_to_plot, 'sanity'));
        sanity;
    end

    
% Select or remove a condition (context role) for the analysis   
%
function condition_checkbox_callback(hObject, eventdata, handles)
    global contextRole;
    global which_conditions;

    condition = get(hObject, 'String');
    do_include = get(hObject, 'Value');
    if do_include
        which_conditions = which_conditions | strcmp(contextRole, condition);
    else
        which_conditions = which_conditions & ~strcmp(contextRole, condition);
    end

    update_invariant;

    
% Select or remove a subject for the analysis   
%
function participant_checkbox_callback(hObject, eventdata, handles)
    global participant;
    global which_subjects;

    subject = get(hObject, 'String');
    do_include = get(hObject, 'Value');
    if do_include
        which_subjects = which_subjects | strcmp(participant, subject);
    else
        which_subjects = which_subjects & ~strcmp(participant, subject);
    end

    update_invariant;

    
% Select or remove a run for the analysis   
%
function run_checkbox_callback(hObject, eventdata, handles)
    global all_contextRoles;
    global roundId;
    global contextRole;
    global which_runs;
    global trialsPerRound;
    global roundsPerContext;
    
    selected_rows = logical(false(size(roundId)));
    
    ith_round = get(hObject, 'UserData'); % 1st, 2nd, or 3rd r of each condition
    first_trial_of_each_round = 1:trialsPerRound:length(contextRole);
    disp(first_trial_of_each_round)
    for condition = all_contextRoles
        % find the first trial in each round for that condition (across all
        % subjects)
        %
        first_trials_of_rounds_in_condition = first_trial_of_each_round( ...
            ismember(contextRole(first_trial_of_each_round), condition));
        
        disp(first_trials_of_rounds_in_condition);
        for start = first_trials_of_rounds_in_condition(ith_round:roundsPerContext:end)
            % mark the rows corresponding to this run
            %ith
            disp(start);
            selected_rows(start:start + trialsPerRound - 1) = true;
        end
    end
    assert(mod(sum(selected_rows), trialsPerRound) == 0); 
    
    do_include = get(hObject, 'Value');
    if do_include
        which_runs = which_runs | selected_rows;
    else
        which_runs = which_runs & ~selected_rows;
    end

    update_invariant;