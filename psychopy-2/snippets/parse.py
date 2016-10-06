# Parse the wide format .csv file generated by psychopy
# and dump it into a nicely trimmed csv file that our MATLAB scripts can understand
# Usage: python parse.py [input csv file] [output csv file]
#

import os
import sys
import csv

colformat = "%s %s %s %d %s %s %s %d %d %s %s %s %f %d %s %s %d %d %d"

colnames = [
    'participant',
    'session',
    'mriMode',
    'isPractice',
    'restaurantsReshuffled',
    'foodsReshuffled',
    'contextRole',
    'contextId',
    'cueId',
    'sick',
    'corrAns',
    'response.keys',
    'response.rt',
    'response.corr',
    'restaurant',
    'food',
    'isTrain',
    'roundId',
    'trialId'
]

assert len(colnames) == len(colformat.split(' ')), "Make sure to update colformat here and in the MATLAB script that parses the file"

# which columns to export from the csv
#
def parseRow(entry):
    if entry['contextId'] == '': # not a trial (e.g. instructions)
        return None
    isTrain = entry['trials.thisN'] != ''
    assert isTrain or entry['test_trials.thisN'] != ''
    entryContextsReshuffled = [int(x) for x in entry['contextsReshuffled'].split(',')]
    entryCuesReshuffled = [int(x) for x in entry['cuesReshuffled'].split(',')]
    entryRestaurants = [r.strip() for r in entry['restaurantNames'].split(',')]
    out = [
        entry['participant'],
        entry['session'],
        entry['mriMode'],
        int(entry['isPractice'] == 'yes'),
        #"expStart": "1990-03-02 20:00:00", # TODO
        #'"' + entry['restaurantNames'] + '"',
        '"' + ';'.join([entryRestaurants[entryContextsReshuffled[x]] for x in range(0, 3)]) + '"', # restaurantNames
        '"' + ';'.join([entry['foodFilesPrefix'] + str(entryCuesReshuffled[x]) for x in range(0, 3)]) + '"', # foods
        entry['contextRole'],
        entry['contextId'],
        entry['cueId'],
        entry['sick'],
        entry['corrAns'],
        entry['responseKey.keys'] if isTrain else entry['responseKey_2.keys'],
        entry['responseKey.rt'] if isTrain else entry['responseKey_2.rt'],
        entry['responseKey.corr'] if isTrain else entry['responseKey_2.corr'],
        entry['restaurant'],
        entry['food'],
        int(isTrain),
        int(entry['runs.thisN']) + 1,
        (int(entry['trials.thisN']) + 1) if isTrain else (int(entry['test_trials.thisN']) + 1)
        #"stimOnset": "2016-03-02 10:00:00.23234", # TODO fmri clock, convert
        #"responseTime": "2016-03-02 11:00:00.02423", # TODO
        #"feedbackOnset": "2016-03-02 11:11:11.234234" # TODO fmri clock, convert
    ]
    assert len(out) == len(colnames), "Make sure to update colnames"
    # sanity check to make sure we didn't screw up the data gathering
    #
    assert entryRestaurants[entryContextsReshuffled[int(entry['contextId'])]] == entry['restaurant'], "You screwed up the data gathering -- these should be equal"
    assert entry['foodFilesPrefix'] + str(entryCuesReshuffled[int(entry['cueId'])]) == entry['food'], "You screwed up the data gathering -- these should be equal"

    return ','.join([str(x) for x in out])

if __name__  == "__main__":
    infile = sys.argv[1]
    outfile = sys.argv[2]
    
    with open(infile, 'r') as fin:
        reader = csv.DictReader(fin)
        with open(outfile, 'w') as fout:
            fout.write(','.join(colnames) + "\n")
            for row in reader:
                parsedRow = parseRow(row)
                if parsedRow:
                    fout.write(parsedRow + "\n")