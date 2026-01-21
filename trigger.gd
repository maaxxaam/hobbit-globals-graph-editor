class_name TriggerNode extends GlobalsGraphNodeBase

const component_type_desc_map: Dictionary[int, String] = {
	0:  "Empty action",
	5:  "Periodically with random chance",
	9:  "Bilbo has X items",
	22: "Lighting related trigger",
	24: "On quest completed"
}
const component_type_name_map: Dictionary[int, Dictionary] = {
	-1: {
		"StaysTrue": "Stays True?",
		"TriggeredOnTrue": "Triggered on True?"
	},
	0: {},
	5: {
		"CheckTime": "Period to check after: ",
		"RandomPercent": "Percent chance to happen: "
	},
	9: {},
	22: {},
	24: {
		"QuestName": "Quest name: "
	}
}
const component_type_param_map: Dictionary[int, Dictionary] = {
	-1: {},
	0: {},
	5: {
		"RandomPercent": {
			"max_value": 100,
			"suffix": "%",
			"unbounded_up": false
		},
		"CheckTime": {
			"suffix": " sec"
		}
	},
	9: {},
	22: {},
	24: {}
}
# A map of component type overrides for a specific type
var component_type_type_map: Dictionary[int, Dictionary] = {
	#
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
	return entries


func spawn_custom_parsed_components(entries: Array[GlobalsParser.ParsedValue]) -> Array:
	if not component_type_type_map.has(type_index):
		return entries
	var mapping: Dictionary = component_type_type_map.get(type_index)
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
	if not (component_type_name_map.has(type_index) and component_type_desc_map.has(type_index) and component_type_param_map.has(type_index)):
		push_warning("Unknown trigger type %d in '%s'" % [type_index, parsed_data.name])
		type_description.text = str(type_index)
		return # do not try parsing unknown types. There be dragons!
	type_description.text = component_type_desc_map.get(type_index)
	var params: Array[GlobalsParser.ParsedValue] = parsed_data.params.duplicate(true).filter(func(item): return (item.name != "TriggerName") and (item.name != "TriggerType"))
	component_name_map = component_type_name_map.get(-1)
	component_params_map = component_type_param_map.get(-1)
	if type_index != 0:
		new_parsed_component(AvailableComponents.Boolean, parsed_data.find_param_by_name("StaysTrue"))
		new_parsed_component(AvailableComponents.Boolean, parsed_data.find_param_by_name("TriggeredOnTrue"))
		params = params.filter(func(item): return (item.name != "StaysTrue") and (item.name != "TriggeredOnTrue"))
	component_name_map = component_type_name_map.get(type_index)
	component_params_map = component_type_param_map.get(type_index)
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
