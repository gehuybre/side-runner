# Spawner.gd
extends Node2D

@export var coin_scene: PackedScene
@export var obstacle_scenes: Array[PackedScene] = []  # Array of different obstacle types

@export var spawn_interval: float = 1.0         # base interval
@export var start_x: float = 900.0              # spawn X (closer to screen for earlier visibility)
@export var world_speed: float = 1260.0          # canonical world speed from architecture docs 
@export var lanes_y: PackedFloat32Array = []    # Will be set by player

@export var min_gap_px: float = 140.0           # ensure spacing between spawns
@export var speed_increase_interval: float = 15.0  # increase speed every 15 seconds
@export var speed_increase_rate: float = 1.1    # multiply by 1.1 (10% increase)
@export var coin_sequence_length: int = 4       # base number of coins in sequence (will be randomized)
@export var coin_sequence_spacing: float = 0.1  # time between coins in sequence (faster for continuous collection)
@export var obstacle_spawn_interval: float = 1.2  # time between obstacle spawns (slightly longer for more coin time)
@export var obstacle_chance: float = 0.7        # 70% chance to spawn obstacle when interval is reached (reduced for more coin collection)

@export var min_spawn_distance: float = 150.0   # minimum distance between spawns to prevent overlap (reduced for denser gameplay)

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
var _rng := RandomNumberGenerator.new()
var _game_active: bool = true
var _speed_timer: float = 0.0
var _current_speed_multiplier: float = 1.0
var _current_lane: int = 0
var _coins_in_sequence: int = 0
var _current_sequence_length: int = 4            # Current sequence length (randomized)
var _recent_spawns: Array[Dictionary] = []  # Track recent spawns to prevent overlaps

func _ready() -> void:
	_rng.randomize()
	_next_spawn_time = spawn_interval
	_next_obstacle_spawn_time = obstacle_spawn_interval
	
	# Initialize coin sequence tracking
	_current_lane = _rng.randi_range(0, 2)
	_coins_in_sequence = 0
	_current_sequence_length = _rng.randi_range(coin_sequence_min, coin_sequence_max)
	
	print("Spawner ready! obstacle_scenes count: ", obstacle_scenes.size(), " coin_scene: ", coin_scene)
	print("Initial coin sequence length: ", _current_sequence_length)
	
	# Initialize parallax scroller speed
	var parallax = get_parent().get_node("ParallaxScroller")
	if parallax and parallax.has_method("set"):
		parallax.set("scroll_speed", world_speed)
	
	# Connect to player signals
	var player = get_parent().get_node("Player")
	if player:
		if player.has_signal("player_died"):
			player.connect("player_died", Callable(self, "_on_player_died"))
			print("Connected to player death signal")
		if player.has_signal("lanes_updated"):
			player.connect("lanes_updated", Callable(self, "_on_lanes_updated"))
			print("Connected to player lanes signal")
		
		# Get lanes directly if player already calculated them
		if player.has_method("get") and "lanes" in player:
			_on_lanes_updated(player.lanes)

func _on_lanes_updated(new_lanes: Array[float]) -> void:
	lanes_y = PackedFloat32Array(new_lanes)
	print("Spawner updated lanes: ", lanes_y)

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
		_next_spawn_time = coin_sequence_spacing
	
	# Handle obstacle spawning separately
	_next_obstacle_spawn_time -= delta
	if _next_obstacle_spawn_time <= 0.0:
		if _rng.randf() <= obstacle_chance:
			if multi_obstacle_enabled:
				_spawn_obstacle_wave()
			else:
				_spawn_single_obstacle()
		_next_obstacle_spawn_time = obstacle_spawn_interval

