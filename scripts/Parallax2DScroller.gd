# Parallax2DScroller.gd
extends Parallax2D

@export var speed_multiplier: float = 1.0
@export var auto_set_repeat_from_child: bool = true
@export var scale_to_viewport: bool = true

func _ready() -> void:
	# Auto-detect repeat size from child sprite region
	if auto_set_repeat_from_child and repeat_size.x == 0.0:
		var width: float = _infer_repeat_width()
		if width > 0.0:
			repeat_size = Vector2(width, repeat_size.y)
	
	# Scale sprites to cover viewport if enabled
	if scale_to_viewport:
		_scale_to_viewport()
	
	# Ensure all layers start at the same scroll position
	scroll_offset = Vector2.ZERO
	
	# Adjust autoscroll based on speed multiplier
	if autoscroll.x != 0:
		autoscroll.x = autoscroll.x * speed_multiplier

func _scale_to_viewport() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var center_y = viewport_size.y * 0.5
	
	for child in get_children():
		if child is Sprite2D:
			var sprite: Sprite2D = child
			if sprite.texture:
				var texture_height = sprite.texture.get_height()
				var scale_factor = viewport_size.y / texture_height
				sprite.scale.y = scale_factor
				# Keep aspect ratio for width or use 1.0 if you want to stretch
				sprite.scale.x = scale_factor
				# Center the sprite vertically
				sprite.position.y = center_y

func _infer_repeat_width() -> float:
	var width: float = 0.0
	for c in get_children():
		if c is Sprite2D:
			var spr: Sprite2D = c
			if spr.region_enabled:
				width = spr.region_rect.size.x * abs(spr.scale.x)
			elif spr.texture:
				width = spr.texture.get_size().x * abs(spr.scale.x)
			break
		elif c is TextureRect:
			var tex_rect: TextureRect = c
			if tex_rect.texture:
				width = tex_rect.texture.get_size().x * abs(tex_rect.scale.x)
			break
	return width
