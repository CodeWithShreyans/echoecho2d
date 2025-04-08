extends "res://scripts/enemy.gd"

@export var shoot_cooldown = 3.0
@export var shoot_distance = 500.0
@export var shoot_accuracy = 0.9
@export var projectile_count = 1

var projectile_scene = preload("res://scenes/shooter_projectile.tscn")
var shoot_timer = 0.0
var can_shoot = true

func _ready():
	super._ready()
	
	if sprite:
		sprite.modulate = Color(1.0, 0.5, 0.2, 1.0)

func _physics_process(delta):
	super._physics_process(delta)
	
	if !can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	if player and is_revealed and can_shoot:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player <= shoot_distance:
			shoot_at_player()

func shoot_at_player():
	if !is_wave_chasing and !is_dying:
		print("Shooter enemy is shooting at player")
		
		var direction_to_player = (player.global_position - global_position).normalized()
		
		if shoot_accuracy < 1:
			var random_angle = (1.0 - shoot_accuracy) * PI * 0.25
			var angle_to_player = direction_to_player.angle()
			var randomized_angle = angle_to_player + randf_range(-random_angle, random_angle)
			direction_to_player = Vector2(cos(randomized_angle), sin(randomized_angle))
		
		if projectile_count > 1:
			var spread_angle = PI * 0.2
			var half_spread = spread_angle / 2
			var angle_step = spread_angle / (projectile_count - 1)
			var base_angle = direction_to_player.angle()
			
			for i in range(projectile_count):
				var projectile_angle = base_angle - half_spread + (angle_step * i)
				var projectile_direction = Vector2(cos(projectile_angle), sin(projectile_angle))
				spawn_projectile(projectile_direction)
		else:
			spawn_projectile(direction_to_player)
		
		can_shoot = false
		shoot_timer = shoot_cooldown

func spawn_projectile(direction):
	var projectile = projectile_scene.instantiate()
	
	if get_parent():
		get_parent().add_child(projectile)
	else:
		get_tree().get_root().add_child(projectile)
	
	var spawn_offset = direction * 20.0
	projectile.initialize(global_position + spawn_offset, direction)
	
	projectile.modulate.a = 1.0
