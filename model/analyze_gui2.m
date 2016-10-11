function analyze_gui2

    % These are held constant
    %
    global all_subjects; % the unique id's of all subjects
    global participant; % the participant column for all rows in the data
    
    % We change these
    %
    global which_subjects; % which rows correspond to the subjects we've selected for analysis
    global subjects; % the unique id's of subjects we've selected for analysis (computed)
    global which_rows; % which rows of the data we've selected for analysis (computed)

    format = '%s %s %s %d %s %s %s %d %d %s %s %s %f %d %s %s %d %d %d';

    [participant, session, mriMode, isPractice, restaurantsReshuffled, foodsReshuffled, contextRole, contextId, cueId, sick, corrAns, response.keys, response.rt, response.corr, restaurant, food, isTrain, roundId, trialId] = ...
        textread('pilot-with-hayley.csv', format, 'delimiter', ',', 'headerlines', 1);

    all_subjects = unique(participant)';    
    which_subjects = logical(true(size(participant)));
        
    f = figure;

    c = {};
    idx = 1;
    for who = all_subjects
        c{idx} = uicontrol(f, 'Style', 'checkbox', 'String', who, ... % should be 'who' -- we use that in the callback
                          'Value', 1, 'Position', [10 10 + 20 * (idx - 1) 130 20], ...
                          'Callback', @participant_checkbox_callback);
        idx = idx + 1;
    end
    %b = uicontrol('Style','pushbutton','Callback',@pushbutton_callback);

    % call this every time something changes
    %
    function update_invariant
        which_rows = which_subjects;
        subjects = unique(participant(which_rows))';
        disp(subjects);
    end    
    
    function participant_checkbox_callback(hObject, eventdata, handles)
        subject = get(hObject, 'String');
        do_include = get(hObject, 'Value');
        if do_include
            which_subjects = which_subjects | strcmp(participant, subject);
        else
            which_subjects = which_subjects & ~strcmp(participant, subject);
        end
        
        update_invariant;
    end

    
end