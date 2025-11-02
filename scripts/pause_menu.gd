# PauseMenu.gd
extends Control

var is_paused: bool = false
var touch_controls: Control = null

signal resume_game
signal return_to_main_menu

func _ready() -> void:
	print("Pause menu ready")
	# IMPORTANT: Use ALWAYS process mode so we can detect pause input even when game is running
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	# Make sure this node has lower priority than touch controls
	process_priority = 50  # Lower than touch controls (1000)
	# Make sure the pause menu can receive input even when hidden
	set_process_input(true)
	hide()
	
	# Connect to touch controls if available
	_connect_touch_controls()

func _connect_touch_controls() -> void:
	# Look for touch controls in the scene tree
	var world = get_parent().get_parent()  # CanvasLayer -> World
	if world:
		touch_controls = world.get_node_or_null("TouchControlsLayer/TouchControls")
		if not touch_controls:
			# Try alternative paths for backward compatibility
			touch_controls = world.get_node_or_null("CanvasLayer/TouchControls")
			if not touch_controls:
				touch_controls = world.get_node_or_null("UI/TouchControls")
				if not touch_controls:
					touch_controls = world.get_node_or_null("TouchControls")
		
		if touch_controls:
			touch_controls.pause_pressed.connect(_on_touch_pause)
			print("Pause menu connected to touch controls")
		else:
			print("No touch controls found for pause menu")

func _input(event: InputEvent) -> void:
	# Only handle keyboard pause, let touch controls handle touch events
	if event is InputEventKey and event.is_action_pressed("pause"):
		print("Pause input detected - Pause action pressed")
		if is_paused:
			_resume_game()
		else:
			_pause_game()
		# Accept the event to prevent it from being handled elsewhere
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()

# Touch input handler
func _on_touch_pause() -> void:
	print("Touch pause detected")
	if is_paused:
		_resume_game()
	else:
		_pause_game()

func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	show()
	print("Game paused")

func _resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	hide()
	resume_game.emit()
	print("Game resumed")

func _on_resume_button_pressed() -> void:
	_resume_game()

func _on_quit_button_pressed() -> void:
	print("Returning to main menu...")
	get_tree().paused = false
	return_to_main_menu.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")