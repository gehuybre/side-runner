# GameManager.gd
extends Node

var current_scene_path: String = ""
var high_score: int = 0
var save_file_path: String = "user://highscore.save"

func _ready() -> void:
	print("Game Manager initialized")
	load_high_score()
	
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

func update_high_score(new_score: int) -> bool:
	if new_score > high_score:
		high_score = new_score
		save_high_score()
		print("New high score: ", high_score)
		return true
	return false

func get_high_score() -> int:
	return high_score

func save_high_score() -> void:
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()
		print("High score saved: ", high_score)
	else:
		print("Failed to save high score")

func load_high_score() -> void:
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()
			print("High score loaded: ", high_score)
		else:
			print("Failed to load high score file")
	else:
		print("No save file found, starting with high score of 0")