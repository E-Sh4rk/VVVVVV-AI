
PROJ_SPEED = 7

X_FRICTION = 1.1f0
X_MAX = 6f0
CX = 6

@enum ACTION wait=1 left=2 right=3 suicide=4

struct GameInfo
    tap_left
    tap_right
end

struct GameObject
    x
    y
    w
    h
    xs
    ys
end

struct GameState
    timer
    terminal
    tline
    bline
    player
    projectiles
    info
end

function process_input(info::GameInfo, xs::Float32, action::ACTION)
    tl = info.tap_left
    tr = info.tap_right

    if action == left
        tl += 1
    else
        if tl <= 4 && tl > 0 && xs < 0f0
            xs = 0f0
        end
        tl = 0
    end

    if action == right
        tr += 1
    else
        if tr <= 4 && tr > 0 && xs > 0f0
            xs = 0f0
        end
        tr = 0
    end

    if action == left
        xs -= 3f0
    elseif action == right
        xs += 3f0
    end

    return (GameInfo(tl, tr), xs)
end

function apply_friction_x(xs::Float32)
    if xs > 0f0
        xs -= X_FRICTION
    elseif xs < 0f0
        xs += X_FRICTION
    end
    xs = max(min(xs, X_MAX), -X_MAX)
    if abs(xs) < X_FRICTION
        xs = 0f0
    end
    return xs
end

function compute_new_ys(state::GameState) # Also takes friction into account
    ys = state.player.ys

    if abs(ys) == 2
        ys = sign(ys) * 5
    elseif abs(ys) == 5
        ys = sign(ys) * 8
    elseif abs(ys) == 8
        ys = sign(ys) * 10
    end

    if state.player.y <= state.tline.y
        ys = ys == 0 ? 2 : 0
    elseif state.player.y + state.player.h > state.bline.y
        ys = ys == 0 ? -2 : 0
    end

    return ys
end

function apply_speed_x(x, xs)
    x = trunc(x - CX + xs)
    if x <= -10
        x += 320
    elseif x > 310
        x -= 320
    end
    return x + CX
end

function player_proj_in_collision(player, proj)
    cx = proj.x + proj.w/2
    cy = proj.y + proj.h/2
    radius = (proj.w + proj.h) / 4

    textX = min(max(cx, player.x), player.x + player.w)
    testY = min(max(cy, player.y), player.y + player.h)

    distX = cx - testX
    distY = cy - testY
    distance² = distX*distX + distY*distY

    return distance² <= radius*radius
end

function simulate_next(state::GameState, action::ACTION)
    if state.terminal
        return state
    end
    # Player
    (info, xs) = process_input(state.info, state.player.xs, action)
    xs = apply_friction_x(xs)
    ys = compute_new_ys(state)
    y = state.player.y + ys
    x = apply_speed_x(state.player.x)
    player = GameObject(x, y, state.player.w, state.player.h, xs, ys)
    # Projectiles
    projectiles = []
    for proj in state.projectiles
        p = GameObject(proj.x + proj.xs, proj.y + proj.ys,
            proj.w, proj.h, proj.xs, proj.ys)
        push!(projectiles, p)
    end
    # Collisions (terminal)
    terminal = false
    for proj in projectiles
        if player_proj_in_collision(player, proj)
            terminal = true
            break
        end
    end

    return GameState(state.timer + 1, terminal, state.tline, state.bline,
        player, projectiles, info)
end
