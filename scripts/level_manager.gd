class_name LevelManager
extends Node2D

static var instance = null

@export var spawn_distance = 1000.0
@export var despawn_distance = 1500.0
@export var obstacle_count_per_chunk = 5
@export var enemy_count_per_chunk = 5
@export var chunk_size = 1000.0
@export var max_player_speed = 1000.0
@export var safe_radius_around_player = 200.0

@onready var obstacle_scene = preload("res://scenes/wall.tscn")
@onready var enemy_scene = preload("res://scenes/enemy.tscn")
@onready var shooter_enemy_scene = preload("res://scenes/shooter_enemy.tscn")
@onready var wave_scene = preload("res://scenes/wave.tscn")
@onready var player = $Player
@onready var chunks_container = $Chunks
@onready var camera = $Camera2D

var active_chunks = {}
var rng = RandomNumberGenerator.new()
var last_player_position = Vector2.ZERO
var last_update_time = 0.0
var waves_container = null

var base_shooter_spawn_chance = 0.01
var shooter_spawn_chance_per_score = 0.0001
var max_shooter_spawn_chance = 0.4

func _ready():
	instance = self
	
	name = "LevelManager"
	
	rng.randomize()
	if not player:
		push_error("Player not found in the scene!")
		return
	
	last_player_position = player.global_position
	last_update_time = Time.get_ticks_msec() / 1000.0
	
	waves_container = Node2D.new()
	waves_container.name = "Waves"
	add_child(waves_container)
	
	if player:
		print("Connecting player signals")
		player.wave_emitted.connect(_on_player_wave_emitted)
		player.player_died.connect(_on_player_died)
		player.wave_burst_emitted.connect(_on_player_wave_burst_emitted)
	else:
		print("Player node not found!")
	
	var score_manager = get_node("/root/ScoreManager")
	if score_manager:
		score_manager.reset()
		print("Score reset at level start")
		
	_update_chunks()

func get_player():
	return player

func get_chunk_size():
	return chunk_size

func get_safe_radius():
	return safe_radius_around_player

func _process(delta):
	if player:
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_diff = current_time - last_update_time
		
		var distance = player.global_position.distance_to(last_player_position)
		var speed = distance / time_diff if time_diff > 0 else 0
		
		if speed > max_player_speed and time_diff > 0.1:
			print("Player moving too fast! Possible physics glitch. Speed: ", speed)
			player.global_position = last_player_position
		else:
			camera.global_position = player.global_position
			
			_update_chunks()
			
			last_player_position = player.global_position
			last_update_time = current_time

func _on_player_wave_emitted(pos, direction):
	print("Wave emission signal received")
	var wave = wave_scene.instantiate()
	waves_container.add_child(wave)
	wave.initialize(pos, direction)
	print("Wave initialized at position: ", pos)

func _on_player_wave_burst_emitted(pos):
	print("Wave burst emitted at: ", pos)

func _on_player_died():
	print("Player died")

func _update_chunks():
	var player_chunk_x = floor(player.global_position.x / chunk_size)
	var player_chunk_y = floor(player.global_position.y / chunk_size)
	
	var chunk_view_distance = ceil(spawn_distance / chunk_size)
	
	var chunks_in_range = {}
	
	for x in range(player_chunk_x - chunk_view_distance, player_chunk_x + chunk_view_distance + 1):
		for y in range(player_chunk_y - chunk_view_distance, player_chunk_y + chunk_view_distance + 1):
			var chunk_coords = Vector2(x, y)
			chunks_in_range[chunk_coords] = true
			
			if not active_chunks.has(chunk_coords):
				_generate_chunk(chunk_coords)
	
	var chunks_to_remove = []
	for chunk_coords in active_chunks:
		if not chunks_in_range.has(chunk_coords):
			chunks_to_remove.append(chunk_coords)
	
	for chunk_coords in chunks_to_remove:
		_remove_chunk(chunk_coords)

