import math
import numpy as np
import cv2 as cv

PLAYER_X_JUMP = 320

PLAYER_MAX_Y_SPEED = 10
PLAYER_MAX_X_SPEED = 6
PROJ_MAX_SPEED = 7

PROJ_X_START_OFFSET = 150

DOWNSCALE = 3
HEIGHT_MULITPLE_OF = 44 # 42
WIDTH_MULITPLE_OF = 116
NB_CHANNELS = 3

LINE1_ADJUST = 0 # 1
LINE2_ADJUST = 0 # -2

class State:
    score=0
    terminal=True
    image=None

def in_collision(s1, s2):
    top = max(s1["y"], s2["y"])
    bottom = min(s1["y"] + s1["h"], s2["y"] + s2["h"])
    left = max(s1["x"], s2["x"])
    right = min(s1["x"] + s1["w"], s2["x"] + s2["w"])
    return top <= bottom and left <= right

def compute_speed_of_projectile(previous_json, sprite):
    sprite["xs"] = 0
    if previous_json == None:
        return
    for psprite in previous_json["proj"]:
        if psprite["y"] == sprite["y"] and in_collision(psprite, sprite):
            diff = sprite["x"] - psprite["x"]
            if psprite["xs"] == 0 or np.sign(diff) == np.sign(psprite["xs"]):
                sprite["xs"] = diff
    
def compute_speed_of_character(previous_json, sprite):
    if previous_json == None:
        sprite["ys"] = 0
        sprite["xs"] = 0
        return
    sprite["ys"] = sprite["y"] - previous_json["player"]["y"]
    sprite["xs"] = sprite["x"] - previous_json["player"]["x"]
    if abs(sprite["xs"]) > PLAYER_MAX_X_SPEED + 1:
        if sprite["xs"] > 0:
            sprite["xs"] -= PLAYER_X_JUMP
        else:
            sprite["xs"] += PLAYER_X_JUMP
    
def generate_matrix(prev_json, json):
    if len(json["lines"]) != 2:
        return None

    lines = json["lines"]
    if lines[0]["y"] > lines[1]["y"]:
        tmp = lines[1]["y"]
        lines[1]["y"] = lines[0]["y"]
        lines[0]["y"] = tmp
    # Little preprocessing
    lines[0]["y"] += LINE1_ADJUST
    lines[1]["y"] += LINE2_ADJUST

    proj = json["proj"]
    for p in proj:
        compute_speed_of_projectile(prev_json, p)
    player = json["player"]
    compute_speed_of_character(prev_json, player)

    ymin = lines[0]["y"]
    ymax = lines[1]["y"]+lines[1]["h"]
    xmin = min(lines[0]["x"], lines[1]["x"])
    xmax = max(lines[0]["x"]+lines[0]["w"],
               lines[1]["x"]+lines[1]["w"])
    n = xmax-xmin
    m = ymax-ymin
    height_mult = HEIGHT_MULITPLE_OF * DOWNSCALE
    width_mult = WIDTH_MULITPLE_OF * DOWNSCALE
    npad = (width_mult - (n % width_mult)) % width_mult
    mpad = (height_mult - (m % height_mult)) % height_mult
    m += mpad
    n += npad
    y_offset = mpad // 2 - ymin
    x_offset = npad // 2 - xmin
    M = np.zeros((m,n,3), np.uint8)

    def draw_full_sprite(sprite, color):
        cv.rectangle(M,(sprite["x"]+x_offset,sprite["y"]+y_offset),(sprite["x"]+sprite["w"]+x_offset-1,sprite["y"]+sprite["h"]+y_offset-1),color,-1)
    def draw_full_sprite_circle(sprite, color):
        cv.circle(M,(sprite["x"]+sprite["w"]//2+x_offset,sprite["y"]+sprite["h"]//2+y_offset),(sprite["w"]+sprite["h"])//4,color,-1)

    cv.line(M,(x_offset+xmin,0),(x_offset+xmin,m-1), (255,0,0),1)
    cv.line(M,(x_offset+xmax-1,0),(x_offset+xmax-1,m-1), (255,0,0),1)
    for i in range(len(proj)):
        if proj[i]["xs"] < 0 and proj[i]["x"] >= xmax:
            blue = max(0, (PROJ_X_START_OFFSET-(proj[i]["x"]-xmax))*255//PROJ_X_START_OFFSET)
            cv.rectangle(M,(xmax+x_offset,proj[i]["y"]+y_offset),(n-1,proj[i]["y"]+proj[i]["h"]+y_offset-1),(blue,0,0),-1)
        if proj[i]["xs"] > 0 and proj[i]["x"]+proj[i]["w"] <= xmin:
            blue = max(0, (PROJ_X_START_OFFSET+(proj[i]["x"]+proj[i]["w"]-xmin))*255//PROJ_X_START_OFFSET)
            cv.rectangle(M,(0,proj[i]["y"]+y_offset),(x_offset+xmin-1,proj[i]["y"]+proj[i]["h"]+y_offset-1),(blue,0,0),-1)

    if NB_CHANNELS < 3: # No velocity indications

        draw_full_sprite(lines[0], (255,0,0))
        draw_full_sprite(lines[1], (255,0,0))
        for i in range(len(proj)):
            draw_full_sprite_circle(proj[i], (0,0,255))
        draw_full_sprite(player, (0,255,0))

    else: # Color change depending on velocity

        # Projectiles: R | RB
        #
        # Player: G | GB
        #         GR
        #
        # Horizontal lines: GR & G
        #
        # Vertical lines: B

        draw_full_sprite(lines[0], (0,255,255))
        draw_full_sprite(lines[1], (0,255,0))

        for i in range(len(proj)):
            blue = (proj[i]["xs"] + PROJ_MAX_SPEED) * 255 / (2*PROJ_MAX_SPEED)
            draw_full_sprite_circle(proj[i], (blue, 0, 255))
        blue = (player["xs"] + PLAYER_MAX_X_SPEED) * 255 / (2*PLAYER_MAX_X_SPEED)
        red = (player["ys"] + PLAYER_MAX_Y_SPEED) * 255 / (2*PLAYER_MAX_Y_SPEED)
        draw_full_sprite(player, (blue, 255, red))

    M = cv.resize(M, (n//DOWNSCALE, m//DOWNSCALE), interpolation=cv.INTER_AREA)

    if NB_CHANNELS == 1:
        coefficients = [1,0.6,0.4]
        m = np.array(coefficients).reshape((1,3))
        M = cv.transform(M, m)
    elif NB_CHANNELS == 2:
        coefficients = [0,0,0,1,0.75,0,0,0,1]
        m = np.array(coefficients).reshape((3,3))
        M = cv.transform(M, m)
    # else:
    #     coefficients = [2,0,0,0,1,0,0,0,1]
    #     m = np.array(coefficients).reshape((3,3))
    #     M = cv.transform(M, m)

    return M

def display_matrix(M):
    cv.namedWindow('preview',cv.WINDOW_NORMAL)
    cv.imshow('preview', M)
    cv.waitKey(1)

def i2b(i):
    return False if i == 0 else True

def parse_state(prev_json, js):
    state = State()
    state.score = js["timer"]
    state.image = generate_matrix(prev_json, js)
    state.terminal = i2b(js["dead"]) or not(i2b(js["playable"]))
    return state
    