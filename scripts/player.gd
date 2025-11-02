extends Node2D

@export var fixed_x: float = -400.0
@export var lane_gap_ratio: float = 0.25  # 25% of viewport height between lanes
@export var tween_time: float = 0.12
@export var custom_lanes_y: PackedFloat32Array = []

var lanes: Array[float] = []
var lane_index: int = 1
var _lane_tween: Tween = null
var is_dead: bool = false

signal player_died
signal lanes_updated(new_lanes: Array[float])

func _ready() -> void:
	position.x = fixed_x
	_calculate_lanes()
	position.y = lanes[lane_index]
	print("Player positioned at lane ", lane_index, " (y=", position.y, ")")
	
	# Emit signal so spawner can sync lanes
	lanes_updated.emit(lanes)

func _calculate_lanes() -> void:
	if custom_lanes_y.size() == 3:
		lanes = [custom_lanes_y[0], custom_lanes_y[1], custom_lanes_y[2]]
		print("Player using custom lanes: ", lanes)
	else:
		var viewport_size = get_viewport().get_visible_rect().size
		var center_y = viewport_size.y * 0.5
		var gap = viewport_size.y * lane_gap_ratio
		
		lanes = [center_y - gap, center_y, center_y + gap]
		print("Player calculated viewport-relative lanes: ", lanes, " (viewport: ", viewport_size, ")")

func _process(_delta: float) -> void:
	# Keep X pinned just in case
	if position.x != fixed_x:
		position.x = fixed_x

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
		
	if event.is_action_pressed("lane_up"):
		_change_lane(-1)
	elif event.is_action_pressed("lane_down"):
		_change_lane(1)

func _change_lane(dir: int) -> void:
	var target_index: int = clamp(lane_index + dir, 0, 2)
	if target_index == lane_index:
		return

	lane_index = target_index
	var target_y: float = lanes[lane_index]

	if _lane_tween != null and _lane_tween.is_running():
		_lane_tween.kill()

	_lane_tween = create_tween()
	_lane_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lane_tween.tween_property(self, "position:y", target_y, tween_time)

func take_damage() -> void:
	if is_dead:
		return
	
	die()

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	print("Player died!")
	
	# Stop any lane changing tween
	if _lane_tween != null and _lane_tween.is_running():
		_lane_tween.kill()
	
	# Get the animated sprite and stop animation
	var character_body = get_node("CharacterBody2D")
	if character_body:
		var animated_sprite = character_body.get_node("AnimatedSprite2D")
		if animated_sprite:
			animated_sprite.stop()
	
	# Emit death signal for game management
	player_died.emit()
	
	# Optional: Add visual death effect like rotation or color change
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(self, "rotation", PI/2, 0.5)
	death_tween.tween_property(self, "modulate", Color.RED, 0.3)
