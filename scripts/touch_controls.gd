# TouchControls.gd
extends Control

@export var swipe_threshold: float = 50.0  # Minimum distance for swipe detection
@export var tap_max_duration: float = 0.3  # Maximum time for tap (vs hold)
@export var debug_mode: bool = false  # Show debug overlay

signal lane_up_pressed
signal lane_down_pressed
signal pause_pressed
signal restart_pressed

var touch_start_pos: Vector2
var touch_start_time: float
var is_touching: bool = false
var last_tap_time: float = 0.0
var double_tap_threshold: float = 0.5  # Maximum time between taps for double-tap
var is_game_over: bool = false  # Track game state

func _ready() -> void:
	print("TouchControls _ready() called on platform: ", OS.get_name())
	
	# Make this control cover the entire screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# CRITICAL: Enable input processing for this control and make it work during pause
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't interfere with UI buttons
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when paused
	set_process_input(true)
	set_process_unhandled_input(true)
	
	# CRITICAL: Set highest priority to ensure touch controls get input first
	process_priority = 1000  # Higher than pause menu
	
	print("TouchControls size: ", size, " position: ", position)
	
	# Wait a frame for the mobile manager to be ready
	await get_tree().process_frame
	
	# Configure visibility based on mobile manager
	if has_node("/root/MobileManager"):
		var mobile_manager = get_node("/root/MobileManager")
		print("Mobile manager found. Is mobile: ", mobile_manager.is_mobile())
		if mobile_manager.is_mobile():
			visible = true
			print("Touch controls enabled")
		else:
			visible = false
			print("Touch controls hidden for desktop")
	else:
		# Fallback to OS detection if mobile manager not available
		var is_mobile = OS.get_name() in ["Android", "iOS"]
		print("Mobile manager not found. Direct OS detection: ", is_mobile)
		if is_mobile:
			visible = true
		else:
			visible = false
		print("Touch controls initialized (fallback mode) for platform: ", OS.get_name())
	
	print("TouchControls final visibility: ", visible)
	print("TouchControls final size: ", size)
	print("TouchControls mouse_filter: ", mouse_filter)
	
	# Enable debug mode on Android for testing
	if OS.get_name() == "Android":
		debug_mode = true
		if debug_mode:
			print("Debug mode enabled for Android")
	
	# Connect to HUD game over signal if available
	await get_tree().process_frame
	_connect_to_hud()

func _connect_to_hud() -> void:
	# Look for HUD in the scene tree
	var world = get_parent().get_parent()  # TouchControlsLayer -> World
	if world:
		var hud = world.get_node_or_null("CanvasLayer/HUD")
		if hud and hud.has_signal("game_over"):
			hud.game_over.connect(_on_game_over)
			print("TouchControls connected to HUD game_over signal")
			
			# Connect our restart signal to the HUD if it has a method to handle it
			if hud.has_method("_input"):
				restart_pressed.connect(_on_touch_restart_pressed)
				print("TouchControls restart signal connected")
		else:
			print("HUD not found or doesn't have game_over signal")

func _on_touch_restart_pressed() -> void:
	# Handle touch restart by simulating input event
	if is_game_over:
		print("Touch restart - reloading scene")
		get_tree().reload_current_scene()

func _on_game_over(_final_score: int, _time_survived: float) -> void:
	is_game_over = true
	print("TouchControls: Game over detected")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		print("Mouse entered TouchControls")
	elif what == NOTIFICATION_WM_MOUSE_EXIT:
		print("Mouse exited TouchControls")

func _gui_input(_event: InputEvent) -> void:
	# Disabled - we use _unhandled_input instead to avoid conflicts with UI buttons
	pass

func _input(_event: InputEvent) -> void:
	# Only handle touch events that don't hit UI buttons
	# Let UI buttons process their events first
	pass

