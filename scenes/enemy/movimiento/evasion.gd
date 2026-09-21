# evasion.gd
extends Node
class_name Evasion

# ==================== CONFIGURACIÓN ====================
@export var velocidad_evasion: float = 1.5       # Velocidad lenta al evadir
@export var tiempo_max_evasion: float = 2.0      # Tiempo máximo evadiendo antes de retroceder
@export var tiempo_retroceso: float = 1.0        # Duración del retroceso
@export var angulo_giro: float = 45.0            # Ángulo máximo de giro aleatorio (grados)
@export var suavizado: float = 5.0               # Suavizado de la rotación

# ==================== ESTADO INTERNO ====================
var evasion_activa: bool = false
var retrocediendo: bool = false
var tiempo_evasion: float = 0.0
var tiempo_retroceso_restante: float = 0.0
var direccion_evasion: Vector3 = Vector3.ZERO
var ultima_direccion: Vector3 = Vector3.FORWARD
var nodo_padre: Node3D = null
var area_deteccion: Area3D = null
var debug_activo: bool = false


# ==================== LÓGICA PRINCIPAL ====================
# Devuelve la velocidad de evasión (o Vector3.ZERO si no hay evasión activa)
func calcular_evasion(direccion_actual: Vector3, delta: float) -> Vector3:
	#if not evasion_activa:
		#return Vector3.ZERO
	
	# Actualizar tiempo de evasión
	tiempo_evasion += delta
	
	# Si está retrocediendo
	if retrocediendo:
		tiempo_retroceso_restante -= delta
		if tiempo_retroceso_restante <= 0:
			retrocediendo = false
			_generar_direccion_aleatoria()
		return direccion_evasion * velocidad_evasion
	
	# Si pasó mucho tiempo evadiendo, retroceder
	if tiempo_evasion >= tiempo_max_evasion:
		_iniciar_retroceso()
		return direccion_evasion * velocidad_evasion
	
	# Suavizar la dirección de evasión
	direccion_evasion = ultima_direccion.lerp(direccion_evasion, suavizado * delta).normalized()
	
	return direccion_evasion * velocidad_evasion

# ==================== ACTIVACIÓN DE EVASIÓN ====================
func _activar_evasion() -> void:
	if evasion_activa:
		return
	
	evasion_activa = true
	retrocediendo = false
	tiempo_evasion = 0.0
	_generar_direccion_aleatoria()
	
	if debug_activo:
		print("🚧 Evasión activada")

func _generar_direccion_aleatoria() -> void:
	# Tomar la dirección actual y girarla un ángulo aleatorio
	var angulo := deg_to_rad(randf_range(-angulo_giro, angulo_giro))
	
	# Rotar la dirección actual en el plano XZ
	var nueva_direccion := ultima_direccion.rotated(Vector3.UP, angulo)
	nueva_direccion.y = 0
	direccion_evasion = nueva_direccion.normalized()
	
	if debug_activo:
		print("🔄 Nueva dirección de evasión: ", direccion_evasion)

func _iniciar_retroceso() -> void:
	retrocediendo = true
	tiempo_retroceso_restante = tiempo_retroceso
	# Retroceder en dirección opuesta a la actual
	direccion_evasion = -ultima_direccion
	direccion_evasion.y = 0
	direccion_evasion = direccion_evasion.normalized()
	
	if debug_activo:
		print("⏪ Retrocediendo")

# ==================== SEÑALES DEL ÁREA ====================
func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D or body is CharacterBody3D:
		_activar_evasion()

func _on_body_exited(body: Node3D) -> void:
	# Si ya no hay colisiones, desactivar evasión
	_verificar_salida()

func _on_area_entered(area: Area3D) -> void:
	_activar_evasion()

func _on_area_exited(area: Area3D) -> void:
	_verificar_salida()

func _verificar_salida() -> void:
	# Si el área ya no tiene colisiones, desactivar evasión
	if area_deteccion and area_deteccion.get_overlapping_bodies().is_empty() and area_deteccion.get_overlapping_areas().is_empty():
		evasion_activa = false
		retrocediendo = false
		tiempo_evasion = 0.0
		direccion_evasion = Vector3.ZERO
		
		if debug_activo:
			print("✅ Evasión desactivada")

# ==================== CONSULTAS ====================
func esta_evadiendo() -> bool:
	return evasion_activa

func esta_retrocediendo() -> bool:
	return retrocediendo

func get_direccion_evasion() -> Vector3:
	return direccion_evasion

# ==================== UTILIDADES ====================
func set_velocidad(nueva_velocidad: float) -> void:
	velocidad_evasion = max(0.0, nueva_velocidad)

func set_tiempo_max(nuevo_tiempo: float) -> void:
	tiempo_max_evasion = max(0.1, nuevo_tiempo)

func set_angulo_giro(nuevo_angulo: float) -> void:
	angulo_giro = clamp(nuevo_angulo, 0.0, 180.0)

func set_debug(activo: bool) -> void:
	debug_activo = activo

func reiniciar() -> void:
	evasion_activa = false
	retrocediendo = false
	tiempo_evasion = 0.0
	tiempo_retroceso_restante = 0.0
	direccion_evasion = Vector3.ZERO
