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
    # Primeira otimização
    optimize!(m)

    # Verifique se a solução inicial foi encontrada
    if termination_status(m) != MOI.OPTIMAL && termination_status(m) != MOI.FEASIBLE
        println("No feasible or optimal solution found.")
        return nothing
    end

    solution = JuMP.value.(x)

    # Checando a conectividade da solução inicial
    if !check_connectivity(solution, n)
        println("Initial solution does not form a single connected group.")
        # Tente transformar cada célula preta em branca e reotimize
        for i in 1:n
            for j in 1:n
                if solution[i, j] == 1  # Célula preta
                    constraint = @constraint(m, x[i, j] == 0)  # Tornar esta célula branca
                    #set_value(x[i,j], 0)
                    optimize!(m)

                    # Cheque se a nova solução é viável
                    if termination_status(m) == MOI.INFEASIBLE
                        println("No feasible solution after changing cell ($i, $j) to white.")
                        delete(m, constraint)
                        continue
                    end

                    new_solution = JuMP.value.(x)
                    if check_connectivity(new_solution, n)
                        println("Modified solution is connected.")
                        if termination_status(m) == MOI.OPTIMAL
                            println("An optimal solution has been found after modification.")
                            return new_solution
                        else
                            println("A feasible but not optimal solution was found after modification.")
                            return new_solution
                        end
                    else
                        println("Modified solution at cell ($i, $j) still not connected.")
                    end
                end
            end
        end

        println("No valid connected and optimal solution found after modifications.")
        return nothing
    else
        println("Initial solution is connected and optimal.")
    end

    return solution
end



"""
Heuristically solve an instance
"""
function heuristicSolve(t::Matrix{Int64})
    n = size(t, 1)
    solution = copy(t)
    times_total = Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64, Int64}}()
    isSingle = false

    while !isSingle
        all_single = true
        line_groups = Dict{Tuple{Int64, Int64}, Vector{Tuple{Int64, Int}}}()
        column_groups = Dict{Tuple{Int64, Int64}, Vector{Tuple{Int64, Int}}}()

        for i in 1:n
            for j in 1:n
                line_times, column_times = count_times(solution, (i, j))
                times_total[(i, j)] = (line_times, column_times, solution[i,j])
                if line_times > 0 || column_times > 0
                    all_single = false
                end

            end
        end
        isSingle = all_single
    end
end

function verifyBlack(solution::Matrix{Int64}, coordinate::Tuple{Int64, Int64})
    return 
end

function count_times(solution::Matrix{Int64}, coordinate::Tuple{Int64, Int64})
    n = size(solution, 1)
    (line, column) = coordinate
    line_times = 0
    column_times = 0

    target = solution[line, column]

    for j in 1:n
        if solution[line, j] == target && j != column
            line_times += 1
        end
    end

    for i in 1:n
        if solution[i, column] == target && i != line
            column_times += 1
        end
    end

    return line_times, column_times
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
