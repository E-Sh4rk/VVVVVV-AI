# @everywhere include("src/simulation.jl")
# include("src/comm.jl")
# @everywhere include("src/search.jl")
# include("src/debug.jl")
include("src/simulation.jl")
include("src/comm.jl")
include("src/search.jl")
include("src/debug.jl")

DEBUG = true
TRAINING = true

function main()
    println("VBot - Bot for the Super Gravitron")

    (io, state) = initialize_game(TRAINING)
    state = wait_for_new_game!(io, state)
    while true
        (actions, min_step) = search_best_actions(state, 1, DEBUG)
        DEBUG && (sim_state = state)
        for i in 1:min_step
            DEBUG && (sim_state = simulate_next(sim_state, actions[i]))
            state = next!(io, state, actions[i])
            if DEBUG && !check_simulation(sim_state, state)
                println("S=$min_step")
                readline()
            end
            if state.terminal
                state = reset!(io, state)
                break
            end
        end
    end
    quit_game!(io)
end

main()
