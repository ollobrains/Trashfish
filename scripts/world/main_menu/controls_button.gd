extends Node2D


func attacked():
	get_tree().change_scene_to_file("res://scenes/world/controls_menu/controls_screen.tscn")
