function analyze_gui2

    % These are held constant
    %
    global all_subjects; % the unique id's of all subjects
    global participant; % the participant column from the data (for all rows)
    global make_optimal_choices;
    
    global analyze_with_gui; % so analyze.m knows not to do certain things

    % We change these
    %
    global which_subjects; % which rows correspond to the subjects we've selected for analysis
    global subjects; % the unique id's of subjects we've selected for analysis (computed)
    global which_rows; % which rows of the data we've selected for analysis (computed)

    % TODO dedupe with analyze.m; also we only use the participant column
    %
    format = '%s %s %s %d %s %s %s %d %d %s %s %s %f %d %s %s %d %d %d';
    [participant, session, mriMode, isPractice, restaurantsReshuffled, foodsReshuffled, contextRole, contextId, cueId, sick, corrAns, response.keys, response.rt, response.corr, restaurant, food, isTrain, roundId, trialId] = ...
        textread('pilot-with-hayley.csv', format, 'delimiter', ',', 'headerlines', 1);
    analyze_with_gui = true;
    make_optimal_choices = true;

    all_subjects = unique(participant)';    
    which_subjects = logical(true(size(participant))); % all subjects initially
    update_invariant;

    f = figure;

    % Check boxes for picking which subjects we're showing
    %
    checkboxes = {};
    idx = 1;
    for who = all_subjects
        checkboxes{idx} = uicontrol(f, 'Style', 'checkbox', 'String', who, ... % should be 'who' -- we use that in the callback
                          'Value', 1, 'Position', [10 10 + 20 * (idx - 1) 130 20], ...
                          'Callback', @participant_checkbox_callback);
        idx = idx + 1;
    end
    
    % Whether to make optimal choices
    %
    optimal_radiobutton_group = uibuttongroup(f,'Title','Optimal Choices',...
            'Units','pixels', 'Position',[10 10 + 20 * idx 100 60]);
    optimal_radiobutton_yes = uicontrol(optimal_radiobutton_group,'Style','radiobutton','String','Yes',...
            'Units','pixels', 'Position',[10 30 50 10], ...
            'Callback', @optimal_callback);
    optimal_radiobutton_no = uicontrol(optimal_radiobutton_group,'Style','radiobutton','String','No',...
            'Units','pixels', 'Position',[10 10 50 10], ...
            'Callback', @optimal_callback);

    % The Run button
    %
    run_button = uicontrol('Style', 'pushbutton', 'String', 'Run', ...
                           'Position', [100 10 70 20], ...
                           'Callback', @run_button_callback);

% Call this every time something changes
%
function update_invariant
    global participant;
    global which_subjects;
    global subjects;
    global which_rows;
    
    which_rows = which_subjects;
    subjects = unique(participant(which_rows))';
    disp(subjects);
    
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
    
% Re-render the analysis with the selected options
%
function run_button_callback(hObject, eventdata, handles)
    global analyze_with_gui;
    global subjects;
    global which_rows;
    global make_optimal_choices;
    
    % Only what is "global" here will be declared for the stuff in analyze
    % it's like you're copy-pasting the code here/
    % So you need to declare all the stuff you need as global here
    %
    analyze;

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
