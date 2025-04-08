extends CharacterBody2D

signal wave_emitted(position, direction)
signal player_died
signal wave_burst_emitted(position)

@export var speed = 300.0
@export var wave_cooldown = 2.0
@export var small_wave_cooldown = 1
@export var max_waves_before_alert = 5
@export var wave_alert_cooldown = 3.0
@export var wave_count = 200
@export var wave_spread = 110.0

var can_emit_wave = true
var waves_emitted = 0
var wave_emit_count = 0
var alert_timer = 0.0
var last_safe_position = Vector2.ZERO
var triangle: Polygon2D
var sprite: Sprite2D
var booster_sprite: Sprite2D
var current_direction = Vector2.UP
var booster_animation_time: float = 0.0

func _ready():
	print("Player ready")
	last_safe_position = global_position
	triangle = $PlayerTriangle
	
	if !has_node("ShipSprite"):
		sprite = Sprite2D.new()
		sprite.name = "ShipSprite"
		add_child(sprite)
	else:
		sprite = $ShipSprite
	
	booster_sprite = Sprite2D.new()
	booster_sprite.name = "BoosterSprite"
	add_child(booster_sprite)
	
	booster_sprite.position = Vector2(-20, 0)
	booster_sprite.z_index = -1
	
	randomize()
	var ship_number = randi_range(1, 9)
	var ship_texture_path = "res://assets/Ships/spaceShips_%03d.png" % ship_number
	var ship_texture = load(ship_texture_path)
	
	var booster_files = [
		"spaceEffects_001.png",
		"spaceEffects_002.png",
		"spaceEffects_003.png",
		"spaceEffects_004.png",
		"spaceEffects_005.png",
		"spaceEffects_018.png"
	]
	var booster_texture_path = "res://assets/Boosters/" + booster_files[randi() % booster_files.size()]
	var booster_texture = load(booster_texture_path)
	
	if booster_texture:
		booster_sprite.texture = booster_texture
		booster_sprite.centered = true
		booster_sprite.scale = Vector2(0.5, 0.5)
		booster_sprite.visible = false
		print("Using booster sprite: ", booster_texture_path)
	else:
		print("Failed to load booster texture: ", booster_texture_path)
	
	if ship_texture:
		sprite.texture = ship_texture
		triangle.visible = false
		sprite.visible = true
		sprite.centered = true
		sprite.scale = Vector2(0.4, 0.4)
		print("Using ship sprite: ", ship_texture_path)
	else:
		print("Failed to load ship texture: ", ship_texture_path)
		sprite.visible = false
		triangle.visible = true

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	direction = direction.normalized()
	
	if direction != Vector2.ZERO:
		current_direction = direction
	
	velocity = direction * speed
	
	if booster_sprite:
		booster_sprite.visible = direction != Vector2.ZERO
		
		if direction != Vector2.ZERO:
			var booster_offset = - direction.normalized() * 40
			booster_sprite.position = booster_offset
			
			booster_animation_time += delta * 5.0
			var pulse = sin(booster_animation_time) * 0.1 + 0.9
			booster_sprite.scale = Vector2(0.5, 0.5) * pulse
			
			var alpha_pulse = sin(booster_animation_time * 0.8) * 0.2 + 0.8
			booster_sprite.modulate.a = alpha_pulse
	
	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
	else:
		var movement_angle = direction.angle()
		if sprite and sprite.visible:
			sprite.rotation = movement_angle - PI / 2
			
			if booster_sprite:
				booster_sprite.rotation = movement_angle - PI / 2
		else:
			triangle.rotation = movement_angle
			
			if booster_sprite:
				booster_sprite.rotation = movement_angle
	
	if velocity.length() < speed * 1.5:
		last_safe_position = global_position
	
	move_and_slide()
	
	if direction == Vector2.ZERO and global_position.distance_to(last_safe_position) > 100:
		global_position = last_safe_position
		velocity = Vector2.ZERO
	
	if !can_emit_wave:
		alert_timer += delta
		if alert_timer >= wave_alert_cooldown:
			waves_emitted = 0
			alert_timer = 0.0
	
	if Input.is_action_just_pressed("shoot_wave") or Input.is_action_just_pressed("ui_accept"):
		print("Wave action triggered")
		emit_wave_burst()

func emit_wave_burst():
	if can_emit_wave:
		print("Emitting wave burst from position: ", global_position)
		
		var base_direction
		
		if current_direction != Vector2.ZERO:
			base_direction = current_direction
		elif sprite and sprite.visible:
			base_direction = Vector2(cos(sprite.rotation + PI / 2), sin(sprite.rotation + PI / 2))
		else:
			base_direction = Vector2(cos(triangle.rotation), sin(triangle.rotation))
		
		var base_angle = base_direction.angle()
		
		var half_spread = deg_to_rad(wave_spread / 2)
		var start_angle = base_angle - half_spread
		var angle_step = deg_to_rad(wave_spread) / (wave_count - 1)
		
		for i in range(wave_count):
			var angle = start_angle + (angle_step * i)
			var direction = Vector2(cos(angle), sin(angle))
			wave_emitted.emit(global_position, direction)
		
		print("Notifying enemies about wave burst at position: ", global_position)
		wave_burst_emitted.emit(global_position)
		
		print("Calling on_wave_emitted_nearby on all enemies")
		get_tree().call_group("enemies", "on_wave_emitted_nearby", global_position)
		
		waves_emitted += 1
		wave_emit_count += 1
		
		if waves_emitted >= max_waves_before_alert:
			print("Max waves reached, alerting nearby enemies")
			get_tree().call_group("enemies", "alert_enemy", global_position)
			waves_emitted = 0
		
		can_emit_wave = false
		
		if wave_emit_count >= 5:
			await get_tree().create_timer(wave_cooldown).timeout
			wave_emit_count = 0
			print("Full wave cooldown finished")
		else:
			await get_tree().create_timer(small_wave_cooldown).timeout
			print("Small wave cooldown finished")
			
		can_emit_wave = true

func die():
	player_died.emit()
	
	var score_manager = get_node("/root/ScoreManager")
	if score_manager:
		var has_lives_left = score_manager.lose_life()
		if has_lives_left:
			global_position = Vector2.ZERO
			velocity = Vector2.ZERO
			can_emit_wave = true
			waves_emitted = 0
			wave_emit_count = 0
			alert_timer = 0.0
			
			var hitbox = $Hitbox
			if hitbox:
				hitbox.set_deferred("monitoring", false)
				hitbox.set_deferred("monitorable", false)
			modulate.a = 0.5
			
			await get_tree().create_timer(1.5).timeout
			if hitbox:
				hitbox.set_deferred("monitoring", true)
				hitbox.set_deferred("monitorable", true)
			modulate.a = 1.0
			
			return
		else:
			print("Game over! Final score:", score_manager.get_score())
	
	get_tree().call_deferred("reload_current_scene")
