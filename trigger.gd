class_name TriggerNode extends GlobalsGraphNodeBase

const component_type_name_def_map: Dictionary[String, String] = {
	"StaysTrue": "Stays True?",
	"TriggeredOnTrue": "Triggered on True?"
}


# A map of component type overrides for a specific type
var component_type_type_def_map: Dictionary[String, GlobalsGraphNodeBase.AvailableComponents] = {
	"StaysTrue": AvailableComponents.Boolean,
	"TriggeredOnTrue": AvailableComponents.Boolean
}


func export_before_components() -> Dictionary[String, Variant]:
	return {
		"ActionType%s" % [node_class_index]: type_index,
		"ActionName%s" % [node_class_index]: node_description.text
	}


func export_after_components() -> Dictionary[String, Variant]:
	return {}


func wrap_var_name(var_name: String) -> String:
	return var_name + str(node_class_index)


func from_empty(_type: int):
	pass


func spawn_special_parsed_components(entries: Array[GlobalsParser.ParsedValue]) -> Array:
	if component_type_type_map.is_empty():
		return entries
	for type_key in component_type_type_map.keys():
		if component_type_type_map[type_key] != GlobalsGraphNodeBase.AvailableComponents.Counter:
			continue
		var array_mapping := (component_params_map[type_key] as VarParameters).data.get("array_id", -1) as int
		if array_mapping == -1:
			push_error('"%s" is an array counter but no "array_id" was provided in its params, skipping' % [type_key])
			continue
		var array_name := (component_params_map[type_key] as VarParameters).data.get("array_name", "") as String
		if array_name.is_empty():
			push_error('"%s" is an array counter but no "array_name" was provided in its params, skipping' % [type_key])
			continue
		var array_map = graph.array_storage.mapping.get(array_mapping) as ComponentData
		if array_map == null:
			push_error('"%s" is an array counter of unknown array type %s' % [type_key, array_mapping])
			continue
		var length_index: int = entries.find_custom(func(item: GlobalsParser.ParsedValue): return item.name == type_key)
		if length_index == -1:
			push_error('"%s" is an array counter for type %s but no such entry found in %s' % [type_key, type_index, node_description.text])
			continue
		var length: int = entries[length_index].value as int
		entries[length_index].name = "/REMOVE_ME_DEAD/"
		var array_data: Array[Dictionary] = []
		array_data.resize(length)

		for i in len(entries):
			var type: AvailableComponents = array_map.type_overrides.get(entries[i].name, AvailableComponents.Unknown)
			if type == AvailableComponents.Unknown or type == AvailableComponents.Counter:
				continue

			for j in length:
				array_data[j].set(entries[i].name, (entries[i].value as Array)[j])

			entries[i].name = "/REMOVE_ME_DEAD/"
		add_parsed_component(AvailableComponents.Counter, array_name, array_data, (component_params_map[type_key] as VarParameters))
	return entries.filter(func(item: GlobalsParser.ParsedValue): return item.name != "/REMOVE_ME_DEAD/")


func spawn_custom_parsed_components(entries: Array[GlobalsParser.ParsedValue]) -> Array:
	if not component_storage.mapping.has(type_index):
		return entries
	var type_data: ComponentData = component_storage.mapping.get(type_index) as ComponentData
	var mapping: Dictionary = type_data.type_overrides
	for i in len(entries):
		var type: AvailableComponents = mapping.get(entries[i].name, AvailableComponents.Unknown)
		if type == AvailableComponents.Unknown:
			continue
		new_parsed_component(type, entries[i])
		entries[i].name = "/REMOVE_ME_DEAD/"
	return entries.filter(func(item: GlobalsParser.ParsedValue): return item.name != "/REMOVE_ME_DEAD/")


func from_parsed(parsed_data: GlobalsParser.ParsedEntry):
	set_node_title(parsed_data.name)
	var desc_entry := parsed_data.find_param_by_name("TriggerName")
	var type_entry := parsed_data.find_param_by_name("TriggerType")
	if (desc_entry == null) or (type_entry == null):
		return # TODO: error
	node_description.text = desc_entry.value
	type_index = type_entry.value
	if not component_storage.mapping.has(type_index):
		push_warning("Unknown trigger type %d in '%s'" % [type_index, parsed_data.name])
		type_description.text = str(type_index)
		return # do not try parsing unknown types. There be dragons!
	var type_data: ComponentData = component_storage.mapping.get(type_index) as ComponentData
	type_description.text = type_data.descriptive_name
	var params: Array[GlobalsParser.ParsedValue] = parsed_data.params.duplicate(true).filter(func(item): return (item.name != "TriggerName") and (item.name != "TriggerType"))
	component_name_map = component_type_name_def_map
	if type_index != 0:
		new_parsed_component(AvailableComponents.Boolean, parsed_data.find_param_by_name("StaysTrue"))
		new_parsed_component(AvailableComponents.Boolean, parsed_data.find_param_by_name("TriggeredOnTrue"))
		params = params.filter(func(item): return (item.name != "StaysTrue") and (item.name != "TriggeredOnTrue"))
	component_name_map = type_data.variable_aliases
	component_params_map = type_data.variable_params
	component_type_type_map = type_data.type_overrides
	params = spawn_special_parsed_components(params.duplicate(true))
	params = spawn_custom_parsed_components(params.duplicate(true))
	spawn_simple_parsed_components(params)


func get_component_default(_type: AvailableComponents, _component_name: String):
	pass


func get_node_description() -> String:
	return node_description.text


func _ready():
	type_description = $TriggerType/TypeDesc
	node_description = $TriggerName


func link_graph(new_graph: GlobalsGraph):
	super.link_graph(new_graph)
	component_storage = graph.trigger_storage
