extends Area2D

signal collected(amount: int)
signal pickup_requested(drop: Node2D)

@export var amount: int = 1

var _is_pickup_requested: bool = false


func _ready() -> void:
	input_pickable = true
	collision_layer = 0
	collision_mask = 1
	add_to_group("item_axe")
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	collected.emit(amount)
	queue_free()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	request_pickup()


func request_pickup() -> void:
	if _is_pickup_requested:
		return
	_is_pickup_requested = true
	pickup_requested.emit(self)


func is_pickup_requested() -> bool:
	return _is_pickup_requested
