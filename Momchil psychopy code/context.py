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
groups = [1,2,3]  # subject group(s)
random.shuffle(groups)

restaurants = [
    ["Molina's Cantina", "Restaurante Arroyo", "El Coyote Cafe"],
    ["Le Parisien", "Chez Toinette", "Au Petit Sud Ouest"],
    ["Lau's Dim Sum Bar", "OO Kook Korean BBQ", "Happy Sheep Hot Pot"]
]
foods = [
    ["mexican_food1.png", "mexican_food2.png","mexican_food3.png"],
    ["french_food1.png", "french_food2.png", "french_food3.png"],
    ["asian_food1.png", "asian_food2.png", "asian_food3.png"]
]
cuisines = [0, 1, 2]
random.shuffle(cuisines)
train = [0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3] # sequence of training trials
random.shuffle(train)
test = [0,1,2,3] # sequence of test trials
random.shuffle(test)
Test = 0 # are we in the testing phase?

now = datetime.datetime.now()
subjId = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(10))
filename = subjId + '_' + now.strftime('%Y-%m-%d_%H-%M-%S') + '_' + ''.join(str(g) for g in groups) + '_' + ''.join(str(c) for c in cuisines) + '.csv'
print 'filename = ', filename
filename = os.path.join('data', filename)
dataFile = open(filename, 'w') # TODO bufsize 0 to flush always?

# outcomes -- did the customer get sick on train[trial] (not defined for test trials)
# 1 = sick, 0 = not sick
#
outcomes = [
    [1, 0, 1, 0],   # group = 1 (irrelevant context)
    [1, 0, 0, 1],   # group = 2 (modulatory context)
    [1, 1, 0, 0]    # group = 3 (additive context)
]

train_cue = [0, 1, 0, 1] # training foods for each trial type
train_context = [0, 0, 1, 1] # training restaurant for each trial type
test_cue = [0, 0, 2, 2] # testing foods for each trial type
test_context = [0, 2, 0, 2] # testing restaurant for each trial type

# TODO


# have diff conditions in each subject
# cross-balance based on subject id (6 perms, use mod 6)
# have different foods & restaurant names (french? italian?)

# instructions / extra messages & boilerplate from Sam JS script

# QUESTIONS

# ipython/cmd line -- how to?



#
# Create window and stimuli
#

win = visual.Window([1000,800],allowGUI=True, monitor='testMonitor', units='deg')
restaurant_txt = visual.TextStim(win, pos=[0, +6.5], text="Restaurant name")
food_img = visual.ImageStim(win, pos=[0, +3])
sick_img = visual.ImageStim(win, "sick.png")
sick_txt = visual.TextStim(win, pos=[-6,-9],text='Sick\n<-') # sick = left
notsick_img = visual.ImageStim(win, "smiley.png")
notsick_txt = visual.TextStim(win, pos=[+6,-9],
    text="Not sick\n->") # not sick = right
feedback_txt = visual.TextStim(win, pos=[0, -9])
correct_txt = visual.TextStim(win, pos=[0, -1.5], text="CORRECT", color='blue', bold=True)
wrong_txt = visual.TextStim(win, pos=[0, -1.5], text="WRONG", color='red', bold=True)
predict_txt = visual.TextStim(win, pos=[0, +9], text="Predict whether the customer will get sick from this food.", wrapWidth=20)
done_txt = visual.TextStim(win, pos=[0, 0], text="You are done! Thank your for your participation. Please wait for the experimenter.", wrapWidth=20)
#and some handy clocks to keep track of time
globalClock = core.Clock()

#
# Run experiment
#
print 'groups = ', groups

for i in range(3):
    group = groups[i]
    cuisine = cuisines[i]
    print '\n\n ------ group ', group, ', cuisine ', cuisine, '-----\n\n' 
    
    trial = -1 # current trial
    Test = 0
    for _ in range(nTrain + nTest):
        trial += 1
        
        # get restaurant & food on trial X
        #
        if Test == 0 and trial == nTrain:
            Test = 1
            trial = 0
        elif Test == 1 and trial == nTest:
            break

        if Test == 1:
            cue = test_cue[test[trial]]
            context = test_context[test[trial]]
        else:
            cue = train_cue[train[trial]]
            context = train_context[train[trial]]
        food = foods[cuisine][cue]
        restaurant = restaurants[cuisine][context]
        
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
        predict_txt.draw()
        win.flip()

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
            outcome = outcomes[group - 1][train[trial]]
            if outcome:
                sick_img.pos = [0, -5];
                feedback_txt.setText("The customer got sick!\nWait for next trial")
                sick_img.draw()
            else:
                notsick_img.pos = [0, -5];
                feedback_txt.setText("The customer didn't get sick!\nWait for next trial")
                notsick_img.draw()
            food_img.draw()
            restaurant_txt.draw()
            feedback_txt.draw()
            if outcome == response:
                correct_txt.draw()
            else:
                wrong_txt.draw()
        else:
            outcome = -1 # no "known" outcome in test case
            feedback_txt.setText("Wait for next trial")
            feedback_txt.draw()
        win.flip()
        
        dataFile.write("%d,%d,%d,%d\n" % (outcome, context, cue, response))
        core.wait(2) # so the subject can see the feedback
        
done_txt.draw()
win.flip()

core.wait(10)