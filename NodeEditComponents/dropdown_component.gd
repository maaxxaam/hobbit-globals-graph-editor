class_name DropdownComponent extends EditComponent

var options: OptionButton
var name_text: Label
var default_params: Dictionary[String, Variant] = {
	"options": ["Enabled", "Disabled", "Unknown State 2", "Permanently Disabled"]
}


func _ready():
	variable_default = 0


func set_value(value: Variant):
	if value is not int:
		push_error("Expected int on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
		return
	variable_value = value
	if options.selected != value:
		if value >= options.item_count:
			var option_texts: Array[String] = []
			for idx in options.item_count:
				option_texts.append(options.get_item_text(idx))
			push_error("Got asked for dropdown option %s in var %s, only have %s" % [value, variable_name, option_texts])
		options.select(value)


func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: Dictionary = default_params):
	variable_display_name = display_name
	options = $OptionButton
	name_text = $Label
	graph_node = node
	variable_name = var_name
	name_text.text = display_name + " "
	variable_order = graph_node.component_count

	for item in params.get("options", default_params["options"]):
		options.add_item(item)

	set_value(value)


func _on_option_button_item_selected(index):
	set_value(index)
