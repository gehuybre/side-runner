# MainMenu.gd
extends Control

var mobile_mode_toggle: CheckBox

func _ready() -> void:
	print("Main Menu loaded")
	_setup_mobile_options()

func _setup_mobile_options() -> void:
	# Add mobile mode toggle if we're not on mobile
	if has_node("/root/MobileManager"):
		var mobile_manager = get_node("/root/MobileManager")
		if not mobile_manager.is_mobile():
			_add_mobile_toggle()

func _add_mobile_toggle() -> void:
	# Find the VBox container with buttons
	var buttons_container = find_child("VBoxContainer", true, false)
	if buttons_container:
		# Add a separator and mobile toggle
		var separator = HSeparator.new()
		buttons_container.add_child(separator)
		
		mobile_mode_toggle = CheckBox.new()
		mobile_mode_toggle.text = "Touch Controls (for testing mobile)"
		mobile_mode_toggle.toggled.connect(_on_mobile_toggle_changed)
		buttons_container.add_child(mobile_mode_toggle)

func _on_mobile_toggle_changed(enabled: bool) -> void:
	if has_node("/root/MobileManager"):
		var mobile_manager = get_node("/root/MobileManager")
		if enabled:
			mobile_manager.enable_mobile_mode()
		else:
			mobile_manager.disable_mobile_mode()
		print("Mobile mode toggled: ", enabled)

func _on_start_button_pressed() -> void:
	print("Starting game...")
	get_tree().change_scene_to_file("res://scenes/world-1.tscn")

func _on_options_button_pressed() -> void:
	print("Options not implemented yet")
	# TODO: Implement options menu

func _on_quit_button_pressed() -> void:
	print("Quitting game...")
	get_tree().quit()