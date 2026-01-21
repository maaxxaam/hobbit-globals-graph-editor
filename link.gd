class_name LinkNode extends GlobalsGraphNodeBase


func export_before_components() -> Dictionary[String, Variant]:
	return {}


func export_after_components() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	var connections = graph.get_connection_list_from_node(name)
	var in_connections = connections.filter(func(item): return item["to_node"] == name).map(func(item): return item["from_node"])
	var out_connections = connections.filter(func(item): return item["from_node"] == name).map(func(item): return item["to_node"])
	# Start with triggers first
	var triggers: Array[int] = []
	for item in in_connections:
		var node = graph.get_node(NodePath(item)) as GlobalsGraphNodeBase
		triggers.append(node.node_class_index)
	triggers.sort()
	result.set("LinkTriggerCount%s" % [node_class_index], len(triggers))
	for i in len(triggers):
		result.set("LinkTriggerIndex%s-%s" % [node_class_index, i], triggers[i])
	# Then actions
	var actions: Array[int] = []
	for item in out_connections:
		var node = graph.get_node(NodePath(item)) as GlobalsGraphNodeBase
		actions.append(node.node_class_index)
	actions.sort()
	result.set("LinkActionCount%s" % [node_class_index], len(actions))
	for i in len(actions):
		result.set("LinkActionIndex%s-%s" % [node_class_index, i], actions[i])
	return result


func wrap_var_name(var_name: String) -> String:
	return var_name + String.num_int64(node_class_index)


func _ready():
	component_name_map = {
		"LinkRepeats": "Link Repeats? ",
		"LogicType": "Logic type: ",
		"LinkState": "Link state: "
	}
	component_params_map = {
		"LogicType": {
			"options": ["All triggers", "Any trigger"]
		}
	}


func from_parsed(parsed_data: GlobalsParser.ParsedEntry):
	var link_repeats := parsed_data.find_param_by_name("LinkRepeats")
	var link_state := parsed_data.find_param_by_name("LinkState")
	var logic_type := parsed_data.find_param_by_name("LogicType")
	var triggers := parsed_data.find_param_by_name("LinkTrigger")
	var actions := parsed_data.find_param_by_name("LinkAction")
	if link_repeats == null:
		return
	if logic_type == null:
		return
	if link_state == null:
		return
	if triggers == null:
		return
	if actions == null:
		return
	set_node_title(parsed_data.name)
	new_parsed_component(AvailableComponents.Boolean, link_repeats)
	new_parsed_component(AvailableComponents.Choice, link_state)
	new_parsed_component(AvailableComponents.Choice, logic_type)
	set_slot(0, true, 0, Color(1.0, 1.0, 1.0), true, 1, Color(1.0, 1.0, 0.0))


func from_empty(_type: int):
	node_class_index = graph.get_node_class_index("LinkNode")
	title = "Link%s" % [node_class_index]
	add_new_component(AvailableComponents.Boolean, "LinkRepeats")
	add_new_component(AvailableComponents.Choice, "LinkState")
	add_new_component(AvailableComponents.Choice, "LogicType")
	set_slot(0, true, 0, Color(1.0, 1.0, 1.0), true, 1, Color(1.0, 1.0, 0.0))


func get_component_default(type: AvailableComponents, _component_name: String):
	return _component_default_defaults(type)


func get_node_description() -> String:
	return title