func _unhandled_input(event: InputEvent) -> void:
	# Handle touch events that weren't processed by UI buttons
	if not visible:
		return
		
	print("_unhandled_input called with event: ", event.get_class())
	
	# Check if this touch is on a UI area first - if so, don't handle it
	var is_on_ui = false
	if event is InputEventScreenTouch:
		is_on_ui = _is_touch_on_ui_area(event.position)
	elif event is InputEventMouseButton:
		is_on_ui = _is_touch_on_ui_area(event.position)
	
	if is_on_ui:
		print("Touch is on UI area - not handling in touch controls")
		return
	
	if event is InputEventScreenTouch:
		print("Screen touch detected in _unhandled_input")
		_handle_touch(event)
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		print("Mouse button detected in _unhandled_input (touch emulation)")
		# Convert mouse button to touch event for consistent handling
		var touch_event = InputEventScreenTouch.new()
		touch_event.pressed = event.pressed
		touch_event.position = event.position
		_handle_touch(touch_event)
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()
	elif event is InputEventScreenDrag:
		print("Screen drag detected in _unhandled_input")
		_handle_drag(event)
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Touch started
		touch_start_pos = event.position
		touch_start_time = Time.get_ticks_msec() / 1000.0
		is_touching = true
		print("Touch started at: ", touch_start_pos, " Game over: ", is_game_over, " Paused: ", get_tree().paused)
		
		# PRIORITY 1: Check for pause/restart gesture (top-right corner tap)
		var screen_size = get_viewport().get_visible_rect().size
		var top_right_area = Rect2(screen_size.x * 0.8, 0, screen_size.x * 0.2, screen_size.y * 0.2)
		if top_right_area.has_point(event.position):
			print("Top-right area tapped")
			
			# Check for double-tap (restart) vs single tap (pause)
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_tap_time < double_tap_threshold:
				print("Double-tap detected - restart!")
				_trigger_restart()
			else:
				print("Single tap - pause!")
				_trigger_pause()
			
			last_tap_time = current_time
			return
		
		# PRIORITY 2: For game over and pause states, only handle areas outside UI
		# (UI buttons will handle their own touch events)
		# This provides a fallback for empty areas in case buttons are missed
		if is_game_over and not _is_touch_on_ui_area(event.position):
			print("Game over detected - touch outside UI restarts game")
			get_tree().reload_current_scene()
			return
		elif get_tree().paused and not _is_touch_on_ui_area(event.position):
			print("Game paused - touch outside UI resumes game")
			_trigger_pause()  # This will handle resume
			return
	else:
		# Touch ended
		if is_touching:
			_handle_touch_end(event)
		is_touching = false

func _is_touch_on_ui_area(touch_pos: Vector2) -> bool:
	# Check if touch position is within any visible UI areas
	var world = get_parent().get_parent()  # TouchControlsLayer -> World
	if not world:
		print("Touch UI check: No world found")
		return false
	
	# Check pause menu
	var pause_menu = world.get_node_or_null("CanvasLayer/PauseMenu")
	if pause_menu and pause_menu.visible:
		var pause_panel = pause_menu.get_node_or_null("PausePanel")
		if pause_panel and pause_panel.visible:
			var global_rect = pause_panel.get_global_rect()
			if global_rect.has_point(touch_pos):
				print("Touch UI check: Touch on pause menu at ", touch_pos)
				return true
	
	# Check game over overlay
	var hud = world.get_node_or_null("CanvasLayer/HUD")
	if hud:
		var game_over_overlay = hud.get_node_or_null("GameOverOverlay")
		if game_over_overlay and game_over_overlay.visible:
			var game_over_panel = game_over_overlay.get_node_or_null("GameOverPanel")
			if game_over_panel and game_over_panel.visible:
				var global_rect = game_over_panel.get_global_rect()
				print("Touch UI check: Game over panel rect: ", global_rect, " Touch pos: ", touch_pos)
				if global_rect.has_point(touch_pos):
					print("Touch UI check: Touch on game over menu at ", touch_pos)
					return true
	
	print("Touch UI check: Touch not on UI at ", touch_pos)
	return false

