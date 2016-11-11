function [ subjects, subjdirs, nRuns ] = contextGetSubjectsDirsAndRuns()

subjects = {'con001', 'con002', 'con003', 'con004', ...
            'con005', 'con006', 'con007', 'con008'}; % TODO don't hardcode
subjdirs = {'161030_con001', '161030_con002', '161101_CON_003', '161106_CON_004', ...
            '161106_CON_005', '161106_CON_006', '161106_CON_007', '161108_CON_008'};
nRuns = {9, 9, 5, 9, ...
         9, 9, 9, 9}; % runs per subject


end

