
import JSON

DOWNSCALE = 4
HEIGHT_MULTIPLE_OF = 42
NB_CHANNELS = 3

macro with_framerate(framerate, expr)
    return quote
        elapsed = @elapsed $(esc(expr))
        towait = $(esc(framerate))/1000 - elapsed
        if towait > 0
            sleep(towait)
        end
    end
end

function generate_matrix(json)
    if (length(json["lines"]) != 2)
        return nothing
    end

    lines = json["lines"]
    proj = json["proj"]
    player = json["player"]

    function downscale_sprite!(sprite)
        sprite["x"] ÷= DOWNSCALE
        sprite["y"] ÷= DOWNSCALE
        sprite["w"] = round(Int, sprite["w"]/DOWNSCALE, RoundUp)
        sprite["h"] = round(Int, sprite["h"]/DOWNSCALE, RoundUp)
    end
    if DOWNSCALE > 1
        downscale_sprite!(player)
        for i = 1:length(proj)
            downscale_sprite!(proj[i])
        end
        downscale_sprite!(lines[1])
        downscale_sprite!(lines[2])
    end

    ymin = min(lines[1]["y"], lines[2]["y"])
    ymax = max(lines[1]["y"]+lines[1]["h"],
               lines[2]["y"]+lines[2]["h"])
    xmin = min(lines[1]["x"], lines[2]["x"])
    xmax = max(lines[1]["x"]+lines[1]["w"],
               lines[2]["x"]+lines[2]["w"])
    n = xmax-xmin
    m = ymax-ymin
    mpad = (HEIGHT_MULTIPLE_OF - (m%HEIGHT_MULTIPLE_OF)) % HEIGHT_MULTIPLE_OF
    m += mpad
    y_offset = mpad ÷ 2
    M = zeros(UInt8, n, m, NB_CHANNELS)

    function set!(x,y,v)
        y += y_offset
        if x >= 1 && y >= 1 && x <= n && y <= m
            M[x,y,v] = 1
        end
    end
    function draw_full_sprite!(sprite,v)
        for i = sprite["x"]+1:sprite["x"]+sprite["w"]
            for j = sprite["y"]+1:sprite["y"]+sprite["h"]
                set!(i-xmin,j-ymin,v)
            end
        end
    end
    function draw_full_sprite_circle!(sprite,v)
        r = (sprite["w"] + sprite["h"])/4.0
        mx = sprite["w"]/2.0
        my = sprite["h"]/2.0
        r² = r^2
        for i = 1:sprite["w"]
            for j = 1:sprite["h"]
                if (i-0.5-mx)^2 + (j-0.5-my)^2 <= r²
                    set!(sprite["x"]-xmin+i,sprite["y"]-ymin+j,v)
                end
            end
        end
    end

    draw_full_sprite!(lines[1], 1)
    draw_full_sprite!(lines[2], 1)
    for i = 1:length(proj)
        draw_full_sprite_circle!(proj[i], 2)
    end
    draw_full_sprite!(player, 3)

    for i = 1:m
        M[1,i,1] = 1
        M[end,i,1] = 1
    end

    return M
end

struct GameState
    timer
    playable
    M
end

@enum ACTION wait=1 left=2 right=3 suicide=4
ACTION_MAP = [ "", "l", "r", "s" ]

function i2b(i)
    return i == 0 ? false : true
end

function read_state!(io)
    json = JSON.parse(readline(io))
    playable = !i2b(json["dead"]) && i2b(json["playable"])
    M = generate_matrix(json)
    return GameState(json["timer"], playable, M)
end

function send_move!(io, action::ACTION)
    println(io, ACTION_MAP[Int(action)])
end

function next!(io, action::ACTION)
    send_move!(io, action)
    return read_state!(io)
end

function initialize_game!(io)
    while readline(io) != "SWN_INITIALIZED"
        sleep(0.01)
    end
    return next!(io, wait)
end

function is_finished(state)
    return !state.playable
end

function score(state)
    return state.timer
end

function matrix(state)
    return state.M
end

function restart!(io, state, framerate = 0)
    if !is_finished(state)
        @with_framerate(framerate, state = next!(io, suicide))
    end
    while is_finished(state)
        @with_framerate(framerate, state = next!(io, wait))
    end
    return state
end