func _handle_drag(event: InputEventScreenDrag) -> void:
	if not is_touching:
		return
		
	var drag_distance = event.position - touch_start_pos
	var drag_magnitude = drag_distance.length()
	
	# Only process significant drags
	if drag_magnitude > swipe_threshold:
		# Vertical swipe detection
		if abs(drag_distance.y) > abs(drag_distance.x):
			if drag_distance.y < 0:  # Swipe up
				print("Swipe up detected")
				_trigger_lane_up()
			else:  # Swipe down
				print("Swipe down detected")
				_trigger_lane_down()
			
			# Reset touch to prevent multiple triggers
			is_touching = false

func _handle_touch_end(event: InputEventScreenTouch) -> void:
	var touch_duration = (Time.get_ticks_msec() / 1000.0) - touch_start_time
	var touch_distance = event.position.distance_to(touch_start_pos)
	
	print("Touch ended - Duration: ", touch_duration, " Distance: ", touch_distance)
	
	# If it was a quick tap (not a drag), treat as lane change based on screen position
	if touch_duration < tap_max_duration and touch_distance < swipe_threshold:
		var screen_center_y = get_viewport().get_visible_rect().size.y * 0.5
		
		print("Quick tap detected - Center Y: ", screen_center_y, " Touch Y: ", event.position.y)
		
		if event.position.y < screen_center_y:
			print("Tap up detected")
			_trigger_lane_up()
		else:
			print("Tap down detected")
			_trigger_lane_down()

func _trigger_lane_up() -> void:
	print("Touch: Lane up triggered - Platform: ", OS.get_name())
	if has_node("/root/MobileManager"):
		get_node("/root/MobileManager").trigger_haptic_light()
	lane_up_pressed.emit()

func _trigger_lane_down() -> void:
	print("Touch: Lane down triggered - Platform: ", OS.get_name())
	if has_node("/root/MobileManager"):
		get_node("/root/MobileManager").trigger_haptic_light()
	lane_down_pressed.emit()

func _trigger_pause() -> void:
	print("Touch: Pause triggered - Platform: ", OS.get_name())
	if has_node("/root/MobileManager"):
		get_node("/root/MobileManager").trigger_haptic_medium()
	pause_pressed.emit()

func _trigger_restart() -> void:
	print("Touch: Restart triggered - Platform: ", OS.get_name())
	if has_node("/root/MobileManager"):
		get_node("/root/MobileManager").trigger_haptic_medium()
	
	# If game is over or paused, restart the scene
	if is_game_over or get_tree().paused:
		print("Restarting scene due to game over or pause state")
		is_game_over = false
		get_tree().paused = false
		get_tree().reload_current_scene()
	else:
		# Emit restart signal for other systems to handle
		restart_pressed.emit()

# Public functions for external control (for compatibility)
func show_controls() -> void:
	visible = true

func hide_controls() -> void:
	visible = false

func set_opacity(_opacity: float) -> void:
	# This function exists for compatibility but doesn't do anything
	# since we're not using visible buttons anymore
	pass# Debug overlay
func _draw() -> void:
	if not debug_mode:
		return
		
	var screen_size = get_viewport().get_visible_rect().size
	
	# Draw debug areas
	# Pause area (top-right)
	var pause_area = Rect2(screen_size.x * 0.8, 0, screen_size.x * 0.2, screen_size.y * 0.2)
	draw_rect(pause_area, Color.YELLOW, false, 2)
	
	# Center line for tap zones
	draw_line(Vector2(0, screen_size.y * 0.5), Vector2(screen_size.x, screen_size.y * 0.5), Color.CYAN, 2)
	
	# Touch position if currently touching
	if is_touching:
		draw_circle(touch_start_pos, 20, Color.RED)
