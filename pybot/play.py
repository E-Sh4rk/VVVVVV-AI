import time
from state import display_matrix
from comm import initialize_game, next_step, reset_game, ACTION
from env import Env
import torch
from agent import Agent
from cmdparser import parser, init_torch

SLEEP = 0
SHOW_MATRIX = False
USE_ENV_ENGINE = True
TRAINING = True

if USE_ENV_ENGINE:
    args = parser.parse_args()
    init_torch(args)
    # Load environment
    env = Env(args, TRAINING)
    env.eval()
    state = env.reset()
    # Load network
    dqn = Agent(args, env)
    dqn.eval()

    reward_sum = 0
    while True:
        action = dqn.act(state)
        (state,reward,done) = env.step(action)
        reward_sum += reward
        if done:
            print(reward_sum)
            reward_sum = 0
            state = env.reset()
        if SHOW_MATRIX:
            env.render()
        if SLEEP > 0:
            time.sleep(SLEEP)
else:
    (io, pjson, state) = initialize_game(TRAINING)
    (pjson, state) = reset_game(io, state)
    reward_sum = 0
    while True:
        (pjson, state) = next_step(io, pjson, ACTION.RIGHT)
        if state.terminal:
            print(reward_sum)
            reward_sum = 0
            (pjson, state) = reset_game(io, state)
        else:
            reward_sum += 1
        if SHOW_MATRIX:
            display_matrix(state.image)
        if SLEEP > 0:
            time.sleep(SLEEP)
