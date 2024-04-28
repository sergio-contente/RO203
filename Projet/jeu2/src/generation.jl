using Random

include("io.jl")

function generate_instance(n)
    y = ones(Int, n, n)
    x = zeros(Int, n, n)
    filled_cases = 0
    black_cases = select_black_cases(y)
    while filled_cases < n * n
        i = filled_cases ÷ n + 1
        j = filled_cases % n + 1
        if y[i, j] == 1
            val_tested = Int[]
            v = rand(1:n)
            push!(val_tested, v)
            while !is_number_valuable(x, i, j, v) && length(val_tested) < n
                v = rand(setdiff(1:n, val_tested))
                push!(val_tested, v)
            end
            x[i, j] = v
            filled_cases += 1

            if length(val_tested) >= n
                x = zeros(Int, n, n)
                filled_cases = 0
            end
        else
            filled_cases += 1
        end
    end

    for i = 1:n, j = 1:n
        if x[i, j] == 0
            x[i, j] = rand(1:n)
        end
    end
    x
end

function is_number_valuable(t, i, j, k)
    all(t[:, j] .!= k) && all(t[i, :] .!= k)
end

function surrounded_by_white_cases(y, i, j)
    n = size(y, 1)
    !any([(i > 1 && y[i-1, j] == 0), (i < n && y[i+1, j] == 0), (j > 1 && y[i, j-1] == 0), (j < n && y[i, j+1] == 0)])
end

function white_neighbors(y, i, j)
    n = size(y, 1)
    neighbors = Tuple{Int64, Int64}[]
    if i > 1 && y[i-1, j] == 1  # Check top neighbor
        push!(neighbors, (i-1, j))
    end
    if i < n && y[i+1, j] == 1  # Check bottom neighbor
        push!(neighbors, (i+1, j))
    end
    if j > 1 && y[i, j-1] == 1  # Check left neighbor
        push!(neighbors, (i, j-1))
    end
    if j < n && y[i, j+1] == 1  # Check right neighbor
        push!(neighbors, (i, j+1))
    end
    neighbors
end


function white_vertices_list(y)
    [(i, j) for i in 1:size(y, 1), j in 1:size(y, 2) if y[i, j] == 1]
end

function connected_component(y)
    vertices_to_see = []
    visited_vertices = []
    push!(vertices_to_see, y[1, 1] == 1 ? (1, 1) : (1, 2))
    while !isempty(vertices_to_see)
        vertex = popfirst!(vertices_to_see)
        if vertex ∉ visited_vertices
            push!(visited_vertices, vertex)
            for neighbor in white_neighbors(y, vertex...)
                if neighbor ∉ visited_vertices && neighbor ∉ vertices_to_see
                    push!(vertices_to_see, neighbor)
                end
            end
        end
    end
    visited_vertices
end

function is_graph_connected(y)
    length(connected_component(y)) == length(white_vertices_list(y))
end

function select_black_cases(y)
    n = size(y, 1)
    black_cases = []
    eligible_cases = [(i, j) for i in 1:n, j in 1:n if y[i, j] == 1 && surrounded_by_white_cases(y, i, j)]

    while !isempty(eligible_cases)
        r = rand(1:length(eligible_cases))
        i, j = eligible_cases[r]
        y[i, j] = 0
        deleteat!(eligible_cases, r)
        eligible_cases = filter(e -> e ∉ white_neighbors(y, i, j), eligible_cases)

        if is_graph_connected(y)
            push!(black_cases, (i, j))
        else
            y[i, j] = 1
        end
    end
    black_cases
end

function save_instance(instance_matrix, filename)
    open(filename, "w") do file
        for row in eachrow(instance_matrix)
            write(file, join(row, ',') * "\n")
        end
    end
end



function generateDataSet()
    for size in [5, 6, 7, 8, 9, 10, 11, 12]
        for instance in 1:10
            file_name = "../data/instance_t$(size)_$(instance).txt"
            if !isfile(file_name)
                println("-- Generating file $file_name")
                save_instance(generate_instance(size), file_name)
            end
        end
    end
end
