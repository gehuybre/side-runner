extends ParallaxBackground

@export var scroll_speed: float = 598.0  # doubled base speed (299 * 2)
@export var layer_multipliers: PackedFloat32Array = [0.25, 0.5, 1.0]

var _active: bool = true

func _ready() -> void:
	# Auto-configure motion_mirroring.x from the first Sprite2D child width if not set.
	for child in get_children():
		if child is ParallaxLayer:
			var pl: ParallaxLayer = child
			if pl.motion_mirroring.x == 0.0:
				var wrap_w: float = _infer_layer_width(pl)
				if wrap_w > 0.0:
					pl.motion_mirroring = Vector2(wrap_w, pl.motion_mirroring.y)
	
	# Connect to player death signal to stop scrolling
	var player = get_parent().get_node("Player")
	if player and player.has_signal("player_died"):
		player.connect("player_died", Callable(self, "_on_player_died"))

func _process(delta: float) -> void:
	if not _active:
		return
		
	var i: int = 0
	for child in get_children():
		if child is ParallaxLayer:
			var pl: ParallaxLayer = child
			var mult: float = layer_multipliers[i] if i < layer_multipliers.size() else 1.0
			pl.motion_offset.x -= scroll_speed * mult * delta
			i += 1

func _on_player_died() -> void:
	_active = false
	print("Parallax scrolling stopped - player died")

func _infer_layer_width(p_layer: ParallaxLayer) -> float:
	var width: float = 0.0
	for c in p_layer.get_children():
		if c is Sprite2D:
			var spr: Sprite2D = c
			if spr.texture != null:
				var tex_size: Vector2 = spr.texture.get_size()
				width = tex_size.x * abs(spr.scale.x)
				break
		elif c is TextureRect:
			var tex_rect: TextureRect = c
			if tex_rect.texture != null:
				var tex_size2: Vector2 = tex_rect.texture.get_size()
				width = tex_size2.x * abs(tex_rect.scale.x)
				break
	return width
