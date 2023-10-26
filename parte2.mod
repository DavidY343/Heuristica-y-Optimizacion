###############
#  Conjuntos  #
###############

set Distritos;
set Localizaciones;
set Localizaciones_nuevas; 

################
#  Parámetros  #
################

param Llamadas {Distritos}; # Número de llamadas que hace cada distrito
param Tiempo {Localizaciones, Distritos}; # Tiempo que tarda el parking L al distrito D
param Max_llamadas;  # Max nºllamadas que puede atender un parking: 10000
param Tiempo_maximo_atencion; # Los 35 min maximo de tiempo en llegar al distrito
param Maximo_esfuerzo_relativo; # El 150% para el balance de esfuerzo
param Coste_nuevo_parking; # Coste de construir los parkin L4 L5 L5
param Coste_combustible; # Coste €/min
param M; # Un valor grande
param Min_percent; # Minimo del 10% de llamadas para un parking
param Max_distribucion; #Max 75% de distribucion
param Epsilon; #Numero infinitamente pequeño

###########################
#  Variables de decisión  #
###########################

var x {Localizaciones, Distritos} integer, >= 0;
var Loc_construidas {Localizaciones} binary; # binario para ver que localizaciones se quedan activas
var b1 {Localizaciones, Distritos} binary; # Binario necesario para la restriccion del 10%
var b2 {Distritos} binary; # Binario necesario para la restriccion de al menos 75%

######################
#  Función objetivo  #
######################

# Minimizar el gasto total (coste fijo + coste en combustible)
minimize Minimo_coste: sum {l in Localizaciones, d in Distritos} Coste_combustible * Tiempo[l,d] * x[l,d] 
					+ sum {ln in Localizaciones_nuevas} Coste_nuevo_parking * Loc_construidas[ln];
					
###################
#  Restricciones  #
###################

# Todas las llamadas de todos los distritos deben ser atendidas en algún parking de ambulancias
s.t. atender_llamadas {d in Distritos}: sum {l in Localizaciones} x[l,d] = Llamadas[d];

# Un parking de ambulancias no puede tener mas de 10000 llamdas
s.t. maximo_llamadas {l in Localizaciones}: sum {d in Distritos} x[l,d] <= Max_llamadas;

# Se debe garantizar que un parking no tardará nunca más de 35 minutos en llegar 
s.t. maximo_tiempo {l in Localizaciones, d in Distritos}: 
	Tiempo[l,d] * x[l,d] <= Tiempo_maximo_atencion * x[l,d];

# El número total de llamadas asignado a un parking ser mas del 150% del número total de llamadas
#  asignado a cualquier otro parking
s.t. balance_esfuerzo {l1 in Localizaciones, l2 in Localizaciones: l1 != l2}: 
	sum {d in Distritos} x[l1,d]  <= (Maximo_esfuerzo_relativo * sum {d in Distritos} x[l2,d]) + (1 - Loc_construidas[l2]) * M;

# Calculo del binario para saber que localizaciones se quedan activas
s.t. localizacion_seleccionada {l in Localizaciones}: 
	sum{d in Distritos} x[l, d] >= 0 - M * (1 - Loc_construidas[l]) + Epsilon;
s.t. localizacion_no_seleccionada {l in Localizaciones}: 
	sum{d in Distritos} x[l, d] <= 0 + M * Loc_construidas[l];

# Si el número de llamadas de un distrito es mayor o igual que el 75% del número máximo de llamadas que pueden
# atender los parkings, sus llamadas se tienen que distribuir necesariamente entre dos o más parkings de ambulancias.
s.t. max_llamadas_75 {l in Localizaciones, d in Distritos}:
	 x[l, d] <= ((sum{loc in Localizaciones} x[loc, d]) + (1 - b2[d]) * M) - Epsilon;

# Calculo del binario necesario para la restriccion del 75%
s.t. binario_75_part1 {d in Distritos}: 
	sum {l in Localizaciones} x[l, d]  >= (Max_distribucion * Max_llamadas) - M * (1 - b2[d]);
s.t. binaria_75_part2 {d in Distritos}: 
	sum {l in Localizaciones} x[l, d] <= b2[d] * M + (Max_distribucion * Max_llamadas) - Epsilon;

# Si un parking de ambulancias cubre alguna llamada de un distrito, 
# no puede cubrir menos del 10% del total de las llamadas de ese distrito.
s.t. minimo_llamadas {l in Localizaciones, d in Distritos}: x[l,d] >= Min_percent * Llamadas[d] * b1[l,d];

# Si hay llamadas desde un distrito a un parking, entonces w[l,d] = 1
s.t. asignacion_llamadas_part1 {l in Localizaciones, d in Distritos}: x[l,d] >= - M * (1 - b1[l,d]) + Epsilon;
s.t. asignacion_llamadas_part2 {l in Localizaciones, d in Distritos}: x[l,d] <= M * b1[l,d];

############
#  SOLVER  #
############

solve;
display Loc_construidas;
display Minimo_coste;
end;
