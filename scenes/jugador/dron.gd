# dron_escolta.gd
extends CharacterBody3D
class_name DronEscolta

# ==================== CONFIGURACIÓN ====================
@export var distancia_al_jugador: float = 2.5      # Distancia fija lateral
@export var velocidad_seguimiento: float = 5.0     # Velocidad para seguir
@export var suavizado: float = 8.0                 # Suavizado del movimiento
@export var altura_fija: float = 2.0               # Y fija del dron
@export var lado: int = 1                          # 1 = derecha, -1 = izquierda

# ==================== EVASIÓN ====================
@export var velocidad_evasion: float = 3.0
@export var tiempo_evasion: float = 0.5
@export var angulo_giro_max: float = 60.0

# ==================== REFERENCIAS ====================
var jugador: Node3D = null
var direccion_evasion: Vector3 = Vector3.ZERO
var evasion_activa: bool = false
var tiempo_evasion_restante: float = 0.0
var obstaculos_cercanos: Array[Node3D] = []

@onready var area_obstaculos: Area3D = $bigote
var posicionado= false

# ==================== INICIALIZACIÓN ====================
func _ready() -> void:
	# Conectar señales del área
	area_obstaculos.body_entered.connect(_on_body_entered)
	area_obstaculos.body_exited.connect(_on_body_exited)
	area_obstaculos.area_entered.connect(_on_area_entered)
	area_obstaculos.area_exited.connect(_on_area_exited)
	add_to_group('drone')
	jugador = get_tree().get_first_node_in_group("Jugadores")
	

# Método para asignar el jugador objetivo y el lado
func configurar(jugador_objetivo: Node3D, lado_asignado: int) -> void:
	
	lado = lado_asignado  # 1 = derecha, -1 = izquierda

# ==================== LÓGICA PRINCIPAL ====================
func _physics_process(delta: float) -> void:
	
	
	# 1. Calcular posición objetivo (al costado del jugador)
	var posicion_objetivo := _calcular_posicion_objetivo()
	
	# 2. Calcular dirección hacia el objetivo
	var direccion := (posicion_objetivo - global_position)
	direccion.y = 0
	var distancia := direccion.length()
	direccion = direccion.normalized()
	
	# 3. Aplicar evasión si hay obstáculos
	if evasion_activa:
		tiempo_evasion_restante -= delta
		if tiempo_evasion_restante <= 0:
			evasion_activa = false
		else:
			# Mezclar dirección con la evasión
			direccion = (direccion + direccion_evasion).normalized()
	
	# 4. Calcular velocidad final (Arrive suave)
	var velocidad_objetivo := Vector3.ZERO
	if distancia > 0.3:
		var factor = clamp(distancia / 2.0, 0.0, 1.0)
		velocidad_objetivo = direccion * velocidad_seguimiento * factor
	
	# 5. Suavizar la velocidad
	velocity.x = lerp(velocity.x, velocidad_objetivo.x, suavizado * delta)
	velocity.z = lerp(velocity.z, velocidad_objetivo.z, suavizado * delta)
	
	# 6. Mantener Y fija
	velocity.y = 0
	
	# 7. Aplicar movimiento
	move_and_slide()
	
	# 8. Forzar Y fija (por si acaso)
	global_position.y = altura_fija
	
	# 9. Rotar hacia el jugador
	_rotar_hacia_jugador(delta)

# ==================== POSICIÓN OBJETIVO ====================
func _calcular_posicion_objetivo() -> Vector3:
	# Obtener el vector "derecha" del jugador
	var derecha := jugador.global_transform.basis.x
	derecha.y = 0
	derecha = derecha.normalized()
	
	# Aplicar el lado correspondiente
	var offset := derecha * distancia_al_jugador * lado
	
	# Posición objetivo: al lado del jugador + altura fija
	var objetivo := jugador.global_position + offset
	objetivo.y = altura_fija
	
	return objetivo

# ==================== ROTACIÓN ====================
func _rotar_hacia_jugador(delta: float) -> void:
	if not jugador:
		return
	
	var direccion := (jugador.global_position - global_position)
	direccion.y = 0
	
	if direccion.length() > 0.1:
		var angulo_objetivo := atan2(direccion.x, direccion.z)
		rotation.y = lerp_angle(rotation.y, angulo_objetivo, delta * 5.0)

# ==================== EVASIÓN ====================
func _on_body_entered(body: Node3D) -> void:
	if body is StaticBody3D or body is CharacterBody3D:
		obstaculos_cercanos.append(body)
		_activar_evasion(body)

func _on_body_exited(body: Node3D) -> void:
	obstaculos_cercanos.erase(body)

func _on_area_entered(area: Area3D) -> void:
	obstaculos_cercanos.append(area)
	_activar_evasion(area)

func _on_area_exited(area: Area3D) -> void:
	obstaculos_cercanos.erase(area)

func _activar_evasion(obstaculo: Node3D) -> void:
	# Dirección de huida (alejarse del obstáculo)
	var direccion_huida := (global_position - obstaculo.global_position)
	direccion_huida.y = 0
	
	if direccion_huida.length() < 0.01:
		direccion_huida = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	
	# Agregar giro aleatorio para evitar atascarse
	var angulo := deg_to_rad(randf_range(-angulo_giro_max, angulo_giro_max))
	direccion_huida = direccion_huida.rotated(Vector3.UP, angulo)
	
	direccion_evasion = direccion_huida.normalized()
	evasion_activa = true
	tiempo_evasion_restante = tiempo_evasion
