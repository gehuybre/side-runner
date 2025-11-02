# TouchControls.gd
extends Control

@export var lane_button_size: Vector2 = Vector2(200, 400)
@export var button_margin: float = 50.0
@export var button_opacity: float = 0.3
@export var touch_feedback_scale: float = 1.2
@export var show_on_desktop: bool = false  # Hide on desktop by default

@onready var lane_up_button: TouchScreenButton
@onready var lane_down_button: TouchScreenButton
@onready var pause_button: TouchScreenButton

signal lane_up_pressed
signal lane_down_pressed
signal pause_pressed

func _ready() -> void:
	# Create touch buttons first
	_create_touch_buttons()
	_setup_button_positions()
	
	# Wait a frame for the mobile manager to be ready
	await get_tree().process_frame
	
	# Configure visibility based on mobile manager
	if has_node("/root/MobileManager"):
		var mobile_manager = get_node("/root/MobileManager")
		if mobile_manager.is_mobile() or show_on_desktop:
			visible = true
			print("Touch controls enabled")
		else:
			visible = false
			print("Touch controls hidden for desktop")
	else:
		# Fallback to OS detection if mobile manager not available
		var is_mobile = OS.get_name() in ["Android", "iOS"]
		if not is_mobile and not show_on_desktop:
			visible = false
		print("Touch controls initialized (fallback mode) for platform: ", OS.get_name())

func _create_touch_buttons() -> void:
	# Create lane up button (left side)
	lane_up_button = TouchScreenButton.new()
	lane_up_button.name = "LaneUpButton"
	lane_up_button.texture_normal = _create_button_texture("↑", Color.CYAN)
	lane_up_button.texture_pressed = _create_button_texture("↑", Color.WHITE)
	lane_up_button.modulate.a = button_opacity
	add_child(lane_up_button)
	
	# Create lane down button (left side, below up button)
	lane_down_button = TouchScreenButton.new()
	lane_down_button.name = "LaneDownButton"
	lane_down_button.texture_normal = _create_button_texture("↓", Color.CYAN)
	lane_down_button.texture_pressed = _create_button_texture("↓", Color.WHITE)
	lane_down_button.modulate.a = button_opacity
	add_child(lane_down_button)
	
	# Create pause button (top right)
	pause_button = TouchScreenButton.new()
	pause_button.name = "PauseButton"
	pause_button.texture_normal = _create_button_texture("⏸", Color.YELLOW)
	pause_button.texture_pressed = _create_button_texture("⏸", Color.WHITE)
	pause_button.modulate.a = button_opacity
	add_child(pause_button)
	
	# Connect signals
	lane_up_button.pressed.connect(_on_lane_up_pressed)
	lane_down_button.pressed.connect(_on_lane_down_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	
	# Add touch feedback
	lane_up_button.pressed.connect(func(): _button_feedback(lane_up_button))
	lane_down_button.pressed.connect(func(): _button_feedback(lane_down_button))
	pause_button.pressed.connect(func(): _button_feedback(pause_button))

func _setup_button_positions() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Position lane control buttons on the left side
	var left_x = button_margin
	var center_y = viewport_size.y * 0.5
	var button_spacing = lane_button_size.y * 0.6
	
	# Lane up button (upper left)
	lane_up_button.position = Vector2(left_x, center_y - button_spacing * 0.5 - lane_button_size.y)
	lane_up_button.shape = RectangleShape2D.new()
	lane_up_button.shape.size = lane_button_size
	
	# Lane down button (lower left)
	lane_down_button.position = Vector2(left_x, center_y + button_spacing * 0.5)
	lane_down_button.shape = RectangleShape2D.new()
	lane_down_button.shape.size = lane_button_size
	
	# Pause button (top right)
	var pause_size = Vector2(120, 120)
	pause_button.position = Vector2(viewport_size.x - pause_size.x - button_margin, button_margin)
	pause_button.shape = RectangleShape2D.new()
	pause_button.shape.size = pause_size

func _create_button_texture(_text: String, color: Color) -> ImageTexture:
	# Create a simple colored texture with text for touch buttons
	var image = Image.create(int(lane_button_size.x), int(lane_button_size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color(color.r, color.g, color.b, 0.6))
	
	# Add border
	var border_width = 4
	for x in range(border_width):
		for y in range(int(lane_button_size.y)):
			image.set_pixel(x, y, color)
			image.set_pixel(int(lane_button_size.x) - 1 - x, y, color)
	for y in range(border_width):
		for x in range(int(lane_button_size.x)):
			image.set_pixel(x, y, color)
			image.set_pixel(x, int(lane_button_size.y) - 1 - y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _button_feedback(button: TouchScreenButton) -> void:
	# Visual feedback when button is pressed
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE * touch_feedback_scale, 0.1)
	tween.tween_callback(func(): 
		var return_tween = create_tween()
		return_tween.tween_property(button, "scale", Vector2.ONE, 0.1)
	).set_delay(0.1)

func _on_lane_up_pressed() -> void:
	print("Touch: Lane up pressed")
	if has_node("/root/MobileManager"):
		get_node("/root/MobileManager").trigger_haptic_light()
	lane_up_pressed.emit()

func _on_lane_down_pressed() -> void:
	print("Touch: Lane down pressed")
	if has_node("/root/MobileManager"):
		get_node("/root/MobileManager").trigger_haptic_light()
	lane_down_pressed.emit()

func _on_pause_pressed() -> void:
	print("Touch: Pause pressed")
	if has_node("/root/MobileManager"):
		get_node("/root/MobileManager").trigger_haptic_medium()
	pause_pressed.emit()

# Public functions for external control
func show_controls() -> void:
	visible = true

func hide_controls() -> void:
	visible = false

func set_opacity(opacity: float) -> void:
	button_opacity = clamp(opacity, 0.1, 1.0)
	if lane_up_button:
		lane_up_button.modulate.a = button_opacity
	if lane_down_button:
		lane_down_button.modulate.a = button_opacity
	if pause_button:
		pause_button.modulate.a = button_opacity