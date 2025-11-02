# CameraController.gd
extends Camera2D

@export var camera_offset_x_ratio: float = -0.1  # 10% left of center
@export var zoom_level: float = 1.5  # Increased zoom to fill screen better

func _ready() -> void:
	_position_camera()

func _position_camera() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var center_x = viewport_size.x * camera_offset_x_ratio
	var center_y = viewport_size.y * 0.5
	
	position = Vector2(center_x, center_y)
	zoom = Vector2(zoom_level, zoom_level)
	print("Camera positioned at: ", position, " with zoom: ", zoom, " viewport: ", viewport_size)