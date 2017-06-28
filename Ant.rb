def euc_2d(c1, c2)
  Math.sqrt((c1[0] - c2[0])**2.0 + (c1[1] - c2[1])**2.0).round
end
#Calcula o custo total de uma solu��o. A amtriz de permuta��o e uma solucao. Sendo que a ordem das cidades e a ordem do vetor.
def cost(permutation, cities)
  distance =0
  permutation.each_with_index do |c1, i|
	#checa se a cidade analisada e a ultimo do vetor. a cidade dois sera a primeira se a cidade 1 for a ultima. do contrrio a cidade dois sera a proxima do vetor
    c2 = (i==permutation.size-1) ? permutation[0] : permutation[i+1]
    distance += euc_2d(cities[c1], cities[c2])
  end
  return distance
end



#Gera uma primeira solu��o de maneira randomica! Uma solu��o nada mais e que um caminho entre as cidades! Usada apenas uma vez
def random_permutation(cities)
  perm = Array.new(cities.size){|i| i}
  perm.each_index do |i|
    r = rand(perm.size-i) + i
    perm[r], perm[i] = perm[i], perm[r]
  end
  return perm
end


#Inicializa a matriz de pheromonio. Gera um array de array(Matriz). A matriz mede o feromonio de uma cidade a outra. Nesse caso inicializa todos com o mesmo valor(Quantidade de cidades/ naivescore)
def initialise_pheromone_matrix(num_cities, naive_score)
  v = num_cities.to_f / naive_score
  # Lembra uma matriz de incidencia! A coluna/ linha e uma cidade. o encontro da coluna e linha e o pheromonio entre as cidades.
  return Array.new(num_cities){|i| Array.new(num_cities, v)}
end



# Essa funcao serve para calcular todas as opcoes para a proxima cidade, todas as escolhas. Passa por todas as cidades. Gera um vetor com todas as escolhas possiveis. Para cada escolha e calculado probabilidade daquela cidade ser a proxima escolhida 
def calculate_choices(cities, last_city, exclude, pheromone, c_heur, c_hist)
  #Checa todas as possibildiades para se escolher a proxima cidade.
  choices = []
  #passa por todas as cidades. coord pega as coordenadas de uma dada cidade, i a posicao dela no array de cidades. o i identifica qual cidade no array � 
  cities.each_with_index do |coord, i|
    #checa se a cidade ja foi visitada. as cidades visitadas esta em exclude. A cidade analisada estar no vetor exclude? Se sim, sai dessa intera��o
	next if exclude.include?(i)
    
	#Indentifica qual cidade esta sendo analisada
	prob = {:city=>i}
   
    #calcula o fator historico. O c hist mostra o quanto voce considera o historico. Historico o quanto que passaram naquela cidade, e se mede isso coma  matriz de pheronio. Se passaram muito por ali de maniera frequente, maior o fator de historico pois o pheromonio ali estar� muito alto
	prob[:history] = pheromone[last_city][i] ** c_hist
	# Considera o vetor distancia 
	prob[:distance] = euc_2d(cities[last_city], coord)
    # Calcula o faotr heuristico, isso e, o quanto que a distancia vai influir nessa decisao. Quanto maior a distancia, menor a chance de se escolher
	prob[:heuristic] = (1.0/prob[:distance]) ** c_heur
    # Calcula a probabilidade da escolha ser escolhida. Multiplica o fator de distancia e o fator heuristico	
	prob[:prob] = prob[:history] * prob[:heuristic]
    # Adiciona a escolha no vetor de escolha
	choices << prob
  end
  choices
end


#Essa funcao escolhera a proxima cidade a ser considerada em uma solu��o. Ainda que exista um peso, a proxima cidade ainda e aleatoria 
def select_next_city(choices)
  #Soma a probabilidade de todas as ocpes para a proxima cidade
  sum = choices.inject(0.0){|sum,element| sum + element[:prob]}
  #Ira retornar uma escolha qualquer caso qeu a probabilidade de todo mundo seja zero
  return choices[rand(choices.size)][:city] if sum == 0.0
  #Gera um numero aleatorio entre 0 e 1.
  v = rand()
  
  #Ira passar por todas as escolhas 
  choices.each_with_index do |choice, i|
    #Cada escolha ira reduzir o valor randomico gerado. Quanto maior a probabilidade do escolha, maiores a chances de superar o valor de V
	v -= (choice[:prob]/sum)
	#Assim que uma escoha superar o valor ramdomico gerado, ela ser� a proxima. Fico puto por que  e randomico no final
    return choice[:city] if v <= 0.0
  end
  # Se todas as escolhas nao superarem o valor aleatorio gerado, entao a ultima cara do array e escolhido.
  return choices.last[:city]
