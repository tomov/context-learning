from psychopy import core, visual, gui, data, event
from psychopy.tools.filetools import fromFile, toFile
import random
import datetime
import os
import string

#
# Constants
#

nTest = 4
nTrain = 20
trial = -1 # current trial
groups = [1,2,3]  # subject group(s)
random.shuffle(groups)
m = groups[0] # pick one TODO do all

reward = 0
mode = 1
restaurants = ["Molina's Cantina", "Restaurante Arroyo", "El Coyote Cafe"]
foods = ["food1.png", "food2.png","food3.png"]
train = [0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3] # sequence of training trials
random.shuffle(train)
test = [0,1,2,3] # sequence of test trials
random.shuffle(test)
food = 0
context = 0
Test = 0 # are we in the testing phase?
f = 0

now = datetime.datetime.now()
subjId = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(10))
filename = subjId + '_' + now.strftime('%Y-%m-%d_%H-%M-%S') + '_' + str(groups[0]) + str(groups[1]) + str(groups[2]) + '.csv'
print 'filename = ', filename
filename = os.path.join('data', filename)
dataFile = open(filename, 'w') # TODO bufsize 0 to flush always?

# outcomes -- did the customer get sick on train[trial] (not defined for test trials)
# 1 = sick, 0 = not sick
#
r = None
if m == 1:
    r = [1, 0, 1, 0]
elif m == 2:
    r = [1, 0, 0, 1]
else:
    assert m == 3
    r = [1, 1, 0, 0]

train_cue = [0, 1, 0, 1] # training foods for each trial type
train_context = [0, 0, 1, 1] # training restaurant for each trial type
test_cue = [0, 0, 2, 2] # testing foods for each trial type
test_context = [0, 2, 0, 2] # testing restaurant for each trial type

# TODO

# record responses

# have diff conditions in each subject
# cross-balance based on subject id (6 perms, use mod 6)
# have different foods & restaurant names (french? italian?)

# better UI -- correct / wrong
# style it -- colors, etc
# instructions / extra messages & boilerplate from Sam JS script

# QUESTIONS

# ipython/cmd line -- how to?



#
# Create window and stimuli
#

win = visual.Window([1000,800],allowGUI=True, monitor='testMonitor', units='deg')
restaurant_txt = visual.TextStim(win, pos=[0, +6.5], text="Restaurant name")
food_img = visual.ImageStim(win, "food1.png", pos=[0, +3])
sick_img = visual.ImageStim(win, "sick.png")
sick_txt = visual.TextStim(win, pos=[-6,-9],text='Sick\n<-') # sick = left
notsick_img = visual.ImageStim(win, "smiley.png")
notsick_txt = visual.TextStim(win, pos=[+6,-9],
    text="Not sick\n->") # not sick = right
feedback_txt = visual.TextStim(win, pos=[0, -9])
correct_txt = visual.TextStim(win, pos=[0, -1.5], text="CORRECT", color='blue', bold=True)
wrong_txt = visual.TextStim(win, pos=[0, -1.5], text="WRONG", color='red', bold=True)
#and some handy clocks to keep track of time
globalClock = core.Clock()

#
# Run experiment
#

for _ in range(nTrain + nTest):
    trial += 1
    
    # get restaurant & food on trial X
    #
    if Test == 0 and trial == nTrain:
        Test = 1
        trial = 0

    if Test == 1:
        cue = test_cue[test[trial]]
        context = test_context[test[trial]]
    else:
        cue = train_cue[train[trial]]
        context = train_context[train[trial]]
    food = foods[cue]
    restaurant = restaurants[context]
    
    print _, ' -- trial:', trial, 'Test:', Test, 'food:', food, 'restaurant', restaurant
    
    # UI setup
    #
    food_img.setImage(food)
    restaurant_txt.setText(restaurant)
    sick_img.pos = [-6, -5];
    notsick_img.pos = [+6, -5];
    
    # show restaurant & food
    #
    food_img.draw()
    restaurant_txt.draw()
    sick_img.draw()
    sick_txt.draw()
    notsick_img.draw()
    notsick_txt.draw()
    win.flip()
    #core.wait(1)

    # get user response
    #
    response = None
    while response is None: # keep trying until user presses left or right
        allKeys = event.waitKeys()
        print '          key = ', allKeys
        for thisKey in allKeys:
            if thisKey=='left': # sick = left
                response = 1
            elif thisKey=='right':
                response = 0
            elif thisKey in ['q', 'escape']:
                core.quit() #abort experiment
    assert response is not None
   
    # give feedback
    #
    if not Test:
        outcome = r[train[trial]]
        if outcome:
            sick_img.pos = [0, -5];
            feedback_txt.setText("The customer got sick!\nPress any key to continue")
            sick_img.draw()
        else:
            notsick_img.pos = [0, -5];
            feedback_txt.setText("The customer didn't get sick!\nPress any key to continue")
            notsick_img.draw()
        food_img.draw()
        restaurant_txt.draw()
        feedback_txt.draw()
        if outcome == response:
            correct_txt.draw()
        else:
            wrong_txt.draw()
        win.flip()
        
        allKeys = event.waitKeys()
    else:
        outcome = -1 # no "known" outcome in test case
        
    dataFile.write("%d,%d,%d,%d\n" % (outcome, context, cue, response))
        
    
    
