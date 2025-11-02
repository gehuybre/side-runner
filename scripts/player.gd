extends Node2D

@export var fixed_x: float = -400.0
@export_range(0.05, 0.4) var lane_gap_ratio: float = 0.14  # Legacy gap control (kept for compatibility)
@export_range(0.1, 0.6) var lane_height_ratio: float = 0.35  # Total height band containing all lanes
@export var lane_vertical_offset_ratio: float = 0.08  # Offset from vertical center for lanes
@export var tween_time: float = 0.12
@export var custom_lanes_y: PackedFloat32Array = []
@export var jump_height: float = 90.0
@export var jump_duration: float = 0.6
@export var magnet_duration_default: float = 5.0

@onready var character_body: CharacterBody2D = $CharacterBody2D
@onready var animated_sprite = character_body.get_node("AnimatedSprite2D") if character_body else null

var lanes: Array[float] = []
var lane_index: int = 1
var _lane_tween: Tween = null
var _jump_tween: Tween = null
var is_dead: bool = false
var is_jumping: bool = false
var touch_controls: Control = null
var _character_base_y: float = 0.0
var _magnet_timer: Timer = null
var _magnet_active: bool = false

signal player_died
signal lanes_updated(new_lanes: Array[float])
signal magnet_state_changed(active: bool)

func _ready() -> void:
	position.x = fixed_x
	_calculate_lanes()
	position.y = lanes[lane_index]
	print("Player positioned at lane ", lane_index, " (y=", position.y, ")")

	if character_body:
		_character_base_y = character_body.position.y
	if animated_sprite:
		animated_sprite.play("run")
	
	_magnet_timer = Timer.new()
	_magnet_timer.one_shot = true
	add_child(_magnet_timer)
	_magnet_timer.timeout.connect(_on_magnet_timer_timeout)
	
	# Emit signal so spawner can sync lanes
	lanes_updated.emit(lanes)
	
	# Connect to touch controls if they exist
	_connect_touch_controls()

func _connect_touch_controls() -> void:
	# Look for touch controls in the scene tree
	var world = get_parent()
	if world:
		# Try new location first (TouchControlsLayer)
		touch_controls = world.get_node_or_null("TouchControlsLayer/TouchControls")
		if not touch_controls:
			# Try old location for backward compatibility
			touch_controls = world.get_node_or_null("CanvasLayer/TouchControls")
			if not touch_controls:
				# Try alternative paths
				touch_controls = world.get_node_or_null("UI/TouchControls")
				if not touch_controls:
					touch_controls = world.get_node_or_null("TouchControls")
		
		if touch_controls:
			touch_controls.lane_up_pressed.connect(_on_touch_lane_up)
			touch_controls.lane_down_pressed.connect(_on_touch_lane_down)
			if touch_controls.has_signal("jump_pressed"):
				touch_controls.jump_pressed.connect(_on_touch_jump)
			print("Player connected to touch controls at: ", touch_controls.get_path())
		else:
			print("No touch controls found in scene")

func _calculate_lanes() -> void:
	if custom_lanes_y.size() == 3:
		lanes = [custom_lanes_y[0], custom_lanes_y[1], custom_lanes_y[2]]
		print("Player using custom lanes: ", lanes)
	else:
		var viewport_size = get_viewport().get_visible_rect().size
		var center_y = viewport_size.y * (0.5 + lane_vertical_offset_ratio)
		var half_band = viewport_size.y * lane_height_ratio * 0.5
		lanes = [center_y - half_band, center_y, center_y + half_band]
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
	elif event.is_action_pressed("jump"):
		jump()

# Touch input handlers
func _on_touch_lane_up() -> void:
	if not is_dead:
		_change_lane(-1)

func _on_touch_lane_down() -> void:
	if not is_dead:
		_change_lane(1)

func _on_touch_jump() -> void:
	if not is_dead:
		jump()

func _change_lane(dir: int) -> void:
	if is_jumping:
		return

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

func jump() -> void:
	if is_dead or is_jumping or character_body == null:
		return

	is_jumping = true

	if _lane_tween != null and _lane_tween.is_running():
		_lane_tween.kill()

	if _jump_tween != null and _jump_tween.is_running():
		_jump_tween.kill()
		_jump_tween = null

	if animated_sprite:
		animated_sprite.play("jump")

	_jump_tween = create_tween()
	_jump_tween.tween_property(character_body, "position:y", _character_base_y - jump_height, jump_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(character_body, "position:y", _character_base_y, jump_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_jump_tween.finished.connect(_on_jump_finished)

func _on_jump_finished() -> void:
	is_jumping = false
	_jump_tween = null
	if animated_sprite and not is_dead:
		animated_sprite.play("run")

func take_damage() -> void:
	if is_dead:
		return
	
	die()

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	_deactivate_magnet()
	print("Player died!")
	
	# Stop any lane changing tween
	if _lane_tween != null and _lane_tween.is_running():
		_lane_tween.kill()
	
	if _jump_tween != null and _jump_tween.is_running():
		_jump_tween.kill()
		_jump_tween = null
	
	if character_body:
		character_body.position.y = _character_base_y
	
	is_jumping = false
	
	# Get the animated sprite and stop animation
	if animated_sprite:
		animated_sprite.stop()
	
	# Emit death signal for game management
	player_died.emit()
	
	# Optional: Add visual death effect like rotation or color change
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(self, "rotation", PI/2, 0.5)
	death_tween.tween_property(self, "modulate", Color.RED, 0.3)

func activate_magnet(duration: float = -1.0) -> void:
	if is_dead:
		return
	var effective_duration: float = duration
	if effective_duration <= 0.0:
		effective_duration = magnet_duration_default
	if _magnet_timer == null:
		return
	_magnet_active = true
	_magnet_timer.start(effective_duration)
	magnet_state_changed.emit(true)
	print("Magnet activated for ", effective_duration, " seconds")

func is_magnet_active() -> bool:
	return _magnet_active

func get_magnet_anchor_position() -> Vector2:
	if character_body:
		return character_body.global_position
	return global_position

func _deactivate_magnet() -> void:
	if _magnet_timer:
		_magnet_timer.stop()
	if _magnet_active:
		_magnet_active = false
		magnet_state_changed.emit(false)

func _on_magnet_timer_timeout() -> void:
	if not _magnet_active:
		return
	_magnet_active = false
	magnet_state_changed.emit(false)
	print("Magnet effect expired")
