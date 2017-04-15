EXPT = contextExpt();
glmodel = 30;
subj = 1;
run = 2;
include_motion = false;

multi = EXPT.create_multi(glmodel, subj, run);
load('context_create_multi.mat'); % WARNING WARNING WARNING: MASSIVE COUPLING. This relies on context_create_multi saving its state into this file. I just don't wanna copy-paste or abstract away the code that load the data from there
disp(condition)

TR = EXPT.TR;
sess_prefix = ['Sn(', num2str(run), ')'];
trs = 1 : TR : TR*length(SPM.Sess(run).row); % or start at 0? how does slice timing interpolation work in SPM?


modeldir = fullfile(EXPT.modeldir,['model',num2str(glmodel)],['subj',num2str(subj)]);
load(fullfile(modeldir,'SPM.mat'));

figure;

% which regressors to display
%
cols = SPM.Sess(run).col;
if ~include_motion
    cols = cols(1:end-6); % ditch motion regressors
end

% show stimulus sequence
% this is ConLearn-specific 
%
subplot(length(cols) + 1, 1, 1);
hold on;

is_sick = strcmp(sick(which_all), 'Yes');
is_train = which_train(which_all);
resps = response.keys(which_all);
corr = response.corr(which_all);

onsets = cellfun(@str2num, actualChoiceOnset(which_all)');
for t=onsets
    plot([t t], [-1 1], '--', 'Color', [0.8 0.8 0.8]);
end

feedback_onsets = cellfun(@str2num, actualFeedbackOnset(which_train)');
for i=1:length(feedback_onsets)
	if corr(i)
        color = 'blue';
    else
        color = 'red';
    end
    plot([feedback_onsets(i) feedback_onsets(i)], [-1 1], 'Color', color);
end

stims = strcat('x', num2str(cueId(which_all) + 1), 'c', num2str(contextId(which_all) + 1));
text(onsets(is_sick & is_train), double(strcmp(resps(is_sick & is_train), 'left')), stims(is_sick & is_train,:), 'Color', [0 0.5 0]);
text(onsets(~is_sick & is_train), double(strcmp(resps(~is_sick & is_train), 'left')), stims(~is_sick & is_train,:), 'Color', [0.5 0.5 0]);
text(onsets(~is_train), double(strcmp(resps(~is_train), 'left')), stims(~is_train,:), 'Color', [0.3 0.3 0.3]);

ylim([-0.3 1.1]);
yticks([0 1]);
yticklabels({'chose not sick', 'chose sick'});

h = [plot(NaN,NaN, 'Color', [0 0.5 0],'LineWidth', 2); plot(NaN,NaN,'Color', [0.5 0.5 0],'LineWidth', 2); plot(NaN,NaN,'Color', [0.3 0.3 0.3],'LineWidth', 2)];
legend(h, {'sick', 'not sick', 'test'});
hold off;


% iterate over regressors
%
plot_idx = 1;
for i = cols
    assert(strncmp(SPM.xX.name{i}, sess_prefix, length(sess_prefix)));
    
    plot_idx = plot_idx + 1;
    subplot(length(cols) + 1, 1, plot_idx);
    hold on;
    h = [];
    
    % plot trial onsets / offsets as vertical dashed lines
    %
    feedback_onsets = cellfun(@str2num, actualChoiceOnset(which_all)');
    for t=feedback_onsets
        plot([t t], [-1 1], '--', 'Color', [0.8 0.8 0.8]);
    end
    
    % plot original regressor from model
    %
    leg = {SPM.xX.name{i}};
    eps = 1e-6;
    for j = 1:length(multi.names)
        n = length(multi.onsets{j});
        x = [multi.onsets{j} - eps; multi.onsets{j}; multi.onsets{j} + multi.durations{j}'; multi.onsets{j} + multi.durations{j}' + eps];
        x = x(:)';
        x = [0 x max(trs)];
        if ~isempty(strfind(SPM.xX.name{i}, [multi.names{j}, '*']))
            y = [zeros(1,n); ones(1,n); ones(1,n); zeros(1,n)];
            y = y(:)';
            y = [0 y 0];
            h = [h, plot(x, y)];
            leg = [leg; multi.names{j}];
        end
            
        if j <= length(multi.pmod)
            for k = 1:length(multi.pmod(j).name)
                if ~isempty(strfind(SPM.xX.name{i}, [multi.pmod(j).name{k}, '^']))
                    y = [zeros(1,n); multi.pmod(j).param{k}; multi.pmod(j).param{k}; zeros(1,n)];
                    y = y(:)';
                    y = [0 y 0];
                    h = [h, plot(x, y)];
                    leg = [leg; ['pmod: ', multi.pmod(j).name{k}]];
                end
            end
        end
    end
    
    % plot regressor convolved with HRF
    %
    h = [h, plot(trs, SPM.xX.X(SPM.Sess(run).row, i)', 'Color', 'blue')];
    
    yL = get(gca,'YLim');
    ylim([yL(1), yL(2) + 0.1]);    
    title(SPM.xX.name{i}, 'Interpreter', 'none');
    legend(h, leg, 'Interpreter', 'none');
        
    hold off
end
