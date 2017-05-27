% plot BICs from hyperparameter fit (using fit.m) 
% into a nice table
%

% as output by fit.m
%
load('fit_from_cluster.mat');

% must be same order as fit.m TODO FIXME COUPLING

structures = {[1 1 1 0], [1 0 0 0], [0 1 0 0], [0 0 1 0], [1 1 0 0], [1 0 1 0], [0 1 1 0]};
struct_names = {'M1, ', 'M2, ', 'M3, ', 'M4, '};

table_rowNames = {};
table_colNames = {'mean_BIC', 'mean_AIC', 'sum_loglik', 'num_params'};
table = nan(numel(structures), numel(table_colNames));
table_row = 0;

pilot_or_fmri = {'pilot', 'fmri'};
fixed_or_random_effects = {'random effects', 'fixed effects'};

for fmri_data = [0 1]
    for fixed_effects = [0 1]
        which_structuress = {[1 1 1 0], [1 0 0 0], [0 1 0 0], [0 0 1 0]}; % COUPLING -- should be same as in fit.m
        for which_structures = which_structuress
            
            which_structures = which_structures{1};
            
            table_row = table_row + 1;
            fprintf('\nstructures %s\n', strcat(struct_names{logical(which_structures)}));            
            fprintf(' result name = %s\n', results_names{table_row});
            
            rowName = sprintf('%s; %s; %s', pilot_or_fmri{fmri_data + 1}, ...
                fixed_or_random_effects{fixed_effects + 1}, strcat(struct_names{logical(which_structures)}));
            table_rowNames = [table_rowNames, {rowName}];
            
            result = results(table_row);
            
            table(table_row, 1) = mean(result.bic);
            table(table_row, 2) = mean(result.aic);
            table(table_row, 3) = sum(result.loglik);
            table(table_row, 4) = numel(result.x);
        end

    end
end

T = array2table(table, 'RowNames', table_rowNames, 'VariableNames', table_colNames)


