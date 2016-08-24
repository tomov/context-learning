from psychopy import core, visual, gui, data, event
from psychopy.tools.filetools import fromFile, toFile
import random
import datetime

# TODO

# button keypress
# show images in sequence
# record responses

# have diff conditions in each subject
# cross-balance based on subject id (6 perms, use mod 6)
# have different foods & restaurant names (french? italian?)

# better UI -- correct / wrong
# style it -- colors, etc
# instructions / extra messages & boilerplate from Sam JS script

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
restaurant = visual.TextStim(win, pos=[0, +6.5], text="Restaurant name")
food = visual.ImageStim(win, "food1.png", pos=[0, +3])
sick_img = visual.ImageStim(win, "sick.png", pos=[-6, -4])
sick_msg = visual.TextStim(win, pos=[-6,-8],text='Sick\n<-')
notsick_img = visual.ImageStim(win, "smiley.png", pos=[6, -4])
notsick_msg = visual.TextStim(win, pos=[+6,-8],
    text="Not sick\n->")
#and some handy clocks to keep track of time
globalClock = core.Clock()

food.draw()
sick_img.draw()
sick_msg.draw()
notsick_img.draw()
notsick_msg.draw()
restaurant.draw()

win.flip()

allKeys=event.waitKeys()