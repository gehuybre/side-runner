# GameManager.gd
extends Node

var current_scene_path: String = ""

func _ready() -> void:
	print("Game Manager initialized")
	
func change_to_scene(scene_path: String) -> void:
	print("Changing to scene: ", scene_path)
	current_scene_path = scene_path
	get_tree().change_scene_to_file(scene_path)

func restart_current_scene() -> void:
	print("Restarting current scene")
	if current_scene_path != "":
		get_tree().change_scene_to_file(current_scene_path)
	else:
		get_tree().reload_current_scene()

func quit_game() -> void:
	print("Quitting game...")
	get_tree().quit()