# obstacle_avoidance.gd

extends Node
class_name ObstacleAvoidance

# ==================== CONFIGURACIÓN ====================
@export var velocidad_evasion: float = 4.0       # Velocidad al evadir
@export var distancia_deteccion: float = 2.5     # Radio del área de detección
@export var tiempo_evasion: float = 0.6          # Cuánto dura la evasión
@export var fuerza_evasion: float = 1.5          # Mezcla con la dirección actual
@export var suavizado: float = 8.0               # Suavizado de rotación

# ==================== ESTADO INTERNO ====================
var obstaculos_cercanos: Array[Node3D] = []
var evasion_activa: bool = false
var tiempo_evasion_restante: float = 0.0
var direccion_evasion: Vector3 = Vector3.ZERO
var area_deteccion: Area3D = null
var debug_activo: bool = false



# ==================== LÓGICA PRINCIPAL ====================
# Devuelve la velocidad de evasión (o Vector3.ZERO si no hay evasión activa)
func calcular_evasion(direccion_actual: Vector3, delta: float) -> Vector3:
	# Actualizar tiempo de evasión
	if evasion_activa:
		tiempo_evasion_restante -= delta
		if tiempo_evasion_restante <= 0:
			evasion_activa = false
			direccion_evasion = Vector3.ZERO
			return Vector3.ZERO
	
	if not evasion_activa:
		# Si hay obstáculos cercanos, activar evasión
		if not obstaculos_cercanos.is_empty():
			_activar_evasion()
		else:
			return Vector3.ZERO
	
	if not evasion_activa:
		return Vector3.ZERO
	
	# Suavizar la dirección de evasión
	var direccion_suave := direccion_actual.lerp(direccion_evasion, suavizado * delta).normalized()
	
	return direccion_suave * velocidad_evasion

# ==================== ACTIVACIÓN DE EVASIÓN ====================
func _activar_evasion() -> void:
	var obstaculo := _obtener_obstaculo_mas_cercano()
	if not obstaculo:
		return
	
	# Calcular dirección de huida (alejarse del obstáculo)
	var direccion_huida = (get_parent().global_position - obstaculo.global_position)
	direccion_huida.y = 0
	
	if direccion_huida.length() < 0.01:
		# Si están en la misma posición, elegir una dirección aleatoria
		direccion_huida = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	
	direccion_evasion = direccion_huida.normalized()
	evasion_activa = true
	tiempo_evasion_restante = tiempo_evasion
	
	if debug_activo:
		print("🚧 Evadiendo obstáculo: ", obstaculo.name)

# ==================== SEÑALES DEL ÁREA ====================
func _on_body_entered(body: Node3D) -> void:
	if body not in obstaculos_cercanos:
		obstaculos_cercanos.append(body)

func _on_body_exited(body: Node3D) -> void:
	obstaculos_cercanos.erase(body)

func _on_area_entered(area: Area3D) -> void:
	if area not in obstaculos_cercanos:
		obstaculos_cercanos.append(area)

func _on_area_exited(area: Area3D) -> void:
	obstaculos_cercanos.erase(area)

# ==================== CONSULTAS ====================
func hay_obstaculos() -> bool:
	return not obstaculos_cercanos.is_empty()

func esta_evadiendo() -> bool:
	return evasion_activa

func _obtener_obstaculo_mas_cercano() -> Node3D:
	var mas_cercano: Node3D = null
	var distancia_minima := INF
	
	for obs in obstaculos_cercanos:
		if not is_instance_valid(obs):
			continue
		var d = get_parent().global_position.distance_to(obs.global_position)
		if d < distancia_minima:
			distancia_minima = d
			mas_cercano = obs
	
	return mas_cercano

# ==================== UTILIDADES ====================
func set_velocidad(nueva_velocidad: float) -> void:
	velocidad_evasion = max(0.0, nueva_velocidad)

func set_tiempo_evasion(nuevo_tiempo: float) -> void:
	tiempo_evasion = max(0.1, nuevo_tiempo)

func set_debug(activo: bool) -> void:
	debug_activo = activo

func reiniciar() -> void:
	obstaculos_cercanos.clear()
	evasion_activa = false
	tiempo_evasion_restante = 0.0
	direccion_evasion = Vector3.ZERO
