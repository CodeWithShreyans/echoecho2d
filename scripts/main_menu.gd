extends Control

func _ready():
	$VBoxContainer/StartGameButton.pressed.connect(_on_start_game_button_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://scenes/infinite_level.tscn")

func _on_quit_button_pressed():
	get_tree().quit()