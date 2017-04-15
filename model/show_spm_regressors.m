EXPT = contextExpt();
glmodel = 2;
subj = 1;
run = 1;
include_motion = false;

multi = EXPT.create_multi(glmodel, subj, run);
load('context_create_multi.mat'); % WARNING WARNING WARNING: MASSIVE COUPLING. This relies on context_create_multi saving its state into this file. I just don't wanna copy-paste or abstract away the code that load the data from there

TR = EXPT.TR;
sess_prefix = ['Sn(', num2str(run), ')'];


modeldir = fullfile(EXPT.modeldir,['model',num2str(glmodel)],['subj',num2str(subj)]);
load(fullfile(modeldir,'SPM.mat'));

figure;

cols = SPM.Sess(run).col; % which regressors to display
if ~include_motion
    cols = cols(1:end-6); % ditch motion regressors
end

% iterate over regressors
%
for i = cols
    assert(strncmp(SPM.xX.name{i}, sess_prefix, length(sess_prefix)));
    
    subplot(length(cols), 1, i);
    hold on;    
    h = [];
    
    % plot trial onsets / offsets as vertical dashed lines
    %
    onsets = cellfun(@str2num, actualChoiceOnset(which_all)');
    yL = get(gca,'YLim');
    ylim([yL(1) - 0.1, yL(2) + 0.1]);
    yL = get(gca,'YLim');
    for t=onsets
        plot([t t], yL, '--', 'Color', [0.8 0.8 0.8]);
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
    trs = 1 : TR : TR*length(SPM.Sess(run).row); % or start at 0? how does slice timing interpolation work in SPM?
    h = [h, plot(trs, SPM.xX.X(SPM.Sess(run).row, i)', 'Color', 'blue')];
    
    title(SPM.xX.name{i}, 'Interpreter', 'none');
    legend(h, leg, 'Interpreter', 'none');
        
    hold off
end
