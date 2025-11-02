# Spawner.gd
extends Node2D

@export var coin_scene: PackedScene
@export var obstacle_scenes: Array[PackedScene] = []  # Array of different obstacle types

@export var spawn_interval: float = 1.0         # base interval
@export var obstacle_chance: float = 0.7        # 70% obstacle, 30% coin
@export var start_x: float = 1200.0             # spawn X (offscreen right)
@export var world_speed: float = 260.0          # keep in sync with parallax
@export var lanes_y: PackedFloat32Array = []    # Will be set by player

@export var min_gap_px: float = 140.0           # ensure spacing between spawns
var _next_spawn_time: float = 0.0
var _rng := RandomNumberGenerator.new()
var _game_active: bool = true

func _ready() -> void:
	_rng.randomize()
	_next_spawn_time = spawn_interval
	print("Spawner ready! obstacle_scenes count: ", obstacle_scenes.size(), " coin_scene: ", coin_scene)
	
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
		
	_next_spawn_time -= delta
	if _next_spawn_time <= 0.0:
		_spawn_random()
		# small difficulty wobble
		_next_spawn_time = max(0.55, spawn_interval - _rng.randf_range(0.0, 0.25))

func _spawn_random() -> void:
	if lanes_y.size() != 3:
		print("Warning: lanes_y size is ", lanes_y.size(), " but expected 3")
		return

	# Prevent impossible overlaps by simple X-gap check
	# Note: This logic needs rework since start_x is fixed, but for now let's disable it
	# if _last_spawn_x > 0.0 and (start_x - _last_spawn_x) < min_gap_px:
	#	print("Skipping spawn due to gap check. Last spawn X: ", _last_spawn_x, " Current start X: ", start_x, " Gap: ", start_x - _last_spawn_x)
	#	return

	var lane_idx: int = _rng.randi_range(0, 2)
	var is_obstacle: bool = _rng.randf() <= obstacle_chance
	
	# If coin_scene is null, always spawn obstacles
	if coin_scene == null:
		is_obstacle = true
	
	var scene: PackedScene = null
	if is_obstacle:
		# Randomly select from available obstacle scenes
		if obstacle_scenes.size() > 0:
			var obstacle_idx = _rng.randi_range(0, obstacle_scenes.size() - 1)
			scene = obstacle_scenes[obstacle_idx]
			print("Selected obstacle type ", obstacle_idx, " from ", obstacle_scenes.size(), " types")
		else:
			print("No obstacle scenes available!")
			return
	else:
		scene = coin_scene
	
	if scene == null:
		print("Scene is null! is_obstacle: ", is_obstacle)
		return

	print("Spawning ", "obstacle" if is_obstacle else "coin", " at lane ", lane_idx, " (y=", lanes_y[lane_idx], ")")
	
	var inst := scene.instantiate()
	if !(inst is Node2D):
		print("Instantiated object is not Node2D!")
		return

	var n2d := inst as Node2D
	n2d.position = Vector2(start_x, lanes_y[lane_idx])

	# Pass world speed into spawned node if it has 'speed'
	if inst.has_method("set") and "speed" in inst:
		inst.set("speed", world_speed)

	# Connect signals (optional)
	if is_obstacle and inst.has_signal("hit_player"):
		inst.connect("hit_player", Callable(self, "_on_hit_player"))
	elif not is_obstacle and inst.has_signal("collected"):
		inst.connect("collected", Callable(self, "_on_coin_collected"))

	add_child(inst)
	print("Successfully spawned and added bee to scene tree")

func _on_coin_collected() -> void:
	print("Spawner received coin collected signal")
	# Tell the HUD to add coin score
	var hud = get_parent().get_node("HUD")
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

func _input(event: InputEvent) -> void:
	if not _game_active and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_restart_game()

func _restart_game() -> void:
	print("Restarting game...")
	
	# Reset HUD before reloading scene
	var hud = get_parent().get_node("HUD")
	if hud and hud.has_method("reset_game"):
		hud.reset_game()
		print("HUD reset for new game")
	
	get_tree().reload_current_scene()
