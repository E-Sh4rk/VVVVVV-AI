
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

function print_object(o::GameObject, label::String)
    (x,y,w,h,xs,ys) = (o.x,o.y,o.w,o.h,o.xs,o.ys)
    println("$label: ($x,$y,$w,$h,$xs,$ys)")
end

function print_all_projectiles(simulation, truth)
    if truth != nothing
        println("======= TRUTH =======")
        for p in truth.projectiles
            print_object(p, "Projectile")
        end
    end
    if simulation != nothing
        println("===== SIMULATION =====")
        for p in simulation.projectiles
            print_object(p, "Projectile")
        end
    end
    println("======================")
end

previous_truth = nothing
previous_simulation = nothing
function check_simulation(simulation::GameState, truth::GameState)
    global previous_truth, previous_simulation
    truth_prev = previous_truth
    sim_prev = previous_simulation
    previous_truth = truth
    previous_simulation = simulation

    if simulation.terminal
        if !truth.terminal
            println("(The predicted game state is wrongly terminal)")
            # return false
        end
        return true
    end
    # PLAYER POSITION
    if !are_game_objects_equivalent(simulation.player, truth.player)
        println("Player position is wrong.")
        print_boxes(simulation.player, truth.player)
        return false
    end
    # PROJECTILES
    for p in simulation.projectiles
        if (p.x > PROJ_DELETED_RIGHT && p.xs > 0) || (p.x < PROJ_DELETED_LEFT && p.xs < 0)
            continue # The projectile may have been removed in the original game
        end
        found = false
        for pt in truth.projectiles
            if are_game_objects_equivalent(p, pt)
                found = true
                break
            end
        end
        if !found
            println("A simulated projectile has no equivalent in the truth.")
            print_object(p, "Projectile")
            print_all_projectiles(sim_prev, truth_prev)
            print_all_projectiles(simulation, truth)
            return false
        end
    end
    for p in truth.projectiles
        if (p.x > PROJ_DELETED_RIGHT && p.xs < 0) || (p.x < PROJ_DELETED_LEFT && p.xs > 0)
            continue # The projectile is new, the simulator may not be notified about it yet
        end
        found = false
        for pt in simulation.projectiles
            if are_game_objects_equivalent(p, pt)
                found = true
                break
            end
        end
        if !found
            println("A projectile has no equivalent in the simulation.")
            print_object(p, "Projectile")
            print_all_projectiles(sim_prev, truth_prev)
            print_all_projectiles(simulation, truth)
            return false
        end
    end
    # COLLISIONS
    if truth.terminal
        println("The predicted game state should be terminal!")
        truth_proj = get_proj_in_collision(truth.player, truth.projectiles)
        if truth_proj == nothing
            println("No collision detected in the truth.")
            (truth_proj,_) = nearest_projectile(player_proj_dist², truth)
            print_object(simulation.player, "Player")
            print_object(truth_proj, "Nearest projectile")
            print_all_projectiles(nothing, truth)
        else
            println("Collision detected in the truth, but not in the simulation.")
            (sim_proj,_) = nearest_projectile(player_proj_dist², simulation)
            print_object(simulation.player, "Player")
            print_boxes(sim_proj, truth_proj)
            print_all_projectiles(simulation, truth)
        end
        return false
    end
    return true
end
