extends Node2D

signal climb_zone_entered(vehicle: Node2D, player: Node2D, target_global_position: Vector2)
signal climb_zone_exited(vehicle: Node2D, player: Node2D)

@onready var left_climb_area: Area2D = $LeftClimbArea
@onready var right_climb_area: Area2D = $RightClimbArea
@onready var left_climb_target: Marker2D = $LeftClimbTarget
@onready var right_climb_target: Marker2D = $RightClimbTarget


func _ready() -> void:
	add_to_group("vehicle_painting_19")
	left_climb_area.body_entered.connect(_on_left_climb_area_body_entered)
	left_climb_area.body_exited.connect(_on_left_climb_area_body_exited)
	right_climb_area.body_entered.connect(_on_right_climb_area_body_entered)
	right_climb_area.body_exited.connect(_on_right_climb_area_body_exited)


func _on_left_climb_area_body_entered(body: Node) -> void:
	_emit_zone_entered_if_player(body, left_climb_target.global_position)


func _on_right_climb_area_body_entered(body: Node) -> void:
	_emit_zone_entered_if_player(body, right_climb_target.global_position)


func _on_left_climb_area_body_exited(body: Node) -> void:
	_emit_zone_exited_if_player(body)


func _on_right_climb_area_body_exited(body: Node) -> void:
	_emit_zone_exited_if_player(body)


func _emit_zone_entered_if_player(body: Node, target_global_position: Vector2) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var player_node: Node2D = body as Node2D
	if player_node == null:
		return
	climb_zone_entered.emit(self, player_node, target_global_position)


func _emit_zone_exited_if_player(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var player_node: Node2D = body as Node2D
	if player_node == null:
		return
	climb_zone_exited.emit(self, player_node)
