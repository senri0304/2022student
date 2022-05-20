# -*- coding: utf-8 -*-
import datetime
import math
import os
import pyglet
import random
import time
from collections import deque

import numpy as np
import pandas as pd
from pyglet.gl import *
from pyglet.image import AbstractImage

import display_info

# Prefernce
# ------------------------------------------------------------------------
rept = 6
cal = -45
exclude_mousePointer = False
test_eye = 1
# ------------------------------------------------------------------------

# Get display informations
display = pyglet.canvas.get_display()
screens = display.get_screens()
win = pyglet.window.Window(style=pyglet.window.Window.WINDOW_STYLE_BORDERLESS)
win.set_fullscreen(fullscreen=True, screen=screens[len(screens) - 1])  # Present secondary display
win.set_exclusive_mouse(exclude_mousePointer)  # Exclude mouse pointer
key = pyglet.window.key

# Load variable conditions
deg1 = display_info.deg1
cntx = screens[len(screens) - 1].width / 2  # Store center of screen about x position
cnty = screens[len(screens) - 1].height / 3  # Store center of screen about y position
dat = pd.DataFrame()
iso = 8.0
draw_objects = []  # 描画対象リスト
end_routine = False  # Routine status to be exitable or not
tc = 0  # Count transients
tcs = []  # Store transients per trials
kud_list = []  # Store durations of key pressed
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

# disparities
variation = [3, 6, 9, 12]

# measure only crossed disparity
# Replicate for repetition
variation2 = list(np.repeat(variation, rept))

# added zero disparity condition
# variation2.extend([0]*rept*len(test_eye))
# test_eye2.extend(test_eye*rept)

# Randomize
r = random.randint(0, math.factorial(len(variation2)))
random.seed(r)
sequence = random.sample(variation2, len(variation2))

print(sequence)
print(len(sequence))


# ----------- Core program following ----------------------------

# A getting key response function
class key_resp(object):
    def on_key_press(self, symbol, modifiers):
        global tc, exit, trial_start
        if exit is False and symbol == key.DOWN:
            kd.append(time.time())
            tc = tc + 1
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
        global tc
        if exit is False and symbol == key.DOWN:
            ku.append(time.time())
            tc = tc + 1


resp_handler = key_resp()


# Store objects into draw_objects
def fixer():
    draw_objects.append(fixl)
    draw_objects.append(fixr)


def replace():
    del draw_objects[:]
    fixer()
    draw_objects.append(R)
    draw_objects.append(L)


# A end routine function
def exit_routine(dt):
    global exit
    exit = True
    beep_sound.play()
    prepare_routine()
    fixer()
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
    global ku, kud, kd, kud_list, mdt, dtstd, n, tc, tcs, sequence
    ku.append(trial_start + 30.0)
    while len(kd) > 0:
        kud.append(ku.popleft() - kd.popleft() + 0)  # list up key_press_duration
    kud_list.append(str(kud))
    c = sum(kud)
    cdt.append(c)
    tcs.append(tc)
    if kud == []:
        kud.append(0)
    m = np.mean(kud)
    d = np.std(kud)
    mdt.append(m)
    dtstd.append(d)
    print("--------------------------------------------------")
    print("trial: " + str(n) + "/" + str(len(variation2)))
    print("start: " + str(trial_start))
    print("end: " + str(trial_end))
    print("key_pressed: " + str(kud))
    print("transient counts: " + str(tc))
    print("cdt: " + str(c))
    print("mdt: " + str(m))
    print("dtstd: " + str(d))
    print("condition: " + str(sequence[n - 1]))
    print("--------------------------------------------------")
    # Check the experiment continue or break
    if n != len(variation2):
        pyglet.clock.schedule_once(exit_routine, 14.0)
    else:
        pyglet.app.exit()


def set_polygon(seq, seq3):
    global L, R, n
    if seq3 == -1:
        # Set up polygon for stimulus
        R = pyglet.resource.image('stereograms/-' + str(seq) + 'ls.png')
        R = pyglet.sprite.Sprite(R)
        R.x = cntx + deg1 * iso + cal - R.width / 2.0
        R.y = cnty - R.height / 2.0
        L = pyglet.resource.image('stereograms/ls.png')
        L = pyglet.sprite.Sprite(L)
        L.x = cntx - deg1 * iso - cal - L.width / 2.0
        L.y = cnty - L.height / 2.0
    elif seq3 == 1:
        # Set up polygon for stimulus
        R = pyglet.resource.image('stereograms/ls.png')
        R = pyglet.sprite.Sprite(R)
        R.x = cntx + deg1 * iso + cal - R.width / 2.0
        R.y = cnty - R.height / 2.0
        L = pyglet.resource.image('stereograms/' + str(seq) + 'ls.png')
        L = pyglet.sprite.Sprite(L)
        L.x = cntx - deg1 * iso - cal - L.width / 2.0
        L.y = cnty - L.height / 2.0
    else:
        pyglet.app.exit()
        print('wrong set: test_eye')


def prepare_routine():
    if n < len(variation2):
        fixer()
        set_polygon(sequence[n], test_eye)
    else:
        pass


# Store the start time
start = time.time()
win.push_handlers(resp_handler)

fixer()
set_polygon(sequence[0], test_eye)

for i in sequence:
    tc = 0  # Count transients
    ku = deque([])  # Store unix time when key up
    kd = deque([])  # Store unix time when key down
    kud = []  # Differences between kd and ku

    pyglet.app.run()

# -------------- End loop -------------------------------

win.close()

# Store the end time
end_time = time.time()
daten = datetime.datetime.now()

# Write results onto csv
results = pd.DataFrame({'cnd': sequence,  # Store variance_A conditions
                        'test_eye': test_eye,
                        'transient_counts': tcs,  # Store transient_counts
                        'cdt': cdt,  # Store cdt(target values) and input number of trials
                        'mdt': mdt,
                        'dtstd': dtstd,
                        'key_press_list': kud_list})  # Store the key_press_duration list

os.makedirs('data', exist_ok=True)

name = str(daten)
name = name.replace(":", "'")
results.to_csv(path_or_buf='./data/DATE' + name + '.csv', index=False)  # Output experimental data

# Output following to shell, check this experiment
print(u'開始日時: ' + str(start))
print(u'終了日時: ' + str(end_time))
print(u'経過時間: ' + str(end_time - start))
