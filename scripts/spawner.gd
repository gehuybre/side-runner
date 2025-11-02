# Spawner.gd
extends Node2D

@export var coin_scene: PackedScene
@export var obstacle_scenes: Array[PackedScene] = []  # Array of different obstacle types

@export var spawn_interval: float = 1.0         # base interval
const DEFAULT_COIN_SPAWN_X := 900.0
const DEFAULT_OBSTACLE_SPAWN_X := 1200.0

@export var start_x: float = DEFAULT_COIN_SPAWN_X   # legacy spawn X (used if dedicated values not set)
@export var coin_spawn_x: float = DEFAULT_COIN_SPAWN_X  # coin spawn X position
@export var obstacle_spawn_x: float = DEFAULT_OBSTACLE_SPAWN_X  # obstacle spawn X (further so they slide in)
@export var world_speed: float = 630.0           # canonical world speed (reduced for slower spawns)
@export var lanes_y: PackedFloat32Array = []    # Will be set by player

@export var min_gap_px: float = 140.0           # ensure spacing between spawns
@export var coin_collision_radius: float = 36.0
@export var obstacle_collision_radius: float = 64.0
@export var vertical_overlap_threshold: float = 48.0
@export var magnet_scene: PackedScene
@export var magnet_spawn_min_interval: float = 30.0
@export var magnet_spawn_max_interval: float = 60.0
@export var magnet_spawn_y_margin: float = 90.0
@export var magnet_collision_radius: float = 80.0
@export_range(0.1, 1.0) var magnet_horizontal_speed_factor: float = 0.6
@export var magnet_effect_duration: float = 5.0
@export var magnet_coin_spawn_multiplier: float = 3.0
@export var speed_increase_interval: float = 15.0  # increase speed every 15 seconds
@export var speed_increase_rate: float = 1.1    # multiply by 1.1 (10% increase)
@export var coin_sequence_length: int = 4       # base number of coins in sequence (will be randomized)
@export var coin_sequence_spacing: float = 0.1  # time between coins in sequence (faster for continuous collection)
@export var obstacle_spawn_interval: float = 1.2  # time between obstacle spawns (slightly longer for more coin time)
@export var obstacle_chance: float = 0.7        # 70% chance to spawn obstacle when interval is reached (reduced for more coin collection)

@export var min_spawn_distance: float = 150.0   # minimum distance between spawns to prevent overlap (reduced for denser gameplay)
@export_range(0.0, 1.0) var jump_sequence_chance: float = 0.35  # chance to spawn a jump-path coin sequence
@export var jump_sequence_min_spacing: float = 0.08             # minimum time between jump coins to follow the arc cleanly
@export_range(0.0, 0.45) var jump_sequence_edge_trim: float = 0.05  # trims edges so coins start/finish slightly above the lane

# Multi-obstacle wave configuration
@export var multi_obstacle_enabled: bool = true
@export var max_obstacles_per_wave: int = 3     # up to 3 lanes
@export var min_clear_lanes: int = 1            # keep at least this many lanes free

# Coin sequence configuration
@export var coin_sequence_min: int = 6           # minimum coins in a sequence (increased for more continuous collection)
@export var coin_sequence_max: int = 20          # maximum coins in a sequence (increased for longer sequences)

# Remember safe paths between waves
var _last_free_lanes: Array[int] = [0, 1, 2]    # lanes with no obstacle in the previous wave

var _next_spawn_time: float = 0.0
var _next_obstacle_spawn_time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _game_active: bool = true
var _speed_timer: float = 0.0
var _current_speed_multiplier: float = 1.0
var _current_lane: int = 0
var _coins_in_sequence: int = 0
var _current_sequence_length: int = 4            # Current sequence length (randomized)
var _recent_spawns: Array[Dictionary] = []  # Track recent spawns to prevent overlaps
var _player_jump_height: float = 90.0
var _player_jump_duration: float = 0.6
var _player_fixed_x: float = -400.0
var _current_coin_spacing: float = 0.1
var _current_coin_spacing_base: float = 0.1
var _current_sequence_is_jump_arc: bool = false
var _magnet_spawn_timer: float = 0.0
var _magnet_instance: Node = null
var _magnet_spawn_multiplier: float = 1.0

