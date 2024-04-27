# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function dfs(graph, start, visited)
    stack = [start]
    while !isempty(stack)
        vertex = pop!(stack)
        if vertex ∉ visited
            push!(visited, vertex)
            for neighbor in setdiff(graph[vertex], visited)
                push!(stack, neighbor)
            end
        end
    end
end

function check_connectivity(solution, n)
    graph = Dict()
    for i in 1:n
        for j in 1:n
            if solution[i, j] == 0
                neighbors = Set()
                if i > 1 && solution[i-1, j] == 0
                    push!(neighbors, (i-1, j))
                end
                if i < n && solution[i+1, j] == 0
                    push!(neighbors, (i+1, j))
                end
                if j > 1 && solution[i, j-1] == 0
                    push!(neighbors, (i, j-1))
                end
                if j < n && solution[i, j+1] == 0
                    push!(neighbors, (i, j+1))
                end
                graph[(i, j)] = neighbors
            end
        end
    end
    # Perform DFS to check connectivity
    visited = Set()
    start_node = first(keys(graph))
    dfs(graph, start_node, visited)
    return length(visited) == length(keys(graph))
end

function cplexSolve(t::Matrix{Int64})
    n = size(t, 1)
    m = Model(CPLEX.Optimizer)

    @variable(m, x[1:n, 1:n], Bin)

    for i in 1:n
        for j in 1:n
            for k in 1:n
                if t[i, j] == t[i, k] && j != k
                    @constraint(m, x[i, j] + x[i, k] >= 1)
                end
                if t[i, j] == t[k, j] && i != k
                    @constraint(m, x[i, j] + x[k, j] >= 1)
                end
            end
        end
    end

    for i in 1:n
        for j in 1:n
            if i > 1
                @constraint(m, x[i, j] + x[i-1, j] <= 1)
            end
            if j > 1
                @constraint(m, x[i, j] + x[i, j-1] <= 1)
            end
            if i < n
                @constraint(m, x[i, j] + x[i+1, j] <= 1)
            end
            if j < n
                @constraint(m, x[i, j] + x[i, j+1] <= 1)
            end
        end
    end

    @objective(m, Min, sum(x))
    optimize!(m)

    solution = JuMP.value.(x)
    if termination_status(m) == MOI.OPTIMAL
        println("Optimal solution found. Checking connectivity...")
        if check_connectivity(solution, n)
            println("The white squares form a single connected group.")
        else
            println("The white squares do not form a single connected group.")
        end
    else
        println("No optimal solution found.")
    end

    return solution
end


"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
