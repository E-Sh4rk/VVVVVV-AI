# @everywhere include("src/simulation.jl")
# include("src/comm.jl")
# @everywhere include("src/search.jl")
# include("src/debug.jl")
include("src/simulation.jl")
include("src/comm.jl")
include("src/search.jl")
include("src/debug.jl")

DEBUG = false

function main()
    println("VBot - Bot for the Super Gravitron")

    (io, state) = initialize_game(true)
    state = reset!(io, state)
    while true
        (action, step) = search_best_action(state, DEBUG)
        DEBUG && (sim_state = state)
        for i in 1:step
            DEBUG && (sim_state = simulate_next(sim_state, action))
            state = next!(io, state, action)
            if DEBUG && !check_simulation(sim_state, state)
                println("S=$step")
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
