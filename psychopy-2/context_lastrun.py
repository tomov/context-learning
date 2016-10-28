#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
This experiment was created using PsychoPy2 Experiment Builder (v1.82.01), Fri Oct 28 15:02:13 2016
If you publish work using this script please cite the relevant PsychoPy publications
  Peirce, JW (2007) PsychoPy - Psychophysics software in Python. Journal of Neuroscience Methods, 162(1-2), 8-13.
  Peirce, JW (2009) Generating stimuli for neuroscience using PsychoPy. Frontiers in Neuroinformatics, 2:10. doi: 10.3389/neuro.11.010.2008
"""

from __future__ import division  # so that 1/3=0.333 instead of 1/3=0
from psychopy import visual, core, data, event, logging, sound, gui
from psychopy.constants import *  # things like STARTED, FINISHED
import numpy as np  # whole numpy lib is available, prepend 'np.'
from numpy import sin, cos, tan, log, log10, pi, average, sqrt, std, deg2rad, rad2deg, linspace, asarray
from numpy.random import random, randint, normal, shuffle
import os  # handy system and path functions

# Ensure that relative paths start from the same directory as this script
_thisDir = os.path.dirname(os.path.abspath(__file__))
os.chdir(_thisDir)

# Store info about the experiment session
expName = 'context'  # from the Builder filename that created this script
expInfo = {u'isPractice': u'no', u'session': u'001', u'participant': u'con000', u'mriMode': u'scan'}
dlg = gui.DlgFromDict(dictionary=expInfo, title=expName)
if dlg.OK == False: core.quit()  # user pressed cancel
expInfo['date'] = data.getDateStr()  # add a simple timestamp
expInfo['expName'] = expName

# Data file name stem = absolute path + name; later add .psyexp, .csv, .log, etc
filename = _thisDir + os.sep + 'data/%s_%s_%s' %(expInfo['participant'], expName, expInfo['date'])

# An ExperimentHandler isn't essential but helps with data saving
thisExp = data.ExperimentHandler(name=expName, version='',
    extraInfo=expInfo, runtimeInfo=None,
    originPath=u'/Users/memsql/Dropbox/Research/context/psychopy-2/context.psyexp',
    savePickle=True, saveWideText=True,
    dataFileName=filename)
#save a log file for detail verbose info
logFile = logging.LogFile(filename+'.log', level=logging.EXP)
logging.console.setLevel(logging.WARNING)  # this outputs to the screen, not a file

endExpNow = False  # flag for 'escape' or other condition => quit the exp

# Start Code - component code to be run before the window creation

# Setup the Window
win = visual.Window(size=(1440, 900), fullscr=True, screen=0, allowGUI=False, allowStencil=False,
    monitor='testMonitor', color=[0,0,0], colorSpace='rgb',
    blendMode='avg', useFBO=True,
    )
# store frame rate of monitor if we can measure it successfully
expInfo['frameRate']=win.getActualFrameRate()
if expInfo['frameRate']!=None:
    frameDur = 1.0/round(expInfo['frameRate'])
else:
    frameDur = 1.0/60.0 # couldn't get a reliable measure so guess

# Initialize components for Routine "instr"
instrClock = core.Clock()
win.setColor('black')
if expInfo['mriMode'] != 'off': # we're scanning!
    assert expInfo['mriMode'] == 'scan'
    sickPressInstr = "with your index finger"
    notsickPressInstr = "with your middle finger"
else: # not scanning => behavioral
    sickPressInstr = "the left arrow key (<-)"
    notsickPressInstr = "the right arrow key (->)"


instruction ='''Imagine that you are a health inspector trying to determine the cause of illness in different restaurants.''' \
+ ''' On each trial you will see the name of the restaurant and a particular food.''' \
+ ''' Your job is to predict whether a customer will get sick from eating the food.''' \
+ ''' The outcome may or may not depend on the particular restaurant the customer is in (you have to figure that out).''' \
+ ''' In some cases you will make predictions about the same food in different restaurants.

The experiment consists of 9 rounds. In each round, you will make 24 predictions about a different set of restaurants and foods.''' \
+ ''' After each prediction (except the last 4), you will receive feedback about whether or not the customer got sick.

Press %s if you believe the customer will get sick from eating the food.

Press %s if you believe the customer will NOT get sick.

You will have 3 seconds to press on each trial.

Press any button to begin the first round.''' % (sickPressInstr, notsickPressInstr)
instrText = visual.TextStim(win=win, ori=0, name='instrText',
    text=instruction
,    font='Arial',
    pos=[0, 0], height=0.07, wrapWidth=1.6,
    color='white', colorSpace='rgb', opacity=1,
    depth=-2.0)

# Initialize components for Routine "new_run"
new_runClock = core.Clock()



import os
import csv

# TODO FIXME this is hardcoded & duplicated with the trials, test_trials & runs loop
#
nRuns = 9
nTrainTrialsPerRun = 20
# in practice mode, only run 1 rep (4 trials)
# also see End Routine
# ... BUT NOT REALLY any more => gotta get the real deal in the fMRI practice
#if expInfo['isPractice'] == 'yes':
#    nTrainTrialsPerRun = 4
nTestTrialsPerRun = 4

nTrialsPerRun = nTrainTrialsPerRun + nTestTrialsPerRun;
nTotalTrials = nRuns * nTrialsPerRun

# TODO these are hardcoded!
trainTrialFixedTime = 5 # stim presentation + ISI + feedback
testTrialFixedTime = 6 # stim presentation


# OKAY some serious hacksauce follows.
#
# In fMRI mode, we pre-generate the ITI's and the stim sequences (x1c2, x2c1, x1c1, x2c1, etc)
# for each run for each subject. We do this with optseq2 which ensures the
# spacing of ITI's makes sense. So in fMRI mode, instead of using the
# randomly generated stim sequence by psychopy (see "trials" and "test_trials" loops),
# we take the pre-generated one from optseq2.
#
# The reason I didn't just put the .csv file as the conditions file of the trials/test_trials loops
# is that I wanted to have it be backwards-compatible, and so that
# if we want to mess around or do a behavioral run, we don't have to
# go back and pre-generate all that crap with optseq.
#
# NOTE that this assumes the file format is pre-determined and that the partipant ID
# has the form conPXXX, and that the corresponding file exists.
#
# Also note that the whole trial / run sequence is hardcoded in here
# particularly the duration of the different times -- sorry that's just
# the way things are.
#
# Also note that as an extra precaution to not accidentally use the same set of ITI's twice
# (which would cost us $2000, give or take), we rename each file after using it. 
# 

if expInfo['mriMode'] != 'off':
    assert expInfo['mriMode'] == 'scan'

    fMRI_run_itis = [[]] * nRuns
    fMRI_run_itiOffsets = [[]] * nRuns
    fMRI_run_cueIds = [[]] * nRuns
    fMRI_run_contextIds = [[]] * nRuns

    # pre-load all the runs, so if something's fucked we know before we start scanning
    #
    for run_idx in range(nRuns):
        itis_file = os.path.join('itis', 'csv', '%s_run%d_itis.csv' % (expInfo['participant'], run_idx))
        print 'Using ITIs file ', itis_file
        t = 10 # TODO hardcoded initial fixation time
        with open(itis_file, 'r') as f:
            reader = csv.reader(f, delimiter=',')
            next(reader) # skip the headers
            sanity_trial_n = 0
            for row in reader:
                print row
                assert row[0] == str(sanity_trial_n), "Wrong entry on line " + str(sanity_trial_n) + "; got " + row[0]
                fMRI_run_itis[run_idx].append(float(row[1]))
                if sanity_trial_n < 20: # TODO hardcoded last train trial id (0-based)
                    t += 5 # TODO hardcoded train trial time
                else:
                    t += 6 # TODO hardcoded test trial time
                t += float(row[1]) # the ITI
                if sanity_trial_n == 19: # TODO hardcoded after last training trial
                    t += 4 # TODO hardcoded "test_warning" duration
                fMRI_run_itiOffsets[run_idx].append(t)
                fMRI_run_cueIds[run_idx].append(int(row[2]))
                fMRI_run_contextIds[run_idx].append(int(row[3]))
                sanity_trial_n += 1
            assert sanity_trial_n == nTrialsPerRun, "Should have exactly 24 trials in the ITIs file"
            assert fMRI_run_itiOffsets[run_idx][-1] == 214, "Last ITI offset should be 214; instead it's " + str(fMRI_run_itiOffsets[run_idx][-1])

        # TODO reenable before start!
        #os.rename(itis_file, itis_file + '_USED') # so we don't accidentally use them twice. That would be a disaster

runInstr = visual.TextStim(win=win, ori=0, name='runInstr',
    text='the text is set manually\n',    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=1.5,
    color='white', colorSpace='rgb', opacity=1,
    depth=-5.0)

# Initialize components for Routine "waitForTrigger"
waitForTriggerClock = core.Clock()
fmriClock = core.Clock() # clock for syncing with fMRI scanner
# definitely log it!

#trigger = 'parallel'
trigger = 'usb'
if trigger == 'parallel':
    from psychopy import parallel 
elif trigger == 'usb':
    from psychopy.hardware.emulator import launchScan    

    # settings for launchScan:
    MR_settings = { 
        'TR': 2.5, # duration (sec) per volume
        'volumes': 141, # number of whole-brain 3D volumes / frames
        'sync': 'equal', # character to use as the sync timing event; assumed to come at start of a volume
        'skip': 0, # number of volumes lacking a sync pulse at start of scan (for T1 stabilization)
        }


# Initialize components for Routine "Fixation"
FixationClock = core.Clock()
fixationCross = visual.TextStim(win=win, ori=0, name='fixationCross',
    text='+',    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=0.0)

# Initialize components for Routine "trial"
trialClock = core.Clock()
import time
expInfo['expStartWallTime'] = time.ctime()

if expInfo['mriMode'] != 'off': # we're scanning!
    assert expInfo['mriMode'] == 'scan'
    sickButton = '1' # index finger
    notsickButton = '2' # middle finger
else: # not scanning => behavioral
    sickButton = 'left'
    notsickButton = 'right'
# different jitter distributions depending on mode 
#

if expInfo['mriMode'] != 'off': # we're scanning
    assert expInfo['mriMode'] == 'scan'
    
    #
    # .... here we have pre-generated the ITI's using optseq2 and pulled them
    # from a separate file for the current run.
    # So no need to pre-generate anything here.
    #

else: # behavioral
    #
    #  ..... here we pre-generate the ITI's in the code
    #

    itiMean = 1.5
    itiLambda = 0.5
    itiMin = 1
    itiMax = 4
    maxAllowedRunTime = 3 * 60 # max 3 mins per run in behavioral

    # Generate the ITI's
    # TODO the times are hardcoded & duplicated with the ones in the builder
    #
    runOverheadTime = 10 # info screens

    # For each run, generate the ITI's from a laplacian
    # and make sure that they fit in the max allowed run time 
    # for each run, keep trying until we find a sequence of ITIs
    # that do fit; otherwise if we fail after a lot of attempts,
    # just take the shorted ITI sequence
    #
    allItis = []
    runItisSanity = [] # for sanity check
    for r in range(nRuns):
        bestItis = None
        print 'run = ', r
        for attempt in range(1, 100):
            itis = np.random.laplace(itiMean, itiLambda, nTrialsPerRun)
            itis = np.clip(itis, itiMin, itiMax)
            print '  attempt ', attempt, ' = ', sum(itis)
            if not bestItis or sum(itis) < sum(bestItis):
                bestItis = itis
            totalRunTime = sum(itis) + nTrainTrialsPerRun * trainTrialFixedTime + nTestTrialsPerRun * testTrialFixedTime + runOverheadTime
            print '                total run time = ', totalRunTime, ' vs. ', maxAllowedRunTime
            if totalRunTime < maxAllowedRunTime:
                break
        bestItis = list(bestItis)
        allItis.extend(bestItis) # add ITI's for this run to the list
        runItisSanity.append(bestItis) # for sanity

    nextItiIdx = 0
    assert len(allItis) == nTotalTrials
# psychopy only writes the data at the very end
# we want data with intermediate results
# so we have this thing that dumps to a .wtf-tile
# as the experiment is going on
#
streamingFilename = thisExp.dataFileName + '.wtf'
streamingFile = open(streamingFilename, 'a')
streamingDelim = ','

# get names of data columns
#
def getExpDataNames():
    names = thisExp._getAllParamNames()
    names.extend(thisExp.dataNames)
    # names from the extraInfo dictionary
    names.extend(thisExp._getExtraInfo()[0])
    return names

# write a header lines
#
def writeHeadersToStreamingFile():
    for heading in getExpDataNames():
        streamingFile.write(u'%s%s' % (heading, streamingDelim))
    streamingFile.write('\n')
    streamingFile.flush()

def flushEntryToStreamingFile(entry):
    for name in getExpDataNames():
        entry.keys()
        if name in entry.keys():
            ename = unicode(entry[name])
            if ',' in ename or '\n' in ename:
                fmt = u'"%s"%s'
            else:
                fmt = u'%s%s'
            streamingFile.write(fmt % (entry[name], streamingDelim))
        else:
            streamingFile.write(streamingDelim)
    streamingFile.write('\n')
    streamingFile.flush()

nextEntryToFlush = 0

# write entries that we haven't flushed yet
# this writes both to the .wtf file and to the mysql db
#
def flushEntries():
    global nextEntryToFlush

    # don't write anything during the initial run
    # that's b/c the number of columns can change
    #
    if runs.thisN == 0:
        return

    # if we're after the initial run, flush everything
    # that we haven't flushed yet
    #
    while nextEntryToFlush < len(thisExp.entries):
        flushEntryToStreamingFile(thisExp.entries[nextEntryToFlush])
        nextEntryToFlush += 1



def addFmriClockData(column = 'fmriTime', add = 0): # for tracking different events
    thisExp.addData(column, fmriClock.getTime() + add)

def addExtraData(): # extra info we want to record on every train/test trial
    thisExp.addData('contextsReshuffled', ','.join([str(x) for x in contextsReshuffled]))
    thisExp.addData('contextIdReal', contextId)
    thisExp.addData('restaurant', restaurants[contextsReshuffled[contextId]])
    thisExp.addData('cuesReshuffled', ','.join([str(x) for x in cuesReshuffled]))
    thisExp.addData('cueIdReal', cueId)
    thisExp.addData('food', foodFilesPrefix + str(cuesReshuffled[cueId]))
    thisExp.addData('contextRoleReal', contextRole)
    thisExp.addData('corrAnsReal', corrAns)
    thisExp.addData('sickReal', sick)
trialInstrText = visual.TextStim(win=win, ori=0, name='trialInstrText',
    text='Predict whether the customer will get sick from this food.',    font='Arial',
    pos=[0, 0.8], height=0.075, wrapWidth=20,
    color='white', colorSpace='rgb', opacity=1,
    depth=-8.0)
restaurantText = visual.TextStim(win=win, ori=0, name='restaurantText',
    text='default text',    font='Arial Bold',
    pos=[0, +0.35], height=0.1, wrapWidth=None,
    color='pink', colorSpace='rgb', opacity=1,
    depth=-9.0)
foodImg = visual.ImageStim(win=win, name='foodImg',
    image='sin', mask=None,
    ori=0, pos=[0, 0.0], size=[0.5, 0.5],
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-10.0)
sickImg = visual.ImageStim(win=win, name='sickImg',
    image=os.path.join('images', 'sick.png'), mask=None,
    ori=0, pos=[-0.5, -0.6], size=[0.3, 0.45],
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-11.0)
notsickImg = visual.ImageStim(win=win, name='notsickImg',
    image=os.path.join('images', 'smiley.png'), mask=None,
    ori=0, pos=[+0.5, -0.6], size=[0.3, 0.45],
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-12.0)
ITI = core.StaticPeriod(win=win, screenHz=expInfo['frameRate'], name='ITI')
sickHighlight = visual.TextStim(win=win, ori=0, name='sickHighlight',
    text='_',    font='Arial',
    pos=[-0.5, -0.35], height=1.0, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-14.0)
notsickHighlight = visual.TextStim(win=win, ori=0, name='notsickHighlight',
    text='_',    font='Arial',
    pos=[0.5, -0.35], height=1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-15.0)
correctText = visual.TextStim(win=win, ori=0, name='correctText',
    text='CORRECT',    font='Arial Bold',
    pos=[0, -0.4], height=0.15, wrapWidth=None,
    color='blue', colorSpace='rgb', opacity=1,
    depth=-16.0)
wrongText = visual.TextStim(win=win, ori=0, name='wrongText',
    text='WRONG',    font='Arial Bold',
    pos=[0, -0.4], height=0.15, wrapWidth=None,
    color='red', colorSpace='rgb', opacity=1,
    depth=-17.0)
timeoutText = visual.TextStim(win=win, ori=0, name='timeoutText',
    text='TIMEOUT',    font='Arial Bold',
    pos=[0, -0.4], height=0.15, wrapWidth=None,
    color='red', colorSpace='rgb', opacity=1,
    depth=-18.0)
gotSickText = visual.TextStim(win=win, ori=0, name='gotSickText',
    text='The customer got sick!',    font='Arial',
    pos=[0, -0.55], height=0.075, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-19.0)
didntGetSickText = visual.TextStim(win=win, ori=0, name='didntGetSickText',
    text="The customer didn't get sick!",    font='Arial',
    pos=[0, -0.55], height=0.075, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-20.0)
ISI = core.StaticPeriod(win=win, screenHz=expInfo['frameRate'], name='ISI')
fixationITIText = visual.TextStim(win=win, ori=0, name='fixationITIText',
    text='+',    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-22.0)

# Initialize components for Routine "test_warning"
test_warningClock = core.Clock()
testTrialsHeadsUp = visual.TextStim(win=win, ori=0, name='testTrialsHeadsUp',
    text='Beginning test phase.\n\nYou will not receive feedback on the following 4 trials.',    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=0.0)

# Initialize components for Routine "test_2"
test_2Clock = core.Clock()






ITI_2 = core.StaticPeriod(win=win, screenHz=expInfo['frameRate'], name='ITI_2')
trialInstrText_2 = visual.TextStim(win=win, ori=0, name='trialInstrText_2',
    text='Predict whether the customer will get sick from this food.',    font='Arial',
    pos=[0, 0.8], height=0.075, wrapWidth=20,
    color='white', colorSpace='rgb', opacity=1,
    depth=-8.0)
restaurantText_2 = visual.TextStim(win=win, ori=0, name='restaurantText_2',
    text='default text',    font='Arial Bold',
    pos=[0, +0.35], height=0.1, wrapWidth=None,
    color='pink', colorSpace='rgb', opacity=1,
    depth=-9.0)
foodImg_2 = visual.ImageStim(win=win, name='foodImg_2',
    image='sin', mask=None,
    ori=0, pos=[0, 0.0], size=[0.5, 0.5],
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-10.0)
sickImg_2 = visual.ImageStim(win=win, name='sickImg_2',
    image=os.path.join('images', 'sick.png'), mask=None,
    ori=0, pos=[-0.5, -0.6], size=[0.3, 0.45],
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-11.0)
notsickImg_2 = visual.ImageStim(win=win, name='notsickImg_2',
    image=os.path.join('images', 'smiley.png'), mask=None,
    ori=0, pos=[+0.5, -0.6], size=[0.3, 0.45],
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-12.0)
sickHighlight_2 = visual.TextStim(win=win, ori=0, name='sickHighlight_2',
    text='_',    font='Arial',
    pos=[-0.5, -0.35], height=1.0, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-13.0)
notsickHighlight_2 = visual.TextStim(win=win, ori=0, name='notsickHighlight_2',
    text='_',    font='Arial',
    pos=[0.5, -0.35], height=1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-14.0)
fixationJitterText_2 = visual.TextStim(win=win, ori=0, name='fixationJitterText_2',
    text='+',    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-15.0)

# Initialize components for Routine "Fixation_2"
Fixation_2Clock = core.Clock()
fixationCross_2 = visual.TextStim(win=win, ori=0, name='fixationCross_2',
    text='+',    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=0.0)

# Initialize components for Routine "waitForFinish"
waitForFinishClock = core.Clock()
EXP_DURATION = 352.5
finishText = visual.TextStim(win=win, ori=0, name='finishText',
    text='Please wait for scanner to finish...',    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=None,
    color='black', colorSpace='rgb', opacity=1,
    depth=-1.0)

# Initialize components for Routine "thankyou"
thankyouClock = core.Clock()
if expInfo['mriMode'] != 'off': # we're scanning!
    assert expInfo['mriMode'] == 'scan'
    thankYouMsg = "You have completed the experiment. Please wait for the researcher."
else: # not scanning => behavioral
    thankYouMsg = "You have completed the experiment. Please open the door and wait for your researcher."


thankYouText = visual.TextStim(win=win, ori=0, name='thankYouText',
    text=thankYouMsg,    font='Arial',
    pos=[0, 0], height=0.1, wrapWidth=None,
    color='white', colorSpace='rgb', opacity=1,
    depth=-1.0)

# Create some handy timers
globalClock = core.Clock()  # to track the time since experiment started
routineTimer = core.CountdownTimer()  # to track time remaining of each (non-slip) routine 

#------Prepare to start Routine "instr"-------
t = 0
instrClock.reset()  # clock 
frameN = -1
routineTimer.add(120.000000)
# update component parameters for each repeat


startExpResp = event.BuilderKeyResponse()  # create an object of type KeyResponse
startExpResp.status = NOT_STARTED
# keep track of which components have finished
instrComponents = []
instrComponents.append(instrText)
instrComponents.append(startExpResp)
for thisComponent in instrComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

#-------Start Routine "instr"-------
continueRoutine = True
while continueRoutine and routineTimer.getTime() > 0:
    # get current time
    t = instrClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame
    
    
    
    # *instrText* updates
    if t >= 0.0 and instrText.status == NOT_STARTED:
        # keep track of start time/frame for later
        instrText.tStart = t  # underestimates by a little under one frame
        instrText.frameNStart = frameN  # exact frame index
        instrText.setAutoDraw(True)
    if instrText.status == STARTED and t >= (0.0 + (120-win.monitorFramePeriod*0.75)): #most of one frame period left
        instrText.setAutoDraw(False)
    
    # *startExpResp* updates
    if t >= 1 and startExpResp.status == NOT_STARTED:
        # keep track of start time/frame for later
        startExpResp.tStart = t  # underestimates by a little under one frame
        startExpResp.frameNStart = frameN  # exact frame index
        startExpResp.status = STARTED
        # keyboard checking is just starting
        startExpResp.clock.reset()  # now t=0
        event.clearEvents(eventType='keyboard')
    if startExpResp.status == STARTED and t >= (120-win.monitorFramePeriod*0.75): #most of one frame period left
        startExpResp.status = STOPPED
    if startExpResp.status == STARTED:
        theseKeys = event.getKeys(keyList=['y', 'n', 'left', 'right', 'space', '1', '2'])
        
        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            startExpResp.keys = theseKeys[-1]  # just the last key pressed
            startExpResp.rt = startExpResp.clock.getTime()
            # a response ends the routine
            continueRoutine = False
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in instrComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

#-------Ending Routine "instr"-------
for thisComponent in instrComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)


# check responses
if startExpResp.keys in ['', [], None]:  # No response was made
   startExpResp.keys=None
# store data for thisExp (ExperimentHandler)
thisExp.addData('startExpResp.keys',startExpResp.keys)
if startExpResp.keys != None:  # we had a response
    thisExp.addData('startExpResp.rt', startExpResp.rt)
thisExp.nextEntry()

# set up handler to look after randomisation of conditions etc
runs = data.TrialHandler(nReps=1, method='random', 
    extraInfo=expInfo, originPath=u'/Users/memsql/Dropbox/Research/context/psychopy-2/context.psyexp',
    trialList=data.importConditions('runs.xlsx', selection='range(1,10)'),
    seed=None, name='runs')
thisExp.addLoop(runs)  # add the loop to the experiment
thisRun = runs.trialList[0]  # so we can initialise stimuli with some values
# abbreviate parameter names if possible (e.g. rgb=thisRun.rgb)
if thisRun != None:
    for paramName in thisRun.keys():
        exec(paramName + '= thisRun.' + paramName)

for thisRun in runs:
    currentLoop = runs
    # abbreviate parameter names if possible (e.g. rgb = thisRun.rgb)
    if thisRun != None:
        for paramName in thisRun.keys():
            exec(paramName + '= thisRun.' + paramName)
    
    #------Prepare to start Routine "new_run"-------
    t = 0
    new_runClock.reset()  # clock 
    frameN = -1
    # update component parameters for each repeat
    runInstr.setText("Beginning round #" + str(runs.thisN + 1))
    # Parse the comma-separated list of restaurant names
    #
    restaurants = [r.strip() for r in restaurantNames.split(',')]
    assert len(restaurants) == 3, "There should be 3 comma-separated restaurant names per run; found " + str(len(restaurants))
    
    # Use a separate, hardcoded set of restaurants and foods if it's just a practice run
    #
    if expInfo['isPractice'] == 'yes':
        restaurants = ['Seven Hills', 'Blue Bottle Cafe', 'Restaurant Gary Danko']
        foodFilesPrefix = 'practice_food'
    # Random shuffle the context roles so they're independent from the
    # restaurants / foods.
    #
    # Notice that we ONLY DO THIS ONCE at the beginning
    #
    try:
        assert contextRolesWereShuffled
    except NameError:
        # hack to make sure this happens only once
        # we can't put in Begin Experiment b/c runs is not initialized there
        #
        contextRoles = [run['contextRole'] for run in runs.trialList]
        print 'original contextRoles = ', contextRoles
        # do a psychopy random (NOT fullRandom) shuffle --
        # put contexts in 3 groups (each with all 3 context roles)
        # and shuffle each group separately,
        # e.g. b c a  b a c  a c b
        #
        assert len(contextRoles) % 3 == 0
        shuffledContextRoles = []
        for i in range(3):
            bunch = contextRoles[i * 3 : (i + 1) * 3]
            assert len(bunch) == 3
            assert len(set(bunch)) == 3
            shuffle(bunch)
            shuffledContextRoles.extend(bunch)
        contextRoles = shuffledContextRoles
        print 'Shuffled context roles = ', contextRoles
        # set the flag so we don't run this code again
        #
        contextRolesWereShuffled = True
    
    # very important to set it here so
    # 1) it gets used to initialize the trial loop, and
    # 2) it gets written out to the data file
    #
    thisRun.contextRole = contextRoles[runs.thisN]
    contextRole = contextRoles[runs.thisN] # .................. 
    
    
    # randomize mapping between cues & contexts <--> foods & restaurants
    # within each run
    # note that we DO THIS BEFORE EVERY RUN
    # also note that this is separate from randomizing the order of the 
    # cue-context pairs. This is just the x_i -> image , c_i -> restaurant mapping
    #
    cuesReshuffled = range(0, 3)
    contextsReshuffled = range(0, 3)
    
    shuffle(cuesReshuffled)
    shuffle(contextsReshuffled)
    
    print 'Shuffled cues: ', cuesReshuffled
    print 'Shuffled contexts: ', contextsReshuffled
    
    
    key_resp_3 = event.BuilderKeyResponse()  # create an object of type KeyResponse
    key_resp_3.status = NOT_STARTED
    # keep track of which components have finished
    new_runComponents = []
    new_runComponents.append(runInstr)
    new_runComponents.append(key_resp_3)
    for thisComponent in new_runComponents:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED
    
    #-------Start Routine "new_run"-------
    continueRoutine = True
    while continueRoutine:
        # get current time
        t = new_runClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame
        
        
        
        
        
        
        # *runInstr* updates
        if t >= 0.0 and runInstr.status == NOT_STARTED:
            # keep track of start time/frame for later
            runInstr.tStart = t  # underestimates by a little under one frame
            runInstr.frameNStart = frameN  # exact frame index
            runInstr.setAutoDraw(True)
        if runInstr.status == STARTED and t >= (0.0 + (100.0-win.monitorFramePeriod*0.75)): #most of one frame period left
            runInstr.setAutoDraw(False)
        
        # *key_resp_3* updates
        if t >= 0.0 and key_resp_3.status == NOT_STARTED:
            # keep track of start time/frame for later
            key_resp_3.tStart = t  # underestimates by a little under one frame
            key_resp_3.frameNStart = frameN  # exact frame index
            key_resp_3.status = STARTED
            # keyboard checking is just starting
            key_resp_3.clock.reset()  # now t=0
            event.clearEvents(eventType='keyboard')
        if key_resp_3.status == STARTED:
            theseKeys = event.getKeys(keyList=['space'])
            
            # check for quit:
            if "escape" in theseKeys:
                endExpNow = True
            if len(theseKeys) > 0:  # at least one key was pressed
                key_resp_3.keys = theseKeys[-1]  # just the last key pressed
                key_resp_3.rt = key_resp_3.clock.getTime()
                # a response ends the routine
                continueRoutine = False
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in new_runComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()
    
    #-------Ending Routine "new_run"-------
    for thisComponent in new_runComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    
    
    
    
    # in practice mode, only run 1 round
    #
    if expInfo['isPractice'] == 'yes':
        runs.finished = True
    # check responses
    if key_resp_3.keys in ['', [], None]:  # No response was made
       key_resp_3.keys=None
    # store data for runs (TrialHandler)
    runs.addData('key_resp_3.keys',key_resp_3.keys)
    if key_resp_3.keys != None:  # we had a response
        runs.addData('key_resp_3.rt', key_resp_3.rt)
    # the Routine "new_run" was not non-slip safe, so reset the non-slip timer
    routineTimer.reset()
    
    #------Prepare to start Routine "waitForTrigger"-------
    t = 0
    waitForTriggerClock.reset()  # clock 
    frameN = -1
    # update component parameters for each repeat
    if expInfo['mriMode'] != 'off': # or 'scan' !
        assert expInfo['mriMode'] == 'scan'
    
        if trigger == 'usb':
            vol = launchScan(win, MR_settings, 
                  globalClock=fmriClock, # <-- how you know the time! 
                  mode=expInfo['mriMode']) # <-- mode passed in
        elif trigger == 'parallel':
            parallel.setPortAddress(0x378)
            pin = 10; wait_msg = "Waiting for scanner..."
            pinStatus = parallel.readPin(pin)
            waitMsgStim = visual.TextStim(win, color='DarkGray', text=wait_msg)
            waitMsgStim.draw()
            win.flip()
            while True:
                if pinStatus != parallel.readPin(pin) or len(event.getKeys('esc')):
                   break
                   # start exp when pin values change
            globalClock.reset()
            logging.defaultClock.reset()
            logging.exp('parallel trigger: start of scan')
            win.flip()  # blank the screen on first sync pulse received
    else:
        fmriClock.reset()
    
    expInfo['triggerWallTime'] = time.ctime()
    core.wait(1)
    # keep track of which components have finished
    waitForTriggerComponents = []
    for thisComponent in waitForTriggerComponents:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED
    
    #-------Start Routine "waitForTrigger"-------
    continueRoutine = True
    while continueRoutine:
        # get current time
        t = waitForTriggerClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame
        
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in waitForTriggerComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()
    
    #-------Ending Routine "waitForTrigger"-------
    for thisComponent in waitForTriggerComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    routineTimer.reset()
    # the Routine "waitForTrigger" was not non-slip safe, so reset the non-slip timer
    routineTimer.reset()
    
    #------Prepare to start Routine "Fixation"-------
    t = 0
    FixationClock.reset()  # clock 
    frameN = -1
    routineTimer.add(10.000000)
    # update component parameters for each repeat
    # keep track of which components have finished
    FixationComponents = []
    FixationComponents.append(fixationCross)
    for thisComponent in FixationComponents:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED
    
    #-------Start Routine "Fixation"-------
    continueRoutine = True
    while continueRoutine and routineTimer.getTime() > 0:
        # get current time
        t = FixationClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame
        
        # *fixationCross* updates
        if t >= 0.0 and fixationCross.status == NOT_STARTED:
            # keep track of start time/frame for later
            fixationCross.tStart = t  # underestimates by a little under one frame
            fixationCross.frameNStart = frameN  # exact frame index
            fixationCross.setAutoDraw(True)
        if fixationCross.status == STARTED and t >= (0.0 + (10.0-win.monitorFramePeriod*0.75)): #most of one frame period left
            fixationCross.setAutoDraw(False)
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in FixationComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()
    
    #-------Ending Routine "Fixation"-------
    for thisComponent in FixationComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    
    # set up handler to look after randomisation of conditions etc
    trials = data.TrialHandler(nReps=5, method='fullRandom', 
        extraInfo=expInfo, originPath=u'/Users/memsql/Dropbox/Research/context/psychopy-2/context.psyexp',
        trialList=data.importConditions(contextRole + '.xlsx', selection='range(1,5)'),
        seed=None, name='trials')
    thisExp.addLoop(trials)  # add the loop to the experiment
    thisTrial = trials.trialList[0]  # so we can initialise stimuli with some values
    # abbreviate parameter names if possible (e.g. rgb=thisTrial.rgb)
    if thisTrial != None:
        for paramName in thisTrial.keys():
            exec(paramName + '= thisTrial.' + paramName)
    
    for thisTrial in trials:
        currentLoop = trials
        # abbreviate parameter names if possible (e.g. rgb = thisTrial.rgb)
        if thisTrial != None:
            for paramName in thisTrial.keys():
                exec(paramName + '= thisTrial.' + paramName)
        
        #------Prepare to start Routine "trial"-------
        t = 0
        trialClock.reset()  # clock 
        frameN = -1
        # update component parameters for each repeat
        trials.addData('trialStartWallTime', time.ctime())
        # clear the feedback
        isFeedbackShown = False
        correctText.setOpacity(0)
        wrongText.setOpacity(0)
        timeoutText.setOpacity(0)
        gotSickText.setOpacity(0)
        didntGetSickText.setOpacity(0)
        # hack to re-render the texts with new opacity
        correctText.setText(correctText.text)
        wrongText.setText(wrongText.text)
        timeoutText.setText(timeoutText.text)
        gotSickText.setText(gotSickText.text)
        didntGetSickText.setText(didntGetSickText.text)
        addFmriClockData('choiceOnset')
        
        # in fMRI mode, remap the correct ans 'left' => 1, 'right' => 2 
        # this is crucial to give correct feedback!
        #
        if expInfo['mriMode'] != 'off': # we're scanning!
            assert expInfo['mriMode'] == 'scan'
            if corrAns == 'left':
                corrAns = '1'
            elif corrAns == 'right':
                corrAns = '2'
        
        # don't highlight anything initially
        #
        sickHighlight.setOpacity(0)
        notsickHighlight.setOpacity(0)
        # hack to re-render the text with new opacity
        sickHighlight.setText(sickHighlight.text)
        notsickHighlight.setText(notsickHighlight.text)
        # save the last response key so we don't re-render the _
        #
        lastReponseKey = None
        
        # track whether subject has responded so we can record response time
        # also initialize the response time by 3 (== timeout)
        #
        maxRespTime = 3
        respTime = maxRespTime # by default it's timeout
        hasResponded = False
        respTime = 3 # TODO FIXME hardcoded -- this is the default
        
        if expInfo['mriMode'] != 'off': # we're scanning
            assert expInfo['mriMode'] == 'scan'
        
            # Note that here we override the cueId and the contextId
            #
            itiTime = fMRI_run_itis[runs.thisN][trials.thisN]
            itiOffset = fMRI_run_itiOffsets[runs.thisN][trials.thisN]
            cueId = fMRI_run_cueIds[runs.thisN][trials.thisN]
            contextId = fMRI_run_contextIds[runs.thisN][trials.thisN]
        
            # .......................
            #
            if contextRole == 'irrelevant':
                if cueId == 0:
                    sick = 'Yes'
                    corrAns = sickButton
                else:
                    sick = 'No'
                    corrAns = notsickButton
        
            elif contextRole == 'modulatory':
                if cueId == contextId:
                    sick = 'Yes'
                    corrAns = sickButton
                else:
                    sick = 'No'
                    corrAns = notsickButton
            else:
                assert contextRole == 'additive'
                if contextId == 0:
                    sick = 'Yes'
                    corrAns = sickButton
                else:
                    sick = 'No'
                    corrAns = notsickButton
        
            print 'WHAT THE FUCK ', thisRun.contextRole
            print 'laksdjfhk;asdfjaksdjfh ', contextRole
        
            print '(fMRI train) iti time = ', itiTime, ' itiOffset = ', itiOffset, ' cueId = ', cueId, ' contextId = ', contextId
            thisExp.addData('itiTime', itiTime)
        
        else: # behavioral => different codepath
        
            print '(train) next iti idx = ', nextItiIdx
        
            assert nextItiIdx == runs.thisN * nTrialsPerRun + trials.thisN, \
                str(nextItiIdx) + " == " + str(runs.thisN) + " * " + str(nTrialsPerRun) + " + " + str(trials.thisN)
        
            itiTime = allItis[nextItiIdx]
            nextItiIdx += 1
        
            print '(train) iti time = ', itiTime
            thisExp.addData('itiTime', itiTime)
        
            #print runs.thisN
            #print trials.thisN
            #print len(runItisSanity)
            #print len(runItisSanity[runs.thisN])
        
            assert itiTime == runItisSanity[runs.thisN][trials.thisN], \
                str(itiTime) + " == runItisSanity[" + str(runs.thisN) + "][" + str(trials.thisN) + "] = " + runItisSanity[runs.thisN][trials.thisN]
            assert itiTime >= itiMin
            assert itiTime <= itiMax
        
        assert contextRolesWereShuffled
        thisExp.addData('trialOrTest', 'trial')
        
        # MUST BE LAST! b/c we change the cueId and contextId above
        addExtraData()
        responseKey = event.BuilderKeyResponse()  # create an object of type KeyResponse
        responseKey.status = NOT_STARTED
        restaurantText.setText(restaurants[contextsReshuffled[contextId]])
        foodImg.setImage(os.path.join('foods', foodFilesPrefix + str(cuesReshuffled[cueId]) + '.png'))
        # keep track of which components have finished
        trialComponents = []
        trialComponents.append(responseKey)
        trialComponents.append(trialInstrText)
        trialComponents.append(restaurantText)
        trialComponents.append(foodImg)
        trialComponents.append(sickImg)
        trialComponents.append(notsickImg)
        trialComponents.append(ITI)
        trialComponents.append(sickHighlight)
        trialComponents.append(notsickHighlight)
        trialComponents.append(correctText)
        trialComponents.append(wrongText)
        trialComponents.append(timeoutText)
        trialComponents.append(gotSickText)
        trialComponents.append(didntGetSickText)
        trialComponents.append(ISI)
        trialComponents.append(fixationITIText)
        for thisComponent in trialComponents:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED
        
        #-------Start Routine "trial"-------
        continueRoutine = True
        while continueRoutine:
            # get current time
            t = trialClock.getTime()
            frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
            # update/draw components on each frame
            
            # show user some feedback, and log the ISI / feedback times
            # TODO FIXME stuff is hardcoded here
            #
            if t >= respTime + 1 and not isFeedbackShown: # TODO ISI time (1) is hardcoded
                isFeedbackShown = True
                print '      Feedback time: ', t
                addFmriClockData('isiOffset')
                addFmriClockData('feedbackOnset')
                addFmriClockData('feedbackOffset', 1) # TODO feedback time (1) is hardcoded
                addFmriClockData('itiOnset', 1) # TODO same
            
                if not responseKey.keys: # no response was made
                    timeoutText.setOpacity(1)
                    timeoutText.setText(timeoutText.text)
                else: # response was made
                    if responseKey.corr == 1:
                        correctText.setOpacity(1)
                        wrongText.setOpacity(0)
                    elif responseKey.corr == 0:
                        correctText.setOpacity(0)
                        wrongText.setOpacity(1)
                    else:
                        print responseKey.corr
                        assert False, "responseKey.corr = 0 or 1"
            
                    if sick == 'Yes':
                        gotSickText.setOpacity(1)
                        didntGetSickText.setOpacity(0)
                    elif sick == 'No':
                        gotSickText.setOpacity(0)
                        didntGetSickText.setOpacity(1)
                    else:
                        print sick
                        assert False, "sick can only be Yes or No"
            
                    # hack to redraw the texts with new opacity
                    correctText.setText(correctText.text)
                    wrongText.setText(wrongText.text)
                    gotSickText.setText(gotSickText.text)
                    didntGetSickText.setText(didntGetSickText.text)
            
            # highlight subject's response and log the response time
            #
            if responseKey.keys and not hasResponded:
                hasResponded = True
            
                # do the timing first
                # at this point, we are starting the ISI
                # => we have 1 second of ISI and 1 second of feedback before the ITI
                #
                # TODO more hardcoded crap...
                #
            
                # this code is deprecated; included for sanity check
                respTime = responseKey.rt
                residual = maxRespTime - respTime
                itiTime += residual
                print '        train response highlight: ', t
                print '           residual = ', residual
                print '           new ITI = ', itiTime
            
                # this is the real deal
                timeLeftUntilItiOffset = itiOffset - fmriClock.getTime()
                finalItiTime = timeLeftUntilItiOffset - 2 # less the ISI and the feedback TODO hardcoded
                print '           final ITI = ', finalItiTime
                itiDriftAdjustment = finalItiTime - itiTime
                print '           adjustment = ', itiDriftAdjustment 
                if finalItiTime < 0:
                    finalItiTime = 0 # worst case scenario... if we've drifted too far
                itiTime = finalItiTime # very important to set itiTime -- this is the one that's used in the GUI for the duration of the ITI segment
            
                addFmriClockData('choiceOffset')
                addFmriClockData('isiOnset')
                thisExp.addData('responseTime', respTime)
                thisExp.addData('residualTime', residual)
                thisExp.addData('newItiTime', itiTime)
                thisExp.addData('estimatedItiOffset', itiOffset)
                thisExp.addData('itiDriftAdjustment', itiDriftAdjustment)
            
                # then highlight choice
                #
                if responseKey.keys == sickButton: # sick
                    sickHighlight.opacity = 1
                    notsickHighlight.opacity = 0
                elif responseKey.keys == notsickButton: # not sick
                    sickHighlight.opacity = 0
                    notsickHighlight.opacity = 1
                else:
                    assert False, 'Can only have one response, sick or not sick'
                # save last response so we don't re-render
                lastReponseKey = responseKey.keys 
                # hack to re-render the text with new opacity
                sickHighlight.setText(sickHighlight.text)
                notsickHighlight.setText(notsickHighlight.text)
            
            
            
            
            
            
            # *responseKey* updates
            if t >= 0 and responseKey.status == NOT_STARTED:
                # keep track of start time/frame for later
                responseKey.tStart = t  # underestimates by a little under one frame
                responseKey.frameNStart = frameN  # exact frame index
                responseKey.status = STARTED
                # keyboard checking is just starting
                responseKey.clock.reset()  # now t=0
                event.clearEvents(eventType='keyboard')
            if responseKey.status == STARTED and t >= (0 + (respTime-win.monitorFramePeriod*0.75)): #most of one frame period left
                responseKey.status = STOPPED
            if responseKey.status == STARTED:
                theseKeys = event.getKeys(keyList=['left', 'right', '1', '2'])
                
                # check for quit:
                if "escape" in theseKeys:
                    endExpNow = True
                if len(theseKeys) > 0:  # at least one key was pressed
                    if responseKey.keys == []:  # then this was the first keypress
                        responseKey.keys = theseKeys[0]  # just the first key pressed
                        responseKey.rt = responseKey.clock.getTime()
                        # was this 'correct'?
                        if (responseKey.keys == str(corrAns)) or (responseKey.keys == corrAns):
                            responseKey.corr = 1
                        else:
                            responseKey.corr = 0
            
            # *trialInstrText* updates
            if t >= 0 and trialInstrText.status == NOT_STARTED:
                # keep track of start time/frame for later
                trialInstrText.tStart = t  # underestimates by a little under one frame
                trialInstrText.frameNStart = frameN  # exact frame index
                trialInstrText.setAutoDraw(True)
            if trialInstrText.status == STARTED and t >= (0 + (respTime + 2-win.monitorFramePeriod*0.75)): #most of one frame period left
                trialInstrText.setAutoDraw(False)
            
            # *restaurantText* updates
            if t >= 0 and restaurantText.status == NOT_STARTED:
                # keep track of start time/frame for later
                restaurantText.tStart = t  # underestimates by a little under one frame
                restaurantText.frameNStart = frameN  # exact frame index
                restaurantText.setAutoDraw(True)
            if restaurantText.status == STARTED and t >= (0 + (respTime + 2-win.monitorFramePeriod*0.75)): #most of one frame period left
                restaurantText.setAutoDraw(False)
            
            # *foodImg* updates
            if t >= 0 and foodImg.status == NOT_STARTED:
                # keep track of start time/frame for later
                foodImg.tStart = t  # underestimates by a little under one frame
                foodImg.frameNStart = frameN  # exact frame index
                foodImg.setAutoDraw(True)
            if foodImg.status == STARTED and t >= (0 + (respTime + 2-win.monitorFramePeriod*0.75)): #most of one frame period left
                foodImg.setAutoDraw(False)
            
            # *sickImg* updates
            if t >= 0 and sickImg.status == NOT_STARTED:
                # keep track of start time/frame for later
                sickImg.tStart = t  # underestimates by a little under one frame
                sickImg.frameNStart = frameN  # exact frame index
                sickImg.setAutoDraw(True)
            if sickImg.status == STARTED and t >= (0 + (respTime + 2-win.monitorFramePeriod*0.75)): #most of one frame period left
                sickImg.setAutoDraw(False)
            
            # *notsickImg* updates
            if t >= 0 and notsickImg.status == NOT_STARTED:
                # keep track of start time/frame for later
                notsickImg.tStart = t  # underestimates by a little under one frame
                notsickImg.frameNStart = frameN  # exact frame index
                notsickImg.setAutoDraw(True)
            if notsickImg.status == STARTED and t >= (0 + (respTime + 2-win.monitorFramePeriod*0.75)): #most of one frame period left
                notsickImg.setAutoDraw(False)
            
            # *sickHighlight* updates
            if t >= 0 and sickHighlight.status == NOT_STARTED:
                # keep track of start time/frame for later
                sickHighlight.tStart = t  # underestimates by a little under one frame
                sickHighlight.frameNStart = frameN  # exact frame index
                sickHighlight.setAutoDraw(True)
            if sickHighlight.status == STARTED and t >= (0 + (respTime + 2-win.monitorFramePeriod*0.75)): #most of one frame period left
                sickHighlight.setAutoDraw(False)
            
            # *notsickHighlight* updates
            if t >= 0 and notsickHighlight.status == NOT_STARTED:
                # keep track of start time/frame for later
                notsickHighlight.tStart = t  # underestimates by a little under one frame
                notsickHighlight.frameNStart = frameN  # exact frame index
                notsickHighlight.setAutoDraw(True)
            if notsickHighlight.status == STARTED and t >= (0 + (respTime + 2-win.monitorFramePeriod*0.75)): #most of one frame period left
                notsickHighlight.setAutoDraw(False)
            
            # *correctText* updates
            if t >= respTime + 1 and correctText.status == NOT_STARTED:
                # keep track of start time/frame for later
                correctText.tStart = t  # underestimates by a little under one frame
                correctText.frameNStart = frameN  # exact frame index
                correctText.setAutoDraw(True)
            if correctText.status == STARTED and t >= (respTime + 1 + (1-win.monitorFramePeriod*0.75)): #most of one frame period left
                correctText.setAutoDraw(False)
            
            # *wrongText* updates
            if t >= respTime + 1 and wrongText.status == NOT_STARTED:
                # keep track of start time/frame for later
                wrongText.tStart = t  # underestimates by a little under one frame
                wrongText.frameNStart = frameN  # exact frame index
                wrongText.setAutoDraw(True)
            if wrongText.status == STARTED and t >= (respTime + 1 + (1-win.monitorFramePeriod*0.75)): #most of one frame period left
                wrongText.setAutoDraw(False)
            
            # *timeoutText* updates
            if t >= respTime + 1 and timeoutText.status == NOT_STARTED:
                # keep track of start time/frame for later
                timeoutText.tStart = t  # underestimates by a little under one frame
                timeoutText.frameNStart = frameN  # exact frame index
                timeoutText.setAutoDraw(True)
            if timeoutText.status == STARTED and t >= (respTime + 1 + (1.0-win.monitorFramePeriod*0.75)): #most of one frame period left
                timeoutText.setAutoDraw(False)
            
            # *gotSickText* updates
            if t >= respTime + 1 and gotSickText.status == NOT_STARTED:
                # keep track of start time/frame for later
                gotSickText.tStart = t  # underestimates by a little under one frame
                gotSickText.frameNStart = frameN  # exact frame index
                gotSickText.setAutoDraw(True)
            if gotSickText.status == STARTED and t >= (respTime + 1 + (1.0-win.monitorFramePeriod*0.75)): #most of one frame period left
                gotSickText.setAutoDraw(False)
            
            # *didntGetSickText* updates
            if t >= respTime + 1 and didntGetSickText.status == NOT_STARTED:
                # keep track of start time/frame for later
                didntGetSickText.tStart = t  # underestimates by a little under one frame
                didntGetSickText.frameNStart = frameN  # exact frame index
                didntGetSickText.setAutoDraw(True)
            if didntGetSickText.status == STARTED and t >= (respTime + 1 + (1.0-win.monitorFramePeriod*0.75)): #most of one frame period left
                didntGetSickText.setAutoDraw(False)
            
            # *fixationITIText* updates
            if t >= respTime + 2 and fixationITIText.status == NOT_STARTED:
                # keep track of start time/frame for later
                fixationITIText.tStart = t  # underestimates by a little under one frame
                fixationITIText.frameNStart = frameN  # exact frame index
                fixationITIText.setAutoDraw(True)
            if fixationITIText.status == STARTED and t >= (respTime + 2 + (itiTime-win.monitorFramePeriod*0.75)): #most of one frame period left
                fixationITIText.setAutoDraw(False)
            # *ITI* period
            if t >= respTime + 2 and ITI.status == NOT_STARTED:
                # keep track of start time/frame for later
                ITI.tStart = t  # underestimates by a little under one frame
                ITI.frameNStart = frameN  # exact frame index
                ITI.start(itiTime)
            elif ITI.status == STARTED: #one frame should pass before updating params and completing
                ITI.complete() #finish the static period
            # *ISI* period
            if t >= respTime and ISI.status == NOT_STARTED:
                # keep track of start time/frame for later
                ISI.tStart = t  # underestimates by a little under one frame
                ISI.frameNStart = frameN  # exact frame index
                ISI.start(1)
            elif ISI.status == STARTED: #one frame should pass before updating params and completing
                ISI.complete() #finish the static period
            
            # check if all components have finished
            if not continueRoutine:  # a component has requested a forced-end of Routine
                break
            continueRoutine = False  # will revert to True if at least one component still running
            for thisComponent in trialComponents:
                if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                    continueRoutine = True
                    break  # at least one component has not yet finished
            
            # check for quit (the Esc key)
            if endExpNow or event.getKeys(keyList=["escape"]):
                core.quit()
            
            # refresh the screen
            if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                win.flip()
        
        #-------Ending Routine "trial"-------
        for thisComponent in trialComponents:
            if hasattr(thisComponent, "setAutoDraw"):
                thisComponent.setAutoDraw(False)
        trials.addData('trialEndWallTime', time.ctime())
        
        addFmriClockData('itiOffset')
        # in practice mode, only run 1 rep (4 trials)
        # ... NOT in the fMRI practice rounds => make sure they get it with a full run
        #
        #if expInfo['isPractice'] == 'yes' and trials.thisN >= 3:
        #    trials.finished = True
        flushEntries()
        
        
        # check responses
        if responseKey.keys in ['', [], None]:  # No response was made
           responseKey.keys=None
           # was no response the correct answer?!
           if str(corrAns).lower() == 'none': responseKey.corr = 1  # correct non-response
           else: responseKey.corr = 0  # failed to respond (incorrectly)
        # store data for trials (TrialHandler)
        trials.addData('responseKey.keys',responseKey.keys)
        trials.addData('responseKey.corr', responseKey.corr)
        if responseKey.keys != None:  # we had a response
            trials.addData('responseKey.rt', responseKey.rt)
        # the Routine "trial" was not non-slip safe, so reset the non-slip timer
        routineTimer.reset()
        thisExp.nextEntry()
        
    # completed 5 repeats of 'trials'
    
    
    #------Prepare to start Routine "test_warning"-------
    t = 0
    test_warningClock.reset()  # clock 
    frameN = -1
    routineTimer.add(4.000000)
    # update component parameters for each repeat
    # keep track of which components have finished
    test_warningComponents = []
    test_warningComponents.append(testTrialsHeadsUp)
    for thisComponent in test_warningComponents:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED
    
    #-------Start Routine "test_warning"-------
    continueRoutine = True
    while continueRoutine and routineTimer.getTime() > 0:
        # get current time
        t = test_warningClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame
        
        # *testTrialsHeadsUp* updates
        if t >= 0.0 and testTrialsHeadsUp.status == NOT_STARTED:
            # keep track of start time/frame for later
            testTrialsHeadsUp.tStart = t  # underestimates by a little under one frame
            testTrialsHeadsUp.frameNStart = frameN  # exact frame index
            testTrialsHeadsUp.setAutoDraw(True)
        if testTrialsHeadsUp.status == STARTED and t >= (0.0 + (4.0-win.monitorFramePeriod*0.75)): #most of one frame period left
            testTrialsHeadsUp.setAutoDraw(False)
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in test_warningComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()
    
    #-------Ending Routine "test_warning"-------
    for thisComponent in test_warningComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    
    # set up handler to look after randomisation of conditions etc
    test_trials = data.TrialHandler(nReps=1, method='fullRandom', 
        extraInfo=expInfo, originPath=u'/Users/memsql/Dropbox/Research/context/psychopy-2/context.psyexp',
        trialList=data.importConditions(contextRole + '.xlsx', selection='range(6,10)'),
        seed=None, name='test_trials')
    thisExp.addLoop(test_trials)  # add the loop to the experiment
    thisTest_trial = test_trials.trialList[0]  # so we can initialise stimuli with some values
    # abbreviate parameter names if possible (e.g. rgb=thisTest_trial.rgb)
    if thisTest_trial != None:
        for paramName in thisTest_trial.keys():
            exec(paramName + '= thisTest_trial.' + paramName)
    
    for thisTest_trial in test_trials:
        currentLoop = test_trials
        # abbreviate parameter names if possible (e.g. rgb = thisTest_trial.rgb)
        if thisTest_trial != None:
            for paramName in thisTest_trial.keys():
                exec(paramName + '= thisTest_trial.' + paramName)
        
        #------Prepare to start Routine "test_2"-------
        t = 0
        test_2Clock.reset()  # clock 
        frameN = -1
        # update component parameters for each repeat
        trials.addData('trialStartWallTime', time.ctime())
        # invalid
        """
        # clear the feedback
        isFeedbackShown_2 = False
        timeoutText_2.setOpacity(0)
        # hack to re-render the texts with new opacity
        timeoutText_2.setText(timeoutText_2.text)
        """
        addFmriClockData('choiceOnset')
        addFmriClockData('isiOffset', 6) # TODO FIXME hardcoded trial duration
        addFmriClockData('itiOnset', 6) # TODO FIXME hardcoded trial duration
        
        # don't highlight anything initially
        #
        sickHighlight_2.setOpacity(0)
        notsickHighlight_2.setOpacity(0)
        # hack to re-render the text with new opacity
        sickHighlight_2.setText(sickHighlight_2.text)
        notsickHighlight_2.setText(notsickHighlight_2.text)
        # save the last response so we don't re-render the _
        lastReponseKey_2 = None
        
        hasResponded_2 = False
        
        if expInfo['mriMode'] != 'off': # we're scanning
            assert expInfo['mriMode'] == 'scan'
        
            # Note that here we override the cueId and the contextId
            #
            itiTime_2 = fMRI_run_itis[runs.thisN][test_trials.thisN + nTrainTrialsPerRun]
            cueId = fMRI_run_cueIds[runs.thisN][test_trials.thisN + nTrainTrialsPerRun]
            contextId = fMRI_run_contextIds[runs.thisN][test_trials.thisN + nTrainTrialsPerRun]
        
            print '(fMRI test) iti time = ', itiTime_2, ' cueId = ', cueId, ' contextId = ', contextId
            thisExp.addData('itiTime', itiTime_2)
        
        else:  # behavioral
            print '(test) next iti idx = ', nextItiIdx
        
            assert nextItiIdx == runs.thisN * nTrialsPerRun + nTrainTrialsPerRun + test_trials.thisN, \
                str(nextItiIdx) + " == " + str(runs.thisN) + " * " + str(nTrialsPerRun) + " + " + str(nTrainTrialsPerRun) + " + " + str(test_trials.thisN)
        
            itiTime_2 = allItis[nextItiIdx]
            nextItiIdx += 1
        
            print '(test) iti time = ', itiTime_2
            thisExp.addData('itiTime', itiTime_2)
        
            assert itiTime_2 == runItisSanity[runs.thisN][nTrainTrialsPerRun + test_trials.thisN], \
                str(itiTime_2) + " == runItisSanity[" + str(runs.thisN) + "][" + str(nTrainTrialsPerRun) + " + " + str(test_trials.thisN) + "] = " + runItisSanity[runs.thisN][nTrainTrialsPerRun + test_trials.thisN]
            assert itiTime_2 >= itiMin
            assert itiTime_2 <= itiMax
        
        thisExp.addData('trialOrTest', 'test')
        
        # MUST BE LAST -> b/c we change e.g. the cueId above
        #
        addExtraData()
        responseKey_2 = event.BuilderKeyResponse()  # create an object of type KeyResponse
        responseKey_2.status = NOT_STARTED
        restaurantText_2.setText(restaurants[contextsReshuffled[contextId]])
        foodImg_2.setImage(os.path.join('foods', foodFilesPrefix + str(cuesReshuffled[cueId]) + '.png'))
        # keep track of which components have finished
        test_2Components = []
        test_2Components.append(ITI_2)
        test_2Components.append(responseKey_2)
        test_2Components.append(trialInstrText_2)
        test_2Components.append(restaurantText_2)
        test_2Components.append(foodImg_2)
        test_2Components.append(sickImg_2)
        test_2Components.append(notsickImg_2)
        test_2Components.append(sickHighlight_2)
        test_2Components.append(notsickHighlight_2)
        test_2Components.append(fixationJitterText_2)
        for thisComponent in test_2Components:
            if hasattr(thisComponent, 'status'):
                thisComponent.status = NOT_STARTED
        
        #-------Start Routine "test_2"-------
        continueRoutine = True
        while continueRoutine:
            # get current time
            t = test_2Clock.getTime()
            frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
            # update/draw components on each frame
            
            #invalid
            """
            # show user some feedback ONLY if timeout
            # otherwise we don't show feedback on test trials
            #
            if t >= 5 + itiTime_2 and not isFeedbackShown_2: # TODO don't hardcode
                isFeedbackShown_2 = True
                if not responseKey_2.keys: # no response was made
                    timeoutText_2.setOpacity(1)
                    timeoutText_2.setText(timeoutText_2.text)
                else: # response was made
                    continueRoutine = False
            """
            # highlight subject's response
            #
            if responseKey_2.keys and not hasResponded_2:
                hasResponded_2 = True
            
                # do the timing first
                #
                respTime_2 = responseKey_2.rt
            
                print '        TEST Response highlight at ', t # t is a little slower than responseKey.rt
                addFmriClockData('choiceOffset')
                addFmriClockData('isiOnset')
            
                # highlight choice
                #
                if responseKey_2.keys == sickButton: # sick
                    sickHighlight_2.opacity = 1
                    notsickHighlight_2.opacity = 0
                elif responseKey_2.keys == notsickButton: # not sick
                    sickHighlight_2.opacity = 0
                    notsickHighlight_2.opacity = 1
                else:
                    assert False, 'Can only have one response, sick or not sick'
                # save the last response so we don't re-render the _
                lastReponseKey_2 = responseKey_2.keys
                # hack to re-render the text with new opacity
                sickHighlight_2.setText(sickHighlight_2.text)
                notsickHighlight_2.setText(notsickHighlight_2.text)
            
            
            
            
            # *responseKey_2* updates
            if t >= 0 and responseKey_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                responseKey_2.tStart = t  # underestimates by a little under one frame
                responseKey_2.frameNStart = frameN  # exact frame index
                responseKey_2.status = STARTED
                # keyboard checking is just starting
                responseKey_2.clock.reset()  # now t=0
                event.clearEvents(eventType='keyboard')
            if responseKey_2.status == STARTED and t >= (0 + (6-win.monitorFramePeriod*0.75)): #most of one frame period left
                responseKey_2.status = STOPPED
            if responseKey_2.status == STARTED:
                theseKeys = event.getKeys(keyList=['left', 'right', '1', '2'])
                
                # check for quit:
                if "escape" in theseKeys:
                    endExpNow = True
                if len(theseKeys) > 0:  # at least one key was pressed
                    if responseKey_2.keys == []:  # then this was the first keypress
                        responseKey_2.keys = theseKeys[0]  # just the first key pressed
                        responseKey_2.rt = responseKey_2.clock.getTime()
                        # was this 'correct'?
                        if (responseKey_2.keys == str(corrAns)) or (responseKey_2.keys == corrAns):
                            responseKey_2.corr = 1
                        else:
                            responseKey_2.corr = 0
            
            # *trialInstrText_2* updates
            if t >= 0 and trialInstrText_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                trialInstrText_2.tStart = t  # underestimates by a little under one frame
                trialInstrText_2.frameNStart = frameN  # exact frame index
                trialInstrText_2.setAutoDraw(True)
            if trialInstrText_2.status == STARTED and t >= (0 + (6.0-win.monitorFramePeriod*0.75)): #most of one frame period left
                trialInstrText_2.setAutoDraw(False)
            
            # *restaurantText_2* updates
            if t >= 0 and restaurantText_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                restaurantText_2.tStart = t  # underestimates by a little under one frame
                restaurantText_2.frameNStart = frameN  # exact frame index
                restaurantText_2.setAutoDraw(True)
            if restaurantText_2.status == STARTED and t >= (0 + (6-win.monitorFramePeriod*0.75)): #most of one frame period left
                restaurantText_2.setAutoDraw(False)
            
            # *foodImg_2* updates
            if t >= 0 and foodImg_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                foodImg_2.tStart = t  # underestimates by a little under one frame
                foodImg_2.frameNStart = frameN  # exact frame index
                foodImg_2.setAutoDraw(True)
            if foodImg_2.status == STARTED and t >= (0 + (6.0-win.monitorFramePeriod*0.75)): #most of one frame period left
                foodImg_2.setAutoDraw(False)
            
            # *sickImg_2* updates
            if t >= 0 and sickImg_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                sickImg_2.tStart = t  # underestimates by a little under one frame
                sickImg_2.frameNStart = frameN  # exact frame index
                sickImg_2.setAutoDraw(True)
            if sickImg_2.status == STARTED and t >= (0 + (6.0-win.monitorFramePeriod*0.75)): #most of one frame period left
                sickImg_2.setAutoDraw(False)
            
            # *notsickImg_2* updates
            if t >= 0 and notsickImg_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                notsickImg_2.tStart = t  # underestimates by a little under one frame
                notsickImg_2.frameNStart = frameN  # exact frame index
                notsickImg_2.setAutoDraw(True)
            if notsickImg_2.status == STARTED and t >= (0 + (6-win.monitorFramePeriod*0.75)): #most of one frame period left
                notsickImg_2.setAutoDraw(False)
            
            # *sickHighlight_2* updates
            if t >= 0 and sickHighlight_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                sickHighlight_2.tStart = t  # underestimates by a little under one frame
                sickHighlight_2.frameNStart = frameN  # exact frame index
                sickHighlight_2.setAutoDraw(True)
            if sickHighlight_2.status == STARTED and t >= (0 + (6-win.monitorFramePeriod*0.75)): #most of one frame period left
                sickHighlight_2.setAutoDraw(False)
            
            # *notsickHighlight_2* updates
            if t >= 0 and notsickHighlight_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                notsickHighlight_2.tStart = t  # underestimates by a little under one frame
                notsickHighlight_2.frameNStart = frameN  # exact frame index
                notsickHighlight_2.setAutoDraw(True)
            if notsickHighlight_2.status == STARTED and t >= (0 + (6-win.monitorFramePeriod*0.75)): #most of one frame period left
                notsickHighlight_2.setAutoDraw(False)
            
            # *fixationJitterText_2* updates
            if t >= 6 and fixationJitterText_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                fixationJitterText_2.tStart = t  # underestimates by a little under one frame
                fixationJitterText_2.frameNStart = frameN  # exact frame index
                fixationJitterText_2.setAutoDraw(True)
            if fixationJitterText_2.status == STARTED and t >= (6 + (itiTime_2-win.monitorFramePeriod*0.75)): #most of one frame period left
                fixationJitterText_2.setAutoDraw(False)
            # *ITI_2* period
            if t >= 6 and ITI_2.status == NOT_STARTED:
                # keep track of start time/frame for later
                ITI_2.tStart = t  # underestimates by a little under one frame
                ITI_2.frameNStart = frameN  # exact frame index
                ITI_2.start(itiTime_2)
            elif ITI_2.status == STARTED: #one frame should pass before updating params and completing
                ITI_2.complete() #finish the static period
            
            # check if all components have finished
            if not continueRoutine:  # a component has requested a forced-end of Routine
                break
            continueRoutine = False  # will revert to True if at least one component still running
            for thisComponent in test_2Components:
                if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                    continueRoutine = True
                    break  # at least one component has not yet finished
            
            # check for quit (the Esc key)
            if endExpNow or event.getKeys(keyList=["escape"]):
                core.quit()
            
            # refresh the screen
            if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
                win.flip()
        
        #-------Ending Routine "test_2"-------
        for thisComponent in test_2Components:
            if hasattr(thisComponent, "setAutoDraw"):
                thisComponent.setAutoDraw(False)
        trials.addData('trialEndWallTime', time.ctime())
        
        addFmriClockData('itiOffset')
        
        flushEntries()
        
        # check responses
        if responseKey_2.keys in ['', [], None]:  # No response was made
           responseKey_2.keys=None
           # was no response the correct answer?!
           if str(corrAns).lower() == 'none': responseKey_2.corr = 1  # correct non-response
           else: responseKey_2.corr = 0  # failed to respond (incorrectly)
        # store data for test_trials (TrialHandler)
        test_trials.addData('responseKey_2.keys',responseKey_2.keys)
        test_trials.addData('responseKey_2.corr', responseKey_2.corr)
        if responseKey_2.keys != None:  # we had a response
            test_trials.addData('responseKey_2.rt', responseKey_2.rt)
        # the Routine "test_2" was not non-slip safe, so reset the non-slip timer
        routineTimer.reset()
        thisExp.nextEntry()
        
    # completed 1 repeats of 'test_trials'
    
    
    #------Prepare to start Routine "Fixation_2"-------
    t = 0
    Fixation_2Clock.reset()  # clock 
    frameN = -1
    routineTimer.add(6.000000)
    # update component parameters for each repeat
    # keep track of which components have finished
    Fixation_2Components = []
    Fixation_2Components.append(fixationCross_2)
    for thisComponent in Fixation_2Components:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED
    
    #-------Start Routine "Fixation_2"-------
    continueRoutine = True
    while continueRoutine and routineTimer.getTime() > 0:
        # get current time
        t = Fixation_2Clock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame
        
        # *fixationCross_2* updates
        if t >= 0.0 and fixationCross_2.status == NOT_STARTED:
            # keep track of start time/frame for later
            fixationCross_2.tStart = t  # underestimates by a little under one frame
            fixationCross_2.frameNStart = frameN  # exact frame index
            fixationCross_2.setAutoDraw(True)
        if fixationCross_2.status == STARTED and t >= (0.0 + (6.0-win.monitorFramePeriod*0.75)): #most of one frame period left
            fixationCross_2.setAutoDraw(False)
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in Fixation_2Components:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()
    
    #-------Ending Routine "Fixation_2"-------
    for thisComponent in Fixation_2Components:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    thisExp.nextEntry()
    
# completed 1 repeats of 'runs'


#------Prepare to start Routine "waitForFinish"-------
t = 0
waitForFinishClock.reset()  # clock 
frameN = -1
# update component parameters for each repeat

# keep track of which components have finished
waitForFinishComponents = []
waitForFinishComponents.append(finishText)
for thisComponent in waitForFinishComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

#-------Start Routine "waitForFinish"-------
continueRoutine = True
while continueRoutine:
    # get current time
    t = waitForFinishClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame
    if logging.defaultClock.getTime() > EXP_DURATION:
        continueRoutine = False
        finishText.status = FINISHED
        finishText.setAutoDraw(False)
    
    # *finishText* updates
    if t >= 0.0 and finishText.status == NOT_STARTED:
        # keep track of start time/frame for later
        finishText.tStart = t  # underestimates by a little under one frame
        finishText.frameNStart = frameN  # exact frame index
        finishText.setAutoDraw(True)
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in waitForFinishComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

#-------Ending Routine "waitForFinish"-------
for thisComponent in waitForFinishComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
logging.exp("Experiment Finished")

# the Routine "waitForFinish" was not non-slip safe, so reset the non-slip timer
routineTimer.reset()

#------Prepare to start Routine "thankyou"-------
t = 0
thankyouClock.reset()  # clock 
frameN = -1
routineTimer.add(120.000000)
# update component parameters for each repeat

key_resp_2 = event.BuilderKeyResponse()  # create an object of type KeyResponse
key_resp_2.status = NOT_STARTED
# keep track of which components have finished
thankyouComponents = []
thankyouComponents.append(thankYouText)
thankyouComponents.append(key_resp_2)
for thisComponent in thankyouComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

#-------Start Routine "thankyou"-------
continueRoutine = True
while continueRoutine and routineTimer.getTime() > 0:
    # get current time
    t = thankyouClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame
    
    
    # *thankYouText* updates
    if t >= 0.0 and thankYouText.status == NOT_STARTED:
        # keep track of start time/frame for later
        thankYouText.tStart = t  # underestimates by a little under one frame
        thankYouText.frameNStart = frameN  # exact frame index
        thankYouText.setAutoDraw(True)
    if thankYouText.status == STARTED and t >= (0.0 + (120.0-win.monitorFramePeriod*0.75)): #most of one frame period left
        thankYouText.setAutoDraw(False)
    
    # *key_resp_2* updates
    if t >= 10.0 and key_resp_2.status == NOT_STARTED:
        # keep track of start time/frame for later
        key_resp_2.tStart = t  # underestimates by a little under one frame
        key_resp_2.frameNStart = frameN  # exact frame index
        key_resp_2.status = STARTED
        # keyboard checking is just starting
        key_resp_2.clock.reset()  # now t=0
        event.clearEvents(eventType='keyboard')
    if key_resp_2.status == STARTED and t >= (120-win.monitorFramePeriod*0.75): #most of one frame period left
        key_resp_2.status = STOPPED
    if key_resp_2.status == STARTED:
        theseKeys = event.getKeys(keyList=['y', 'n', 'left', 'right', 'space', '1', '2'])
        
        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            key_resp_2.keys = theseKeys[-1]  # just the last key pressed
            key_resp_2.rt = key_resp_2.clock.getTime()
            # a response ends the routine
            continueRoutine = False
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in thankyouComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

#-------Ending Routine "thankyou"-------
for thisComponent in thankyouComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)

# check responses
if key_resp_2.keys in ['', [], None]:  # No response was made
   key_resp_2.keys=None
# store data for thisExp (ExperimentHandler)
thisExp.addData('key_resp_2.keys',key_resp_2.keys)
if key_resp_2.keys != None:  # we had a response
    thisExp.addData('key_resp_2.rt', key_resp_2.rt)
thisExp.nextEntry()





















#win.saveMovieFrames('thumb.png')

win.close()
core.quit()
