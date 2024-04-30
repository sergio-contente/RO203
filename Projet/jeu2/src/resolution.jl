# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using DataStructures

include("generation.jl")
include("heuristic.jl")

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
                            isOptimal = true
                            resolutionTime = solve_time(m)
                            return (new_solution, resolutionTime, isOptimal)
                        else
                            println("A feasible but not optimal solution was found after modification.")
                            resolutionTime = solve_time(m)
                            return (new_solution, resolutionTime, false)
                        end
                    else
                        println("Modified solution at cell ($i, $j) still not connected.")
                    end
                end
            end
        end

        println("No valid connected and optimal solution found after modifications.")
        return (nothing, 0, false)
    else
        println("Initial solution is connected and optimal.")
        resolutionTime = solve_time(m)
        isOptimal = true
    end

    return (solution, resolutionTime, isOptimal)
end



"""
Heuristically solve an instance
"""
function heuristicSolve(t::Matrix{Int64})
    n = size(t, 1)
    solution = copy(t)
    times_total = Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64, Int64}}()
    freq_dict = Dict{Tuple{Int64, Int64}, Int64}()
    isSingle = false
    saved_state = nothing
    count = 0

    while !isSingle
        # Count how many times a value apears in a line or column
        for i in 1:n
            for j in 1:n
                if solution[i,j] == -1
                    continue
                end
                line_times, column_times = 0, 0
                line_times, column_times = count_times(solution, (i, j))
                times_total[(i, j)] = (line_times, column_times, solution[i,j])
                value = solution[i,j]
            end
        end
        #(best_coordinate, second_best_coordinate, tie) = compareValues(times_total)
        freq_dict = computeFrequency(times_total)
        foundMark = false
        println(solution)
        for (coord, freq) in freq_dict
            if canBeBlack(solution, coord)
                (line, column) = coord
                past_value = solution[line, column]
                Mark(solution, coord)
                if !heuristicCheckConnectivity(solution)
                    println("Solution not connected, checking others")
                    Unmark(solution, coord, past_value)
                else
                    println("Marked and connected")
                    foundMark = true
                    break
                end
            end
        end
        if !foundMark
            println("No solution found")
            return nothing
        else
            updateTimesTotal(solution, times_total)
            isSingle = checkSingularity(solution, times_total)
        end
        #     println("TIE É TRUE")
        #     saved_state = copy(solution)  # Salvar estado do jogo apenas quando há empate
            
        #     if tryMarking(solution, best_coordinate)
        #         println("marcando com a best coord")  # Tentar marcar a melhor coordenada
        #     else tryMarking(solution, second_best_coordinate)
        #         println("marcando com a second best coord")  # Tentar marcar a segunda melhor coordenada
        #     end

        #     if !heuristicCheckConnectivity(solution)
        #         println("GRAFO N CONECTADO")
        #         solution = saved_state  # Voltar ao estado salvo se não estiver conectado
        #         tryMarking(solution, second_best_coordinate)  # Tentar com a segunda melhor coordenada
        #     end
        # else
        #     println("TIE É FALSE")
        #     tryMarking(solution, best_coordinate)
        #     if !heuristicCheckConnectivity(solution)
        #         println("No solution find")
        #         return 
        #     end
        #     println("tryMarking(solution, $best_coordinate) $(tryMarking(solution, best_coordinate))")
        # end
    end
    println("JOGO FINAL: ")
    println(solution)
    return solution
end

function Mark(solution, coord)
    (i,j) = coord
    solution[i,j] = -1  # Marcar preto
    return true
end

function Unmark(solution, coord, past_value)
    (i,j) = coord
    solution[i,j] = past_value  # Marcar branco
    return true
end

function heuristicCheckConnectivity(solution::Matrix)
    n = size(solution, 1)
    mapped_solution = copy(solution)
    for i in 1:n
        for j in 1:n
            if solution[i,j] != -1
                mapped_solution[i,j] = 0
            else
                mapped_solution[i,j] = 1
            end
        end   
    end
    return check_connectivity(mapped_solution, n)
end


"""
Compares how many times each value appears in its row and column and returns the coordinates of the most frequent one,
 second one and if it is a tie 
"""
function compareValues(times_total::Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64, Int64}})
    max_freq = -1
    second_max_freq = -1
    max_value = -1
    second_max_value = -1
    best_coordinate = (-1, -1)
    second_best_coordinate = (-1, -1)
    tie = false
    for (coord, (line_times, column_times, value)) in times_total
        if value == -1
            continue
        end
        total_freq = line_times + column_times
        if total_freq >= max_freq
            if best_coordinate != second_best_coordinate
                second_max_freq = max_freq
                second_best_coordinate = best_coordinate
                second_max_value = max_value
            end
            max_freq = total_freq
            best_coordinate = coord
        end
    end
    println("MAX FREQ: $max_freq\nSECOND MAX FREQ: $second_max_freq")
    if max_freq == second_max_freq &&  max_value == second_max_value && max_freq > 0
        tie = true
        print("SECOND BEST SOLUTION: $second_best_coordinate")
        println("No unique best coordinate found")
        return best_coordinate, second_best_coordinate, tie
    end
    return best_coordinate, second_best_coordinate, tie
