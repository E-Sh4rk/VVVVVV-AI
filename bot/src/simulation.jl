
PROJ_SPEED = 7
PROJ_DELETED_LEFT = -20
PROJ_DELETED_RIGHT = 320

X_FRICTION = 1.1f0
XS_MAX = 6f0
CX = 6
INITIAL_YS = 0
TOP_GRAVITY_CHANGE = 48
BOTTOM_GRAVITY_CHANGE = 163

@enum ACTION wait=1 left=2 right=3 suicide=4

struct GameInfo
    tap_left
    tap_right
end

struct GameObject
    x::Int
    y::Int
    w::Int
    h::Int
    xs::Float32
    ys::Float32
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
    xs = max(min(xs, XS_MAX), -XS_MAX)
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

    if state.player.y <= TOP_GRAVITY_CHANGE
        ys = ys == 0 ? 2 : 0
    elseif state.player.y >= BOTTOM_GRAVITY_CHANGE
        ys = ys == 0 ? -2 : 0
    end

    return ys
end

function apply_speed_x(x, xs)
    x = trunc(Int, x - CX + xs)
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

    testX = min(max(cx, player.x), player.x + player.w)
    testY = min(max(cy, player.y), player.y + player.h)

    distX = cx - testX
    distY = cy - testY
    distance² = distX*distX + distY*distY

    return distance² <= radius*radius
end

function get_proj_in_collision_no_wrap(player, projectiles)
    res = nothing
    for proj in projectiles
        if player_proj_in_collision(player, proj)
            res = proj
            break
        end
    end
    return res
end

function get_proj_in_collision(player, projectiles)
    res = get_proj_in_collision_no_wrap(player, projectiles)
    if res == nothing
        if player.x - CX < 0
            player = GameObject(player.x + 320, player.y, player.w, player.h,
                player.xs, player.ys)
            res = get_proj_in_collision_no_wrap(player, projectiles)
        elseif player.x - CX > 300
            player = GameObject(player.x - 320, player.y, player.w, player.h,
                player.xs, player.ys)
            res = get_proj_in_collision_no_wrap(player, projectiles)
        end
    end
    return res
end

function simulate_next(state::GameState, action::ACTION)
    if state.terminal || action == suicide
        return GameState(state.timer, true, state.tline, state.bline,
            state.player, state.projectiles, state.info)
    end

    # Projectiles
    projectiles = []
    for proj in state.projectiles
        p = GameObject(proj.x + proj.xs, proj.y + proj.ys,
            proj.w, proj.h, proj.xs, proj.ys)
        push!(projectiles, p)
    end

    # Player
    (info, xs) = process_input(state.info, state.player.xs, action)
    xs = apply_friction_x(xs)
    ys = compute_new_ys(state)
    y = state.player.y + ys
    x = apply_speed_x(state.player.x, xs)
    player = GameObject(x, y, state.player.w, state.player.h, xs, ys)

    # Collisions (terminal)
    terminal = get_proj_in_collision(player, projectiles) != nothing

    return GameState(state.timer + 1, terminal, state.tline, state.bline,
        player, projectiles, info)
end

function player_proj_dist(player, proj)
    pcx = player.x + player.w/2
    pcy = player.y + player.h/2

    cx = proj.x + proj.w/2
    cy = proj.y + proj.h/2
    distX = pcx - cx
    distY = pcy - cy
    dist = distX*distX + distY*distY

    return dist
end

function nearest_projectile(state::GameState)
    min_dist = Inf32
    min_proj = nothing
    for proj in state.projectiles
        dist = player_proj_dist(state.player, proj)
        if dist < min_dist
            min_dist = dist
            min_proj = proj
        end
    end
    return (min_proj, min_dist)
end

function evaluate_state(state::GameState)
    if state.terminal
        return -Inf32
    end
    (_, min_dist) = nearest_projectile(state)
    return min_dist
end
