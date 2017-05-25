function show_figure(figure_name)
% Generate figures from the paper.
%
% figure_name = which figure to show, e.g. Figure_3A
%

%figure_name = 'Figure_3B';

switch figure_name
    
    % TODO SAM use subplots
    % TODO linspecr.m -- nicer color map (don't have to use it)
    %
    case 'Figure_3A'
        % Posterior probabilities over structures in each condition
        %
        load('analyze.mat');
        
        handle = figure;
        set(handle, 'Position', [500, 500, 450, 200])

        Ms = [];
        SEMs = [];
        for context = contextRoles
            which = which_rows & isTrain & trialId == 20 & strcmp(contextRole, context);

            P1_n = model.P1(which);
            P2_n = model.P2(which);
            P3_n = model.P3(which);
            
            P_n = [];  % only include the posteriors from models we care about
            if which_models(1), P_n = [P_n ]; end
            if which_models(2), P_n = [P_n ]; end
            if which_models(3), P_n = [P_n ]; end
            Ms = [Ms; mean(P1_n) mean(P2_n) mean(P3_n)];
            SEMs = [SEMs; sem(P1_n) sem(P2_n) sem(P3_n)];
        end

        % TODO SAM remove error bars here
        barweb(Ms, SEMs, 1, {'Irrelevant training', 'Modulatory training', 'Additive training'});
        ylabel('Posterior probability');
        legend({'M1', 'M2', 'M3'}, 'Position', [0.2 0.3 1 1]);
    
        
    case 'Figure_3B'
        % TODO SAM superimpose human dots w/ error bars; rm error bars from model
        %
        % TODO SAM also SEMs -- within-subject errors: wse.m (in the dropbox)
        % TODO SAM also mytitle.m -- easier to plot left-oriented panel titles
        
        % Test performance: model predictions as bars, human data as dots + standard error bars overlaid on the bars
        %
        load('analyze.mat');
        
        handle = figure;
        set(handle, 'Position', [500, 500, 450, 200])        
        
        %
        % Choice probabilities in test phase for MODEL (based on the actual
        % decisions the model made)
        %
        
        Ms = [];
        SEMs = [];
        for context = contextRoles
            which = which_rows & isTrain == 0 & strcmp(contextRole, context);

            x1c1 = strcmp(model.keys(which & cueId == 0 & contextId == 0), 'left');
            x1c3 = strcmp(model.keys(which & cueId == 0 & contextId == 2), 'left');
            x3c1 = strcmp(model.keys(which & cueId == 2 & contextId == 0), 'left');
            x3c3 = strcmp(model.keys(which & cueId == 2 & contextId == 2), 'left');

            M = get_means(x1c1, x1c3, x3c1, x3c3);
            SEM = get_sems(x1c1, x1c3, x3c1, x3c3);
            Ms = [Ms; M];
            SEMs = [SEMs; SEM];
        end

        barweb(Ms, SEMs, 1, {'Irrelevant training', 'Modulatory training', 'Additive training'});
        ylabel('Choice probability');
        legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'}, 'Position', [0.07 0.2 1 1]);
        title('Model');
        
    case 'Figure_3C'
        load('analyze.mat');
        
        handle = figure;
        set(handle, 'Position', [500, 500, 450, 200])        
        
        %
        % Choice probabilities in test phase for SUBJECTS
        %

        Ms = [];
        SEMs = [];
        for context = contextRoles
            which = which_rows & isTrain == 0 & strcmp(contextRole, context);

            x1c1 = strcmp(response.keys(which & cueId == 0 & contextId == 0), 'left');
            x1c3 = strcmp(response.keys(which & cueId == 0 & contextId == 2), 'left');
            x3c1 = strcmp(response.keys(which & cueId == 2 & contextId == 0), 'left');
            x3c3 = strcmp(response.keys(which & cueId == 2 & contextId == 2), 'left');

            M = get_means(x1c1, x1c3, x3c1, x3c3);
            SEM = get_sems(x1c1, x1c3, x3c1, x3c3);
            Ms = [Ms; M];
            SEMs = [SEMs; SEM];
        end

        barweb(Ms, SEMs, 1, {'Irrelevant training', 'Modulatory training', 'Additive training'});
        ylabel('Choice probability');
        legend({'x_1c_1', 'x_1c_3', 'x_3c_1', 'x_3c_3'}, 'Position', [0.07 0.2 1 1]);
        title('Human subjects');
        

        
    case 'Figure_4A'
        % Slices showing KL divergence activations [use the model with the error regressor]
        %
        ccnl_view(contextExpt(), 123, 'surprise - wrong');
        
        
    case 'Figure_4B'     
        % TODO plot fischer Z transform of fischer_all_rs
        %
        
        % Plot showing the least-squares lines relating AG KL beta to the structure learning effect, one line per subject, plus a thicker line showing the average linear relationship.    
        %
        z_scored = false;
        
        load('kl_analysis.mat'); % as output by kl_structure_learning.m

        handle = figure;
        set(handle, 'Position', [500, 500, 200, 200])
        
        assert(strcmp(rois{1}, 'Angular_R'));
        KL_betas_AG = kl_betas(:, :, 1);
        slopes = nan(1, n_subjects);
        intercepts = intercepts(1, n_subjects);
        xs = nan(n_runs, n_subjects);
        
        for subj_idx = 1:n_subjects
            %x = structure_learnings(:, subj_idx);   <-- not good with timeouts
            x = test_liks(:, subj_idx);
            y = KL_betas_AG(:, subj_idx);

            if z_scored
                x = zscore(x);
                y = zscore(y);
            end
            xs(:, subj_idx) = x;
            
            fit = polyfit(x, y, 1);
            slopes(subj_idx) = fit(1);
            intercepts(subj_idx) = fit(2);
            
            hold on;
            yfit = polyval(fit, x);
            plot(x, yfit, 'Color', [0.5 0.5 0.5]);
            hold off;
        end
        
        %x = [-2 0];
        %hold on;
        %for subj_idx = 1:n_subjects
        %    plot(x, x * slopes(subj_idx) + intercepts(subj_idx), 'Color', 'blue');
        %end
        
        max_x = max(xs(:));
        
        hold on;
        x_limits = [-1.6 max_x];
        plot(x_limits, x_limits * mean(slopes) + mean(intercepts), 'LineWidth', 2, 'Color', 'blue');
        hold off;
        
        xlim(x_limits);
        title('Right Angular Gyrus');
        if z_scored
            xlabel('Test choice likelihood (Z-scored)');
            ylabel('Beta for KL divergence (Z-scored)');
            ylim([-1 1]);
        else
            xlabel('Test choice likelihood');
            ylabel('Beta for KL divergence');
            ylim([-30 35]);
        end

end