func _ready() -> void:
	_rng.randomize()
	_next_spawn_time = spawn_interval
	_next_obstacle_spawn_time = obstacle_spawn_interval
	_current_coin_spacing_base = coin_sequence_spacing
	_current_coin_spacing = coin_sequence_spacing
	
	# Maintain backwards compatibility with previously configured start_x values
	if coin_spawn_x == DEFAULT_COIN_SPAWN_X and start_x != DEFAULT_COIN_SPAWN_X:
		coin_spawn_x = start_x
	if obstacle_spawn_x == DEFAULT_OBSTACLE_SPAWN_X and start_x != DEFAULT_COIN_SPAWN_X:
		obstacle_spawn_x = max(obstacle_spawn_x, coin_spawn_x + 200.0)
	
	# Initialize coin sequence tracking
	_current_lane = _rng.randi_range(0, 2)
	
	# Initialize parallax scroller speed
	var parallax = get_parent().get_node("ParallaxScroller")
	if parallax and parallax.has_method("set"):
		parallax.set("scroll_speed", world_speed)
	
	# Connect to player signals
	var player = get_parent().get_node("Player")
	if player:
		_cache_player_parameters(player)
		if player.has_signal("player_died"):
			player.connect("player_died", Callable(self, "_on_player_died"))
			print("Connected to player death signal")
		if player.has_signal("lanes_updated"):
			player.connect("lanes_updated", Callable(self, "_on_lanes_updated"))
			print("Connected to player lanes signal")
		if player.has_signal("magnet_state_changed"):
			player.connect("magnet_state_changed", Callable(self, "_on_player_magnet_state_changed"))
			print("Connected to player magnet signal")
		
		# Get lanes directly if player already calculated them
		if player.has_method("get") and "lanes" in player:
			_on_lanes_updated(player.lanes)
	
	# Connect to touch controls for restart functionality
	var touch_controls = get_parent().get_node_or_null("CanvasLayer/TouchControls")
	if touch_controls and touch_controls.has_signal("restart_pressed"):
		touch_controls.connect("restart_pressed", Callable(self, "_on_touch_restart"))
		print("Connected to touch controls restart signal")

	_reset_coin_sequence(false)
	_schedule_next_magnet_spawn()
	
	print("Spawner ready! obstacle_scenes count: ", obstacle_scenes.size(), " coin_scene: ", coin_scene)
	print("Initial coin sequence length: ", _current_sequence_length)

func _on_lanes_updated(new_lanes: Array[float]) -> void:
	lanes_y = PackedFloat32Array(new_lanes)
	print("Spawner updated lanes: ", lanes_y)

func _cache_player_parameters(player: Node) -> void:
	if "jump_height" in player:
		_player_jump_height = max(0.0, float(player.jump_height))
	if "jump_duration" in player:
		_player_jump_duration = max(0.0, float(player.jump_duration))
	if "fixed_x" in player:
		_player_fixed_x = float(player.fixed_x)
	print("Cached player jump parameters -> height: ", _player_jump_height, " duration: ", _player_jump_duration, " fixed_x: ", _player_fixed_x)

func _reset_coin_sequence(switch_lane: bool) -> void:
	if switch_lane:
		var new_lane: int = _current_lane
		var attempts: int = 0
		while new_lane == _current_lane and attempts < 5:
			new_lane = _rng.randi_range(0, 2)
			attempts += 1
		_current_lane = new_lane
	_current_sequence_length = _rng.randi_range(coin_sequence_min, coin_sequence_max)
	_current_sequence_is_jump_arc = _should_spawn_jump_sequence()
	if _current_sequence_is_jump_arc:
		_configure_jump_sequence()
	else:
		_current_coin_spacing_base = coin_sequence_spacing
	_recalculate_coin_spacing()
	_coins_in_sequence = 0
	var sequence_type = "jump arc" if _current_sequence_is_jump_arc else "lane"
	print("Initialized ", sequence_type, " coin sequence of length ", _current_sequence_length, " on lane ", _current_lane)

