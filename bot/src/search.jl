
# H must not be too big, because the prediction become wrong after some time
# due to the new projectiles that appear randomly in the game.
# In particular, the initial step S should be <= 10 frames.
# H = 60 # 2 seconds
H = 42 # NOTE: H has been decreased because of the 3 frames prediction in bot.jl
M = 1000

ACTIONS = [wait, left, right]
N = length(ACTIONS)
LM = log(N, M)

function search_best_actions(state::GameState, H::Int, S::Int)
    S = min(S, H)
    if state.terminal
        return (-Inf32, nothing)
    elseif S <= 0
        return (evaluate_state(state), [])
    end
    max_v = -Inf32
    max_a = nothing
    for action in ACTIONS
        state_a = state
        for i in 1:S
            state_a = simulate_next(state_a, action)
            if state_a.terminal
                break
            end
        end
        (res_v, res_a) = search_best_actions(state_a, H-S, S)
        if res_a != nothing && res_v > max_v
            max_v = res_v
            push!(res_a, (action, S))
            max_a = res_a
        end
    end
    return (max_v, max_a)
end

function search_best_actions(state::GameState, min_nb_actions::Int, DEBUG::Bool)
    S = ceil(Int, H/LM)
    # We plan the different tasks
    S_all = [S]
    while S_all[end] > 1
        push!(S_all, S_all[end]÷2)
    end
    n = length(S_all)

    # DISTRIBUTED
    # # We launch them on the workers
    # R_all = Array{Any}(nothing, n)
    # for i in 1:n
    #     local S, H
    #     S = S_all[i]
    #     H = trunc(Int, LM*S)
    #     R_all[i] = @spawn search_best_actions(state, H, S)
    # end
    # # We wait for the result
    # actions = nothing
    # for rf in R_all
    #     (_, r) = fetch(rf)
    #     if actions == nothing
    #         actions = r
    #     end
    # end

    # THREADED
    # R_all = Array{Any}(nothing, n)
    # Threads.@threads for i in 1:n
    #     local S, H
    #     S = S_all[i]
    #     H = trunc(Int, LM*S)
    #     (_, r) = search_best_actions(state, H, S)
    #     R_all[i] = r
    # end
    # actions = nothing
    # for r in R_all
    #     if actions == nothing
    #         actions = r
    #         break
    #     end
    # end

    # SEQUENTIAL (lazy)
    actions = nothing
    for S in S_all
        H = trunc(Int, LM*S)
        (_, actions) = search_best_actions(state, H, S)
        actions != nothing && break
    end

    # Output
    if actions == nothing
        DEBUG && println("No solution.")
        actions = [(wait, 1)]
    end
    (_, min_step) = actions[end]
    nb_actions = max(min_nb_actions, min_step)
    res = Array{Any}(nothing, nb_actions)
    for i in 1:nb_actions
        if length(actions) == 0
            res[i] = res[i-1]
            DEBUG && println("Solution too short. Completing with the last move...")
        else
            (a,s) = actions[end]
            s -= 1
            if s <= 0
                pop!(actions)
            else
                actions[end] = (a,s)
            end
            res[i] = a
        end
    end
    return (res, min_step)
end
