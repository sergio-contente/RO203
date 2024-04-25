using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(t::Matrix{Int64})
    n = size(t, 1)

    # Initialize the model
    m = Model(CPLEX.Optimizer)
    
    @variable(m, x[1:n, 1:n], Bin)
    @variable(m, y[1:n, 1:n], Bin)
    @variable(m, z[1:n, 1:n], Bin)

    @objective(m, Min, sum(x[i, j] for i in 1:n, j in 1:n))

    for i in 1:n
        for j in 1:n
            flips = x[i, j] +
                    (i > 1 ? x[i-1, j] : 0) +
                    (i < n ? x[i+1, j] : 0) +
                    (j > 1 ? x[i, j-1] : 0) +
                    (j < n ? x[i, j+1] : 0)

            if t[i, j] == 1
                @constraint(m, flips == 1 + 2 * y[i, j])
            else
                @constraint(m, flips == 2 * z[i, j])
            end
        end
    end

    # Start the timer
    start = time()

    # Solve the model
    optimize!(m)

    return JuMP.primal_status(m) == MOI.FEASIBLE_POINT, time() - start
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
                    isOptimal, resolutionTime = cplexSolve(t)
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

                println(fout, "solveTime = ", resolutionTime)
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end

            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: ", round(resolutionTime, digits=2), "s")
        end
    end
end
