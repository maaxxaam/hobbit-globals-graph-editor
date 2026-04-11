class_name StructComponent extends EditComponent
var contents: Dictionary[String, EditComponent] = {}
@onready var index_label: Label = $HBoxContainer/Index
@onready var container: VBoxContainer = $HBoxContainer/StructContainer
var parameters: Dictionary[String, VarParameters]
var aliases: Dictionary[String, String]
var type_map: Dictionary[String, GlobalsGraphNodeBase.AvailableComponents]
var default_params: Dictionary[String, Variant] = {
	#"min_value": 0,
	#"max_value": 10000,
	#"step": 0.001,
	# "prefix": "",
	# "suffix": "",
	# "unbounded_down": false,
	#"unbounded_up": true
}

func _ready():
	variable_default = 0.0


func set_index(index: int):
	index_label.text = str(index)


func set_value(value: Variant):
	if value is not Dictionary:
		push_error("Expected Dictionary for value, got %s" % [])
	variable_value = value


func add_field(field_type: GlobalsGraphNodeBase.AvailableComponents, key: String, field_value: Variant):
	var new_scene: PackedScene = graph_node.get_scene(field_type)
	var new_item: EditComponent = new_scene.instantiate()
	container.add_child(new_item)
	new_item.init_component(graph_node, key, aliases.get(key, key), field_value, parameters.get(key, VarParameters.new()))
	(variable_value as Dictionary).set(key, field_value)


func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: VarParameters = VarParameters.new()):
	index_label = $HBoxContainer/Index
	container = $HBoxContainer/StructContainer
	variable_display_name = display_name
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count
	variable_value = Dictionary()
	var array_index: int = params.data.get("array_id", -1)
	if array_index == -1:
		push_error('Tried to init array element without supplementing "array_id" in params')
		return
	var array_info: ComponentData = graph_node.graph.array_storage.mapping.get(array_index)
	if array_info == null:
		push_error('Tried to init array element with unknown "array_id" of %s' % [array_index])
		return
	parameters = array_info.variable_params
	type_map = array_info.type_overrides
	aliases = array_info.variable_aliases

	for key in type_map.keys():
		if type_map[key] == GlobalsGraphNodeBase.AvailableComponents.Counter:
			continue
		add_field(type_map[key], key, (value as Dictionary).get(key))

	# set_value(value)


func export() -> Dictionary[String, Variant]:
	# TODO: export for array elemets
	var result: Dictionary[String, Variant] = {}
	for item in contents.keys():
		var exported = contents[item].export()
		for val in exported.keys():
			result.set(val + variable_name, exported[val])
	return result
