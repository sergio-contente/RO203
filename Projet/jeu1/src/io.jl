# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file

- Example of input file for a 5x5 grid
1, , , ,1
 , , , , ,
1,1, ,1, ,
1, , , , ,
 ,1,1, , ,

 - Prerequisites
 Let n be the grid size.
 Each line of the input file must contain n values separated by commas.
 A value can be an integer or a white space

"""
function readInputFile(inputFile::String) :: Matrix{Int64}
    # Open the input file
    datafile = open(inputFile)
    data = readlines(datafile)
    close(datafile)

    # Assume the first non-empty line defines the number of columns
    n = length(split(strip(data[1]), ","))

    # Initialize the matrix with undefined integers
    t = Matrix{Int64}(undef, n, n)

    lineNb = 1

    # Process each line in the data array
    for line in data
        # Remove leading and trailing white space and split by comma
        lineSplit = split(line, ",")

        # Only process lines with correct number of columns
        if length(lineSplit) == n
            for colNb in 1:n
                # Replace empty entries with 0, otherwise convert to integer
                t[lineNb, colNb] = lineSplit[colNb] != " " ? parse(Int64, lineSplit[colNb]) : 0
            end
            lineNb += 1
        end
    end

    return t
end


"""
Display a grid represented by a 2-dimensional array

Argument:
- t: array of size n*n with values in [0, 1] (0 if the cell is off)
"""
function displayGrid(t::Matrix{Int64})
    n = size(t, 1)
    
    # Display the upper border of the grid
    println(" +" * "-"^(3*n-1) * "+") 
    
    # For each cell (l, c)
    for l in 1:n
        print("|")  # Start border of each row
        for c in 1:n
            if t[l, c] == 0
                print(" - ")  # Print dash for zero values with spacing for alignment
            else
                print(" ", t[l, c], " ")  # Print the number with surrounding spaces
            end
        end
        println("|")  # End border of each row
    end

    # Display the lower border of the grid
    println(" +" * "-"^(3*n-1) * "+") 
end

"""
Display a solution represented by a 2-dimensional array

Argument:
- t: array of size n*n with values in [0, 1] (1 if the cell is clicked to solve)
"""
function displaySolution(t::Matrix{Int64})
    n = size(t, 1)
    
    # Display the upper border of the grid
    println(" +" * "-"^(3*n-1) * "+") 
    
    # For each cell (l, c)
    for l in 1:n
        print("|")  # Start border of each row
        for c in 1:n
            if t[l, c] == 0
                print(" - ")  # Print dash for zero values with spacing for alignment
            else
                print(" ", t[l, c], " ")  # Print the number with surrounding spaces
            end
        end
        println("|")  # End border of each row
    end

    # Display the lower border of the grid
    println(" +" * "-"^(3*n-1) * "+") 
end


"""
Save a grid in a text file

Argument
- t: 2-dimensional array of size n*n
- outputFile: path of the output file
"""
function saveInstance(t::Matrix{Int64}, outputFile::String)

    n = size(t, 1)

    # Open the output file
    writer = open(outputFile, "w")

    # For each cell (l, c) of the grid
    for l in 1:n
        for c in 1:n

            # Write its value
            if t[l, c] == 0
                print(writer, " ")
            else
                print(writer, t[l, c])
            end

            if c != n
                print(writer, ",")
            else
                println(writer, "")
            end
        end
    end

    close(writer)
    
end 

"""
Write a solution in an output stream

