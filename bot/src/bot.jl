include("simulation.jl")
include("comm.jl")
include("search.jl")
include("debug.jl")

DEBUG = true

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
            if DEBUG && !is_simulation_correct(sim_state, state)
                println("S=$step")
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
