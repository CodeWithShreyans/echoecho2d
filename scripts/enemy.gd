extends CharacterBody2D

@export var patrol_speed = 15.0
@export var base_chase_speed = 75.0
@export var max_speed_multiplier = 2.5
@export var speed_increment_per_score = 0.2
@export var detection_radius = 600.0
@export var reveal_duration = 0.025
@export var wave_detection_radius = 600.0
@export var stun_duration = 0.5
@export var wave_chase_duration = 2.0
@export var fade_duration = 1.5
@export var death_animation_duration = 0.5
@export var despawn_delay = 0.5

var chase_speed = base_chase_speed
var start_position = Vector2.ZERO
var is_alerted = false
var player = null
var reveal_timer = 0.0
var is_revealed = false
var is_stunned = false
var stun_timer = 0.0
var wave_chase_timer = 0.0
var is_wave_chasing = false
var chase_ended = false
var is_dying = false
var death_timer = 0.0
var despawn_timer = 0.0
var should_despawn = false
var sprite: Sprite2D

func _ready():
	start_position = global_position
	add_to_group("enemies")
	
	sprite = $Sprite2D
	
	randomize()
	var astronaut_number = randi_range(1, 18)
	var astronaut_texture_path = "res://assets/Enemies/spaceAstronauts_%03d.png" % astronaut_number
	var astronaut_texture = load(astronaut_texture_path)
	
	if astronaut_texture:
		sprite.texture = astronaut_texture
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.scale = Vector2(0.5, 0.5)
		print("Using enemy sprite: ", astronaut_texture_path)
	else:
		print("Failed to load enemy texture: ", astronaut_texture_path)
	
	modulate.a = 0

func _physics_process(delta):
	update_chase_speed()
	
	if is_dying:
		death_timer -= delta
		modulate.a = death_timer / death_animation_duration
		scale = Vector2.ONE * (1 + (death_animation_duration - death_timer))
		
		if sprite:
			sprite.rotation += 10.0 * delta
		
		if death_timer <= 0:
			queue_free()
		return
		
	if should_despawn:
		despawn_timer -= delta
		if despawn_timer <= 0:
			_on_despawn()
			return

	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	if is_stunned:
		stun_timer -= delta
		velocity = Vector2.ZERO
					
		if stun_timer <= 0:
			is_stunned = false
			is_wave_chasing = true
			chase_ended = false
			wave_chase_timer = wave_chase_duration
			print("Enemy finished being stunned, now chasing player for ", wave_chase_duration, " seconds")
			
			modulate.a = 1.0
	
	if is_revealed and !is_wave_chasing and !chase_ended:
		reveal_timer -= delta
		if reveal_timer <= 0:
			is_revealed = false
			modulate.a = 0
		else:
			modulate.a = reveal_timer / reveal_duration
	
	if is_wave_chasing and player:
		wave_chase_timer -= delta
		
		if wave_chase_timer > 0:
			var fade_start_time = wave_chase_duration - fade_duration
			if wave_chase_timer < fade_start_time:
				modulate.a = wave_chase_timer / fade_start_time
		
		if wave_chase_timer <= 0:
			is_wave_chasing = false
			chase_ended = true
			is_revealed = false
			velocity = Vector2.ZERO
			modulate.a = 0
			
			should_despawn = true
			despawn_timer = despawn_delay
		else:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * chase_speed
			
			if sprite and is_revealed:
				sprite.rotation = direction.angle() - PI / 2
				
			move_and_slide()
			return
	
	if is_alerted and player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * chase_speed
		
		if sprite and is_revealed:
			sprite.rotation = direction.angle() - PI / 2
			
		if !is_stunned:
			move_and_slide()
	else:
		velocity = Vector2.ZERO

func alert_enemy(player_pos):
	if global_position.distance_to(player_pos) <= detection_radius:
		is_alerted = true
		if player == null:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player = players[0]
		
		var alert_duration = 5.0
		var difficulty_manager = get_node_or_null("/root/DifficultyManager")
		if difficulty_manager:
			alert_duration = 5.0 * difficulty_manager.get_enemy_alert_duration_multiplier()
			
		await get_tree().create_timer(alert_duration).timeout
		is_alerted = false
		velocity = Vector2.ZERO

func on_wave_hit():
	die()

func react_to_wave_nearby():
	is_revealed = true
	reveal_timer = reveal_duration
	modulate.a = 1.0
	
	chase_ended = false
	
	is_stunned = true
	stun_timer = stun_duration
	velocity = Vector2.ZERO

func _on_despawn():
	var enemy_manager = get_node_or_null("/root/EnemyManager")
	if enemy_manager:
		enemy_manager.respawn_enemy(global_position)
	
	queue_free()

func die():
	if is_dying:
		return
		
	is_dying = true
	death_timer = death_animation_duration
	modulate.a = 1.0
	
	velocity = Vector2.ZERO
	is_stunned = false
	is_wave_chasing = false
	is_revealed = true
	

	get_node("/root/ScoreManager").enemy_killed()
	
	$Hitbox.set_deferred("monitoring", false)
	$Hitbox.set_deferred("monitorable", false)

func start_fading_out():
	pass

func on_wave_emitted_nearby(wave_pos):
	var adjusted_radius = wave_detection_radius
	var difficulty_manager = get_node_or_null("/root/DifficultyManager")
	if difficulty_manager:
		adjusted_radius = wave_detection_radius * difficulty_manager.get_wave_detection_radius_multiplier()
	
	var distance = global_position.distance_to(wave_pos)
	if distance <= adjusted_radius:
		react_to_wave_nearby()

func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		body.call_deferred("die")

func update_chase_speed():
	var difficulty_manager = get_node_or_null("/root/DifficultyManager")
	
	var score_manager = get_node("/root/ScoreManager")
	var multiplier = 1.0
	
	if score_manager:
		var player_score = score_manager.get_score()
		multiplier = 1.0 + (player_score * speed_increment_per_score / 100.0)
		multiplier = clamp(multiplier, 1.0, max_speed_multiplier)
	
	if difficulty_manager:
		multiplier *= difficulty_manager.get_enemy_speed_multiplier()
		
	chase_speed = base_chase_speed * multiplier
	
	if difficulty_manager and is_wave_chasing:
		wave_chase_duration = 2.0 * difficulty_manager.get_enemy_alert_duration_multiplier()
