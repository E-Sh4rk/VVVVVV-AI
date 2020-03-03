include("simulation.jl")
include("comm.jl")
include("debug.jl")

function main()
    println("Simulated Physics Testing")

    (io, state) = initialize_game(true)
    state = reset!(io, state)
    while true
        action = rand([wait, left, right])
        n = rand(1:25)
        for i in 1:n
            predicted = simulate_next(state, action)
            state = next!(io, state, action)
            if !check_simulation(predicted, state)
                readline()
            end
            if state.terminal
                println("Reset")
                state = reset!(io, state)
                break
            end
        end
    end
    quit_game!(io)
end

main()
