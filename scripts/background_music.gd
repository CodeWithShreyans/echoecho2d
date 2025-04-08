extends Node

static var instance = null

var music_player: AudioStreamPlayer

func _ready():
	if instance != null:
		queue_free()
		return
	instance = self
	
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	var music = load("res://assets/music.wav")
	if music:
		music_player.stream = music
		music_player.volume_db = -10.0
		music_player.play()
		music_player.finished.connect(_on_music_finished)
	else:
		push_error("Failed to load background music!")

func _on_music_finished():
	music_player.play()

func stop_music():
	music_player.stop()