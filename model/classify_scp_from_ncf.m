% generate scp commands to get the relevant data files based on the output
% of classify.m
%
% This is classifying condition based on training trials [1..18 20] and
% testing on trial 19 (all runs)
%

folder = 'classify_outputs_3';

jobs = [86846035,86846036,86846037,86846038,86846039,86846040,86846041];

masks = {'hippocampus', 'ofc', 'striatum', 'vmpfc', 'rlpfc', 'bg', 'pallidum'};

scp_from = 'mtomov13@ncfws13.rc.fas.harvard.edu:/net/rcss11/srv/export/ncf_gershman/share_root/Lab/scripts/matlab/ConLearn/';
scps = {};

train_files = {};
test_files = {};

%figure;

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
        
        scp = ['scp ', fullfile(scp_from, fitObj_filename), ' ', folder];
        scps = [scps; {scp}];
        scp = ['scp ', fullfile(scp_from, test_results_filename), ' ', folder];
        scps = [scps; {scp}];
    end
end

fprintf('\n\n\n');
for i = 1:length(scps)
    disp(scps{i});
end

for i = 1:length(train_files)
    disp(train_files{i});
end
