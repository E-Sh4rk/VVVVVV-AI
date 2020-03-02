include("simulation.jl")
include("comm.jl")
include("search.jl")

function main()
    println("VBot - Bot for the Super Gravitron")

    (io, state) = initialize_game(true)
    state = reset!(io, state)
    while true
        (action, step) = search_best_action(state)
        println(action)
        for i in 1:step
            state = next!(io, state, action)
            if state.terminal
                state = reset!(io, state)
                break
            end
        end
    end
    quit_game!(io)
end

main()
