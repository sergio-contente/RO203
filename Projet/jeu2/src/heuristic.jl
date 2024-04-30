
#génère un vecteur y qui contient des cases noires qui masquent les doublons  sur les lignes et les colones de la grille. Les choix sont faits aléatoirement. Renvoie b==1 ssi la grille ainsi trouvée est connexe.

function heuristicSolve2(grille)
	n=size(grille,1)
	y=ones(Int,n,n)
	kv=0
	cases_noires=[]
	doublons=liste_doublons(grille)
	while (doublons!=[])&&(kv<=3*n*n)
		kv+=1
		x,kx=random_choose_in_list(doublons)
		cases_noires=supprimer_doubons_de_x(grille,y,x)
		if cases_noires!=[]
			deleteat!(doublons,kx)
		end
	end
	# println("doublons",doublons)
	#displaySolution(grille,y)
	if doublons==[]
		b=1
		return b,y
	else 
		b=0
		return y
	end
end 

#génère une liste de liste de coordonnés de doublons. ex : [[(i,j),(i,l),(i,k)],[…]] si sur la ligne i, les élements aux positions j k et l sont identiques

function liste_doublons(grille)
	n = size(grille,1)
	doublons=[]
	for i in 1:n
		for val in 1:n
			if doublon_ligne(i,grille,val)!=[]
				append!(doublons,[doublon_ligne(i,grille,val)])
			end
		end
	end
	for j in 1:n
		for val in 1:n
			if doublon_colone(j,grille,val)!=[]
				append!(doublons,[doublon_colone(j,grille,val)])
			end
		end
	end
	
	return doublons
end

#mémorise dans une liste les couples de coordonnées de valeur val à la ligne i. s’il y en a plus que 2, retourne une telle liste.
function doublon_ligne(i,grille,val)
	n = size(grille,1)
	mem=[]
	for j in 1:n
		if grille[i,j]==val
			append!(mem,[(i,j)])
		end
	end
	if size(mem,1)>1
		return mem
	else
		return []
	end
end

#mémorise dans une liste les couples de coordonnées de valeur val à la colone j. s’il y en a plus que 2, retourne une telle liste.
function doublon_colone(j,grille,val)
	n = size(grille,1)
	mem=[]
	for i in 1:n
		if grille[i,j]==val
			append!(mem,[(i,j)])
		end
	end
	if size(mem,1)>1
		return mem
	else
		return []
	end
end

#retourne un élement aléatoire de l et son indice
function random_choose_in_list(l)
	n=size(l,1)
	i=ceil.(Int, n * rand())
	return l[i],i
end

#supprimer dans une liste de couples de coordonnées les couples de coordonnées (i,j) 
function supprimer_doublons_i_j(liste,i,j)
	s=size(liste,1)
	for k=1:s
		if liste[k]==(i,j)
			deleteat!(liste,k)
			break
		end
	end
	return liste
end

#une case est admissible (à être noircie) si elle est entourée de cases blanches. Cette fonction renvoie toutes les cases admissibles de x(x liste de couples de coordonées) en fonction des cases noires déjà coloriées contenues dans y. 
function liste_cases_admissibles(y,x)
	n=size(y,1)
	
	cases_admissibles=[]
	
	for (i,j) in x
		if case_entouree_de_case_blanche(y,i,j)==1
			append!(cases_admissibles,[(i,j)])
		end
	end
	return cases_admissibles
end

#essaye de noircir les doublons de x tel que la grille reste connexe. envoie cases_noires une liste des coordonnées des cases nouvellement noircies s'il y arrive en moins de 3n tentatives, et renvoie [] sinon. y a été mis à jour.
function supprimer_doubons_de_x(grille,y,x)
	cases_noires=[]
	n=size(y,1)
	cont=0
	while ((size(x,1)>1)&&(cont<=3*n*n))
		cont=cont+1
		cases_admissibles=liste_cases_admissibles(y,x)
		if cases_admissibles!=[]
		(i,j),k=random_choose_in_list(cases_admissibles)
		y[i,j]=0
			if is_graph_connexe(y) 
				append!(cases_noires,[(i,j)])
				supprimer_doublons((i,j),x)
				cases_admissibles=liste_cases_admissibles(y,x)
			else
				y[i,j]=1
				
			end
		end
	end
	if size(x,1)==1
		return cases_noires
	else
		return []
	end
