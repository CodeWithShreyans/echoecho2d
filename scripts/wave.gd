extends Node2D

@export var wave_speed = 400.0
@export var max_distance = 750.0
@export var wave_width = 5.0
@export var wave_color = Color(0.0, 1.0, 1.0, 1.0)
@export var wave_length = 30.0
@export var trail_length = 3

var direction = Vector2.ZERO
var distance_traveled = 0.0
var start_position = Vector2.ZERO
var previous_positions = []
var max_trail_points = 10
var is_enemy_reflection = false
var active = true
var last_position = Vector2.ZERO
var reflection_count = 0

func _ready():
	print("Wave instance created")
	start_position = global_position
	last_position = global_position
	modulate = Color(1.5, 1.5, 1.5, 1.0)
	$Area2D.collision_layer = 4
	$Area2D.collision_mask = 3

func initialize(pos: Vector2, dir: Vector2):
	print("Wave initialized with direction: ", dir)
	global_position = pos
	last_position = pos
	direction = dir
	rotation = dir.angle()
	previous_positions = [pos]
	queue_redraw()

func _process(delta):
	if not active:
		return
		
	var prev_pos = global_position
	
	position += direction * wave_speed * delta
	
	var frame_distance = global_position.distance_to(prev_pos)
	distance_traveled += frame_distance
	
	last_position = global_position
	previous_positions.push_front(global_position)
	if previous_positions.size() > max_trail_points:
		previous_positions.pop_back()
	
	var progress = distance_traveled / max_distance
	var alpha = clamp(1.0 - progress, 0.0, 1.0)
	modulate.a = alpha
	
	if distance_traveled >= max_distance:
		print("Wave reached max distance, removing")
		queue_free()
	
	queue_redraw()

func _draw():
	if not active:
		return
		
	var current_color = Color(1.0, 0.2, 0.2, 1.0) if is_enemy_reflection else wave_color
	
	var line_points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(wave_length, 0)
	])
	
	var glow_color = current_color
	glow_color.a = 0.7
	draw_polyline(line_points, glow_color, wave_width * 2.5)
	draw_polyline(line_points, current_color, wave_width)
	
	var core_color = current_color
	core_color.a = 1.0
	draw_polyline(line_points, core_color, wave_width * 0.5)
	
	if previous_positions.size() > 1:
		for i in range(previous_positions.size() - 1):
			var fade = clamp(1.0 - (float(i) / previous_positions.size()), 0.3, 1.0)
			var trail_color = current_color
			trail_color.a *= fade * 0.9
			var start = to_local(previous_positions[i])
			var end = to_local(previous_positions[i + 1])
			draw_line(start, end, trail_color, wave_width * fade)

func reflect(normal: Vector2, is_from_enemy: bool = false):
	reflection_count += 1
	direction = direction.bounce(normal)
	rotation = direction.angle()
	previous_positions = [global_position]
	is_enemy_reflection = is_from_enemy

func _on_area_2d_body_entered(body):
	if not active:
		return
		
	print("Wave detected collision with: ", body.name, ", groups: ", body.get_groups())
	
	if body.is_in_group("walls"):
		print("Wave hit wall, despawning")
		queue_free()
	elif body.is_in_group("enemies"):
		print("Wave hit enemy at position: ", body.global_position)
		
		if body.has_method("on_wave_hit"):
			print("Calling on_wave_hit on enemy")
			body.on_wave_hit()
		else:
			print("ERROR: Enemy does not have on_wave_hit method!")
		
		queue_free()
