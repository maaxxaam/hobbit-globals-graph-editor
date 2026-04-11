class_name ActionNode extends GlobalsGraphNodeBase

const component_type_name_def_map: Dictionary[String, String] = {
	"ExecuteDelay": "Execution delay: ",
	"ExecuteImmediately": "Execute Immediately?"
}

var component_type_param_def_map: Dictionary[String, VarParameters] = {
	"ExecuteDelay": VarParameters.from_dict({
		"suffix": "sec"
	})
}

# A map of component type overrides for a specific type
var component_type_type_def_map: Dictionary[String, GlobalsGraphNodeBase.AvailableComponents] = {
	"ExecuteImmediately": AvailableComponents.Boolean
}


func export_before_components() -> Dictionary[String, Variant]:
	return {
		"ActionType%s" % [node_class_index]: type_index,
		"ActionName%s" % [node_class_index]: node_description.text
	}


func export_after_components() -> Dictionary[String, Variant]:
	return {}


func wrap_var_name(var_name: String) -> String:
	return "Action%s%s" % [node_class_index, var_name]


func from_empty(type: int):
	node_class_index = graph.get_node_class_index("ActionNode")
	var node_title: String = "Action%s" % [node_class_index]
	set_node_title(node_title)
	node_description.text = ""
	type_index = type
	if not component_storage.mapping.has(type_index):
		push_warning("Unknown action type %d in '%s'" % [type_index, node_title])
		type_description.text = str(type_index)
		return # do not try parsing unknown types. There be dragons!
	var type_data: ComponentData = component_storage.mapping.get(type_index) as ComponentData
	type_description.text = type_data.descriptive_name
	component_name_map = component_type_name_def_map
	component_params_map = component_type_param_def_map
	if type_index != 0:
		add_new_component(AvailableComponents.Float, "ExecuteDelay")
		add_new_component(AvailableComponents.Boolean, "ExecuteImmediately")
	component_name_map = type_data.variable_aliases
	component_params_map = type_data.variable_params
	component_type_type_map = type_data.type_overrides
	for key in component_type_type_map:
		if component_type_type_map.get(key, AvailableComponents.Unknown) == AvailableComponents.Unknown:
			continue


func spawn_special_parsed_components(entries: Array[GlobalsParser.ParsedValue]) -> Array:
	if component_type_type_map.is_empty():
		return entries
	if type_index == 42: # Edge case: NPC1 + NPC2 fields get combined into an array
		var npcs_index = entries.find_custom(func(item: GlobalsParser.ParsedValue): return item.name == "NPC")
		if npcs_index == -1:
			push_error("No NPC array found for action type 42")
		else:
			var npcs: Array = entries[npcs_index].value as Array
			add_parsed_component(AvailableComponents.GUID, "NPC1", npcs[1], component_params_map.get("NPC1", VarParameters.new()))
			add_parsed_component(AvailableComponents.GUID, "NPC2", npcs[2], component_params_map.get("NPC2", VarParameters.new()))
			entries[npcs_index].name = "/REMOVE_ME_DEAD/"

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
	if component_type_type_map.is_empty():
		return entries
	for i in len(entries):
		var type: AvailableComponents = component_type_type_map.get(entries[i].name, AvailableComponents.Unknown)
		if type == AvailableComponents.Unknown:
			continue
		new_parsed_component(type, entries[i])
		if type == AvailableComponents.Link:
			set_slot(4 + len(components) - 1, true, 2, Color(0.0, 0.0, 1.0), false, 0, Color())
		entries[i].name = "/REMOVE_ME_DEAD/"
	return entries.filter(func(item: GlobalsParser.ParsedValue): return item.name != "/REMOVE_ME_DEAD/")


func from_parsed(parsed_data: GlobalsParser.ParsedEntry):
	set_node_title(parsed_data.name)
	var desc_entry := parsed_data.find_param_by_name("ActionName")
	var type_entry := parsed_data.find_param_by_name("ActionType")
	if (desc_entry == null) or (type_entry == null):
		return # TODO: error
	node_description.text = desc_entry.value
	type_index = type_entry.value
	if not component_storage.mapping.has(type_index):
		push_warning("Unknown action type %d in '%s'" % [type_index, parsed_data.name])
		type_description.text = str(type_index)
		return # do not try parsing unknown types. There be dragons!
	var type_data: ComponentData = component_storage.mapping.get(type_index) as ComponentData
	type_description.text = type_data.descriptive_name
	var params: Array[GlobalsParser.ParsedValue] = parsed_data.params.duplicate(true).filter(func(item): return (item.name != "ActionName") and (item.name != "ActionType"))
	component_name_map = component_type_name_def_map
	component_params_map = component_type_param_def_map
	if type_index != 0:
		new_parsed_component(AvailableComponents.Float, parsed_data.find_param_by_name("ExecuteDelay"))
		new_parsed_component(AvailableComponents.Boolean, parsed_data.find_param_by_name("ExecuteImmediately"))
		params = params.filter(func(item): return (item.name != "ExecuteDelay") and (item.name != "ExecuteImmediately"))
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
	node_description = $ActionName
	type_description = $ActionType/TypeDesc


func link_graph(new_graph: GlobalsGraph):
	super.link_graph(new_graph)
	component_storage = graph.action_storage
