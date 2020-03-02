
function are_game_objects_equivalent(o1::GameObject, o2::GameObject)
    return o1.x == o2.x && o1.y == o2.y && o1.w == o2.w && o1.h == o2.h
end

function print_boxes(simulation::GameObject, truth::GameObject)
    simx = simulation.x
    simy = simulation.y
    tx = truth.x
    ty = truth.y
    println("Predicted: ($simx,$simy)\tTruth: ($tx,$ty)")
end

function is_simulation_correct(simulation::GameState, truth::GameState)
    if !are_game_objects_equivalent(simulation.player, truth.player)
        println("Player position is wrong.")
        print_boxes(simulation.player, truth.player)
        return false
    end
    if simulation.terminal
        return true
    elseif truth.terminal
        println("The game state should be terminal!")
        truth_proj = nothing
        for proj in truth.projectiles
            if player_proj_in_collision(truth.player, proj)
                truth_proj = proj
                break
            end
        end
        if truth_proj == nothing
            println("The collision check seems to be broken.")
            (truth_proj,_) = nearest_projectile(truth)
            (sim_proj,_) = nearest_projectile(simulation)
            print_boxes(sim_proj, truth_proj)
        else
            (sim_proj,_) = nearest_projectile(simulation)
            if !are_game_objects_equivalent(sim_proj, truth_proj)
                println("No projectile at this position in the simulation.")
                print_boxes(sim_proj, truth_proj)
            else
                println("This line should not appear.")
            end
        end
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
    return true
end
