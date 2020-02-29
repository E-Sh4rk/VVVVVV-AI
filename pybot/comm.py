import subprocess
import os
from state import parse_state
import time
import json
from enum import Enum

VVVVVV_CMD_TRAINING = ["../VVVVVV.exe", "-training"]
VVVVVV_CMD = ["../VVVVVV.exe"]

class ACTION(Enum):
    WAIT=0
    LEFT=1
    RIGHT=2
    SUICIDE=3

ACTION_MAP = [ "", "l", "r", "s" ]

def send_move(io, action):
    cmd = ACTION_MAP[action._value_] + os.linesep
    io.stdin.write(cmd.encode("utf-8"))
    io.stdin.flush()

def read_state(io, prev_json):
    current = None
    while current == None:
        line = io.stdout.readline().decode("utf-8").rstrip()
        if line == "NO_SWN":
            send_move(io, ACTION.WAIT)
        elif line.startswith('{'):
            current = json.loads(line)
    return (current, parse_state(prev_json, current))

def next_step(io, prev_json, action):
    send_move(io, action)
    return read_state(io, prev_json)

def reset_game(io, state):
    if not(state.terminal):
        (_, state) = next_step(io, None, ACTION.SUICIDE)
        assert state.terminal
    while state.terminal:
        (pjson, state) = next_step(io, None, ACTION.WAIT)
    return (pjson, state)

def initialize_game(training):
    cmd = VVVVVV_CMD_TRAINING if training else VVVVVV_CMD
    io = subprocess.Popen(cmd, bufsize=-1, stdin=subprocess.PIPE, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    (pjson, state) = next_step(io, None, ACTION.WAIT)
    return (io, pjson, state)
