
# Adicione essa função para contar o número de vezes que um valor aparece na linha ou coluna
function count_times2(solution::Matrix{Int64}, value::Int64, index::Int64, dimension::Symbol)
	n = size(solution, 1)
	count = 0
	for i in 1:n
			if dimension == :row && solution[index, i] == value
					count += 1
			elseif dimension == :col && solution[i, index] == value
					count += 1
			end
	end
	return count
end

# Adicione essa função para verificar se uma célula pode ser transformada em preto
function can_be_black(solution::Matrix{Int64}, coord::Tuple{Int64, Int64})
	i, j = coord
	n = size(solution, 1)
	
	# Verifique se a célula não está adjacente a uma célula preta
	if i > 1 && solution[i-1, j] == -1 ||
		 i < n && solution[i+1, j] == -1 ||
		 j > 1 && solution[i, j-1] == -1 ||
		 j < n && solution[i, j+1] == -1
			return false
	end
	return true
end

# Adapte a função heuristicSolve para implementar a heurística descrita
function heuristicSolve2(t::Matrix{Int64})
	n = size(t, 1)
	solution = copy(t)

	# Inicialize todos os elementos de 'solution' com branco (1)
	fill!(solution, 1)

	while true
			# Encontre todas as células que podem ser transformadas em preto
			black_candidates = [(i, j) for i in 1:n for j in 1:n if can_be_black(solution, (i, j))]
			shuffle!(black_candidates)  # Misture aleatoriamente os candidatos

			made_progress = false

			for coord in black_candidates
					# Tente transformar a célula atual em preta e verifique se a solução ainda é conectada
					solution[coord...] = -1
					if check_connectivity2(solution)
							made_progress = true
							break  # Sai do loop se fizermos progresso
					else
							# Se a solução não for mais conectada, reverta para branco
							solution[coord...] = 1
					end
			end

			if !made_progress
					# Se nenhum progresso for feito, então não podemos resolver a heurística
					println("Não foi possível encontrar uma solução viável.")
					return nothing
			end

			# Se chegarmos a uma solução onde cada número é único em sua linha e coluna, terminamos
			is_unique_solution = true
			for i in 1:n
					for val in 1:n
							if count_times2(solution, val, i, :row) > 1 || count_times2(solution, val, i, :col) > 1
									is_unique_solution = false
									break
							end
					end
					if !is_unique_solution
							break
					end
			end

			if is_unique_solution
					println("Solução única e conectada encontrada!")
					return solution
			end
	end
end


# Essa função verifica a conectividade da solução
function check_connectivity2(solution::Matrix{Int64})
	n = size(solution, 1)
	graph = zeros(Bool, n, n)
	for i in 1:n
			for j in 1:n
					if solution[i, j] == 1
							graph[i, j] = true
					end
			end
	end
	
	visited = falses(n, n)
	queue = Tuple{Int, Int}[]
	start_node = findfirst(graph)
	push!(queue, start_node)
	
	while !isempty(queue)
			current_node = popfirst!(queue)
			visited[current_node...] = true
			neighbors = [(current_node[1]-1, current_node[2]), 
									 (current_node[1]+1, current_node[2]),
									 (current_node[1], current_node[2]-1),
									 (current_node[1], current_node[2]+1)]
			for neighbor in neighbors
					if 1 <= neighbor[1] <= n && 1 <= neighbor[2] <= n && graph[neighbor...]
							if !visited[neighbor...]
									push!(queue, neighbor)
							end
					end
			end
	end
	
	return all(visited)
end
