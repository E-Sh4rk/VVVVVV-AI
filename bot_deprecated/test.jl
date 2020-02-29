
# TESTING THE BEHAVIOR OF RESHAPE

BATCH = 5

function print_first_two_dims(M)
    if ndims(M) == 5
        for k = 1:size(M,3)
            for l = 1:size(M,4)
                show(stdout, "text/plain", M[:,:,k,l,BATCH])
                println("\n--------------------------")
            end
        end
    end
    if ndims(M) == 4
        for k = 1:size(M,3)
            show(stdout, "text/plain", M[:,:,k,BATCH])
            println("\n--------------------------")
        end
    end
end

 A = Vector(1:5*4*3*2*7)
 A = reshape(A, 5, 4, 3, 2, 7)
 print_first_two_dims(A)
 println("")
 println("======================================")
 println("")
 B = reshape(A, 5, 4, :, 7)
 print_first_two_dims(B)
