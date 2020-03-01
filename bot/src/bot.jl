
include("game.jl")

function main()
    println("VBot - Bot for the Super Gravitron")

    (io, state) = initialize_game(true)
    state = reset!(io, state)
    # while true
    #     state = next!(io, state, right)
    # end
    quit_game!(io)
end

main()
