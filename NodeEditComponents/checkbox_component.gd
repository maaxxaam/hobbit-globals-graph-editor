class_name CheckboxComponent extends EditComponent

var checkbox: CheckBox


func _ready():
	variable_default = false


func set_value(value: Variant):
	if value is not bool:
		if value is int and value in [0,1]:
			value = bool(value)
		else:
			push_error("Expected bool on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
			return
	variable_value = value
	checkbox.set_pressed_no_signal(value)


func _on_check_box_toggled(toggled_on):
	set_value(toggled_on)


func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, _params: Dictionary):
	variable_display_name = display_name
	checkbox = $CheckBox
	graph_node = node
	variable_name = var_name
	checkbox.text = display_name
	variable_order = graph_node.component_count
	set_value(value)