func _should_spawn_jump_sequence() -> bool:
	if jump_sequence_chance <= 0.0:
		return false
	if _player_jump_duration <= 0.0 or _player_jump_height <= 0.0:
		return false
	if jump_sequence_chance >= 1.0:
		return true
	return _rng.randf() <= jump_sequence_chance

func _configure_jump_sequence() -> void:
	if _player_jump_duration <= 0.0 or _player_jump_height <= 0.0:
		_current_sequence_is_jump_arc = false
		_current_coin_spacing_base = coin_sequence_spacing
		_recalculate_coin_spacing()
		return
	var min_length: int = 3
	var max_length: int = coin_sequence_max
	if jump_sequence_min_spacing > 0.0:
		var max_by_spacing: int = int(floor(_player_jump_duration / jump_sequence_min_spacing)) + 1
		max_by_spacing = max(max_by_spacing, min_length)
		max_length = min(max_length, max_by_spacing)
	else:
		max_length = max(max_length, min_length)
	_current_sequence_length = clamp(_current_sequence_length, min_length, max_length)
	if _current_sequence_length <= 1:
		_current_sequence_length = 2
	var base_spacing: float = _player_jump_duration / max(1, _current_sequence_length - 1)
	if jump_sequence_min_spacing > 0.0:
		base_spacing = max(jump_sequence_min_spacing, base_spacing)
	_current_coin_spacing_base = base_spacing
	_recalculate_coin_spacing()

func _get_coin_spawn_y(lane_idx: int, coin_index: int) -> float:
	if lane_idx < 0 or lane_idx >= lanes_y.size():
		return 0.0
	var base_y: float = lanes_y[lane_idx]
	if not _current_sequence_is_jump_arc:
		return base_y
	var sequence_length: int = max(_current_sequence_length, 2)
	var progress: float = 0.5
	if sequence_length > 1:
		progress = float(coin_index) / float(sequence_length - 1)
	var trim: float = clamp(jump_sequence_edge_trim, 0.0, 0.45)
	if trim > 0.0 and sequence_length > 1:
		progress = lerp(trim, 1.0 - trim, progress)
	var offset: float = _sample_jump_offset(progress)
	return base_y + offset

func _sample_jump_offset(progress: float) -> float:
	if _player_jump_duration <= 0.0 or _player_jump_height <= 0.0:
		return 0.0
	var clamped: float = clamp(progress, 0.0, 1.0)
	var total_duration: float = _player_jump_duration
	var half_duration: float = total_duration * 0.5
	var t: float = clamped * total_duration
	if half_duration <= 0.0:
		return -_player_jump_height
	if t <= half_duration:
		var normalized: float = t / half_duration
		var easing: float = sin(normalized * PI * 0.5)
		return -_player_jump_height * easing
	var normalized_down: float = (t - half_duration) / half_duration
	var easing_down: float = cos(normalized_down * PI * 0.5)
	return -_player_jump_height * easing_down

func _get_effective_speed() -> float:
	return world_speed * _current_speed_multiplier

func _recalculate_coin_spacing() -> void:
	var multiplier: float = max(_magnet_spawn_multiplier, 1.0)
	if multiplier <= 0.0:
		multiplier = 1.0
	_current_coin_spacing = max(0.05, _current_coin_spacing_base / multiplier)

func _process(delta: float) -> void:
	if not _game_active:
		return
	
	# Update speed progression timer
	_speed_timer += delta
	if _speed_timer >= speed_increase_interval:
		_speed_timer = 0.0
		_current_speed_multiplier *= speed_increase_rate
		print("Speed increased! New multiplier: ", _current_speed_multiplier, " Effective speed: ", world_speed * _current_speed_multiplier)
		
		# Update parallax scroller speed
		var parallax = get_parent().get_node("ParallaxScroller")
		if parallax and parallax.has_method("set"):
			parallax.set("scroll_speed", world_speed * _current_speed_multiplier)
		
	_next_spawn_time -= delta
	if _next_spawn_time <= 0.0:
		_spawn_coin()
		# Use shorter interval for coin sequences
		_next_spawn_time = _current_coin_spacing
	
	# Handle obstacle spawning separately
	_next_obstacle_spawn_time -= delta
	if _next_obstacle_spawn_time <= 0.0:
		if _rng.randf() <= obstacle_chance:
			if multi_obstacle_enabled:
				_spawn_obstacle_wave()
			else:
				_spawn_single_obstacle()
		_next_obstacle_spawn_time = obstacle_spawn_interval
	
	# Handle magnet spawn scheduling
	_process_magnet_spawn(delta)

