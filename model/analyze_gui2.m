function analyze_gui2

    % These are held constant
    %
    global all_subjects; % the unique id's of all subjects
    global participant; % the participant column from the data (for all rows)
    
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

    all_subjects = unique(participant)';    
    which_subjects = logical(true(size(participant))); % all subjects initially
    update_invariant;

    f = figure;

    checkboxes = {};
    idx = 1;
    for who = all_subjects
        checkboxes{idx} = uicontrol(f, 'Style', 'checkbox', 'String', who, ... % should be 'who' -- we use that in the callback
                          'Value', 1, 'Position', [10 10 + 20 * (idx - 1) 130 20], ...
                          'Callback', @participant_checkbox_callback);
        idx = idx + 1;
    end
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

% Re-render the analysis with the selected options
%
function run_button_callback(hObject, eventdata, handles)
    global analyze_with_gui;
    global subjects;
    global which_rows;
    
    % Only what is "global" here will be declared for the stuff in analyze
    % it's like you're copy-pasting the code here
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
