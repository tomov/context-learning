from psychopy import core, visual, gui, data, event
from psychopy.tools.filetools import fromFile, toFile
import random
import datetime

# TODO

# just show an image
# button keypress
# show images in sequence
# record responses

# have diff conditions in each subject
# cross-balance based on subject id (6 perms, use mod 6)
# have different foods & restaurant names (french? italian?)

# better UI -- correct / wrong

# QUESTIONS

# ipython/cmd line -- how to?


try: #try to get a previous parameters file
    expInfo = fromFile('lastParams.pickle')
except: #if not there then use a default set
    expInfo = {'observer':'jwp', 'refOrientation':0}

# present a dialogue to change params
#dlg = gui.DlgFromDict(expInfo, title='simple JND Exp', fixed=['dateStr'])
#if dlg.OK:
#    toFile('lastParams.pickle', expInfo)#save params to file for next time
#else:        
    #quit
#    core.quit()

print 'expInfo = ', expInfo

# create window and stimuli
win = visual.Window([800,600],allowGUI=True, monitor='testMonitor', units='deg')
food = visual.ImageStim(win, "food1.png")
#and some handy clocks to keep track of time
globalClock = core.Clock()

food.draw()
win.flip()

allKeys=event.waitKeys()