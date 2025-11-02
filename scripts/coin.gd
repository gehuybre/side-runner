# Coin.gd
extends Node2D

signal collected

@export var speed: float = 260.0  # Movement speed (sync with world speed)
@export var destroy_x: float = -1200.0  # X position to destroy coin (extended for longer visibility)
@export var magnet_pull_speed: float = 900.0

var _player: Node = null

func _ready() -> void:
	# Connect collision detection
	var area = $Area2D
	if area:
		area.connect("body_entered", Callable(self, "_on_body_entered"))
		print("Coin collision detection connected")
	else:
		print("Warning: Coin Area2D not found!")
	_player = _find_player()

func _process(delta: float) -> void:
	var current_position: Vector2 = global_position
	var displacement: Vector2 = Vector2(-speed * delta, 0.0)
	var magnet_active: bool = _is_player_magnet_active()
	if magnet_active and _player:
		var target_position: Vector2 = _get_player_attract_position()
		var to_player: Vector2 = target_position - current_position
		var distance_to_player: float = to_player.length()
		if distance_to_player > 1.0:
			var pull_direction: Vector2 = to_player.normalized()
			var pull_step: float = min(magnet_pull_speed * delta, distance_to_player)
			displacement += pull_direction * pull_step
	global_position = current_position + displacement
	
	# Destroy when off-screen
	if global_position.x <= destroy_x:
		queue_free()

func _on_body_entered(body: Node) -> void:
	print("Coin collision detected with: ", body.name, " (type: ", body.get_class(), ")")
	var parent = body.get_parent()
	print("Body parent: ", parent.name if parent else "no parent")
	
	# Check if this is the player's CharacterBody2D by looking at the parent
	var player_node = null
	if parent and parent.name == "Player":
		player_node = parent
		print("Found Player parent node")
	elif body.name == "Player":
		player_node = body
		print("Body is Player node directly")
	
	if player_node:
		print("Coin collected by player!")
		collected.emit()
		queue_free()
	else:
		print("Not player collision, ignoring")

func _find_player() -> Node:
	var world: Node = get_tree().current_scene
	if world:
		return world.get_node_or_null("Player")
	return null

func _is_player_magnet_active() -> bool:
	if _player == null:
		_player = _find_player()
	if _player and _player.has_method("is_magnet_active"):
		return _player.is_magnet_active()
	return false

func _get_player_attract_position() -> Vector2:
	if _player and _player.has_method("get_magnet_anchor_position"):
		return _player.get_magnet_anchor_position()
	if _player and _player is Node2D:
		return (_player as Node2D).global_position
	return global_position
