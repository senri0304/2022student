#!/usr/bin/env python
# coding: utf-8

import pyglet.canvas

# Input display information
inch = 23.0
aspect_width = 16.0
aspect_height = 9.0

# Input a variety
variation = [0, 1, 2, 3, 4]
ecc_var = [int(1)]


# Get display information
display = pyglet.canvas.get_display()
screens = display.get_screens()

resolution = screens[len(screens) - 1].height

c = (aspect_width ** 2 + aspect_height ** 2) ** 0.5
d_height = 2.54 * (aspect_height / c) * inch

deg1 = round(resolution * (1 / d_height))
