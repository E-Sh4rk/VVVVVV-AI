
ACTIONS = [wait, left, right]
M = 1000 # Max number of leaves (= max computation) for each value of S
# Search steps (they will be all tried consecutively until a search succeed).
# They should all be greater or divisors of the frame prediction in bot.jl.
# S+frame_prediction should not be too high (<= 10) because the simulator
# cannot predict new projectiles.
# High values correspond to long-term but unprecise decisions.
# 4 seems to be a good compromise (not too high so no major simulation errors,
# and the inertia only applies after 5+ consecutive moves in a direction).
S = [4, 3, 2, 1]

# Automatic parameters
AN = length(ACTIONS)
LM = log(AN, M)

N = length(S)
H = [floor(Int, LM)*s for s in S]

function heuristic_dist²_no_wrap(player, proj)
    if (proj.x + proj.w < player.x && proj.xs < 0) ||
        (proj.x > player.x + player.w && proj.xs > 0)
        return Inf32
    end
    if proj.y + proj.h < player.y && player.ys > 0
        player_line_dist = max(0, BOTTOM_GRAVITY_CHANGE - player.ys)
        d = 4*player_line_dist*player_line_dist
        return d + player_proj_dist²_no_wrap(player, proj)
    end
    if proj.y > player.y + player.h && player.ys < 0
        player_line_dist = max(0, player.ys - TOP_GRAVITY_CHANGE)
        d = 4*player_line_dist*player_line_dist
        return d + player_proj_dist²_no_wrap(player, proj)
    end
    return player_proj_dist²_no_wrap(player, proj)
end

function heuristic_dist²(player, proj)
    return player_proj_dist_with_wrap(heuristic_dist²_no_wrap, player, proj)
end

# The evaluation function mostly impacts short-term decisions (small value of S),
# thus it should not feature any long-term considerations such as
# 'the character should be close to the center of the screen'.
function evaluate_state(state::GameState)
    if state.terminal
        return -Inf32
    end
    (_, min_dist²) = nearest_projectile(heuristic_dist², state)
    return min_dist²
end

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
            state_a.terminal && break
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
    # DISTRIBUTED
    # # We launch them on the workers
    # R = Array{Any}(nothing, N)
    # for i in 1:N
    #     R[i] = @spawn search_best_actions(state, H[i], S[i])
    # end
    # # We wait for the result
    # actions = nothing
    # for rf in R
    #     (_, r) = fetch(rf)
    #     if actions == nothing
    #         actions = r
    #     end
    # end

    # THREADED
    # R = Array{Any}(nothing, N)
    # Threads.@threads for i in 1:N
    #     (_, r) = search_best_actions(state, H[i], S[i])
    #     R[i] = r
    # end
    # actions = nothing
    # for r in R
    #     if actions == nothing
    #         actions = r
    #         break
    #     end
    # end

    # SEQUENTIAL (lazy)
    actions = nothing
    for i in 1:N
        (_, actions) = search_best_actions(state, H[i], S[i])
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
