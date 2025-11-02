# MainMenu.gd
extends Control

func _ready() -> void:
	print("Main Menu loaded")

func _on_start_button_pressed() -> void:
	print("Starting game...")
	get_tree().change_scene_to_file("res://scenes/world-1.tscn")

func _on_options_button_pressed() -> void:
	print("Options not implemented yet")
	# TODO: Implement options menu

func _on_quit_button_pressed() -> void:
	print("Quitting game...")
	get_tree().quit()