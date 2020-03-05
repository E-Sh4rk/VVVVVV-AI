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

Just open a terminal in this directory and run `python play.py --model results/canonical/1875/model.pth` (the game must be present in `../game`).

You can use another model, but in this case do not forget to specify the right architecture (`--architecture` and `--hidden-size`).
You can also optionally activate cuDNN by using the flag `--enable-cudnn`.

You can customize the global parameters at the top of `play.py`:
- If `SHOW_MATRIX` is true, the input given to the DQN will be displayed (warning: it can slow down the process a lot).
- If `TRAINING` is true, the game will directly start in the Super Gravitron with an increased framerate.

## Training

Please refer to `training.txt`. Note that the training can take a lot of RAM (about 10 Go with the default configuration).
