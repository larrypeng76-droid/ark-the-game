extends Node2D

@export_range(0.05, 1.0, 0.01) var lifetime: float = 0.22
@export_range(1.0, 256.0, 1.0) var radius: float = 2.0
@export var fill_color: Color = Color(0.65, 0.85, 1.0, 0.22)
@export var outline_color: Color = Color(0.80, 0.95, 1.0, 0.45)

var _time_left: float = 0.0


func _ready() -> void:
	_time_left = lifetime
	queue_redraw()


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return
	var alpha_factor: float = _time_left / maxf(lifetime, 0.001)
	modulate.a = alpha_factor


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline_color, 2.0)
