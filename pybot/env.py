# -*- coding: utf-8 -*-
from collections import deque
import random
import cv2
import torch
from state import display_matrix, NB_CHANNELS, HEIGHT_MULTIPLE_OF, WIDTH_MULTIPLE_OF
from comm import initialize_game, reset_game, next_step, ACTION

FSKIP = 2
# FSKIP = 3

class Env():
  def __init__(self, args, training):
    self.device = args.device
    # TODO: args.max_episode_length
    (self.io, self.pjson, self.state) = initialize_game(training)
    actions = [ACTION.WAIT, ACTION.LEFT, ACTION.RIGHT]
    self.actions = dict([i, e] for i, e in zip(range(len(actions)), actions))
    self.lives = 0  # Life counter (used in DeepMind training)
    self.life_termination = False  # Used to check if resetting only from loss of life
    self.window = args.history_length  # Number of frames to concatenate
    self.state_buffer = deque([], maxlen=self.window*NB_CHANNELS)
    self.training = True  # Consistent with model training mode

  def _get_state(self):
    state = self.state.image
    if NB_CHANNELS == 3:
      (b,g,r) = cv2.split(state)
      return [
        torch.tensor(b, dtype=torch.float32, device=self.device).div_(255),
        torch.tensor(g, dtype=torch.float32, device=self.device).div_(255),
        torch.tensor(r, dtype=torch.float32, device=self.device).div_(255)
      ]
    elif NB_CHANNELS == 2:
      (b,g,r) = cv2.split(state)
      return [
        torch.tensor(g, dtype=torch.float32, device=self.device).div_(255),
        torch.tensor(r, dtype=torch.float32, device=self.device).div_(255)
      ]
    else:
      return [torch.tensor(state, dtype=torch.float32, device=self.device).div_(255)]

  def _reset_buffer(self):
    for _ in range(self.window*NB_CHANNELS):
      self.state_buffer.append(torch.zeros(HEIGHT_MULTIPLE_OF, WIDTH_MULTIPLE_OF, device=self.device))

  def _append_state_to_buffer(self, observation):
      # observation = self._get_state()
      self.state_buffer.extend(observation)

  def reset(self):
    if self.life_termination:
      self.life_termination = False  # Reset flag
      (self.pjson, self.state) = reset_game(self.io, self.state)
    else:
      # Reset internals
      self._reset_buffer()
      (self.pjson, self.state) = reset_game(self.io, self.state)
      # Perform up to 30 random no-ops before starting
      for _ in range(random.randrange(5, 20)): # NOTE: changed to 15 because this game is 30FPS
        (self.pjson, self.state) = next_step(self.io, self.pjson, ACTION.WAIT)
    # Process and return "initial" state
    self._append_state_to_buffer(self._get_state())
    self.lives = 0
    return torch.stack(list(self.state_buffer), 0)

  def step(self, action):
    # Repeat action 4 times, max pool over last 2 frames
    # NOTE: changed to FSKIP times and 1 frame, because this game is 30FPS
    # frame_buffer = torch.zeros(2, 84, 84, device=self.device)
    for _ in range(FSKIP):
      (self.pjson, self.state) = next_step(self.io, self.pjson, self.actions.get(action))
      # NOTE: deactivated. We should only add played frame to the frame history (otherwise, conflict with memory buffer optimisation)
      # self._append_state_to_buffer(self._get_state())
      done = self.state.terminal
      # reward += self.ale.act(self.actions.get(action))
      # if t == 2:
      #   frame_buffer[0] = self._get_state()
      # elif t == 3:
      #   frame_buffer[1] = self._get_state()
      # done = self.ale.game_over()
      if done:
        break

    reward = 0 if done else FSKIP
    # observation = frame_buffer.max(0)[0]
    # self._append_state_to_buffer(observation)
    self._append_state_to_buffer(self._get_state())
    
    # Detect loss of life as terminal in training mode
    # if self.training:
    #   lives = self.ale.lives()
    #   if lives < self.lives and lives > 0:  # Lives > 0 for Q*bert
    #     self.life_termination = not done  # Only set flag when not truly done
    #     done = True
    #   self.lives = lives
    # Return state, reward, done
    return torch.stack(list(self.state_buffer), 0), reward, done

  # Uses loss of life as terminal signal
  def train(self):
    self.training = True

  # Uses standard terminal signal
  def eval(self):
    self.training = False

  def action_space(self):
    return len(self.actions)

  def render(self):
    display_matrix(self.state.image)

  def close(self):
    cv2.destroyAllWindows()
    self.io.kill()
