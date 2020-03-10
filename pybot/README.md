# Machine-learning based AI for Super Gravitron

This bot relies on a deep Q network based on [this Python implementation](https://github.com/Kaixhin/Rainbow).

## Requirements

- [Python 3](https://www.python.org/downloads/) (this bot has been tested on Python 3.7.6)
- A GPU supporting CUDA (this bot has been tested with a NVIDIA GeForce RTX 2080)
- A version of the [CUDA drivers](https://developer.nvidia.com/cuda-downloads) supported by [PyTorch](https://pytorch.org/get-started/locally/)
- Optionally, the [cuDNN library](https://developer.nvidia.com/cudnn) corresponding to your version of CUDA
- The following Python libraries:
    - [PyTorch](https://pytorch.org/get-started/locally/)
    - plotly
    - tqdm
    - opencv-python

## Running the bot

Download the pretrained models in the release section, and extract them in the `results` directory.

Now, just open a terminal in the current directory and run `python play.py --model results/canonical/1875/model.pth` (the [modded version of the game](https://github.com/E-Sh4rk/VVVVVV) must be present in `../game`).

You can use another model, but in this case do not forget to specify the right architecture (`--architecture` and `--hidden-size`).
You can also optionally activate cuDNN by using the flag `--enable-cudnn`.

You can customize the global parameters at the top of `play.py`:
- If `SHOW_MATRIX` is true, the input given to the DQN will be displayed (warning: it can slow down the process a lot).
- If `TRAINING` is true, the game will directly start in the Super Gravitron with an increased framerate.

## Training

Please refer to `training.txt`. Note that the training can take a lot of RAM (about 10 Go with the default configuration).

Two possible architectures are available (you can of course make your own one in `model.py`):
- `canonical`: 3 convolution layers with a final output size of `4928`, followed by two dense layers. Should be used with `hidden_size=512`.
- `canonical-`: Same as `canonical`, but the first convolution has a bigger stride, leading to an output size of `1408` instead of `4928`. Should be used with `hidden_size=256`. This architecture is about 8x lighter than `canonical`. It learns slightly faster at the beginning, but seems to struggle more after.

## Ideas for improvement

- Currently, the image given as input to the DQN has no information about the intertia of the character (it only indicates its position and velocity). In VVVVVV, inertia appears when the player goes left or right for at least 5 consecutive frames. The information whether the player has inertia or not should be added to the input of the DQN.
