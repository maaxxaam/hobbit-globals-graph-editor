class_name ActionNode extends GlobalsGraphNodeBase

const component_type_desc_map: Dictionary[int, String] = {
	0: "Empty action",
	18: "Display text window",
	19: "Finish level",
	22: "Start quest",
	29: "Finish quest",
	30: "Start a fade",
	34: "Remove quest",
	43: "Material related action",
	44: "Silently kill Bilbo",
	48: "(Unused) Alter dream ripple shader parameters"
}
const component_type_name_map: Dictionary[int, Dictionary] = {
	-1: {
		"ExecuteDelay": "Execution delay: ",
		"ExecuteImmediately": "Execute Immediately?"
	},
	0: {},
	18: {
		"StringID": "String ID: ",
		"Scroll": "Use scroll training window?",
		"DelayTime": "Delay before closing: "
	},
	19: {},
	22: {
		"QuestID": "Quest ID: ",
		"Required": "Mark as required?"
	},
	29: {
		"QuestID": "Quest ID: "
	},
	30: {
		"Fadeout": "Fade type: ",
		"Color": "Fade color: ",
		"Duration": "Duration: "
	},
	34: {
		"QuestID": "Quest ID: "
	},
	43: {
		"MaterialName": "Material name: ",
		"Enable": "Enable material?"
	},
	44: {},
	48: {
		"Amp": "Amplitude: "
	}
}
const component_type_param_map: Dictionary[int, Dictionary] = {
	-1: {
		"ExecuteDelay": {
			"suffix": "sec"
		}
	},
	0: {},
	18: {
		"DelayTime": {
			"suffix": "sec"
		}
	},
	19: {},
	22: {},
	29: {},
	30: {
		"Fadeout": {
			"options": ["Fade In", "Fade Out"]
		},
		"Duration": {
			"suffix": "sec"
		}
	},
	34: {},
	43: {},
	44: {},
	48: {}
}
# A map of component type overrides for a specific type
var component_type_type_map: Dictionary[int, Dictionary] = {
	18: {
		"Scroll": AvailableComponents.Boolean
	},
	22: {
		"Required": AvailableComponents.Boolean
	},
	30: {
		"Color": AvailableComponents.ArrayColor,
		"Fadeout": AvailableComponents.Choice
	},
	43: {
		"Enable": AvailableComponents.Boolean
	}
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
	var desc_entry := parsed_data.find_param_by_name("ActionName")
	var type_entry := parsed_data.find_param_by_name("ActionType")
	if (desc_entry == null) or (type_entry == null):
		return # TODO: error
	node_description.text = desc_entry.value
	type_index = type_entry.value
	if not (component_type_name_map.has(type_index) and component_type_desc_map.has(type_index) and component_type_param_map.has(type_index)):
		push_warning("Unknown action type %d in '%s'" % [type_index, parsed_data.name])
		type_description.text = str(type_index)
		return # do not try parsing unknown types. There be dragons!
	type_description.text = component_type_desc_map.get(type_index)
	var params: Array[GlobalsParser.ParsedValue] = parsed_data.params.duplicate(true).filter(func(item): return (item.name != "ActionName") and (item.name != "ActionType"))
	component_name_map = component_type_name_map.get(-1)
	component_params_map = component_type_param_map.get(-1)
	if type_index != 0:
		new_parsed_component(AvailableComponents.Float, parsed_data.find_param_by_name("ExecuteDelay"))
		new_parsed_component(AvailableComponents.Boolean, parsed_data.find_param_by_name("ExecuteImmediately"))
		params = params.filter(func(item): return (item.name != "ExecuteDelay") and (item.name != "ExecuteImmediately"))
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
	node_description = $ActionName
	type_description = $ActionType/TypeDesc
