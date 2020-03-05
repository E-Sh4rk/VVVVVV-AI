# Search-based AI for Super Gravitron

## Requirements

- The [Julia interpreter](https://julialang.org/downloads/) (any recent version, this bot has been tested on Julia 1.3.1)

## Running the bot

Just open a terminal in this directory and run `julia --project bot.jl` (the game must be present in `../game`).

You can customize the global parameters at the top of `bot.jl`:
- If `DEBUG` is true, the bot will monitor simulations (= compare them with the truth) and log any issue found.
- If `TRAINING` is true, the game will directly start in the Super Gravitron with an increased framerate.
