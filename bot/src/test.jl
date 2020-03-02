include("simulation.jl")
include("comm.jl")

function are_game_objects_equivalent(o1::GameObject, o2::GameObject)
    return o1.x == o2.x && o1.y == o2.y && o1.w == o2.w && o1.h == o2.h
end

function is_simulation_correct(simulation::GameState, truth::GameState)
    if !are_game_objects_equivalent(simulation.player, truth.player)
        println("Player position is wrong.")
        simx = simulation.player.x
        simy = simulation.player.y
        tx = truth.player.x
        ty = truth.player.y
        println("Predicted: ($simx,$simy)\tTruth: ($tx,$ty)")
        return false
    end
    if simulation.terminal
        return true
    elseif truth.terminal
        println("The game state should be terminal!")
        return false
    end
    # for i in 1:length(truth.projectiles)
    #     ps = simulation.projectiles[i]
    #     pt = truth.projectiles[i]
    #     if !are_game_objects_equivalent(ps, pt)
    #         println("Projectile position is wrong.")
    #         return false
    #     end
    # end
end

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
            is_simulation_correct(predicted, state)
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
