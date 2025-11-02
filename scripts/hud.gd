# HUD.gd
extends Control

@export var score_per_second: int = 1
@export var score_per_coin: int = 5

@onready var score_label: Label = $TopBar/ScoreContainer/ScoreLabel
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var final_score_label: Label = $GameOverOverlay/GameOverPanel/GameOverContainer/FinalScoreLabel

var time_score: int = 0  # Score from time alive
var coin_score: int = 0  # Score from coins collected
var total_score: int = 0 # Combined score
var time_alive: float = 0.0
var game_active: bool = true
var game_manager: Node = null
var high_score: int = 0
var is_new_high_score: bool = false

signal game_over(final_score: int, time_survived: float)

func _ready() -> void:
	print("HUD ready! Initial score: ", total_score)
	
	# Enable input processing for restart functionality
	set_process_input(true)
	
	# Ensure HUD can receive input properly, even on mobile
	mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when paused
	
	# Get reference to GameManager
	game_manager = get_node("/root/GameManager") if get_node_or_null("/root/GameManager") else null
	if game_manager:
		high_score = game_manager.get_high_score()
		print("Current high score: ", high_score)
	
	_update_display()
	
	# Make sure game over overlay is hidden
	if game_over_overlay:
		game_over_overlay.visible = false
	
	# Connect to spawner coin collection (HUD is now in CanvasLayer, so need to go up to world)
	var world = get_parent().get_parent()  # CanvasLayer -> World
	var spawner = world.get_node("Spawner")
	if spawner:
		# The spawner should connect coins to the HUD, but we can also listen for the signal
		print("HUD found spawner")
	
	# Connect to player death
	var player = world.get_node("Player")
	if player and player.has_signal("player_died"):
		player.connect("player_died", Callable(self, "_on_player_died"))
		print("HUD connected to player death signal")

func _process(delta: float) -> void:
	if not game_active:
		return
		
	# Add time-based score
	time_alive += delta
	var new_time_score = int(time_alive) * score_per_second
	
	# Only update if we've gained a full second
	if new_time_score != time_score:
		time_score = new_time_score
		total_score = time_score + coin_score
		_update_display()

func add_coin_score() -> void:
	coin_score += score_per_coin
	total_score = time_score + coin_score
	print("Coin collected! Coin score: +", score_per_coin, " Total score: ", total_score)
	_update_display()

func _update_display() -> void:
	if score_label:
		score_label.text = "Score: " + str(total_score) + "\nHigh: " + str(high_score)

func _on_player_died() -> void:
	game_active = false
	
	# Check for new high score
	if game_manager:
		is_new_high_score = game_manager.update_high_score(total_score)
		high_score = game_manager.get_high_score()
	
	print("Game Over! Final score: ", total_score, " (Time: ", time_score, " + Coins: ", coin_score, ") Time survived: ", time_alive, " seconds")
	if is_new_high_score:
		print("NEW HIGH SCORE!")
	
	game_over.emit(total_score, time_alive)
	
	# Show game over overlay with final score
	if game_over_overlay:
		game_over_overlay.visible = true
	if final_score_label:
		var score_text = "Final Score: " + str(total_score) + "\n(Time: " + str(time_score) + " + Coins: " + str(coin_score) + ")"
		if is_new_high_score:
			score_text += "\n\n🏆 NEW HIGH SCORE! 🏆"
		else:
			score_text += "\nHigh Score: " + str(high_score)
		final_score_label.text = score_text

func reset_game() -> void:
	time_score = 0
	coin_score = 0
	total_score = 0
	time_alive = 0.0
	game_active = true
	is_new_high_score = false
	
	# Refresh high score from game manager
	if game_manager:
		high_score = game_manager.get_high_score()
	
	# Hide game over overlay
	if game_over_overlay:
		game_over_overlay.visible = false
	
	_update_display()
	print("HUD reset for new game")

func _input(event: InputEvent) -> void:
	# Handle restart when game is over, but only for keyboard input
	# Touch inputs should be handled by touch controls
	if not game_active and game_over_overlay and game_over_overlay.visible:
		if event is InputEventKey and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
			print("Restart input detected in HUD")
			get_tree().reload_current_scene()

func _on_restart_button_pressed() -> void:
	print("Game over restart button pressed")
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	print("Game over quit button pressed - returning to main menu")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
