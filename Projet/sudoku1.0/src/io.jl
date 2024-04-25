# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

"""
Read a grid from an input file

- Argument:
inputFile: path of the input file

- Example of input file for a 9x9 grid
 ,4,2, ,9, , , , 
 , , , , , , , ,5
8, ,5,2, , ,3, , 
 ,5, ,9,3,8, ,4, 
2, , , , , ,7, , 
9, ,4, ,7, , , ,6
 ,9, , , , , , , 
5, , , , ,3, , , 
 , , , , ,9, ,7, 

- Prerequisites
Let n be the grid size.
Each line of the input file must contain n values separated by commas.
A value can be an integer or a white space
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)
    
    n = length(split(data[1], ","))
    t = Vector{Int64}(undef, n, n)

    lineNb = 1

    # For each line of the input file
    for line in data

        lineSplit = split(line, ",")

        if size(lineSplit, 1) == n
            for colNb in 1:n

                if lineSplit[colNb] != " "
                    t[lineNb, colNb] = parse(Int64, lineSplit[colNb])
                else
                    t[lineNb, colNb] = 0
                end
            end
        end 
        
        lineNb += 1
    end

    return t

end

"""
Display a grid represented by a 2-dimensional array

Argument:
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
"""
function displayGrid(t::Matrix{Int64})

    n = size(t, 1)
    blockSize = round.(Int, sqrt(n))
    
    # Display the upper border of the grid
    println(" ", "-"^(3*n+blockSize-1)) 
    
    # For each cell (l, c)
    for l in 1:n
        for c in 1:n

            if rem(c, blockSize) == 1
                print("|")
            end  
            
            if t[l, c] == 0
                print(" -")
            else
                if t[l, c] < 10
                    print(" ")
                end
                
                print(t[l, c])
            end
            print(" ")
        end
        println("|")

        if rem(l, blockSize) == 0
            println(" ", "-"^(3*n+blockSize-1))
        end 
    end
end

"""
Display cplex solution

Argument
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
"""
function displaySolution(x::Array{VariableRef,3})

    n = size(x, 1)
    
    blockSize = round.(Int, sqrt(n))

    # Display the upper border of the grid
    println(" ", "-"^(3*n+blockSize-1)) 

    # For each cell (l, c)
    for l in 1:n
        for c in 1:n

            if rem(c, blockSize) == 1
                print("|")
            end  

            for k in 1:n
                if JuMP.value(x[l, c, k]) > TOL
                    if k < 10
                        print(" ")
                    end 
                    print(k)
                end
            end 
            print(" ")
        end
        println("|")

        if rem(l, blockSize) == 0
            println(" ", "-"^(3*n+blockSize-1))
        end 
    end
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
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
"""
function writeSolution(fout::IOStream, x::Array{VariableRef,3})

    # Convert the solution from x[i, j, k] variables into t[i, j] variables
    n = size(x, 1)
    t = Matrix{Int64}(undef, n, n)
    
    for l in 1:n
        for c in 1:n
            for k in 1:n
                if JuMP.value(x[l, c, k]) > TOL
                    t[l, c] = k
                end
            end
        end 
    end

    # Write the solution
    writeSolution(fout, t)

end



"""
Write a solution in an output stream

Arguments
- fout: the output stream (usually an output file)
- t: 2-dimensional array of size n*n
"""
function writeSolution(fout::IOStream, t::Matrix{Int64})
    
    println(fout, "t = [")
    n = size(t, 1)
    
    for l in 1:n

        print(fout, "[ ")
        
        for c in 1:n
            print(fout, string(t[l, c]) * " ")
        end 

        endLine = "]"

        if l != n
            endLine *= ";"
        end

        println(fout, endLine)
    end

    println(fout, "]")
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
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Vector{String}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Vector{String}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end 

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)

                include(path)

                println(fout, " & ", round(solveTime, digits=2), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
