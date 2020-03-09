# Search-based AI for Super Gravitron

## Requirements

- The [Julia interpreter](https://julialang.org/downloads/) (any recent version, this bot has been tested on Julia 1.3.1)

## Running the bot

Just open a terminal in this directory and run `julia --project bot.jl` (the [modded version of the game](https://github.com/E-Sh4rk/VVVVVV) must be present in `../game`).

You can customize the global parameters at the top of `bot.jl`:
- If `DEBUG` is true, the bot will monitor simulations (= compare them with the truth) and log any issue found.
- If `TRAINING` is true, the game will directly start in the Super Gravitron with an increased framerate.

There are also some advanced parameters in the file `src/search.jl`:
- `PREFER_CENTER_X_THRESHOLD` can be set to force the character to go to the middle when it seems safe to do so.
