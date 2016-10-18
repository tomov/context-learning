import os
import sys
import csv

def parse(fname):
    duration = []
    start = []
    cue = []
    with open(fname) as f:
        reader = csv.reader(f, delimiter=' ')
        for row in reader:
            row = filter(None, row)
            start.append(float(row[0]))
            duration.append(float(row[2]))
            cue.append(row[4])
    jitter = duration[1::2]
    stim = duration[0::2]
    start = start[0::2]
    cue = cue[0::2]
    assert len(stim) == len(cue)

    choice = []
    off = []
    t = 0
    for i in range(len(stim)):
        choice.append(t)
        t += stim[i]
        off.append(t)
        t += jitter[i]
    assert choice == start, " wtf " + str(choice) + " vs " + str(start)

    #print choice
    #print off
    #print jitter
    #print stim
    #print cue
    return choice, off, jitter, stim, cue


if __name__ == "__main__":
    pars = os.listdir("par")

    train = []
    test = []

    for fname in pars:
        if fname.endswith('.par'):
            print fname
            x = parse(os.path.join("par", fname))
            if fname.startswith('itis_test'):
                test.append(x)
            else:
                train.append(x)

    next_train_idx = 0
    next_test_idx = 0
    with open('timing.csv', 'w') as f:
        cols = ['Subject', 'Run', 'Trial', 'Choice', 'Off', 'Jitter', 'Stimulus', 'Cue']
        f.write(','.join(cols) + '\n')
        for subj in range(30):
            for run in range(9):
                choice, off, jitter, stim, cue = train[next_train_idx]
                for i in range(20):
                    row = [subj + 1, run + 1, i + 1, choice[i], off[i], jitter[i], stim[i], cue[i]]
                    f.write(','.join(str(x) for x in row) + '\n')
                next_train_idx += 1
                
                t = off[-1] + jitter[-1] # starting point for test trials
                choice, off, jitter, stim, cue = test[next_test_idx]
                for i in range(4):
                    row = [subj + 1, run + 1, i + 20 + 1, choice[i] + t, off[i] + t, jitter[i], stim[i], cue[i]]
                    f.write(','.join(str(x) for x in row) + '\n')
                next_test_idx += 1

