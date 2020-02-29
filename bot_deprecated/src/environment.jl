
import ReinforcementLearningEnvironments.interact!
import ReinforcementLearningEnvironments.observe
import ReinforcementLearningEnvironments.reset!
import ReinforcementLearningEnvironments.render

mutable struct GravitronEnv <: AbstractEnv
    actions::Vector{ACTION}
    action_space::DiscreteSpace{Int}
    observation_space::MultiDiscreteSpace{UInt8, 3}
    frame_skip::Int
    noopmax::Int
    io
    state
end

function GravitronEnv(io, state, frame_skip = 1, noopmax = 30)
    frame_skip > 0 || throw(ArgumentError("frame_skip must be greater than 0!"))

    observation_size = size(matrix(state))
    observation_space = MultiDiscreteSpace(
        #fill(typemax(Cuchar), observation_size),
        #fill(typemin(Cuchar), observation_size),
        fill(UInt8(1), observation_size),
        fill(UInt8(0), observation_size),
    )

    actions = [wait, left, right]
    action_space = DiscreteSpace(length(actions))

    GravitronEnv(
        actions,
        action_space,
        observation_space,
        frame_skip,
        noopmax,
        io,
        state
    )
end

function state_size(env::GravitronEnv)
    return size(matrix(env.state))
end

function is_terminal(env::GravitronEnv)
    return is_finished(env.state)
end

function interact!(env::GravitronEnv, a)
    for i in 1:env.frame_skip
        env.state = next!(env.io, env.actions[a])
    end
    nothing
end

function observe(env::GravitronEnv)
    return Observation(reward = is_terminal(env) ? -100 : 1,
        terminal = is_terminal(env), state = matrix(env.state))
end

function reset!(env::GravitronEnv)
    restart!(env.io, env.state)
    for _ = 1:rand(0:env.noopmax)
        env.state = next!(env.io, wait)
    end
    nothing
end

function render(env::GravitronEnv)
    println("GravitronEnv render not implemented!")
end
