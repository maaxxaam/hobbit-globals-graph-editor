class_name DropdownComponent extends EditComponent

var options: OptionButton
var name_text: Label
var option_mapping: Dictionary # Dictionary[int, String]
var default_params: Dictionary[String, Variant] = {
	"options": ["Enabled", "Disabled", "Permanently Enabled", "Permanently Disabled"]
}


func _ready():
	variable_default = 0


func mapping_from_array(arr: Array):
	option_mapping = {}
	for i in len(arr):
		option_mapping.set(i, arr[i])


func set_value(value: Variant):
	if value is not int:
		push_error("Expected int on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
		return
	variable_value = value
	if options.selected != value:
		var ids: Array = option_mapping.keys()
		ids.sort()
		var index_to_select: int = ids.find(variable_value)
		if index_to_select == -1:
			push_error("Got asked for dropdown option %s in var %s, only have %s" % [value, variable_name, option_mapping])
		else:
			options.select(index_to_select)


func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: VarParameters = VarParameters.new()):
	variable_display_name = display_name
	options = $OptionButton
	name_text = $Label
	graph_node = node
	variable_name = var_name
	name_text.text = display_name + " "
	variable_order = graph_node.component_count

	var dropdown_options: Variant = params.data.get("options", default_params["options"])
	if dropdown_options is Array:
		mapping_from_array(dropdown_options)
	else:
		option_mapping = (dropdown_options as Dictionary[int, String])
	var option_keys = option_mapping.keys()
	option_keys.sort()
	for item in option_keys:
		options.add_item(option_mapping[item])

	set_value(value)


func _on_option_button_item_selected(index):
	set_value(option_mapping.find_key(options.get_item_text(index)))