func _spawn_coin() -> void:
	if lanes_y.size() != 3:
		print("Warning: lanes_y size is ", lanes_y.size(), " but expected 3")
		return

	# Check if we need to switch lanes (after completing a sequence)
	if _coins_in_sequence >= _current_sequence_length:
		_reset_coin_sequence(true)

	var lane_idx: int = _current_lane
	var coin_index: int = _coins_in_sequence

	var spawn_y: float = _get_coin_spawn_y(lane_idx, coin_index)

	var sequence_type: String = "jump arc" if _current_sequence_is_jump_arc else "lane"
	
	# Check for overlaps before spawning
	if _would_overlap(coin_spawn_x, spawn_y, coin_collision_radius, "coin"):
		print("Skipping coin spawn due to overlap at lane ", lane_idx, " for ", sequence_type, " sequence")
		return
	
	_coins_in_sequence += 1
	
	var scene: PackedScene = coin_scene
	
	if scene == null:
		print("Coin scene is null!")
		return

	print("Spawning coin ", _coins_in_sequence, "/", _current_sequence_length, " at lane ", lane_idx, " (y=", spawn_y, ") type: ", sequence_type)
	
	var inst: Node = scene.instantiate()
	if !(inst is Node2D):
		print("Instantiated object is not Node2D!")
		return

	var n2d: Node2D = inst as Node2D
	n2d.position = Vector2(coin_spawn_x, spawn_y)

	# Pass current effective world speed into spawned node if it has 'speed'
	var effective_speed = _get_effective_speed()
	if inst.has_method("set") and "speed" in inst:
		inst.set("speed", effective_speed)

	# Connect signals for coins
	if inst.has_signal("collected"):
		inst.connect("collected", Callable(self, "_on_coin_collected"))

	# Track this spawn
	_track_spawn(coin_spawn_x, spawn_y, "coin", coin_collision_radius, effective_speed)

	get_parent().add_child(inst)
	print("Successfully spawned and added coin to scene tree")


func _spawn_single_obstacle() -> void:
	if lanes_y.size() != 3:
		print("Warning: lanes_y size is ", lanes_y.size(), " but expected 3")
		return
	if obstacle_scenes.size() == 0:
		print("No obstacle scenes available!")
		return
	var lane_idx: int = _rng.randi_range(0, 2)
	var spawn_y: float = lanes_y[lane_idx]
	if _would_overlap(obstacle_spawn_x, spawn_y, obstacle_collision_radius, "obstacle"):
		print("Skipping obstacle spawn due to overlap at lane ", lane_idx)
		return
	var obstacle_idx = _rng.randi_range(0, obstacle_scenes.size() - 1)
	var scene = obstacle_scenes[obstacle_idx]
	print("Selected obstacle type ", obstacle_idx, " from ", obstacle_scenes.size(), " types")
	if scene == null:
		print("Obstacle scene is null!")
		return
	print("Spawning obstacle at lane ", lane_idx, " (y=", lanes_y[lane_idx], ")")
	var inst: Node = scene.instantiate()
	if !(inst is Node2D):
		print("Instantiated object is not Node2D!")
		return
	var n2d: Node2D = inst as Node2D
	n2d.position = Vector2(obstacle_spawn_x, spawn_y)
	var effective_speed = _get_effective_speed()
	if inst.has_method("set") and "speed" in inst:
		inst.set("speed", effective_speed)
	if inst.has_signal("hit_player"):
		inst.connect("hit_player", Callable(self, "_on_hit_player"))
	_track_spawn(obstacle_spawn_x, spawn_y, "obstacle", obstacle_collision_radius, effective_speed)
	get_parent().add_child(inst)
	print("Successfully spawned and added obstacle to scene tree")

