# RO203
This repository contains all the code used for the Project of the RO203 course (Game Theory and Graphs) at ENSTA Paris 

## Jeux choisis: Flips (1) et Singles (2)

Pour utiliser ce programme, se placer dans le répertoire ./src

Les utilisations possibles sont les suivantes :

I - Génération d'un jeu de données
julia
include("generation.jl")
generateDataSet()

II - Résolution du jeu de données
julia
include("resolution.jl")
solveDataSet()

III - Présentation des résultats sous la forme d'un diagramme de performances
julia
include("io.jl")
performanceDiagram("../res/diagramme.png")

IV - Présentation des résultats sous la forme d'un tableau
julia
include("io.jl")
resultsArray("../res/array.tex")
