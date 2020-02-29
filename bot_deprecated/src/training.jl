
import Serialization

PARAMS_PATH = "params.flux"
TARGET_PARAMS_PATH = "target_params.flux"
SELECTOR_PATH = "selector.dqn"
AGENT_PATH = "agent.dqn"
GRAPH_PATH = "graph.png"

N_FRAMES = 4

function get_model(raw_env)
    (_,_,c) = state_size(raw_env)
    na = length(action_space(raw_env))
    # Formula to compute the size of the output of a convolution: (W−K+2P)/S + 1
    return Chain(
        x -> reshape(x, size(x,1), size(x,2), :, size(x)[end]),
        Conv((8,8), N_FRAMES * c => 32, relu; stride=(4,2)),
        Conv((4,4), 32 => 64, relu; stride=2),
        Conv((3,3), 64 => 64, relu; stride=1),
        x -> reshape(x, :, size(x)[end]),
        Dense(7*6*64, 512, relu),
        Dense(512, na),
    )
end

function train(io, state)

    # TODO: Ideas
    # - Test the Prioritized and the Rainbow versions
    # - Serialize directly QBasedPolicy
    # - Without frame_skip? With a x2 image ? (=> no need for padding in convolutions)

    raw_env = GravitronEnv(io, state, 1, 15)
    ssize = state_size(raw_env) # 84 x 36 x 3 (with downscale = 4)

    env = WrappedEnv(
        env = raw_env,
        preprocessor =
        # Chain(
        #     ImageResize(ssize...),
            StackFrames(UInt8, ssize..., N_FRAMES)
        # )
    )

    device = :gpu
    model = get_model(raw_env)
    target_model = get_model(raw_env)

    if isfile(PARAMS_PATH) && isfile(TARGET_PARAMS_PATH)
        println("Weights files detected...")
        Flux.loadparams!(model, Serialization.deserialize(PARAMS_PATH))
        Flux.loadparams!(target_model, Serialization.deserialize(TARGET_PARAMS_PATH))
    end
    if isfile(SELECTOR_PATH)
        selector = Serialization.deserialize(SELECTOR_PATH)
    else
        # Decay should be 1000000... but seems too much
        selector = EpsilonGreedySelector{:exp}(ϵ_init=1.0, ϵ_stable = 0.025, decay_steps = 100000)
    end

    agent = Agent(
        π = QBasedPolicy(
            learner = DQNLearner(
                approximator = NeuralNetworkQ(
                    model = model,
                    optimizer = RMSProp(0.00025, 0.95), # In the example: ADAM(0.00001)
                    device = device
                ),
                target_approximator = NeuralNetworkQ(
                    model = target_model,
                    optimizer = RMSProp(0.00025, 0.95), # In the example: ADAM(0.00001)
                    device = device
                ),
                update_freq = 4,
                γ = 0.99f0,
                update_horizon = 1,
                batch_size = 32,
                stack_size = N_FRAMES,
                min_replay_history = 50000,
                loss_fun = huber_loss,
                target_update_freq = 10000,
            ),
            selector = selector
        ),
        buffer = circular_RTSA_buffer(
            capacity = 300000, # Should be 1000000... but too much for my poor computer
            state_eltype = UInt8,
            state_size = ssize,
        )
    )

    hook = ComposedHook(
        TotalRewardPerEpisode(),
        TimePerStep()
    );

    run(agent, env, StopAfterStep(#=3000000=#1500000; is_show_progress=true); hook = hook)
    Serialization.serialize(PARAMS_PATH, params(model))
    Serialization.serialize(TARGET_PARAMS_PATH, params(target_model))
    Serialization.serialize(SELECTOR_PATH, selector)
    # Serialization.serialize(AGENT_PATH, agent)
    savefig(plot(hook[1].rewards, xlabel="Episode", ylabel="Reward", label=""), GRAPH_PATH)
end
