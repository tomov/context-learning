% generate scp commands to get the relevant data files based on the output
% of classify.m
%
% This is classifying condition based on training trials [1..18 20] and
% testing on trial 19 (all runs)
%

folder = 'classify_outputs_3';

% this is for Sam's second suggestion
%mat_folder = 'classify_context_heldout_20';
%jobs = [86775784, 86775786, 86775787, 86775788, 86775789, 86775790, 86775791]; % classify2('...', 'contextId', [1:15 21:23], 1:9, [16:20 24:24], 1:9)
%jobs = [86775841, 86775842, 86775843, 86775844, 86775845, 86775846, 86775847]; % classify2('...', 'contextId_training_only', [1:15], 1:9, [16:20], 1:9)
%jobs = [86775908,86775909,86775910,86775911,86775912,86775913,86775914]; % classify2('mask.nii', 'contextId_training_only', [1:19], 1:9, [20:20], 1:9
%masks = {'hippocampus', 'ofc', 'striatum', 'vmpfc', 'rlpfc', 'bg', 'pallidum'};


% these is for Sam's first suggestion; classifying condition based on training trials & 1 held out trial
%mat_folder = 'classify_heldout_trial_18';
jobss = {};
jobss{1} = [86987048, 86987049, 86987051, 86987053, 86987056, 86987058, 86987060]; % hold out trial 1
jobss{2} = [86987026, 86987027, 86987028, 86987029, 86987030, 86987031, 86987032]; % hold out trial 2
jobss{3} = [86987002, 86987003, 86987004, 86987005, 86987006, 86987007, 86987011]; % hold out trial 3
jobss{4} = [86986952, 86986953, 86986954, 86986955, 86986956, 86986957, 86986966]; % hold out trial 4
jobss{5} = [86986917, 86986918, 86986919, 86986920, 86986921, 86986922, 86986923]; % hold out trial 5
jobss{6} = [86986619, 86986620, 86986621, 86986622, 86986623, 86986624, 86986625]; % hold out trial 6
jobss{7} = [86986577, 86986579, 86986590, 86986593, 86986595, 86986596, 86986597]; % hold out trial 7
jobss{8} = [86986517, 86986520, 86986523, 86986525, 86986527, 86986529, 86986531]; % hold out trial 8
jobss{9} = [86985801, 86985809, 86985811, 86985812, 86985813, 86985814, 86985815]; % hold out trial 9
jobss{10} = [86985777, 86985778, 86985779, 86985780, 86985781, 86985782, 86985784]; % hold out trial 10
jobss{11} = [86985728, 86985729, 86985739, 86985741, 86985749, 86985757, 86985758]; % hold out trial 11
jobss{12} = [86985683, 86985688, 86985697, 86985699, 86985701, 86985703, 86985705]; % hold out trial 12
jobss{13} = [86985627, 86985629, 86985631, 86985632, 86985634, 86985636, 86985638]; % hold out trial 13
jobss{14} = [86985585, 86985586, 86985587, 86985588, 86985589, 86985590, 86985591]; % hold out trial 14
jobss{15} = [86985565, 86985566, 86985567, 86985568, 86985569, 86985570, 86985571]; % hold out trial 15
jobss{16} = [86985224, 86985225, 86985228, 86985231, 86985233, 86985236, 86985238]; % hold out trial 16
jobss{17} = [86985122, 86985129, 86985132, 86985134, 86985136, 86985138, 86985141]; % hold out trial 17
jobss{18} = [86846107, 86846108, 86846109, 86846110, 86846111, 86846112, 86846113]; % hold out trial 18
jobss{19} = [86846035, 86846036, 86846037, 86846038, 86846039, 86846040, 86846041]; % hold out trial 19
jobss{20} = [86845655, 86845657, 86845658, 86845660, 86845661, 86845663, 86845664]; % hold out trial 20
masks = {'hippocampus', 'ofc', 'striatum', 'vmpfc', 'rlpfc', 'bg', 'pallidum'};


scp_from = 'mtomov13@ncfws13.rc.fas.harvard.edu:/net/rcss11/srv/export/ncf_gershman/share_root/Lab/scripts/matlab/ConLearn/';
scps = {};

train_files = {};
test_files = {};

%figure;

for held_out_trial_which_jobs = 1:length(jobss)
    jobs = jobss{held_out_trial_which_jobs};
    mat_folder = ['classify_heldout_trial_', num2str(held_out_trial_which_jobs)];

    fprintf('\n\n\n ------- HELD OUT TRIAL %d ------\n\n\n', held_out_trial_which_jobs);
    for classifier = 1:size(jobs, 1)
    %    subplot(2, 3, class);

        for i = 1:length(jobs(classifier,:))
            job = jobs(classifier, i);
            filename = fullfile('classify_outputs_3', ['classify_', num2str(job), '_output.out']);
            disp(filename)

            fid = fopen(filename);
            tline = fgetl(fid);
            in_test_phase = false;
            train_acc = NaN;
            test_acc = NaN;
            lambda = NaN;
            fitObj_filename = []; % classify_train_blabla.mat
            test_results_filename = []; % classify_test_blabla.mat
            while ischar(tline)
                %disp(tline)
                if startsWith(tline, 'classify_test')
                    in_test_phase = true;
                end
                % get success rates
                if startsWith(tline, 'Success rate')
                    x = strsplit(tline, ' ');
                    if ~in_test_phase
                        lambda = x{5}(1:end-1);
                        train_acc = x{7}(1:end-1);
                    else
                        test_lambda = x{5}(1:end-1);
                        assert(strcmp(test_lambda, lambda));
                        test_acc = x{7}(1:end-1);
                    end
                end
                % get .mat filenames
                if startsWith(tline, 'SAVING CVfit to')
                    if isempty(fitObj_filename)
                        fitObj_filename = strsplit(tline, ' ');
                        fitObj_filename = [fitObj_filename{4}, '.mat'];
                    else
                        test_results_filename = strsplit(tline, ' ');
                        test_results_filename = [test_results_filename{4}, '.mat'];
                    end
                end
                % sanity check
                if endsWith(tline, '.nii')
                    assert(strcmp(tline, [masks{i}, '.nii']));
                end
                tline = fgetl(fid);
            end
            fclose(fid);
            
            lambda = str2double(lambda);
            train_acc = str2double(train_acc);
            test_acc = str2double(test_acc);
            
            fprintf('  Success rates (lambda = %.5f): train = %.4f%%, test = %.4f%%\n', lambda, train_acc, test_acc);
            fprintf('  Training filename: %s\n', fitObj_filename);
            fprintf('  Test filename: %s\n', test_results_filename);
            
            train_files = [train_files; {fitObj_filename}];
            test_files = [test_files; {test_results_filename}];
            
            scp_prefix = 'rsync -avh TOP SECRET';
            scp = [scp_prefix, ' ', fullfile(scp_from, fitObj_filename), ' ', mat_folder];
            scps = [scps; {scp}];
            scp = [scp_prefix, ' ', fullfile(scp_from, test_results_filename), ' ', mat_folder];
            scps = [scps; {scp}];
        end
    end
end

for held_out_trial_which_jobs = 1:length(jobss)
    mat_folder = ['classify_heldout_trial_', num2str(held_out_trial_which_jobs)];
    disp(['mkdir ', mat_folder]);
end

fprintf('\n\n\n');
for i = 1:length(scps)
    disp(scps{i});
end

%for i = 1:length(train_files)
%    disp(train_files{i});
%end
