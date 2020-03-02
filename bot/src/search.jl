# TODO: diminush H?
H = 60 # 2 seconds
# H must not be too big, because the prediction become wrong after some time
# due to the new projectiles that appear randomly in the game.
# In particular, the initial step S should be <= 10 frames.
M = 500

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
    max_a = nothing
    max_v = -Inf32
    for action in ACTIONS
        v = evaluate_state_with_search(state, H, S, [action])
        if v > max_v
            max_v = v
            max_a = action
        end
    end
    return max_a
end

function search_best_action(state::GameState, DEBUG::Bool)
    S = trunc(Int, H/LM)

    action = search_best_action(state, H, S)
    while action == nothing && S > 1
        S = S÷2
        H = trunc(Int, LM*S)
        #DEBUG && println("Unable to find a solution... Try again with S=$S...")
        action = search_best_action(state, H, S)
    end

    if action == nothing
        DEBUG && println("No solution.")
        return (wait, 1)
    end
    return (action, S)
end
