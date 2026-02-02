@tool
class_name TitleBar extends Button

@export var node_to_move: Control
var last_mouse_position: Vector2


func _ready():
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	toggle_mode = false
	button_down.connect(_on_button_down)


func _validate_property(property):
	if property.name == "action_mode" or property.name == "toggle_mode" or property.name == "button_pressed":
		property.usage = PROPERTY_USAGE_NO_EDITOR


func _process(_delta):
	if button_pressed and node_to_move != null:
		var offset := last_mouse_position - node_to_move.global_position
		last_mouse_position = get_global_mouse_position()
		node_to_move.global_position = last_mouse_position - offset


func _on_button_down():
	last_mouse_position = get_global_mouse_position()
	prints("Titlebar:", last_mouse_position, global_position)
