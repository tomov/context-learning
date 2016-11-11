# Parse the wide format .csv file generated by fmri-context-task
# and dump it into a nicely trimmed csv file that our MATLAB scripts can understand
#
# Usage: python parse.py [input csv file] [output csv file]
# Usage: python parse.py [input csv file] [output csv file] -a
#
# The former creates a new file (or overwrites it) and adds headers for column names
# The latter appends to an existing file without adding headers
#
# Optionally -f to parse the extra fMRI-synced event onsets/offsets

import os
import sys
import csv

# make sure to update the MATLAB script format too
#
colformat = "%d %s %s %s %d %s" + " %s %d %d %s %s" + " %s %f %d %s %s" + " %d %d %d" + \
    " %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f"

# colnames used for the behavioral pilot
# may want to be careful adding stuff here -- will have to change things in the analyze.m script too (in ../../model)
#
colnames = [
    'drop',
    'participant',
    'session',
    'mriMode',
    'isPractice',
    'runFilename',

    'contextRole',
    'contextId',
    'cueId',
    'isSick',
    'corrButton',

    'response.keys',
    'response.rt',
    'response.corr',
    'restaurant',
    'food',

    'isTrain',
    'roundId',
    'trialId',

    'expStartWallTime',
    'actualChoiceOnset',
    'actualChoiceOffset',
    'actualIsiOnset',
    'actualIsiOffset',
    'actualFeedbackOnset',
    'actualFeedbackOffset',
    'actualItiOnset',
    'actualItiOffset',
    'actualItiDuration',
    'itiDriftAdjustment',
    'stimOnset',
    'stimOffset',
    'itiDuration',
    'itiOffset'
]


assert len(colnames) == len(colformat.split(' ')), "Make sure to update colformat here and in the MATLAB script that parses the file " + str(len(colnames)) + " vs " + str(len(colformat.split(' ')))

# MATLAB was written when left = sick, right = not sick
# here 1 = sick, 2 = not sick => gotta convert
#
def remap_key_for_matlab(key):
    if key == '1':
        return 'left'
    if key == '2':
        return 'right'
    assert key == 'None', key
    return 'None'

# which columns to export from the csv
#
def parseRow(entry):
    if entry['contextId'] == '': # not a trial (e.g. instructions)
        return None
    assert entry['isTest'] == 'True' or entry['isTest'] == 'False', entry['isTest']
    assert entry['isSick'] == 'True' or entry['isSick'] == 'False' or entry['isSick'] == 'None', entry['isSick']
    assert entry['corrButton'] == '1' or entry['corrButton'] == '2' or entry['corrButton'] == 'None', entry['corrButton']
    assert entry['responseKey.keys'] == '1' or entry['responseKey.keys'] == '2' or entry['responseKey.keys'] == 'None', entry['responseKey.keys']
    isTest = entry['isTest'] == 'True'
    out = [
        0, # by default don't drop anything
        entry['participant'],
        entry['session'],
        entry['mriMode'],
        int(entry['isPractice'] == 'yes'),
        entry['runFilename'],

        entry['contextRole'],
        int(entry['contextId']),
        int(entry['cueId']),
        'Yes' if entry['isSick'] == 'True' else 'No', # for MATLAB
        remap_key_for_matlab(entry['corrButton']),

        remap_key_for_matlab(entry['responseKey.keys']),
        entry['responseKey.rt'],
        entry['responseKey.corr'],
        entry['restaurant'],
        entry['food'],

        int(not isTest),
        int(entry['runs.thisN']) + 1,
        (int(entry['test_trials.thisN']) + 1) if isTest else (int(entry['train_trials.thisN']) + 1),

        entry['expStartWallTime'],
        entry['actualChoiceOnset'],
        entry['actualChoiceOffset'],
        entry['actualIsiOnset'],
        entry['actualIsiOffset'],
        entry['actualFeedbackOnset'],
        entry['actualFeedbackOffset'],
        entry['actualItiOnset'],
        entry['actualItiOffset'],
        entry['actualItiDuration'],
        entry['itiDriftAdjustment'],
        entry['stimOnset'],
        entry['stimOffset'],
        entry['itiDuration'],
        entry['itiOffset']
    ]

    # TODO assert entry trialN == trial N
    # assert actual offset ~= offset
    # assert isTest & trialN

    assert len(out) == len(colnames), "Make sure to update colnames " + str(len(out)) + " vs " + str(len(colnames))
    # TODO add an assert for corrAns and sick based on context role

    return ','.join([str(x) for x in out])

if __name__  == "__main__":
    infile = sys.argv[1]
    outfile = sys.argv[2]
    append = False
    if len(sys.argv) >= 4:
        args = sys.argv[3:]
        append = '-a' in args or '--append' in args

    if append:
        desc = 'a'
    else:
        desc = 'w'
    
    with open(infile, 'r') as fin:
        reader = csv.DictReader(fin)
        with open(outfile, desc) as fout: 
            if not append: # write the headers optionally
                fout.write(','.join(colnames) + "\n")
            for row in reader:
                parsedRow = parseRow(row)
                if parsedRow:
                    fout.write(parsedRow + "\n")
