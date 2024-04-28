# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- flips: number of cells that are flipped to get to the configuration

Return
- t: the generated grid Matrix{Int64}
"""
function generateInstance(n::Int64, flips::Int64)
    t = ones(n, n)

    for i in 1:flips
        x = rand(1:n)
        y = rand(1:n)
        t[x, y] = (t[x,y] + 1) % 2
        if x > 1
            t[x-1, y] = (t[x-1, y] + 1) % 2
        end
        if x < n
            t[x+1, y] = (t[x+1, y] + 1) % 2
        end
        if y > 1
            t[x, y-1] = (t[x, y-1] + 1) % 2
        end
        if y < n
            t[x, y+1] = (t[x, y+1] + 1) % 2
        end
    end

    return Int.(t)
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # for each grid size
    for size in [4, 6, 8, 10]

        # for each flips
        for flips in [8, 12, 16, 20]
            
            # generate 10 instance
            for instance in 1:10

                # Generate the instance
                fileName = "../data/instance_t$(size)_f$(flips)_i$(instance).txt"
                
                if !isfile(fileName)
                    println("-- Generating file $(fileName)")
                    # Save the instance
                    saveInstance(generateInstance(size, flips), "../data/instance_t$(size)_f$(flips)_i$(instance).txt")
                end
            end
        end
    end
end



