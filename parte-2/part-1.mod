###############
#  Conjuntos  #
###############

set Distritos; 
set Localizaciones; 

################
#  Parámetros  #
################

param Llamadas {Distritos}; # Número de llamadas que hace cada distrito
param Tiempo {Localizaciones, Distritos}; # Tiempo que tarda el parking L al distrito D
param Max_llamadas; # Max nºllamadas que puede atender un parking: 10000
param Tiempo_maximo_atencion; # Los 35 min maximo de tiempo en llegar al distrito
param Maximo_esfuerzo_relativo; # El 150% para el balance de esfuerzo

###########################
#  Variables de decisión  #
###########################

var x{Localizaciones, Distritos} integer,  >= 0;

######################
#  Función objetivo  #
######################

# Minimizar el tiempo empleado en atender todas las llamadas en un año
minimize Minimo_tiempo: sum {l in Localizaciones, d in Distritos} Tiempo[l,d] * x[l,d];

###################
#  Restricciones  #
###################

# Todas las llamadas de todos los distritos deben ser atendidas en algún parking de ambulancias
s.t. atender_llamadas {d in Distritos}: sum {l in Localizaciones} x[l,d] = Llamadas[d];

# Un parking de ambulancias no puede tener mas de 10000 llamadas
s.t. maximo_llamadas {l in Localizaciones}: sum {d in Distritos} x[l,d] <= Max_llamadas;

# Se debe garantizar que un parking no tardará nunca más de 35 minutos en llegar 
s.t. maximo_tiempo {l in Localizaciones, d in Distritos}: 
	Tiempo[l,d] * x[l,d] <= Tiempo_maximo_atencion * x[l,d];

# El número total de llamadas asignado a un parking ser mas del 150% del número total de llamadas  asignado a cualquier otro parking
s.t. balance_esfuerzo {l1 in Localizaciones, l2 in Localizaciones: l1 != l2}: 
	sum {d in Distritos} x[l1,d] <= Maximo_esfuerzo_relativo * sum {d in Distritos} x[l2,d];

############
#  SOLVER  #
############

solve;
display x;
display Minimo_tiempo;
end;
