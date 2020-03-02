
function are_game_objects_equivalent(o1::GameObject, o2::GameObject)
    return o1.x == o2.x && o1.y == o2.y && o1.w == o2.w && o1.h == o2.h
end

function print_boxes(simulation::GameObject, truth::GameObject)
    simx = simulation.x
    simy = simulation.y
    simw = simulation.w
    simh = simulation.h
    tx = truth.x
    ty = truth.y
    tw = truth.w
    th = truth.h
    println("Predicted: ($simx,$simy,$simw,$simh)\tTruth: ($tx,$ty,$tw,$th)")
end

function is_simulation_correct(simulation::GameState, truth::GameState)
    if !are_game_objects_equivalent(simulation.player, truth.player)
        println("Player position is wrong.")
        print_boxes(simulation.player, truth.player)
        return false
    end
    if simulation.terminal
        println("(The predicted game state is wrongly terminal)")
        print_boxes(simulation.player, truth.player)
        return true
    elseif truth.terminal
        println("The predicted game state should be terminal!")
        truth_proj = get_proj_in_collision(truth.player, truth.projectiles)
        if truth_proj == nothing
            println("The collision check seems to be broken.")
            (truth_proj,_) = nearest_projectile(truth)
            (sim_proj,_) = nearest_projectile(simulation)
            print_boxes(sim_proj, truth_proj)
            print_boxes(simulation.player, truth.player)
        else
            (sim_proj,_) = nearest_projectile(simulation)
            if !are_game_objects_equivalent(sim_proj, truth_proj)
                println("No projectile at this position in the simulation.")
                print_boxes(sim_proj, truth_proj)
                print_boxes(simulation.player, truth.player)
                n = length(simulation.projectiles)
                m = length(truth.projectiles)
                println("Projectiles in the simulation: $n\tTruth: $m")
            else
                println("This line should not appear.")
                print_boxes(sim_proj, truth_proj)
                print_boxes(simulation.player, truth.player)
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