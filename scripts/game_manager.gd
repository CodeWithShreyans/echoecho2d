extends Node2D

@onready var wave_scene = preload("res://scenes/wave.tscn")
@onready var player = $Player
@onready var walls = $Walls
@onready var obstacles = $Obstacles

func _ready():
    print("Game manager ready")
    for wall in walls.get_children():
        if wall.has_node("ColorRect"):
            wall.get_node("ColorRect").modulate.a = 1
        elif wall.has_node("Sprite2D"):
            wall.get_node("Sprite2D").modulate.a = 1
    
    for obstacle in obstacles.get_children():
        if obstacle.has_node("ColorRect"):
            obstacle.get_node("ColorRect").modulate.a = 1
        elif obstacle.has_node("Sprite2D"):
            obstacle.get_node("Sprite2D").modulate.a = 1
    
    if player:
        print("Connecting player signals")
        player.wave_emitted.connect(_on_player_wave_emitted)
        player.player_died.connect(_on_player_died)
        player.wave_burst_emitted.connect(_on_player_wave_burst_emitted)
    else:
        print("Player node not found!")

func _on_player_wave_emitted(pos, direction):
    print("Wave emission signal received")
    var wave = wave_scene.instantiate()
    add_child(wave)
    wave.initialize(pos, direction)
    print("Wave initialized at position: ", pos)

func _on_player_wave_burst_emitted(pos):
    print("Wave burst emitted at: ", pos)

func _on_player_died():
    print("Player died")
    pass