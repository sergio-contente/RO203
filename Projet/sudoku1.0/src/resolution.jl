# This file contains methods to solve a sudoku grid (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001


"""
Solve a sudoku grid with CPLEX

Argument
- t: array of size n*n with values in [0, n] (0 if the cell is empty)

Return
- status: :Optimal if the problem is solved optimally
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
- getsolvetime(m): resolution time in seconds
"""
function cplexSolve(t::Matrix{Int, 2})

    n = size(t, 1)

    # Create the model
    m = Model(CPLEX.Optimizer)

    # x[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, x[1:n, 1:n, 1:n], Bin)

    # Set the fixed value in the grid
    for l in 1:n
        for c in 1:n
            if t[l, c] != 0
                @constraint(m, x[l,c, t[l, c]] == 1)
            end
        end
    end

    # Each cell (i, j) has one value k
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i, j, k] for k in 1:n) == 1)

    # Each line l has one cell with value k
    @constraint(m, [k in 1:n, l in 1:n], sum(x[l, j, k] for j in 1:n) == 1)

    # Each column c has one cell with value k
    @constraint(m, [k in 1:n, c in 1:n], sum(x[i, c, k] for i in 1:n) == 1)

    # Get the size of a block
    blockSize = round.(Int, sqrt(n))

    # Each block has one cell with value k
    # (lTop, cLeft) is the top left cell of each block
    @constraint(m, [lTop in 1:blockSize:n, cLeft in 1:blockSize:n, k in 1:n], sum(x[lTop+i, cLeft+j, k] for i in 0:blockSize-1, j in 0:blockSize-1) == 1)

    # Maximize the top-left cell (reduce the problem symmetry)
    @objective(m, Max, sum(x[1, 1, k] for k in 1:n))

    start = time()
    optimize!(m)

    # Return:
    # - a boolean which is true if a feasible solution is found (type: Bool);
    # - the value of each cell (type: Matrix{VariableRef})
    # - the resolution time (type Float64)
    return primal_status(m) == MOI.FEASIBLE_POINT, x, time() - start

end

"""
Heuristically solve a grid by successively assigning values to one of the most constrained cells 
(i.e., a cell in which the number of remaining possible values is the lowest)

Argument
- t: array of size n*n with values in [0, n] (0 if the cell is empty)

Return
- gridFeasible: true if the problem is solved
- tCopy: the grid solved (or partially solved if the problem is not solved)
"""
function heuristicSolve(t::Matrix{Int}, checkFeasibility::Bool)

    n = size(t, 1)
    tCopy = copy(t)

    # True if the grid has completely been filled
    gridFilled = false

    # True if the grid may still have a solution
    gridStillFeasible = true

    # While the grid is not filled and it may still be solvable
    while !gridFilled && gridStillFeasible

        # Coordinates of the most constrained cell
        mcCell = [-1 -1]

        # Values which can be assigned to the most constrained cell
        values = nothing
        
        # Randomly select a cell and a value
        l = ceil.(Int, n * rand())
        c = ceil.(Int, n * rand())
        id = 1

        # For each cell of the grid, while a cell with 0 values has not been found
        while id <= n*n && (values == nothing || size(values, 1)  != 0)

            # If the cell does not have a value
            if tCopy[l, c] == 0

                # Get the values which can be assigned to the cell
                cValues = possibleValues(tCopy, l, c)

                # If it is the first cell or if it is the most constrained cell currently found
                if values == nothing || size(cValues, 1) < size(values, 1)

                    values = cValues
                    mcCell = [l c]
                end 
            end
            
            # Go to the next cell                    
            if c < n
                c += 1
            else
                if l < n
                    l += 1
                    c = 1
                else
                    l = 1
                    c = 1
                end
            end

            id += 1
        end

        # If all the cell have a value
        if values == nothing

            gridFilled = true
            gridStillFeasible = true
        else

            # If a cell cannot be assigned any value
            if size(values, 1) == 0
                gridStillFeasible = false

                # Else assign a random value to the most constrained cell 
            else
                
                newValue = ceil.(Int, rand() * size(values, 1))
                if checkFeasibility
                    
                    gridStillFeasible = false
                    id = 1
                    while !gridStillFeasible && id <= size(values, 1)

                        tCopy[mcCell[1], mcCell[2]] = values[rem(newValue, size(values, 1)) + 1]
                        
                        if isGridFeasible(tCopy)
                            gridStillFeasible = true
                        else
                            newValue += 1
                        end

                        id += 1
                        
                    end
                else 
                    tCopy[mcCell[1], mcCell[2]] = values[newValue]
                end 
            end 
        end  
    end  

    return gridStillFeasible, tCopy
    
end 

"""
Number of values which could currently be assigned to a cell

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- l, c: row and column of the cell

Return
- values: array of integers which do not appear on line l, column c or in the block of (l, c)
"""
function possibleValues(t::Matrix{Int}, l::Int64, c::Int64)

    values = Vector{Int64}()

    for v in 1:size(t, 1)
        if isValid(t, l, c, v)
            values = append!(values, v)
        end 
    end 

    return values
    
end

"""
Solve all the instances contained in "../data" through CPLEX and the heuristic

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    resolutionMethod = ["cplex", "heuristique", "heuristique2"]
    resolutionFolder = resFolder .* resolutionMethod
    
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each input file
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        t = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the input file has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"

                    # Solve it and get the results
                    isOptimal, x, resolutionTime = cplexSolve(t)
                    
                    # Also write the solution (if any)
                    if isOptimal
                        writeSolution(fout, x)
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false
                    solution = []

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        print(".")

                        isOptimal, solution = heuristicSolve(t, resolutionMethod[methodId] == "heuristique2")

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                    end

                    println("")

                    # Write the solution (if any)
                    if isOptimal
                        writeSolution(fout, solution)
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal) 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end

"""
Test if the grid is feasible

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
"""
function isGridFeasible(t::Matrix{Int64})

    n = size(t, 1)
    isFeasible = true

    l = 1
    c = 1

    # For each cell (l, c) while previous cells can be assigned a value
    while isFeasible && l <= n

        # If a value is not assigned to (l, c)
        if t[l, c] == 0

            # Test all values v until a value which can be assigned to (l, c) is found
            feasibleValueFound = false
            v = 1

            while !feasibleValueFound && v <= n

                if isValid(t, l, c, v)
                    feasibleValueFound = true
                end
                
                v += 1
                
            end
            
            if !feasibleValueFound
                isFeasible = false
            end 
        end 

        # Go to the next cell
        if c < n
            c += 1
        else
            l += 1
            c = 1
        end
    end

    return isFeasible
end 