func _generate_chunk(chunk_coords):
	print("Generating chunk at: ", chunk_coords)
	
	var chunk_container = Node2D.new()
	chunk_container.name = "Chunk_" + str(chunk_coords.x) + "_" + str(chunk_coords.y)
	chunks_container.add_child(chunk_container)
	
	var chunk_pos = Vector2(
		chunk_coords.x * chunk_size,
		chunk_coords.y * chunk_size
	)
	
	var obstacles_placed = 0
	var max_attempts = obstacle_count_per_chunk * 2
	var attempts = 0
	
	while obstacles_placed < obstacle_count_per_chunk and attempts < max_attempts:
		attempts += 1
		var obstacle = obstacle_scene.instantiate()
		chunk_container.add_child(obstacle)
		
		var offset = Vector2(
			rng.randf_range(0, chunk_size),
			rng.randf_range(0, chunk_size)
		)
		var obstacle_position = chunk_pos + offset
		
		if obstacle_position.length() < safe_radius_around_player:
			obstacle.queue_free()
			continue
		
		obstacle.global_position = obstacle_position
		
		obstacle.rotation = rng.randf_range(0, 2 * PI)
		
		var scale_factor = rng.randf_range(0.5, 2.0)
		obstacle.scale = Vector2(scale_factor, scale_factor)
		
		if obstacle.has_node("ColorRect"):
			obstacle.get_node("ColorRect").modulate.a = 1
		elif obstacle.has_node("Sprite2D"):
			obstacle.get_node("Sprite2D").modulate.a = 1
			
		obstacles_placed += 1
	
	var adjusted_enemy_count = enemy_count_per_chunk
	var difficulty_manager = get_node_or_null("/root/DifficultyManager")
	if difficulty_manager:
		adjusted_enemy_count = ceil(enemy_count_per_chunk * difficulty_manager.get_enemy_count_multiplier())
		print("Adjusting enemy count based on difficulty. Base: ", enemy_count_per_chunk, ", Adjusted: ", adjusted_enemy_count)
	
	var score_manager = get_node_or_null("/root/ScoreManager")
	var shooter_chance = base_shooter_spawn_chance
	
	if score_manager:
		var current_score = score_manager.get_score()
		shooter_chance += current_score * shooter_spawn_chance_per_score
		shooter_chance = clamp(shooter_chance, base_shooter_spawn_chance, max_shooter_spawn_chance)
		
		if difficulty_manager:
			shooter_chance *= difficulty_manager.get_shooter_spawn_rate_multiplier()
			shooter_chance = clamp(shooter_chance, base_shooter_spawn_chance, max_shooter_spawn_chance)
	
	var enemies_placed = 0
	max_attempts = adjusted_enemy_count * 2
	attempts = 0
	
	while enemies_placed < adjusted_enemy_count and attempts < max_attempts:
		attempts += 1
		
		var is_shooter = randf() < shooter_chance
		var enemy_scene_to_use = shooter_enemy_scene if is_shooter else enemy_scene
		
		var enemy = enemy_scene_to_use.instantiate()
		chunk_container.add_child(enemy)
		
		if is_shooter:
			print("Spawning SHOOTER enemy in chunk - Score: ", score_manager.get_score() if score_manager else 0,
				", Chance: ", shooter_chance * 100, "%")
		
		var offset = Vector2(
			rng.randf_range(0, chunk_size),
			rng.randf_range(0, chunk_size)
		)
		var enemy_position = chunk_pos + offset
		
		if enemy_position.length() < safe_radius_around_player:
			enemy.queue_free()
			continue
		
		enemy.global_position = enemy_position
		enemies_placed += 1
	
	active_chunks[chunk_coords] = chunk_container

func _remove_chunk(chunk_coords):
	print("Removing chunk at: ", chunk_coords)
	
	if active_chunks.has(chunk_coords):
		var chunk_container = active_chunks[chunk_coords]
		chunk_container.queue_free()
		active_chunks.erase(chunk_coords)

func _should_despawn(pos):
	return player.global_position.distance_to(pos) > despawn_distance