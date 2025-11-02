# CameraController.gd
extends Camera2D

@export var camera_offset_x_ratio: float = -0.1  # 10% left of center
@export var zoom_level: float = 1.5  # Increased zoom to fill screen better
@export var follow_player: bool = false  # Changed to false for fixed camera

func _ready() -> void:
	_position_camera()

func _position_camera() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	if follow_player:
		# Position camera to follow player with offset
		var player = get_parent().get_node("Player")
		if player:
			var center_x = player.position.x + (viewport_size.x * camera_offset_x_ratio)
			var center_y = viewport_size.y * 0.5
			position = Vector2(center_x, center_y)
		else:
			# Fallback if no player found
			position = Vector2(viewport_size.x * camera_offset_x_ratio, viewport_size.y * 0.5)
	else:
		# Fixed camera position - center it properly for endless runner
		var center_x = 0.0  # Center the camera at origin
		var center_y = viewport_size.y * 0.5
		position = Vector2(center_x, center_y)
	
	zoom = Vector2(zoom_level, zoom_level)
	print("Camera positioned at: ", position, " with zoom: ", zoom, " viewport: ", viewport_size)