func _spawn_obstacle_wave() -> void:
	# Spawn 1..max_obstacles_per_wave obstacles at the same X across distinct lanes,
	# while ensuring at least `min_clear_lanes` lanes remain free and there is a safe path from the previous wave.
	if lanes_y.size() != 3:
		print("Warning: lanes_y size is ", lanes_y.size(), " but expected 3")
		return
	if obstacle_scenes.size() == 0:
		print("No obstacle scenes available!")
		return

	# Compute candidate lanes that don't overlap recent spawns at this X
	var candidates: Array[int] = []
	for lane in [0, 1, 2]:
		var lane_y = lanes_y[lane]
		if not _would_overlap(obstacle_spawn_x, lane_y, obstacle_collision_radius, "obstacle"):
			candidates.append(lane)

	if candidates.is_empty():
		print("Skipping wave: all lanes would overlap with recent spawns")
		return

	# We can block at most (3 - min_clear_lanes) lanes
	var max_blockable: int = clamp(3 - min_clear_lanes, 0, 3)
	var max_this_wave: int = clamp(max_obstacles_per_wave, 1, 3)
	var to_block_count: int = clamp(_rng.randi_range(1, max_this_wave), 1, max_blockable)

	# Choose lanes to block, but keep a continuous safe path with the previous wave
	candidates.shuffle()
	var blocked_lanes: Array[int] = []
	for lane in candidates:
		if blocked_lanes.size() >= to_block_count:
			break
		blocked_lanes.append(lane)

	# Ensure at least one lane stays free
	var free_lanes: Array[int] = [0, 1, 2]
	for b in blocked_lanes:
		free_lanes.erase(b)
	if free_lanes.is_empty():
		# Free one lane at random to guarantee possibility
		var freed: int = blocked_lanes.pop_back()
		print("Freed lane ", freed, " to keep a path")
		free_lanes = [0, 1, 2]
		for b in blocked_lanes:
			free_lanes.erase(b)

	# Maintain continuity: keep at least one lane free that was also free in the last wave
	var intersection: Array[int] = []
	for l in free_lanes:
		if l in _last_free_lanes:
			intersection.append(l)
	if intersection.is_empty():
		# Force continuity by freeing one of the previously-free lanes if it's currently blocked
		for l in _last_free_lanes:
			if l in blocked_lanes:
				blocked_lanes.erase(l)
				free_lanes.append(l)
				print("Adjusted wave to keep continuous safe lane ", l)
				break

	# Final spawn across blocked lanes
	var effective_speed: float = _get_effective_speed()
	for lane_idx in blocked_lanes:
		var obstacle_idx = _rng.randi_range(0, obstacle_scenes.size() - 1)
		var scene = obstacle_scenes[obstacle_idx]
		if scene == null:
			continue
		var inst: Node = scene.instantiate()
		if !(inst is Node2D):
			continue
		var n2d: Node2D = inst as Node2D
		var spawn_y: float = lanes_y[lane_idx]
		n2d.position = Vector2(obstacle_spawn_x, spawn_y)
		if inst.has_method("set") and "speed" in inst:
			inst.set("speed", effective_speed)
		if inst.has_signal("hit_player"):
			inst.connect("hit_player", Callable(self, "_on_hit_player"))
		_track_spawn(obstacle_spawn_x, spawn_y, "obstacle", obstacle_collision_radius, effective_speed)
		get_parent().add_child(inst)
		print("Spawned obstacle in wave at lane ", lane_idx)

	# Update last free lanes for the next wave
	_last_free_lanes = [0, 1, 2]
	for b in blocked_lanes:
		_last_free_lanes.erase(b)

func _process_magnet_spawn(delta: float) -> void:
	if magnet_scene == null:
		return
	if _magnet_instance != null:
		return
	if magnet_spawn_max_interval <= 0.0:
		return
	_magnet_spawn_timer -= delta
	if _magnet_spawn_timer <= 0.0:
		_spawn_magnet_star()

