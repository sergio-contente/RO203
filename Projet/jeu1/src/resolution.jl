using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""


function cplexSolve(t::Matrix{Int64})
    n = size(t, 1)
    m = Model(CPLEX.Optimizer)

    @variable(m, flips[1:n, 1:n], Bin)
    @variable(m, choice[i=1:n, j=1:n, k=1:3], Bin)  # Binary variables for choosing flips
    @variable(m, local_flips[1:n, 1:n], Int)

    for i in 1:n
        for j in 1:n
            local_flips = flips[i, j]
            if i > 1
                local_flips += flips[i-1, j]
            end
            if i < n
                local_flips += flips[i+1, j]
            end
            if j > 1
                local_flips += flips[i, j-1]
            end
            if j < n
                local_flips += flips[i, j+1]
            end

            if t[i, j] == 0
                # Choices for odd numbers of flips: 1, 3, 5
                @constraint(m, local_flips == 1*choice[i,j,1] + 3*choice[i,j,2] + 5*choice[i,j,3])
                @constraint(m, sum(choice[i,j,:]) == 1)  # Ensure exactly one choice is made
            else
                # Choices for even numbers of flips: 0, 2, 4
                @constraint(m, local_flips == 0*choice[i,j,1] + 2*choice[i,j,2] + 4*choice[i,j,3])
                @constraint(m, sum(choice[i,j,:]) == 1)  # Ensure exactly one choice is made
            end
        end
    end

    @objective(m, Min, sum(flips))
    start = time()
    optimize!(m)

    if termination_status(m) == MOI.OPTIMAL
        solution_flips = convert(Matrix{Int64}, JuMP.value.(flips))
    #     println("Optimal solution found. Flips needed:")
    #     println(solution_flips)
    # else
    #     println("No optimal solution found.")
    end

    return termination_status(m) == MOI.OPTIMAL, solution_flips, time() - start 
end


"""
Heuristically solve an instance
"""
function heuristicSolve()
    # Placeholder for heuristic solution implementation
    println("In file resolution.jl, in method heuristicSolve(), TODO: Implement heuristic solution logic")
    return false, 0  # This should return a tuple of isOptimal and solveTime
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics
The results are written in "../res/cplex" and "../res/heuristic"
Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()
    dataFolder = "../data/"
    resFolder = "../res/"

    resolutionMethod = ["cplex"]  # Assuming only CPLEX is used for now
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end

    global isOptimal = false
    global solveTime = -1

    # For each instance (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x -> occursin(".txt", x), readdir(dataFolder))
        println("-- Resolution of ", file)
        t = readInputFile(dataFolder * file)
        
        # For each resolution method
        for methodId in 1:length(resolutionMethod)
            outputFile = resolutionFolder[methodId] * "/" * file
            
            if !isfile(outputFile)
                fout = open(outputFile, "w")  
                resolutionTime = -1
                isOptimal = false
                
                if resolutionMethod[methodId] == "cplex"
                    # Solve the instance with CPLEX
                    isOptimal, solution, resolutionTime = cplexSolve(t)
                    
                    if isOptimal
                        println(fout, "Solution found.")
                        
                    else
                        println(fout, "No solution found.")
                    end
                else
                    startingTime = time()
                    while !isOptimal && resolutionTime < 100
                        isOptimal, resolutionTime = heuristicSolve()
                        resolutionTime = time() - startingTime
                    end
                    
                    if isOptimal
                        println(fout, "Heuristic solution found.")
                    else
                        println(fout, "No solution found.")
                    end
                end
                println(fout, solution)
                println(fout, "solveTime = ", resolutionTime)
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end
            
            println("Instance read")
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: ", round(resolutionTime, digits=2), "s")
        end
    end
end
