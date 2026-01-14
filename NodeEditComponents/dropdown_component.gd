class_name DropdownComponent extends EditComponent

var options: OptionButton
var name_text: Label
var default_params: Dictionary[String, Variant] = {
	"options": ["Enabled", "Disabled"]
}

func set_value(value: Variant):
	if value is not int:
		push_error("Expected int on assignment to value '%s', got %s" % [variable_name, typeof(value)])
		return
	variable_value = value
	if options.selected != value:
		options.select(value)

func init_component(node: GlobalsGraphNodeBase, var_name: String, value: Variant, params: Dictionary[String, Variant] = default_params):
	options = $OptionButton
	name_text = $Label
	graph_node = node
	variable_name = var_name
	name_text.text = variable_name + " "
	variable_order = graph_node.component_count

	for item in params.get("options", default_params["options"]):
		options.add_item(item)

	set_value(value)


func _on_option_button_item_selected(index):
	set_value(index)
