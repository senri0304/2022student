# -*- coding: utf-8 -*-
import os, pyglet, time, datetime, random, copy, math
from typing import List, Any

from pyglet.gl import *
from pyglet.image import AbstractImage
from collections import deque
import pandas as pd
import numpy as np
import display_info

# Prefernce
# ------------------------------------------------------------------------
rept = 3
cal = -45
exclude_mousePointer = False
# ------------------------------------------------------------------------

# Get display informations
display = pyglet.canvas.get_display()
screens = display.get_screens()
win = pyglet.window.Window(style=pyglet.window.Window.WINDOW_STYLE_BORDERLESS)
win.set_fullscreen(fullscreen=True, screen=screens[len(screens)-1])  # Present secondary display
win.set_exclusive_mouse(exclude_mousePointer)  # Exclude mouse pointer
key = pyglet.window.key

# Load variable conditions
deg1 = display_info.deg1
cntx = screens[len(screens)-1].width / 2  # Store center of screen about x position
cnty = screens[len(screens)-1].height / 3  # Store center of screen about y position
dat = pd.DataFrame()
iso = 8.0
draw_objects = []  # 描画対象リスト
end_routine = False  # Routine status to be exitable or not
tcs = []  # Store transients per trials
press_timing_test = []  # Store durations of key pressed
release_timing_test = []
cdt = []  # Store sum(kud), cumulative reaction time on a trial.
mdt = []
dtstd = []
exit = True
n = 0

# Load resources
p_sound = pyglet.resource.media('materials/840Hz.wav', streaming=False)
beep_sound = pyglet.resource.media('materials/460Hz.wav', streaming=False)
pedestal: AbstractImage = pyglet.image.load('materials/pedestal.png')
fixr = pyglet.sprite.Sprite(pedestal, x=cntx + iso * deg1 + cal - pedestal.width / 2.0, y=cnty - pedestal.height / 2.0)
fixl = pyglet.sprite.Sprite(pedestal, x=cntx - iso * deg1 - cal - pedestal.width / 2.0, y=cnty - pedestal.height / 2.0)

variation = copy.copy(display_info.variation)
ev = copy.copy(display_info.ecc_var)
test_eye = [-1]

# Replicate for repetition
variation2 = variation*len(ev)*len(test_eye)*rept
ev2 = list(np.repeat(ev, len(variation2)/len(ev)))
test_eye2 = list(np.repeat(test_eye, len(variation2)))

# Randomize
r = random.randint(0, math.factorial(len(variation2)))
random.seed(r)
sequence = random.sample(variation2, len(variation2))
random.seed(r)
sequence2 = random.sample(test_eye2, len(variation2))
random.seed(r)
sequence3 = random.sample(ev2, len(variation2))

print(sequence)
print(sequence2)
print(sequence3)
print(len(variation2))

# ----------- Core program following ----------------------------

# A getting key response function
class key_resp(object):
    def on_key_press(self, symbol, modifiers):
        global tc_test, exit, trial_start
        if exit is False and symbol == key.DOWN:
            kd_test.append(time.time())
            tc_test = tc_test + 1
        if exit is True and symbol == key.UP:
            p_sound.play()
            exit = False
            pyglet.clock.schedule_once(delete, 30.0)
            replace()
            trial_start = time.time()
        if symbol == key.ESCAPE:
            win.close()
            pyglet.app.exit()

    def on_key_release(self, symbol, modifiers):
        global tc_test
        if exit is False and symbol == key.DOWN:
            ku_test.append(time.time())
            tc = tc_test + 1


# Store objects into draw_objects
def fixer(seq2):
    if seq2 == 1:
        draw_objects.append(fixl)
        draw_objects.append(fixr)
    elif seq2 == 2:
        pass
#        draw_objects.append(fixl2)
#        draw_objects.append(fixr2)


def replace():
    del draw_objects[:]
    fixer(sequence3[n])
    draw_objects.append(R)
    draw_objects.append(L)


# A end routine function
def exit_routine(dt):
    global exit
    exit = True
    beep_sound.play()
    prepare_routine()
    pyglet.app.exit()


@win.event
def on_draw():
    # Refresh window
    win.clear()
    # 描画対象のオブジェクトを描画する
    for draw_object in draw_objects:
        draw_object.draw()


# Remove stimulus
def delete(dt):
    global n, trial_end
    del draw_objects[:]
    p_sound.play()
    n += 1
    pyglet.clock.schedule_once(get_results, 1.0)
    trial_end = time.time()