end


function computeFrequency(times_total::Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64, Int64}})
    # Initialize the frequency dictionary
    freqDict = Dict{Tuple{Int64, Int64}, Int64}()

    for (coord, (line_times, column_times, value)) in times_total
        if value == -1
            continue
        end
        total_freq = line_times + column_times
        (i,j) = coord
        freqDict[i,j] = total_freq
    end

    # println(freqDict)

    # Sort the dictionary by values in descending order
    # sorted_dict = sort(collect(freqDict), lt=compare_values_desc)

    # # Convert the sorted array of key-value pairs back to a dictionary
    # sorted_freqDict = Dict(sorted_dict)
    sorted_freqDict = sortDictionaryDescending(freqDict)
    return sorted_freqDict
end

using DataStructures

function sortDictionaryDescending(dict::Dict{Tuple{Int, Int}, Int})
    # Convert the dictionary to an array of key-value pairs
    pair_list = collect(dict)
    
    # Sort the array of pairs based on values in descending order
    sorted_pairs = sort(pair_list, by = x -> x[2], rev = true)
    
    # Convert the sorted array back to an ordered dictionary
    sorted_dict = OrderedDict(sorted_pairs)

    println(sorted_dict)
    return sorted_dict
end



function compare_values_desc(kv1, kv2)
    if kv1[2] > kv2[2]
        return true
    elseif kv1[2] < kv2[2]
        return false
    else
        return kv1[1] < kv2[1]  # Add secondary comparison by key
    end
end


function checkSingularity(solution::Matrix{Int64}, times_total::Dict{Tuple{Int64, Int64}, Tuple{Int64, Int64, Int64}})
    all_single = true
    for (key, (line_times, column_times, value)) in times_total
        if line_times > 0 || column_times > 0
            all_single = false
            break  # If one non-single found, no need to check further
        end
    end
    return all_single
end


function verifyBlack(solution::Matrix{Int64}, coordinate::Tuple{Int64, Int64})
    return solution[coordinate] == -1 # Black: -1
end

"""
How many times the value of the current number appears in its column and line
"""
function count_times(solution::Matrix{Int64}, coordinate::Tuple{Int64, Int64})
    n = size(solution, 1)
    (line, column) = coordinate
    line_times = 0
    column_times = 0

    target = solution[line, column]

    for j in 1:n
        if solution[line, j] == target && j != column && solution[line, column] != -1
            line_times += 1
        end
    end

    for i in 1:n
        if solution[i, column] == target && i != line && solution[line, column] != -1
            column_times += 1
        end
        
    end
    return line_times, column_times
end

"""
Can the current cell be black (black adjacent constraint)? 
"""
function canBeBlack(solution::Matrix{Int64}, coordinate::Tuple{Int64, Int64})
    (line, column) = coordinate
    n = size(solution, 1)
    if line > 1 && solution[line-1, column] == -1
        println("casa de cima preta")
        return false
    end
    if line < n && solution[line+1, column] == -1
        println("casa de baixo preta")
        return false
    end
    if column > 1 && solution[line, column-1] == -1
        println("casa da esquerda preta")
        return false
    end
    if column < n && solution[line, column+1] == -1
        println("casa da direita preta")
        return false
    end
    return true
end

function updateTimesTotal(solution::Matrix{Int64}, times_total::Dict)
    println("atualizando valores")
    for key in keys(times_total)
        (i,j) = key
        line_times, column_times = count_times(solution, key)
        times_total[key] = (line_times, column_times, solution[i,j])
    end
end

"""
Write the solution to the output file
"""
function writeSolution(fout, solution, resolutionTime, isOptimal)
    println(fout, "Solution: ")
    for row in eachrow(solution)
        println(fout, join(row, ','))
    end
    println(fout, "solveTime = ", resolutionTime)
    println(fout, "isOptimal = ", isOptimal)
end

"""
Modified solveDataSet function
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"
    resolutionMethods = ["cplex", "heuristic"] # "heuristic"]  # Add "heuristic" if needed

    # Create each result folder if it does not exist
    for method in resolutionMethods
        folder = resFolder * method
        if !isdir(folder)
            mkdir(folder)
        end
    end

    # Process each file in the data directory
    for file in readdir(dataFolder)
        if occursin(".txt", file)
            println("-- Resolving ", file)
            instancePath = dataFolder * file
            t = readInputFile(instancePath)

            for method in resolutionMethods
                outputFile = resFolder * method * "/" * file

                # Check if the solution has already been generated
                if !isfile(outputFile)
                    fout = open(outputFile, "w")
                    resolutionTime, isOptimal = 0.0, false

                    if method == "cplex"
                        solution, resolutionTime, isOptimal = cplexSolve(t)
                    elseif method == "heuristic"
                        time_start = time()
                        solution = heuristicSolve(t)
                        resolutionTime = time() - time_start
                    end

                    if solution !== nothing
                        writeSolution(fout, solution, resolutionTime, isOptimal)
                    else
                        println(fout, "No valid solution found.")
                    end

                    close(fout)
                end
            end
        end
    end
end
