# VVVVVV-AI

This repo contains two bots for the Super Gravitron of [VVVVVV](https://github.com/TerryCavanagh/VVVVVV/).

In order to use them, you need a [modded version of VVVVVV](https://github.com/E-Sh4rk/VVVVVV) that allows control of the game from an external program.
Just place it into the `game` directory
(the executable should be called `VVVVVV.exe`, and all its dependencies must be present, such as `data.zip`).

- The folder `bot` contains a search-based bot written in Julia.

- The folder `pybot` contains the a ML-based bot. It uses a deep Q network based on [this Python implementation](https://github.com/Kaixhin/Rainbow).

- The folder `bot_deprecated` contains a deprecated version of the ML-based bot, written in Julia.
In the future, I might translate the current version of the Python bot in Julia, but for now you should just ignore this directory.

## License

You can freely use the content of this repository as long as:

- You do not use one of those bots during a speedrun (or any kind of superplay) by pretending that you are playing

You can freely modify and distribute the content of this repository as long as:

- You give me credits (please keep a link to this repository)

## Results

- Currently, the ML-based bot survives 30 seconds on average.
It has been trained about 250 hours. Its best time is about 3min30.
- The search-based bot survives much longer (it has more spatial pecision).
I haven't measured how much time it survives in average, but it is for sure more than what humans can do. Its best time is more than 23 minutes (I killed it after 23 minutes, because I am not very patient).

NOTE: these bots do not *cheat* in the sense that they only have information that is displayed by the game. In particular, they do not know what will be the next pattern to come. More precisely, the bots have the following information (constant values are omitted):
- The position of the player with a precision of 1px
- The position of all the projectiles currently active (those that are shown on screen
or announced by an arrow on the side of the screen) with a precision of 1px
- The timer and whether the player is dead or not

A demonstration video is available here:  
[https://youtu.be/OeOmJdrOLFs](https://youtu.be/OeOmJdrOLFs)
