class_name RGBAComponent extends EditComponent

@onready var name_label := $Label
@onready var color_button: ColorPickerButton = $ColorBtn
@onready var color_r: SpinBox = $R
@onready var color_g: SpinBox = $G
@onready var color_b: SpinBox = $B
@onready var color_a: SpinBox = $A
var debounced_value := Color()


func _ready():
	variable_default = Color()


func set_value(value: Variant):
	if value is Array:
		pass
	elif value is Color:
		pass
	else:
		pass


func init_component(node: GlobalsGraphNodeBase, _var_name: String, display_name: String, value: Variant, _params: VarParameters):
	name_label.text = display_name
	graph_node = node
	set_value(value)


func _on_color_btn_color_changed(color):
	set_value(color)


func _on_debounce_timer_timeout():
	set_value(debounced_value)
