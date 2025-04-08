extends Node

signal enemy_despawned(position)

var enemy_scene = preload("res://scenes/enemy.tscn")
var shooter_enemy_scene = preload("res://scenes/shooter_enemy.tscn")

var base_shooter_spawn_chance = 0.01
var shooter_spawn_chance_per_score = 0.0001
var max_shooter_spawn_chance = 0.4

@export var min_spawn_distance = 50.0
@export var max_spawn_distance = 100.0
@export var respawn_delay = 0.5

func _ready():
	if get_tree().get_root().has_node("EnemyManager"):
		queue_free()
		return
	name = "EnemyManager"
	get_tree().get_root().call_deferred("add_child", self)

func respawn_enemy(despawn_position):
	var adjusted_delay = respawn_delay
	var difficulty_manager = get_node_or_null("/root/DifficultyManager")
	if difficulty_manager:
		adjusted_delay = respawn_delay / difficulty_manager.get_enemy_spawn_rate_multiplier()
	
	await get_tree().create_timer(adjusted_delay).timeout
	
	var player = null
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		return
	
	var min_distance = min_spawn_distance
	var max_distance = max_spawn_distance
	
	if difficulty_manager:
		var distance_factor = 1.0 / difficulty_manager.get_enemy_spawn_rate_multiplier()
		min_distance = clamp(min_spawn_distance * distance_factor, min_spawn_distance * 0.7, min_spawn_distance)
		max_distance = clamp(max_spawn_distance * distance_factor, max_spawn_distance * 0.7, max_spawn_distance)
	
	var spawn_pos = _get_random_spawn_position(player.global_position, min_distance, max_distance)
	
	var score_manager = get_node_or_null("/root/ScoreManager")
	var shooter_chance = base_shooter_spawn_chance
	
	if score_manager:
		var current_score = score_manager.get_score()
		shooter_chance += current_score * shooter_spawn_chance_per_score
		shooter_chance = clamp(shooter_chance, base_shooter_spawn_chance, max_shooter_spawn_chance)
		
		if difficulty_manager:
			shooter_chance *= difficulty_manager.get_shooter_spawn_rate_multiplier()
			shooter_chance = clamp(shooter_chance, base_shooter_spawn_chance, max_shooter_spawn_chance)
	
	var is_shooter = randf() < shooter_chance
	var enemy_scene_to_use = shooter_enemy_scene if is_shooter else enemy_scene
	
	var enemy = enemy_scene_to_use.instantiate()
	
	if is_shooter:
		print("Spawning SHOOTER enemy - Score: ", score_manager.get_score() if score_manager else 0,
			", Chance: ", shooter_chance * 100, "%")
	
	if LevelManager.instance:
		var level_manager = LevelManager.instance
		
		var chunk_size = level_manager.chunk_size
		var chunk_x = floor(spawn_pos.x / chunk_size)
		var chunk_y = floor(spawn_pos.y / chunk_size)
		var chunk_key = Vector2(chunk_x, chunk_y)
		
		if level_manager.active_chunks.has(chunk_key):
			var chunk = level_manager.active_chunks[chunk_key]
			chunk.add_child(enemy)
			enemy.global_position = spawn_pos
			print("Enemy respawned at: ", spawn_pos)
		else:
			if level_manager.has_node("Chunks"):
				level_manager.get_node("Chunks").add_child(enemy)
				enemy.global_position = spawn_pos
				print("Enemy respawned in Chunks container at: ", spawn_pos)
			else:
				get_tree().get_root().add_child(enemy)
				enemy.global_position = spawn_pos
				print("Enemy respawned in root at: ", spawn_pos)
	else:
		get_tree().get_root().add_child(enemy)
		enemy.global_position = spawn_pos
		print("Enemy respawned in root at: ", spawn_pos)

func _get_random_spawn_position(player_pos, min_distance = min_spawn_distance, max_distance = max_spawn_distance):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var distance = rng.randf_range(min_distance, max_distance)
	
	var angle = rng.randf_range(0, 2 * PI)
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return player_pos + offset
