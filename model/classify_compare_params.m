% compare different classifier parameter settings based on classification
% perf
%

jobs = [86320806,86320811,86320812,86320813,86320815,86320817,86320821,86320822;
86320823,86320824,86320825,86320826,86320829,86320831,86320832,86320833;
86320834,86320835,86320836,86320837,86320838,86320839,86320840,86320841;
86320842,86320843,86320844,86320845,86320848,86320849,86320850,86320851;
86320852,86320853,86320854,86320855,86320856,86320860,86320861,86320862;
86320863,86320864,86320865,86320866,86320867,86320868,86320869,86320870];
jobs(:,1) = []; % mask.nii failed all

masks = {'mask', 'hippocampus', 'ofc', 'striatum', 'vmpfc', 'rlpfc', 'bg', 'pallidum'};
masks(1) = []; % mask.nii failed

groups = {'grouped', 'grouped', 'grouped', 'ungrouped', 'ungrouped', 'ungrouped'};

alphas = [1 0 0.5 1 0 0.5];

figure;

for class = 1:size(jobs, 1)
    subplot(2, 3, class);
    hold on;

    plot([0 1000], [33.3 33.3], '--', 'Color', [0.3 0.3 0.3]);
    for job = jobs(class,:)
        filename = ['classify_outputs_2/classify_', num2str(job), '_output.out'];
        disp(filename)

        fid = fopen(filename);
        tline = fgetl(fid);
        in_test_phase = false;
        accs = [];
        lambdas = [];
        fitObj_filename = [];
        while ischar(tline)
            %disp(tline)
            if startsWith(tline, 'classify_test')
                in_test_phase = true;
            end
            if in_test_phase && startsWith(tline, 'Success rate for')
                x = strsplit(tline, ' ');
                lambda = x{7}(1:end-1);
                acc = x{9}(1:end-1);
                %disp(lambda)
                lambdas = [lambdas, str2double(lambda)];
                accs = [accs, str2double(acc)];
            end
            %if startsWith(tline, 'SAVING fitObj to')
            %    fitObj_filename = strsplit(tline, ' ');
            %    fitObj_filename = [fitObj_filename{4}, '.mat'];
            %end
            tline = fgetl(fid);
        end
        fclose(fid);
        
        plot(accs, 'LineWidth', 2);

        %break;
    end
    xlabel('\lambda id (decreasing)');
    ylabel('accuracy (%)');
    legend([{'chance'}, masks]);
    title(['\alpha = ', num2str(alphas(class)), ', ', groups{class}]);
    hold off;
end