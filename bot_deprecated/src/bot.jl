using ReinforcementLearning, ReinforcementLearningEnvironments, Flux, Plots

include("game.jl")
include("environment.jl")
include("training.jl")

VVVVVV_PATH = "../desktop_version/flibitBuild/Debug/VVVVVV.exe"
MATRIX_VIEWER_PATH = "display.py"
DISPLAY_MATRIX = true
SYNC_DISPLAY = true
FRAMERATE = 0 # 25
TRAIN = true

function print_error_if_not_io(err)
    if !isa(err, Base.IOError) || !isa(err, ErrorException)
        println(typeof(err))
        println(err)
    end
end

function send_matrix(io, M)
    if io == nothing || !iswritable(io)
        return false
    end
    (n,m,c) = size(M)
    for j = 1:m
        for i = 1:n
            v = 0
            for k = 1:c
                if M[i,j,k] > 0
                    v = k
                end
            end
            print(io, v)
        end
        println(io, "")
    end
    return true
end

mvp = nothing
mvp_matrix = nothing
function display_loop!()
    try
        while true
            global mvp, mvp_matrix
            if !send_matrix(mvp, mvp_matrix)
                return
            end
            sleep(0.01)
        end
    catch err
        print_error_if_not_io(err)
    end
end
function display_matrix!(M)
    global mvp, mvp_matrix
    if M == nothing
        return
    end
    (n,m,_) = size(M)
    mvp_matrix = M
    if mvp == nothing
        mvp = open(`python $MATRIX_VIEWER_PATH`, "w")
        println(mvp, 2*DOWNSCALE)
        println(mvp, n)
        println(mvp, m)
        if !SYNC_DISPLAY
            @async display_loop!()
        end
    end
    if SYNC_DISPLAY
        send_matrix(mvp, mvp_matrix)
    end
end
function close_display!()
    global mvp
    if mvp != nothing
        try
            println(mvp, "")
        catch e
        end
        mvp = nothing
    end
end

function frame(env, model)
    # state = next!(io, right)
    # if DISPLAY_MATRIX
    #     display_matrix!(state.M)
    # end
    # return state
    obs = observe(env)
    if DISPLAY_MATRIX
        display_matrix!(get_state(obs)[:, :, :, 1])
    end

    if get_terminal(obs)
        a = 1
    else
        state = get_state(obs)
        # state = reshape(state, size(state)..., 1)
        state = cat(state; dims=5)
        out = model(state)[:,1]
        (_,i) = findmax(out)
        a = i
    end
    interact!(env, a)
end

function run_model(io, state)
    raw_env = GravitronEnv(io, state, 1, 0)
    ssize = state_size(raw_env)
    env = WrappedEnv(
        env = raw_env,
        preprocessor = StackFrames(UInt8, ssize..., N_FRAMES)
    )
    #state = restart!(io, state, #=FRAMERATE=#0)
    reset!(env)

    model = get_model(raw_env)
    if isfile(PARAMS_PATH)
        println("Weights file detected...")
        Flux.loadparams!(model, Serialization.deserialize(PARAMS_PATH))
    end
    while isreadable(io) && iswritable(io)
        @with_framerate(FRAMERATE, frame(env, model))
    end
end

function main()
    println("VBot - Reinforcement Learning for Super Gravitron")

    # try
        open(`$VVVVVV_PATH`, "r+") do io
            state = initialize_game!(io)
            println("VVVVVV instance initalized.")
            if TRAIN
                train(io, state)
            else
                run_model(io, state)
            end
        end
    # catch err
    #     print_error_if_not_io(err)
    # end

    close_display!()
end

main()
