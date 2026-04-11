class_name ArrayContainer extends EditComponent

const DEBOUNCE_DURATION = 0.2
#@onready var debounce: Timer = $DebounceTimer
@onready var name_label: Label = $ArrayHeader/ArrayName
@onready var item_container: VBoxContainer = $ArrayItems
var items: Array[EditComponent] = []
var parameters: Dictionary[String, Variant]
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


func set_value(_value: Variant):
	variable_value = len(items)


func add_item(value: Dictionary):
	var index: int = len(items)
	var new_scene: PackedScene = graph_node.get_scene(GlobalsGraphNodeBase.AvailableComponents.Structure)
	var new_item: StructComponent = new_scene.instantiate() as StructComponent
	item_container.add_child(new_item)
	new_item.init_component(graph_node, str(index), str(index), value, VarParameters.from_dict(parameters))
	new_item.set_index(index)
	items.append(new_item)


func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: VarParameters = VarParameters.new()):
	variable_display_name = display_name
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count
	name_label.text = display_name + " "
	parameters = params.data

	var array_index: int = params.data.get("array_id", -1)
	if array_index == -1:
		push_error('Tried to init array without supplementing "array_id" in params')
		return
	var array_info: ComponentData = graph_node.graph.array_storage.mapping.get(array_index)
	if array_info == null:
		push_error('Tried to init array with unknown "array_id" of %s' % [array_index])
		return
	variable_display_name = array_info.descriptive_name
	name_label.text = variable_display_name

	# Value here is supposed to be Array[Dictionary]
	for item in (value as Array):
		add_item(item)

	set_value(value)

func export() -> Dictionary[String, Variant]:
	var result = super.export()
	for item in items:
		var exported = item.export()
		for val in exported.keys():
			var export_name: String = val
			if val in parameters:
				export_name += (parameters[val] as VarParameters).data.get("export_suffix", "") as String
	return result
