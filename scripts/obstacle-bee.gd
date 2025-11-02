# ObstacleBee.gd
extends Node2D

@export var speed: float = 260.0
@export var destroy_x: float = -500.0  # Much further left to ensure it passes the player

signal hit_player

@onready var area_2d: Area2D = $Area2D
var _active: bool = true

func _ready() -> void:
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		print("Bee collision connected successfully")
	else:
		print("ERROR: Could not find Area2D in bee!")
	print("Bee spawned at position: ", position)
	
	# Try to connect to player death signal
	var world = get_tree().current_scene
	if world:
		var player = world.get_node("Player")
		if player and player.has_signal("player_died"):
			player.connect("player_died", Callable(self, "_on_player_died"))

func _process(delta: float) -> void:
	if not _active:
		return
		
	# Move left with the world speed
	position.x -= speed * delta
	
	# Destroy when off-screen (much further left now)
	if position.x < destroy_x:
		print("Bee destroyed at position: ", position.x)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("Something entered the bee area: ", body.name, " (type: ", body.get_class(), ")")
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
	
	if player_node and player_node.has_method("take_damage"):
		print("Collision detected with player who has take_damage!")
		hit_player.emit()
		queue_free()
	elif player_node:
		print("Found player but no take_damage method - calling die() directly")
		if player_node.has_method("die"):
			player_node.die()
		hit_player.emit()
		queue_free()
	else:
		print("Not player collision, ignoring")

func _on_player_died() -> void:
	_active = false