def get_results(dt):
    print(str(len(ku_test)) + str(len(kd_test)))
    if len(ku_test) != len(kd_test):
        ku_test.append(trial_start + 30.0)
    press_timing_test.append(str(np.array(kd_test) - trial_start))
    release_timing_test.append(str(np.array(ku_test) - trial_start))
    while len(kd_test) > 0:
        kud_test.append(ku_test.popleft() - kd_test.popleft() + 0)  # list up key_press_duration
    c = sum(kud_test)
    cdt.append(c)
    tcs.append(tc_test)
    if kud_test == []:
        kud_test.append(0)
    m = np.mean(kud_test)
    d = np.std(kud_test)
    mdt.append(m)
    dtstd.append(d)
    print("--------------------------------------------------\n"
          "trial: " + str(n) + "/" + str(len(sequence)) + '\n'
          "start: " + str(trial_start) + '\n'
          "end: " + str(trial_end) + '\n'
          "transient counts: " + str(tc_test) + '\n'
          "cdt: " + str(c) + '\n'
          "mdt: " + str(m) + '\n'
          "dtstd: " + str(d) + '\n'
          "condition: " + str(sequence[n - 1]) + ', ' + str(sequence2[n-1]) + ', ' + str(sequence3[n - 1]) + '\n'
          "--------------------------------------------------")
    # Check the experiment continue or break
    if n != len(sequence):
        pyglet.clock.schedule_once(exit_routine, 19.0)
    else:
        pyglet.app.exit()


# R and L stores suppressor and test, respectively
def set_polygon(seq, seq2, seq3):
    global L, R, n
    if seq3 == 1:
        # Set up polygon for stimulus
        R = pyglet.resource.image('stereograms/' + str(seq) + str(seq2) + 'ls.png')
        R = pyglet.sprite.Sprite(R)
        R.x = cntx + deg1 * iso * seq3 + cal*seq3 - R.width / 2.0
        R.y = cnty - R.height / 2.0
        L = pyglet.resource.image('stereograms/ls' + str(seq2) + '.png')
        L = pyglet.sprite.Sprite(L)
        L.x = cntx - deg1 * iso * seq3 - cal*seq3 - L.width / 2.0
        L.y = cnty - L.height / 2.0
    elif seq3 == -1:
        # Set up polygon for stimulus
        R = pyglet.resource.image('stereograms/ls' + str(seq2) + '.png')
        R = pyglet.sprite.Sprite(R)
        R.x = cntx + deg1 * iso * seq3 + cal*seq3 - R.width / 2.0
        R.y = cnty - R.height / 2.0
        L = pyglet.resource.image('stereograms/' + str(seq) + str(seq2) + 'ls.png')
        L = pyglet.sprite.Sprite(L)
        L.x = cntx - deg1 * iso * seq3 - cal*seq3 - L.width / 2.0
        L.y = cnty - L.height / 2.0
    else:
        pyglet.app.exit()
        print('wrong set')


def prepare_routine():
    if n < len(sequence):
        fixer(sequence3[n])
        set_polygon(sequence[n], sequence3[n], sequence2[n])
    else:
        pass


# Store the start time
start = time.time()
resp_handler = key_resp()
win.push_handlers(resp_handler)

fixer(sequence3[0])
set_polygon(sequence[0], sequence3[0], sequence2[0])


for i in sequence:
    tc_test = 0  # Count transients
    ku_test = deque([])  # Store unix time when key up
    kd_test = deque([])  # Store unix time when key down
    kud_test = []  # Differences between kd and ku
    ku_sup = deque([])  # Store unix time when key up
    kd_sup = deque([])  # Store unix time when key down
    kud_sup = []  # Differences between kd and ku

    pyglet.app.run()

# -------------- End loop -------------------------------

win.close()

# Store the end time
end_time = time.time()
daten = datetime.datetime.now()

# Write results onto csv
results = pd.DataFrame({'cnd': sequence,  # Store variance_A conditions
                        'test_eye': sequence2,
                        'eccentricity': sequence3,
                        'transient_counts_test': tcs,  # Store transient_counts
                        'cdt_test': cdt,  # Store cdt(target values) and input number of trials
                        'mdt_test': mdt,
                        'dtstd_test': dtstd,
                        'press_timing_test': press_timing_test,  # Store the key_press_duration list
                        'release_timing_test': release_timing_test})

os.makedirs('data', exist_ok=True)

name = str(daten)
name = name.replace(":", "'")
results.to_csv(path_or_buf='./data/DATE' + name + '.csv', index=False)  # Output experimental data

# Output following to shell, check this experiment
print(u'開始日時: ' + str(start))
print(u'終了日時: ' + str(end_time))
print(u'経過時間: ' + str(end_time - start))
