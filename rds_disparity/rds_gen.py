import os, wave, struct
from PIL import Image, ImageDraw
import numpy as np
from display_info import *


to_dir = 'stereograms'
os.makedirs(to_dir, exist_ok=True)

lmnt_low = 5

# Input a number you like to initiate
s = 0

# Input luminance of background
lb = 85

# Input luminance of dots
ld = 0

sz = 100 #round(resolution * (5 / d_height))
f = round(sz*0.023/2) *2 # % relative size
inner = sz/4
disparity = round(resolution * 0.05 / d_height)

# Input a variety
variation = [-4, -2, 2, 4]

# fixation point
def fixation(d):
    d.rectangle((int(sz) - f, int(sz) + deg1 + f * 3,
                 int(sz) + f, int(sz) + deg1 - f * 3),
                fill=(0, 0, 255), outline=None)
    d.rectangle((int(sz) - f * 3, int(sz) + deg1 + f,
                 int(sz) + f * 3, int(sz) + deg1 - f),
                fill=(0, 0, 255), outline=None)


# Generate RDSs
def rds_gen(v, s):
    # Two images prepare
    img = Image.new("RGB", (sz, sz), (lb, lb, lb))
    draw = ImageDraw.Draw(img)

    img2 = Image.new("RGB", (sz, sz), (lb, lb, lb))
    draw2 = ImageDraw.Draw(img2)

        # Draw the complementary RDSs
#        for i in range(0, sz):
#            for j in range(1, sz + 1):
#                x = np.round(np.random.binomial(1, 0.3, 1)) * j
#                draw.point((x - 1, i), fill=(0, 0, 0))
#                draw2.point((x - 1, i), fill=(0, 0, 0))
#
#        # Fill the targets area
#        draw.rectangle((int(sz / 2) - int(inner*s / 2) - disparity / 2, int(sz / 2) + int(inner*s / 2),
#                        int(sz / 2) + int(inner*s / 2) - disparity / 2, int(sz / 2) - int(inner*s / 2)),
#                       fill=(lb, lb, lb), outline=None)
#        draw2.rectangle((int(sz / 2) - int(inner*s / 2) + disparity / 2, int(sz / 2) + int(inner*s / 2),
#                         int(sz / 2) + int(inner*s / 2) + disparity / 2, int(sz / 2) - int(inner*s / 2)),
#                        fill=(lb, lb, lb), outline=None)

    # Draw the planes of RD
    for i in range(1, int(sz/3)):
        for j in range(1, int(sz/3)):
            x = np.round(np.random.binomial(1, 0.5, 1)) * j
            if x != 0:
                draw.point((int(sz / 3) + x, int(sz / 3) + i), fill=(0, 0, 0))
                draw2.point((int(sz / 3) + x, int(sz / 3) + i), fill=(0, 0, 0))

    # Fill the targets area
    draw.rectangle((int(sz / 2) - int(inner / 3) - v / 2, int(sz / 2) + int(inner / 3),
                    int(sz / 2) + int(inner / 3) - v / 2, int(sz / 2) - int(inner / 3)),
                   fill=(lb, lb, lb), outline=None)
    draw2.rectangle((int(sz / 2) - int(inner / 3) + v / 2, int(sz / 2) + int(inner / 3),
                     int(sz / 2) + int(inner / 3) + v / 2, int(sz / 2) - int(inner / 3)),
                    fill=(lb, lb, lb), outline=None)

    # Drawing the targets
    for i in range(0, round(inner/1.5)):
        for j in range(0, round(inner/1.5)):
            x = np.round(np.random.binomial(1, 0.5, 1)) * (1 + j)
            if x != 0:
                draw.point((x + int(sz / 2) - int(inner / 3) - 1 - v / 2, i + int(sz / 2) - int(inner / 3)),
                           fill=(0, 0, 0))
                draw2.point((x + int(sz / 2) - int(inner / 3) - 1 + v / 2, i + int(sz / 2) - int(inner / 3)),
                            fill=(0, 0, 0))

    img_resize = img.resize((int(img.width*2), int(img.height*2)))
    img2_resize = img2.resize((int(img2.width*2), int(img2.height*2)))

    draw = ImageDraw.Draw(img_resize)
    draw2 = ImageDraw.Draw(img2_resize)

    fixation(draw)
    fixation(draw2)

    # Write images
    basenameR = os.path.basename(str(s) + 'rds' + str(v) + 'R.png')
    basenameL = os.path.basename(str(s) + 'rds' + str(v) + 'L.png')
    img_resize.save(os.path.join(to_dir, basenameR), quality=100)
    img2_resize.save(os.path.join(to_dir, basenameL), quality=100)


for i in variation:
    for r in range(1, 6):
        rds_gen(i, r)


# stereogram without stimuli
img = Image.new("RGB", (sz*2, sz*2), (lb, lb, lb))
draw = ImageDraw.Draw(img)

fixation(draw)

to_dir = 'materials'
os.makedirs(to_dir, exist_ok=True)
basename = os.path.basename('pedestal.png')
img.save(os.path.join(to_dir, basename), quality=100)

# sound files
# special thank: @kinaonao  https://qiita.com/kinaonao/items/c3f2ef224878fbd232f5

# sin波
# --------------------------------------------------------------------------------------------------------------------
def create_wave(A, f0, fs, t, name):  # A:振幅,f0:基本周波数,fs:サンプリング周波数,再生時間[s],n:名前
    # nポイント
    # --------------------------------------------------------------------------------------------------------------------
    point = np.arange(0, fs * t)
    sin_wave = A * np.sin(2 * np.pi * f0 * point / fs)

    sin_wave = [int(x * 32767.0) for x in sin_wave]  # 16bit符号付き整数に変換

    # バイナリ化
    binwave = struct.pack("h" * len(sin_wave), *sin_wave)

    # サイン波をwavファイルとして書き出し
    w = wave.Wave_write(os.path.join(to_dir, str(name) + ".wav"))
    p = (1, 2, fs, len(binwave), 'NONE',
         'not compressed')  # (チャンネル数(1:モノラル,2:ステレオ)、サンプルサイズ(バイト)、サンプリング周波数、フレーム数、圧縮形式(今のところNONEのみ)、圧縮形式を人に判読可能な形にしたもの？通常、 'NONE' に対して 'not compressed' が返されます。)
    w.setparams(p)
    w.writeframes(binwave)
    w.close()


create_wave(1, 460, 44100, 1.0, '460Hz')
create_wave(1, 840, 44100, 0.1, '840Hz')

