extends Node2D

@export var horizontal_speed: float = 320.0
@export var float_amplitude_range: Vector2 = Vector2(60.0, 140.0)
@export var float_frequency_range: Vector2 = Vector2(0.3, 0.7)
@export var vertical_drift_range: Vector2 = Vector2(-30.0, 30.0)
@export var destroy_x: float = -1200.0
@export var magnet_duration: float = 5.0
@export var spawn_multiplier: float = 3.0

signal collected(duration: float, multiplier: float)
signal finished

var _float_amplitude: float = 80.0
var _float_frequency: float = 0.5
var _vertical_drift: float = 0.0
var _base_position: Vector2
var _elapsed: float = 0.0

func _ready() -> void:
	_base_position = global_position
	_randomize_motion()
	var area: Area2D = $Area2D
	if area:
		area.body_entered.connect(_on_body_entered)

func set_horizontal_speed(speed: float) -> void:
	horizontal_speed = speed

func _randomize_motion() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_float_amplitude = rng.randf_range(float_amplitude_range.x, float_amplitude_range.y)
	_float_frequency = rng.randf_range(float_frequency_range.x, float_frequency_range.y)
	_vertical_drift = rng.randf_range(vertical_drift_range.x, vertical_drift_range.y)

func _process(delta: float) -> void:
	_elapsed += delta
	_base_position.x -= horizontal_speed * delta
	_base_position.y += _vertical_drift * delta
	var sine_offset: float = sin(_elapsed * TAU * _float_frequency) * _float_amplitude
	global_position = Vector2(_base_position.x, _base_position.y + sine_offset)
	if global_position.x <= destroy_x:
		queue_free()

func _on_body_entered(body: Node) -> void:
	var player_node: Node = _resolve_player_from_body(body)
	if player_node == null:
		return
	if player_node.has_method("activate_magnet"):
		player_node.activate_magnet(magnet_duration)
	collected.emit(magnet_duration, spawn_multiplier)
	queue_free()

func _resolve_player_from_body(body: Node) -> Node:
	if body == null:
		return null
	if body.name == "Player":
		return body
	var parent: Node = body.get_parent()
	if parent and parent.name == "Player":
		return parent
	return null

func _exit_tree() -> void:
	finished.emit()
