
# H must not be too big, because the prediction become wrong after some time
# due to the new projectiles that appear randomly in the game.
# In particular, the initial step S should be <= 10 frames.
H = 60 # 2 seconds
M = 1000

ACTIONS = [wait, left, right]
N = length(ACTIONS)
LM = log(N, M)

function evaluate_state_with_search(state::GameState, H::Int, S::Int, first_actions = ACTIONS)
    S = min(S, H)
    if S <= 0 || state.terminal
        return evaluate_state(state)
    end
    max_v = -Inf32
    for action in first_actions
        state_a = state
        for i in 1:S
            state_a = simulate_next(state_a, action)
            if state_a.terminal
                break
            end
        end
        max_v = max(max_v, evaluate_state_with_search(state_a, H-S, S))
    end
    return max_v
end

function search_best_action(state::GameState, H::Int, S::Int)
    n = length(ACTIONS)
    results = Array{Any}(nothing, n)
    # Threads.@threads for i in 1:n # NOTE: uncomment for a threaded search
    for i in 1:n
        results[i] = evaluate_state_with_search(state, H, S, [ACTIONS[i]])
    end

    max_a = nothing
    max_v = -Inf32
    for i in 1:n
        if results[i] > max_v
            max_v = results[i]
            max_a = ACTIONS[i]
        end
    end

    return max_a
end

function search_best_action(state::GameState, DEBUG::Bool)
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
    #     R_all[i] = @spawn search_best_action(state, H, S)
    # end
    # # We wait for the result
    # action = nothing
    # step = nothing
    # for i in 1:n
    #     r = fetch(R_all[i])
    #     if action == nothing
    #         action = r
    #         step = S_all[i]
    #     end
    # end

    # THREADED
    # R_all = Array{Any}(nothing, n)
    # Threads.@threads for i in 1:n
    #     local S, H
    #     S = S_all[i]
    #     H = trunc(Int, LM*S)
    #     R_all[i] = search_best_action(state, H, S)
    # end
    # action = nothing
    # step = nothing
    # for i in 1:n
    #     if action == nothing
    #         action = R_all[i]
    #         step = S_all[i]
    #         break
    #     end
    # end

    # SEQUENTIAL (lazy)
    action = nothing
    step = nothing
    for S in S_all
        H = trunc(Int, LM*S)
        action = search_best_action(state, H, S)
        step = S
        action != nothing && break
    end

    # Output
    if action == nothing
        DEBUG && println("No solution.")
        return (wait, 1)
    end
    return (action, step)
end
