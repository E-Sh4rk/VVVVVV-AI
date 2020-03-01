# VVVVVV-AI

This repo contains bots for the super gravitron of [VVVVVV](https://github.com/TerryCavanagh/VVVVVV/).

In order to use it, you need a [modded version of VVVVVV](https://github.com/E-Sh4rk/VVVVVV) that allows control of the game from an external program.
Just place it into the `game` directory
(the executable should be called `VVVVVV.exe`, and all its dependencies must be present, such as `data.zip`).

- The folder `bot` contains a search-based bot written in Julia (work in progress).

- The folder `pybot` contains the a ML-based bot. It uses a deep Q network based on [this Python implementation](https://github.com/Kaixhin/Rainbow).

- The folder `bot_deprecated` contains a deprecated version of the ML-based bot, written in Julia.
In the future, I might translate the current version of the Python bot in Julia, but for now you should just ignore this directory.
