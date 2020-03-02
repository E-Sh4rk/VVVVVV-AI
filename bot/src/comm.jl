import JSON

macro with_framerate(framerate, expr)
    return quote
        elapsed = @elapsed $(esc(expr))
        towait = $(esc(framerate))/1000 - elapsed
        if towait > 0
            sleep(towait)
        end
    end
end

## PARSING

function i2b(i)
    return i == 0 ? false : true
end

function json_to_game_object(json)
    return GameObject(json["x"], json["y"], json["w"], json["h"], 0, 0)
end

# PLAYER_MAX_X_SPEED = 6
# PLAYER_X_JUMP = 320

function compute_speed_of_player(player, previous_state, xs)
    if previous_state == nothing
        return GameObject(player.x, player.y, player.w, player.h, xs, 0)
    end
    ys = player.y - previous_state.player.y
    # xs = player.x - previous_state.player.x
    # if abs(xs) > PLAYER_MAX_X_SPEED
    #     if xs > 0
    #         xs -= PLAYER_X_JUMP
    #     else
    #         xs += PLAYER_X_JUMP
    #     end
    # end
    xs = apply_friction_x(xs)
    return GameObject(player.x, player.y, player.w, player.h, xs, ys)
end

function in_collision(o1, o2)
    top = max(o1.y, o2.y)
    bottom = min(o1.y + o1.h, o2.y + o2.h)
    left = max(o1.x, o2.x)
    right = min(o1.x + o1.w, o2.x + o2.w)
    return top < bottom && left < right
end

function compute_speed_of_projectile(proj, previous_state)
    if previous_state == nothing
        return proj
    end
    xs = 0
    for p in previous_state.projectiles
        if p.y == proj.y && in_collision(p, proj)
            diff = proj.x - p.x
            if sign(diff) == sign(p.xs)
                xs = diff
            end
        end
    end
    if xs == 0
        xs = proj.x < 0 ? PROJ_SPEED : -PROJ_SPEED
    end
    return GameObject(proj.x, proj.y, proj.w, proj.h, xs, 0)
end

function parse_state(json, previous_state, action::ACTION)
    # Game info
    timer = json["timer"]
    terminal = i2b(json["dead"]) || !i2b(json["playable"])
    # Lines
    line0 = json_to_game_object(json["lines"][1])
    line1 = json_to_game_object(json["lines"][2])
    if line0.y <= line1.y
        tline = line0
        bline = line1
    else
        tline = line1
        bline = line0
    end
    # Move stack
    if previous_state == nothing
        (info, xs) = (GameInfo(0,0), 0)
    else
        (info, xs) =
            process_input(previous_state.info, previous_state.player.xs, action)
    end
    # Player
    player = json_to_game_object(json["player"])
    player = compute_speed_of_player(player, previous_state, xs)
    # Projectiles
    projectiles = []
    for proj in json["proj"]
        p = json_to_game_object(proj)
        p = compute_speed_of_projectile(p, previous_state)
        push!(projectiles, p)
    end

    return GameState(timer, terminal, tline, bline, player, projectiles, info)
end

## COMMUNICATION

VVVVVV_CMD_TRAINING = ["../game/VVVVVV.exe", "-training"]
VVVVVV_CMD = ["../game/VVVVVV.exe"]

ACTION_MAP = [ "", "l", "r", "s" ]

function send_move!(io, action::ACTION)
    println(io, ACTION_MAP[Int(action)])
end

function read_state!(io, previous_state, action::ACTION)
    state = nothing
    while state == nothing
        line = strip(readline(io))
        if line == "NO_SWN"
            send_move!(io, wait)
        elseif startswith(line, "{")
            json = JSON.parse(line)
            state = parse_state(json, previous_state, action)
        end
    end
    return state
end

function next!(io, previous_state, action::ACTION)
    send_move!(io, action)
    return read_state!(io, previous_state, action)
end

function reset!(io, state)
    if !state.terminal
        state = next!(io, nothing, suicide)
        @assert state.terminal
    end
    while state.terminal
        state = next!(io, nothing, wait)
    end
    return state
end

function initialize_game(training)
    cmd = training ? VVVVVV_CMD_TRAINING : VVVVVV_CMD
    io = open(`$cmd`, "r+")
    return (io, next!(io, nothing, wait))
end

function quit_game!(io)
    close(io)
    kill(io)
end
