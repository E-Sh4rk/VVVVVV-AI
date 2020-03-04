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
# Number of frames that should be predicted in advance
# in order to start the search earlier.
# Shouldn't be too high, because information about new projectiles
# cannot be predicted.
PREDICTION = 3

function main()
    println("VBot - Bot for the Super Gravitron")

    (io, state) = initialize_game(TRAINING)
    state = wait_for_new_game!(io, state)
    previous_state = nothing
    previous_action = wait
    must_read_state = false
    while true
        (actions, min_step) = search_best_actions(state, PREDICTION, DEBUG)
        min_step = max(min_step, PREDICTION)
        if must_read_state
            DEBUG && (sim_state = state)
            state = read_state!(io, previous_state, previous_action)
            if state.terminal
                state = reset!(io, state)
            elseif DEBUG && !check_simulation(sim_state, state)
                println("(Predicted frames)")
                readline()
            end
            must_read_state = false
        end
        DEBUG && (sim_state = state)
        reset = false
        for i in 1:min_step-PREDICTION
            previous_state = state
            previous_action = actions[i]
            DEBUG && (sim_state = simulate_next(sim_state, actions[i]))
            state = next!(io, state, actions[i])
            if DEBUG && !check_simulation(sim_state, state)
                println("S=$min_step")
                readline()
            end
            if state.terminal
                state = reset!(io, state)
                reset = true
                break
            end
        end
        # Send and predict result for remaining moves
        if PREDICTION > 0 && !reset
            must_read_state = true
            rem_actions = actions[min_step-PREDICTION+1:min_step]
            send_move_many!(io, rem_actions)
            for action in rem_actions
                previous_state = state
                previous_action = action
                state = simulate_next(state, action)
            end
        end
    end
    quit_game!(io)
end

main()