end

function case_entouree_de_case_blanche(y,i::Int64, j::Int64)
	n = size(y,1)
	b=1
	if i-1>=1
		if y[i-1,j]==0
			b=0
		end
	end
	if i+1<=n
		if y[i+1,j]==0
			b=0
		end
	end
	if j-1>=1
		if y[i,j-1]==0
			b=0
		end
	end
	if j+1<=n
		if y[i,j+1]==0
			b=0
		end
	end
	return b

end

function voisins_blancs(y,i::Int64, j::Int64)
	n = size(y,1)
	v=Tuple{Int64,Int64}[]
	if i-1>=1
		if y[i-1,j]==1
			push!(v,(i-1,j))
		end
	end
	if i+1<=n
		if y[i+1,j]==1
			push!(v,(i+1,j))
		end
	end
	if j-1>=1
		if y[i,j-1]==1
			push!(v,(i,j-1))
		end
	end
	if j+1<=n
		if y[i,j+1]==1
			push!(v,(i,j+1))
		end
	end
	return v

end
function liste_sommets_blancs(y)
	n = size(y,1)
	liste_sommets_blancs=Tuple{Int64,Int64}[]
	for i in 1:n
		for j in 1:n
			if y[i,j]==1
				push!(liste_sommets_blancs,(i,j))
			end
		end
	end
	return liste_sommets_blancs
end

function arbre_connexe(y)
	n = size(y,1)
	sommets_a_voir = Tuple{Int64,Int64}[]
	sommets_visites = Tuple{Int64,Int64}[]
	if y[1,1] == 1
		push!(sommets_a_voir,(1,1))
	else
		push!(sommets_a_voir,(1,2))
	end
	while sommets_a_voir!=[]
		sommet_traite=sommets_a_voir[1]
		deleteat!(sommets_a_voir,1)
		if !(sommet_traite in sommets_visites)
			i,j=sommet_traite
			push!(sommets_visites,sommet_traite)
			voisins=voisins_blancs(y,i,j)
			for l in voisins
				if !(l in sommets_visites)
					if !(l in sommets_a_voir)
						push!(sommets_a_voir,l)
					end
				end
			end
		end
	end
	return sommets_visites
end

function is_graph_connexe(y)
	n = size(y,1)
	i = size(arbre_connexe(y))
	j = size(liste_sommets_blancs(y))
	return i == j
end

function choix_cases_noires(y)
	n = size(y,1)
	liste_cases_admissibles = Tuple{Int64,Int64}[]
	cases_noires = Tuple{Int64,Int64}[]
	for i=1:n
		for j=1:n
			if y[i,j]==1
				if case_entouree_de_case_blanche(y,i,j) == 1
					push!(liste_cases_admissibles,(i,j))
				end
			end
		end
	end
	while liste_cases_admissibles != []
		s = size(liste_cases_admissibles,1)
		r = ceil.(Int, s * rand())
		i,j = liste_cases_admissibles[r]
		y[i,j] = 0
		deleteat!(liste_cases_admissibles,r)
		for e in voisins_blancs(y,i,j)
			supprimer_doublons(e,liste_cases_admissibles)
		end
		if is_graph_connexe(y)
			push!(cases_noires,(i,j))
		else
			y[i,j]=1	
		end
	end
	return cases_noires
end


function supprimer_doublons(e,liste)
	s=size(liste,1)
	for i=1:s
		if liste[i]==e
			deleteat!(liste,i)
			break
		end
	end
	return liste
end