end

#Essa fun��o gerar� uma solu��o! 
def stepwise_const(cities, phero, c_heur, c_hist)
  perm = []
  # Gera a primeira cidade a se caminhar randomicamente. 
  perm << rand(cities.size)
  #essa funcao gera um caminho aleatorio que passa por todas as cidades. Contudo essa solucao ira considerar o pheromonio e a distancia entre as cidades.
  begin
    
	# A fun��o calculate choices pega todas as cidades (cities), a ultima cidade visitada (Perm.last), todas as cidades visitadas (Perm), a matriz de feromonio (phero) e os pesos das heuristicas e do historico
	#Ela verifica todas as possibildiades para proxima cidade a ser visitada. Desconsidera a todas ja visitadas.
	# Para cada escolha esta associada a probabilidade dela ser escolhida
	choices = calculate_choices(cities,perm.last,perm,phero,c_heur,c_hist)
    
	#Com base nas escolhas possiveis, usase a funcao next city para saber qual e a melhor cidade. lembrando que cada possbilidade tem uma probabilidade a ser escohida associada a ela
	next_city = select_next_city(choices)
    #adiciona a proxima cidade a solucao
	perm << next_city
  end until perm.size == cities.size
  return perm
end

# Retira parcela do feromonio de maneira constante. todo mundo da matriz sofre redu��o 
def decay_pheromone(pheromone, decay_factor)
  pheromone.each do |array|
    array.each_with_index do |p, i|
      array[i] = (1.0 - decay_factor) * p
    end
  end
end


def update_pheromone(pheromone, solutions)
#Para todas as solu�oes ele ira atualziar a matriz de pheromonio. Vale destacvar que A mesma solucao ira contribuir vvarias vezes uma vez que o update e executado para cada solucao nova.
  solutions.each do |other| #Other e a solucao analisada nesse instante
	#O vector sao as cidades. Para cada cidade dessa solucao eles irao fazer atualizar o vetor pheromonio
    other[:vector].each_with_index do |x, i|
	  #Verifica se e o ultimo. se for o ultimo, calcula o pheromonio entre a ultima e o primero)(Vetor 0)
      y=(i==other[:vector].size-1) ? other[:vector][0] : other[:vector][i+1]
		#Adiciona pherominio entre cidades com base no custo entre as cidades
	  pheromone[x][y] += (1.0 / other[:cost])
      pheromone[y][x] += (1.0 / other[:cost])
    end
  end
end

def search(cities, max_it, num_ants, decay_factor, c_heur, c_hist)
  #Gera uma primeira solu��o de maniera randomica!
  best = {:vector=>random_permutation(cities)}
  #Calcula o custo dessa solu��o 
  best[:cost] = cost(best[:vector], cities)
#Inicializa o vetr pheromonio
  pheromone = initialise_pheromone_matrix(cities.size, best[:cost])
  # Ira gerar uma quantidade de solu�oes. cada interaacao gera uma solucao. (Max it gera as solucoes
  max_it.times do |iter|
    solutions = []
	# esse looping serve para gerar um candidato com base na quyantidade de formigas.
    num_ants.times do
      candidate = {}
	  # gera um candidato, uma solu��o  com a funcao stepwise. Retorna o vector da ordem das cidades a se visitar
      candidate[:vector] = stepwise_const(cities, pheromone, c_heur, c_hist)
	  #verifica o custo do candidato
	 candidate[:cost] = cost(candidate[:vector], cities)
	  # Verifica se o custo do candito e menor que o custo da melhor solucao adotada. se o custo for menor, entaoe ssa solucao e melgor 
      best = candidate if candidate[:cost] < best[:cost]
      # Adiciona todos os candidatos ao vetor solu��o. Todas as solu��es possiveis estao aqui.
	  solutions << candidate
    end
    decay_pheromone(pheromone, decay_factor)
    update_pheromone(pheromone, solutions)
    puts " > iteration #{(iter+1)}, best=#{best[:cost]}"
  end
  return best
end

if __FILE__ == $0
  # problem configuration
  berlin52 = [[565,575],[25,185],[345,750],[945,685],[845,655],
   [880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],
   [1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],
   [415,635],[510,875],[560,365],[300,465],[520,585],[480,415],
   [835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],
   [410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],
   [685,610],[770,610],[795,645],[720,635],[760,650],[475,960],
   [95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],
   [830,610],[605,625],[595,360],[1340,725],[1740,245]]
  # algorithm configuration
  max_it = 50
  num_ants = 30
  decay_factor = 0.6
  c_heur = 2.5
  c_hist = 1.0
  # execute the algorithm
  best = search(berlin52, max_it, num_ants, decay_factor, c_heur, c_hist)
  puts "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
  sleep(30)
end
