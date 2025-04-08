extends Node

signal difficulty_level_changed(level)

const DIFFICULTY_THRESHOLDS = [
	0,
	1000,
	2500,
	5000,
	10000
]

var current_difficulty_level = 1
var previous_difficulty_level = 1

var enemy_speed_multiplier = 1.0
var enemy_count_multiplier = 1.0
var wave_detection_radius_multiplier = 1.0
var enemy_spawn_rate_multiplier = 1.0
var enemy_alert_duration_multiplier = 1.0
var shooter_spawn_rate_multiplier = 1.0

func _ready():
	name = "DifficultyManager"
	get_tree().get_root().call_deferred("add_child", self)
	
	var score_manager = get_node_or_null("/root/ScoreManager")
	if score_manager:
		score_manager.score_updated.connect(_on_score_updated)
	
	_update_difficulty_parameters()

func _on_score_updated(score):
	var new_level = 1
	for i in range(DIFFICULTY_THRESHOLDS.size()):
		if score >= DIFFICULTY_THRESHOLDS[i]:
			new_level = i + 1
	
	if new_level != current_difficulty_level:
		previous_difficulty_level = current_difficulty_level
		current_difficulty_level = new_level
		_update_difficulty_parameters()
		difficulty_level_changed.emit(current_difficulty_level)
		print("Difficulty increased to level ", current_difficulty_level)

func _update_difficulty_parameters():
	match current_difficulty_level:
		1:
			enemy_speed_multiplier = 1.0
			enemy_count_multiplier = 1.0
			wave_detection_radius_multiplier = 1.0
			enemy_spawn_rate_multiplier = 1.0
			enemy_alert_duration_multiplier = 1.0
			shooter_spawn_rate_multiplier = 1.0
		2:
			enemy_speed_multiplier = 1.2
			enemy_count_multiplier = 1.2
			wave_detection_radius_multiplier = 0.9
			enemy_spawn_rate_multiplier = 1.2
			enemy_alert_duration_multiplier = 1.2
			shooter_spawn_rate_multiplier = 1.5
		3:
			enemy_speed_multiplier = 1.5
			enemy_count_multiplier = 1.5
			wave_detection_radius_multiplier = 0.8
			enemy_spawn_rate_multiplier = 1.5
			enemy_alert_duration_multiplier = 1.5
			shooter_spawn_rate_multiplier = 2.0
		4:
			enemy_speed_multiplier = 1.8
			enemy_count_multiplier = 1.8
			wave_detection_radius_multiplier = 0.7
			enemy_spawn_rate_multiplier = 1.8
			enemy_alert_duration_multiplier = 2.0
			shooter_spawn_rate_multiplier = 2.5
		5:
			enemy_speed_multiplier = 2.2
			enemy_count_multiplier = 2.0
			wave_detection_radius_multiplier = 0.6
			enemy_spawn_rate_multiplier = 2.2
			enemy_alert_duration_multiplier = 2.5
			shooter_spawn_rate_multiplier = 3.0

func get_enemy_speed_multiplier():
	return enemy_speed_multiplier

func get_enemy_count_multiplier():
	return enemy_count_multiplier

func get_wave_detection_radius_multiplier():
	return wave_detection_radius_multiplier

func get_enemy_spawn_rate_multiplier():
	return enemy_spawn_rate_multiplier

func get_enemy_alert_duration_multiplier():
	return enemy_alert_duration_multiplier

func get_shooter_spawn_rate_multiplier():
	return shooter_spawn_rate_multiplier

func get_difficulty_level():
	return current_difficulty_level