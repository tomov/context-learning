function EXPT = contextExpt

    % creates EXPT structure for CCNL fMRI processing pipeline
    %
    % USAGE: EXPT = contextExpr()
    %
    % INPUTS:
    %   local - one if file path is on local computer, 0 if on NCF
    %
    % OUTPUTS:
    %   EXPT - experiment structure with fields
    %          .TR - repetition time
    %          .create_multi - function handle for creating multi structure
    %          .modeldir - where to put model results
    %          .subject(i).datadir - directory for subject data
    %          .subject(i).functional - .nii files for runs
    %          .subject(i).structural - .nii for structural scan
    %
    % Cody Kommers, July 2016
    % Momchil Tomov, Nov 2016
    
    % main directory
    %exptdir = '/ncf/gershman/Lab/ConLearn/'; % on CBS central server
    exptdir = '/Users/memsql/Dropbox/research/context/'; % local group level
    %exptdir = '/Users/memsql/Documents/MATLAB/conlearn-subject-data/'; % local single subject
    
    % Load data from file with all subjects, as well as some constants.
    %
    %load_data_directory = exptdir; % hacksauce
    load_data;
    
    [subjects, subjdirs, nRuns] = contextGetSubjectsDirsAndRuns();
    subjects'
    unique(participant)
    assert(isequal(subjects',unique(participant)));
    
    for subj = 1:length(subjects)
        subjdir = [exptdir, 'subjects/', subjdirs{subj}, '/'];
        EXPT.subject(subj).datadir = [subjdir, 'preproc'];
        
        EXPT.subject(subj).structural = 'struct.nii';
        
        assert(nRuns{subj} == length(unique(roundId(strcmp(participant, subjects{subj})))));
        for run = 1:nRuns{subj}
            EXPT.subject(subj).functional{run} = ['run',sprintf('%03d',run),'.nii'];
        end
        disp(EXPT.subject(subj));
    end
    
    % TR repetition time
    EXPT.TR = 2; %seconds
    % Function handle to create subject multi structure
    EXPT.create_multi = @context_create_multi;
    % Where you want model output data to live
    EXPT.modeldir = [exptdir, 'glmOutput'];
    
    % Where the data live, but not sure which data
    EXPT.datadir = [exptdir, 'testOutput'];


end