Arguments
- fout: the output stream (usually an output file)
- x: 2-dimensional variables array such that x[i, j, k] = 1 if cell is white or 0 otherwise
"""

function readResultFile(filePath::String)
    data = open(filePath) do file
        readlines(file)
    end

    solveTime = nothing
    isOptimal = false
    solution = []

    for line in data
        line = strip(line)  # Clean up whitespace
        if startswith(line, "solveTime =")
            # Attempt to parse the solve time safely
            solveTimeString = strip(split(line, "=")[2])
            solveTime = tryparse(Float64, solveTimeString)
            if isnothing(solveTime)
                println("Warning: Failed to parse solve time in $filePath: '$solveTimeString'")
            end
        elseif startswith(line, "isOptimal =")
            isOptimalString = strip(split(line, "=")[2])
            isOptimal = tryparse(Bool, isOptimalString)
            if isnothing(isOptimal)
                println("Warning: Failed to parse isOptimal in $filePath: '$isOptimalString'")
            end
        elseif startswith(line, "Solution:")
            continue  # Ignore the "Solution:" marker
        else
            # Optionally process the solution matrix here if needed
            try
                row = parse.(Float64, split(line, ","))
                push!(solution, row)
            catch
                println("Warning: Failed to parse matrix row in $filePath: '$line'")
            end
        end
    end

    return solveTime, isOptimal, solution
end



function performanceDiagram(outputFile::String)

    resultFolder = "../res/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    folderName = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)
            
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxSolveTime = 0

    # For each subfolder
    for file in readdir(resultFolder)
        path = resultFolder * file
        
        if isdir(path)

            folderCount += 1
            fileCount = 0

            # For each text file in the subfolder
            for resultFile in filter(x->occursin(".txt", x), readdir(path))

                filePath = joinpath("../jeu2", path, resultFile)
                print("PATH: $filePath\n")
                solveTime, isOptimal = readResultFile(filePath)

                fileCount += 1

                if isOptimal
                    results[folderCount, fileCount] = solveTime

                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 


    # Sort each row increasingly
    results = sort(results, dims=2)

    println("Max solve time: ", maxSolveTime)

    # For each line to plot
    for dim in 1: size(results, 1)

        x = Array{Float64, 1}()
        y = Array{Float64, 1}()

        # x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0

        append!(x, previousX)
        append!(y, previousY)
            
        # Current position in the line
        currentId = 1

        # While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf
            # Number of elements which have the value previousX
            identicalValues = 1

            # While the value is the same
            while currentId < size(results, 2) && results[dim, currentId] == previousX
                currentId += 1
                identicalValues += 1
            end

            # Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)

            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            
            previousX = results[dim, currentId]
            previousY = currentId - 1
        end

        append!(x, maxSolveTime)
        append!(y, currentId - 1)

        # If it is the first subfolder
        if dim == 1

            # Draw a new plot
            #plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)
			plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)

        # Otherwise 
        else
            # Add the new curve to the created plot
            savefig(plot!(x,y, label = folderName[dim], linewidth=3), outputFile)
        end 
    end
end 

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    resultFolder = "../res/"  # Adjust this path if necessary
    
    # Open the LaTeX output file
    fout = open(outputFile, "w")

    # Write the header of the LaTeX document
    println(fout, raw"""\documentclass{article}
\usepackage[french]{babel}
\usepackage[utf8]{inputenc}
\usepackage{multicol}
\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt}
\setlength{\evensidemargin}{9pt}
\setlength{\marginparwidth}{54pt}
\setlength{\textwidth}{481pt}
\setlength{\voffset}{-18pt}
\setlength{\marginparsep}{7pt}
\setlength{\topmargin}{0pt}
\setlength{\headheight}{13pt}
\setlength{\headsep}{10pt}
\setlength{\footskip}{27pt}
\setlength{\textheight}{668pt}
\begin{document}
\begin{center}
\renewcommand{\arraystretch}{1.4}
\begin{tabular}{|l|rr|}
\hline
 & \multicolumn{2}{c|}{\textbf{cplex}}\\
\textbf{Instance} & \textbf{Temps (s)} & \textbf{Optimal ?} \\\hline""")

    # Processando cada arquivo de instância
    for subfolder in readdir(resultFolder)
        path = joinpath(resultFolder, subfolder)
        if isdir(path)
            for instanceFile in readdir(path)
                if occursin(".txt", instanceFile)
                    filePath = joinpath(path, instanceFile)
                    solveTime, isOptimal, _ = readResultFile(filePath)
                    if !isnothing(solveTime)
                        optimalSymbol = isOptimal ? "\$\\times\$" : " "
                        println(fout, replace(instanceFile, "_" => "\\_"), " & ", solveTime, " & ", optimalSymbol, " \\\\")
                    end
                end
            end
        end
    end

    println(fout, "\\hline")
    println(fout, "\\end{tabular}")
    println(fout, "\\end{center}")
    println(fout, "\\end{document}")
    close(fout)
end
