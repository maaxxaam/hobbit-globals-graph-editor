@abstract class_name GlobalsGraphNodeBase extends GraphNode

enum AvailableComponents {
	Boolean,
	Choice,
	Integer,
	Float,
	Str,
	GUID,
	ArrayInteger,
	ArrayFloat,
	ArrayStr,
	ArrayGUID,
	ArrayColor,
	Unknown
}


var graph: GlobalsGraph
var node_description: LineEdit
var node_class_index: int = -1
var type_index: int
var component_count: int = 0
var type_description: Label
var components: Array[EditComponent]
var component_params_map: Dictionary # [String, Dictionary]
var component_name_map: Dictionary # [String, String]
var component_type_map: Dictionary[AvailableComponents, PackedScene] = {
	AvailableComponents.Boolean   : preload("res://NodeEditComponents/checkbox_component.tscn"),
	AvailableComponents.Choice    : preload("res://NodeEditComponents/dropdown_component.tscn"),
	AvailableComponents.Integer   : preload("res://NodeEditComponents/int_component.tscn"),
	AvailableComponents.Float     : preload("res://NodeEditComponents/float_component.tscn"),
	AvailableComponents.Str       : preload("res://NodeEditComponents/string_component.tscn"),
	# TODO: proper GUID component
	AvailableComponents.GUID      : preload("res://NodeEditComponents/string_component.tscn"),
	AvailableComponents.ArrayColor: preload("res://NodeEditComponents/rgba_component.tscn")
}

func export() -> Dictionary[String, Variant]:
	components.sort_custom(func(item1, item2): return item1.variable_order < item2.variable_order)
	var total_components: Dictionary[String, Variant] = export_before_components()
	#total_components.set(wrap_var_name("Name"), node_description.text)
	#total_components.set(wrap_var_name("Type"), type_index)
	for component in components:
		total_components.merge(component.export())
	total_components.merge(export_after_components())
	return { "name": title, "row_count": 1, "rows": [total_components] }


func link_graph(new_graph: GlobalsGraph):
	graph = new_graph


func add_new_component(component_type: AvailableComponents, component_name: String, params: Dictionary[String, Variant] = {}):
	if not component_type_map.has(component_type):
		push_error("Unrecognized component type %s" % [component_type])
		return
	var comp: EditComponent = component_type_map.get(component_type).instantiate()
	add_child(comp)
	comp.init_component(self, component_name, component_name_map.get(component_name, component_name), comp.variable_default, component_params_map.get(component_name, {}) if params.is_empty() else params)
	components.append(comp)


func add_parsed_component(component_type: AvailableComponents, component_name: String, value: Variant, params: Dictionary = {}):
	if not component_type_map.has(component_type):
		push_error("Unrecognized component type %s" % [component_type])
		return
	var comp: EditComponent = component_type_map.get(component_type).instantiate()
	add_child(comp)
	comp.init_component(self, component_name, component_name_map.get(component_name, component_name), value, component_params_map.get(component_name, {}) if params.is_empty() else params)
	components.append(comp)


func new_parsed_component(component_type: AvailableComponents, parsed_data: GlobalsParser.ParsedValue):
	add_parsed_component(component_type, parsed_data.name, parsed_data.value, component_params_map.get(parsed_data.name, {}))


func find_component(component_name: String):
	return components.find_custom(func(item: EditComponent): return item.variable_name == component_name)


func remove_component(component_name: String):
	var component_index: int = find_component(component_name)
	if component_index == -1:
		push_error("Tried to delete component '%s' from node '%s', but that node doesn't have such component" % [component_name, title])
		return
	components[component_index].queue_free()
	components.remove_at(component_index)


func component_type_from_string(from: String) -> AvailableComponents:
	match from:
		"d":
			return AvailableComponents.Integer
		"f":
			return AvailableComponents.Float
		"s":
			return AvailableComponents.Str
		"g":
			return AvailableComponents.GUID
		"ad":
			return AvailableComponents.ArrayInteger
		"af":
			return AvailableComponents.ArrayFloat
		"as":
			return AvailableComponents.ArrayStr
		"ag":
			return AvailableComponents.ArrayGUID
		_:
			return AvailableComponents.Unknown



func _component_default_defaults(type: AvailableComponents) -> Variant:
	match type:
		AvailableComponents.Boolean:
			return false
		AvailableComponents.Choice, AvailableComponents.Integer:
			return 0
		AvailableComponents.Float:
			return 0.0
		_:
			return null


func spawn_simple_parsed_components(entries: Array[GlobalsParser.ParsedValue]) -> void:
	for item in entries:
		var type := component_type_from_string(item.type)
		var params: Dictionary = component_params_map.get(item.name, {})
		add_parsed_component(type, item.name, item.value, params)


func set_node_title(to: String) -> void:
	title = to
	node_class_index = GlobalsParser.get_int_from_string_end(to)


@abstract func export_before_components() -> Dictionary[String, Variant]
@abstract func export_after_components() -> Dictionary[String, Variant]
@abstract func wrap_var_name(var_name: String) -> String
@abstract func from_parsed(parsed_data: GlobalsParser.ParsedEntry)
@abstract func from_empty(type: int)
@abstract func get_component_default(type: AvailableComponents, component_name: String)
@abstract func get_node_description() -> String