func _spawn_magnet_star() -> void:
	if magnet_scene == null:
		return
	var attempts: int = 0
	var spawn_y: float = 0.0
	var valid_position: bool = false
	while attempts < 6 and not valid_position:
		spawn_y = _get_magnet_spawn_y()
		valid_position = not _would_overlap(obstacle_spawn_x, spawn_y, magnet_collision_radius, "magnet")
		attempts += 1
	if not valid_position:
		print("Skipping magnet spawn due to overlap")
		_schedule_next_magnet_spawn()
		return
	var inst: Node = magnet_scene.instantiate()
	if !(inst is Node2D):
		print("Magnet scene is not Node2D!")
		return
	var node: Node2D = inst as Node2D
	var spawn_x: float = obstacle_spawn_x + 160.0
	node.position = Vector2(spawn_x, spawn_y)
	var effective_speed: float = _get_effective_speed()
	var horizontal_speed: float = max(80.0, effective_speed * magnet_horizontal_speed_factor)
	if inst.has_method("set_horizontal_speed"):
		inst.set_horizontal_speed(horizontal_speed)
	inst.magnet_duration = magnet_effect_duration
	inst.spawn_multiplier = magnet_coin_spawn_multiplier
	if inst.has_signal("collected"):
		inst.connect("collected", Callable(self, "_on_magnet_star_collected"))
	if inst.has_signal("finished"):
		inst.connect("finished", Callable(self, "_on_magnet_star_finished"))
	_magnet_instance = inst
	_track_spawn(spawn_x, spawn_y, "magnet", magnet_collision_radius, horizontal_speed)
	get_parent().add_child(inst)
	print("Spawned magnet star at ", spawn_x, ", ", spawn_y)
	_schedule_next_magnet_spawn()

func _get_magnet_spawn_y() -> float:
	var view_rect: Rect2i = get_viewport().get_visible_rect()
	var top: float = view_rect.position.y + magnet_spawn_y_margin
	var bottom: float = view_rect.position.y + view_rect.size.y - magnet_spawn_y_margin
	if lanes_y.size() > 0:
		var min_lane: float = lanes_y[0]
		var max_lane: float = lanes_y[0]
		for lane_val in lanes_y:
			min_lane = min(min_lane, lane_val)
			max_lane = max(max_lane, lane_val)
		top = clamp(min_lane - magnet_spawn_y_margin, view_rect.position.y, view_rect.position.y + view_rect.size.y - magnet_spawn_y_margin)
		bottom = clamp(max_lane + magnet_spawn_y_margin, top + 1.0, view_rect.position.y + view_rect.size.y)
	if bottom <= top:
		bottom = top + 1.0
	return _rng.randf_range(top, bottom)

func _on_magnet_star_collected(_duration: float, _multiplier: float) -> void:
	print("Magnet star collected!")

func _on_magnet_star_finished() -> void:
	_magnet_instance = null

func _schedule_next_magnet_spawn() -> void:
	if magnet_scene == null or magnet_spawn_max_interval <= 0.0:
		_magnet_spawn_timer = 0.0
		return
	var min_interval: float = min(magnet_spawn_min_interval, magnet_spawn_max_interval)
	var max_interval: float = max(magnet_spawn_min_interval, magnet_spawn_max_interval)
	min_interval = max(1.0, min_interval)
	max_interval = max(min_interval, max_interval)
	_magnet_spawn_timer = _rng.randf_range(min_interval, max_interval)
	print("Next magnet spawn in ", _magnet_spawn_timer, " seconds")

func _would_overlap(spawn_x: float, spawn_y: float, radius: float, type: String = "") -> bool:
	# Clean up old spawns that have moved far enough away
	_cleanup_old_spawns()
	# Check if any recent spawn is too close
	for spawn_data in _recent_spawns:
		var other_type: String = String(spawn_data.get("type", ""))
		if type == "coin" and other_type == "coin":
			continue
		var dx: float = abs(spawn_x - float(spawn_data.get("x_position", spawn_x)))
		var dy: float = abs(spawn_y - float(spawn_data.get("y_position", spawn_y)))
		var other_radius: float = float(spawn_data.get("radius", 0.0))
		var horizontal_threshold: float = min_spawn_distance + radius + other_radius
		var vertical_threshold: float = vertical_overlap_threshold + radius + other_radius
		if dx <= horizontal_threshold and dy <= vertical_threshold:
			return true
	return false

