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

III - Présentation des résultats sous la forme d'un tableau
julia
include("io.jl")
resultsArray("../res/array.tex")
