extends Node2D

@export var speed = 300.0
@export var max_distance = 1000.0
@export var damage = 1

var direction = Vector2.ZERO
var distance_traveled = 0.0
var start_position = Vector2.ZERO

func _ready():
	start_position = global_position
	add_to_group("enemy_projectiles")

func initialize(pos: Vector2, dir: Vector2):
	global_position = pos
	direction = dir.normalized()
	rotation = direction.angle()

func _process(delta):
	position += direction * speed * delta
	distance_traveled += speed * delta
	if distance_traveled >= max_distance:
		queue_free()

func _draw():
	var rect_size = Vector2(16, 4)
	var rect_pos = Vector2(-rect_size.x / 2, -rect_size.y / 2)
	draw_rect(Rect2(rect_pos, rect_size), Color(1.0, 0.2, 0.2, 1.0))
	
	var glow_size = rect_size * 1.5
	var glow_pos = Vector2(-glow_size.x / 2, -glow_size.y / 2)
	draw_rect(Rect2(glow_pos, glow_size), Color(1.0, 0.2, 0.2, 0.5))

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.call_deferred("die")
		
		queue_free()
	elif body.is_in_group("walls"):
		queue_free()