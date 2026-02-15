# res://game/player/aim_crosshair.gd

extends Node2D

@export var radius: float = 6.0
@export var line_length: float = 14.0
@export var color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var thickness: float = 1.0


func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position()
	queue_redraw()


func _draw() -> void:
	var inner: float = radius
	var outer: float = radius + line_length
	var faint: Color = Color(color.r, color.g, color.b, color.a * 0.25)

	draw_circle(Vector2.ZERO, inner, faint)
	draw_arc(Vector2.ZERO, inner, 0.0, TAU, 24, color, thickness, true)

	draw_line(Vector2(-outer, 0.0), Vector2(-inner, 0.0), color, thickness, true)
	draw_line(Vector2(outer, 0.0), Vector2(inner, 0.0), color, thickness, true)
	draw_line(Vector2(0.0, -outer), Vector2(0.0, -inner), color, thickness, true)
	draw_line(Vector2(0.0, outer), Vector2(0.0, inner), color, thickness, true)
