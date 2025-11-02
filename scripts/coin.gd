# Coin.gd
extends Node2D

signal collected

@export var speed: float = 260.0  # Movement speed (sync with world speed)
@export var destroy_x: float = -800.0  # X position to destroy coin (moved further left)

func _ready() -> void:
	# Connect collision detection
	var area = $Area2D
	if area:
		area.connect("body_entered", Callable(self, "_on_body_entered"))
		print("Coin collision detection connected")
	else:
		print("Warning: Coin Area2D not found!")

func _process(delta: float) -> void:
	# Move coin left at world speed
	position.x -= speed * delta
	
	# Destroy when off-screen
	if position.x <= destroy_x:
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