func _track_spawn(spawn_x: float, spawn_y: float, type: String, radius: float, speed: float) -> void:
	var spawn_data: Dictionary = {
		"x_position": spawn_x,
		"y_position": spawn_y,
		"type": type,
		"radius": radius,
		"speed": speed,
		"spawn_time": Time.get_unix_time_from_system()
	}
	_recent_spawns.append(spawn_data)

func _cleanup_old_spawns() -> void:
	# Remove spawns that have moved far enough left that they won't cause overlaps
	var cleanup_distance = min_spawn_distance * 2.0  # Extra buffer
	var reference_spawn_x = min(coin_spawn_x, obstacle_spawn_x)
	var left_bound = reference_spawn_x - cleanup_distance
	_recent_spawns = _recent_spawns.filter(func(spawn_data):
		var speed: float = float(spawn_data.get("speed", _get_effective_speed()))
		var estimated_current_x = float(spawn_data.get("x_position", reference_spawn_x)) - (speed * 2.0)  # Estimate 2 seconds of movement
		return estimated_current_x > left_bound
	)

func _on_player_magnet_state_changed(active: bool) -> void:
	if active:
		_magnet_spawn_multiplier = max(1.0, magnet_coin_spawn_multiplier)
		print("Spawner received magnet activation. Applying coin spawn multiplier ", _magnet_spawn_multiplier)
	else:
		_magnet_spawn_multiplier = 1.0
		print("Spawner received magnet end. Resetting coin spawn multiplier")
	_recalculate_coin_spacing()
	_next_spawn_time = min(_next_spawn_time, _current_coin_spacing)

func _on_coin_collected() -> void:
	print("Spawner received coin collected signal")
	# Tell the HUD to add coin score (HUD is now in CanvasLayer)
	var hud = get_parent().get_node("CanvasLayer/HUD")
	if hud and hud.has_method("add_coin_score"):
		hud.add_coin_score()
		print("Added coin score to HUD")
	else:
		print("Could not find HUD or add_coin_score method")
	# TODO: tell a GameManager to add score
	# get_tree().call_group("hud", "add_score", 1)

func _on_hit_player() -> void:
	print("Spawner received hit_player signal")
	# Find the player in the scene and trigger death
	var player = get_parent().get_node("Player")
	if player and player.has_method("take_damage"):
		player.take_damage()
		print("Player hit by obstacle - calling take_damage()")
	elif player and player.has_method("die"):
		player.die()
		print("Player hit by obstacle - calling die() directly")
	else:
		print("Could not find player or damage methods")

func _on_player_died() -> void:
	_game_active = false
	print("Game over! Player died. Press R, SPACE, or ENTER to restart.")
	
	# Show restart instruction
	get_tree().paused = false  # Ensure we can still process input

func _unhandled_input(event: InputEvent) -> void:
	if not _game_active and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_restart_game()

func _on_touch_restart() -> void:
	if not _game_active:
		print("Touch restart detected")
		_restart_game()

func _restart_game() -> void:
	print("Restarting game...")
	
	# Reset speed progression
	_speed_timer = 0.0
	_current_speed_multiplier = 1.0
	
	# Reset coin sequence tracking
	_current_lane = _rng.randi_range(0, 2)
	_reset_coin_sequence(false)
	
	# Reset spawn timers
	_next_spawn_time = spawn_interval
	_next_obstacle_spawn_time = obstacle_spawn_interval
	
	# Clear spawn tracking
	_recent_spawns.clear()
	
	# Reset HUD before reloading scene
	var hud = get_parent().get_node("CanvasLayer/HUD")
	if hud and hud.has_method("reset_game"):
		hud.reset_game()
		print("HUD reset for new game")
	
	get_tree().reload_current_scene()