func _spawn_coin() -> void:
	if lanes_y.size() != 3:
		print("Warning: lanes_y size is ", lanes_y.size(), " but expected 3")
		return

	# Check if we need to switch lanes (after completing a sequence)
	if _coins_in_sequence >= _current_sequence_length:
		_coins_in_sequence = 0
		# Generate new random sequence length for next sequence
		_current_sequence_length = _rng.randi_range(coin_sequence_min, coin_sequence_max)
		# Switch to a different lane
		var new_lane = _current_lane
		while new_lane == _current_lane:
			new_lane = _rng.randi_range(0, 2)
		_current_lane = new_lane
		print("Switched to lane ", _current_lane, " for new coin sequence of length ", _current_sequence_length)

	var lane_idx: int = _current_lane
	
	# Check for overlaps before spawning
	if _would_overlap(start_x, lane_idx):
		print("Skipping coin spawn due to overlap at lane ", lane_idx)
		return
	
	_coins_in_sequence += 1
	
	var scene: PackedScene = coin_scene
	
	if scene == null:
		print("Coin scene is null!")
		return

	print("Spawning coin ", _coins_in_sequence, "/", _current_sequence_length, " at lane ", lane_idx, " (y=", lanes_y[lane_idx], ")")
	
	var inst := scene.instantiate()
	if !(inst is Node2D):
		print("Instantiated object is not Node2D!")
		return

	var n2d := inst as Node2D
	n2d.position = Vector2(start_x, lanes_y[lane_idx])

	# Pass current effective world speed into spawned node if it has 'speed'
	var effective_speed = world_speed * _current_speed_multiplier
	if inst.has_method("set") and "speed" in inst:
		inst.set("speed", effective_speed)

	# Connect signals for coins
	if inst.has_signal("collected"):
		inst.connect("collected", Callable(self, "_on_coin_collected"))

	# Track this spawn
	_track_spawn(start_x, lane_idx, "coin")

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
	if _would_overlap(start_x, lane_idx):
		print("Skipping obstacle spawn due to overlap at lane ", lane_idx)
		return
	var obstacle_idx = _rng.randi_range(0, obstacle_scenes.size() - 1)
	var scene = obstacle_scenes[obstacle_idx]
	print("Selected obstacle type ", obstacle_idx, " from ", obstacle_scenes.size(), " types")
	if scene == null:
		print("Obstacle scene is null!")
		return
	print("Spawning obstacle at lane ", lane_idx, " (y=", lanes_y[lane_idx], ")")
	var inst := scene.instantiate()
	if !(inst is Node2D):
		print("Instantiated object is not Node2D!")
		return
	var n2d := inst as Node2D
	n2d.position = Vector2(start_x, lanes_y[lane_idx])
	var effective_speed = world_speed * _current_speed_multiplier
	if inst.has_method("set") and "speed" in inst:
		inst.set("speed", effective_speed)
	if inst.has_signal("hit_player"):
		inst.connect("hit_player", Callable(self, "_on_hit_player"))
	_track_spawn(start_x, lane_idx, "obstacle")
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
		if not _would_overlap(start_x, lane):
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
	var effective_speed: float = world_speed * _current_speed_multiplier
	for lane_idx in blocked_lanes:
		var obstacle_idx = _rng.randi_range(0, obstacle_scenes.size() - 1)
		var scene = obstacle_scenes[obstacle_idx]
		if scene == null:
			continue
		var inst := scene.instantiate()
		if !(inst is Node2D):
			continue
		var n2d := inst as Node2D
		n2d.position = Vector2(start_x, lanes_y[lane_idx])
		if inst.has_method("set") and "speed" in inst:
			inst.set("speed", effective_speed)
		if inst.has_signal("hit_player"):
			inst.connect("hit_player", Callable(self, "_on_hit_player"))
		_track_spawn(start_x, lane_idx, "obstacle")
		get_parent().add_child(inst)
		print("Spawned obstacle in wave at lane ", lane_idx)

	# Update last free lanes for the next wave
	_last_free_lanes = [0, 1, 2]
	for b in blocked_lanes:
		_last_free_lanes.erase(b)

func _would_overlap(spawn_x: float, lane: int) -> bool:
	# Clean up old spawns that have moved far enough away
	_cleanup_old_spawns()
	# Check if any recent spawn in the same lane is too close
	for spawn_data in _recent_spawns:
		if int(spawn_data["lane"]) == lane:
			var distance = abs(spawn_x - float(spawn_data["x_position"]))
			if distance < min_spawn_distance:
				return true
	return false

func _track_spawn(spawn_x: float, lane: int, type: String) -> void:
	var spawn_data: Dictionary = {
		"x_position": spawn_x,
		"lane": lane,
		"type": type,
		"spawn_time": Time.get_time_dict_from_system()
	}
	_recent_spawns.append(spawn_data)

func _cleanup_old_spawns() -> void:
	# Remove spawns that have moved far enough left that they won't cause overlaps
	var effective_speed = world_speed * _current_speed_multiplier
	var cleanup_distance = min_spawn_distance * 2.0  # Extra buffer
	_recent_spawns = _recent_spawns.filter(func(spawn_data):
		var estimated_current_x = float(spawn_data["x_position"]) - (effective_speed * 2.0)  # Estimate 2 seconds of movement
		return estimated_current_x > (start_x - cleanup_distance)
	)

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

func _restart_game() -> void:
	print("Restarting game...")
	
	# Reset speed progression
	_speed_timer = 0.0
	_current_speed_multiplier = 1.0
	
	# Reset coin sequence tracking
	_current_lane = _rng.randi_range(0, 2)
	_coins_in_sequence = 0
	_current_sequence_length = _rng.randi_range(coin_sequence_min, coin_sequence_max)
	
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
