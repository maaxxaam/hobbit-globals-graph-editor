class_name LinkNode extends GlobalsGraphNodeBase

var connect_triggers: Array[StringName] = []
var trigger_remove_queue: Array[bool] = []
var connect_actions: Array[StringName] = []
var action_remove_queue: Array[bool] = []
var update_queued: bool = false


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
		"LogicType": VarParameters.from_dict({
			"options": ["All triggers", "Any trigger"]
		})
	}


func from_parsed(parsed_data: GlobalsParser.ParsedEntry):
	var link_repeats := parsed_data.find_param_by_name("LinkRepeats")
	var link_state := parsed_data.find_param_by_name("LinkState")
	var logic_type := parsed_data.find_param_by_name("LogicType")
	# var triggers := parsed_data.find_param_by_name("LinkTrigger")
	# var actions := parsed_data.find_param_by_name("LinkAction")
	if link_repeats == null:
		return
	if logic_type == null:
		return
	if link_state == null:
		return
	# if triggers == null:
	# 	return
	# if actions == null:
	# 	return
	set_node_title(parsed_data.name)
	new_parsed_component(AvailableComponents.Boolean, link_repeats)
	new_parsed_component(AvailableComponents.Choice, link_state)
	new_parsed_component(AvailableComponents.Choice, logic_type)
	add_new_component(AvailableComponents.LinkSlot, "Slot0")
	set_slot(3, true, 0, Color(1.0, 1.0, 1.0), true, 1, Color(1.0, 1.0, 0.0))
	# Add a slot for link state changes
	set_slot(1, false, 0, Color(1.0, 1.0, 1.0), true, 2, Color(0.0, 0.0, 1.0))


func from_empty(_type: int):
	node_class_index = graph.get_node_class_index("LinkNode")
	title = "Link%s" % [node_class_index]
	add_new_component(AvailableComponents.Boolean, "LinkRepeats")
	add_new_component(AvailableComponents.Choice, "LinkState")
	add_new_component(AvailableComponents.Choice, "LogicType", component_params_map.get("LogicType"))
	add_new_component(AvailableComponents.LinkSlot, "Slot0")
	set_slot(3, true, 0, Color(1.0, 1.0, 1.0), true, 1, Color(1.0, 1.0, 0.0))
	# Add a slot for link state changes
	set_slot(1, false, 0, Color(1.0, 1.0, 1.0), true, 2, Color(0.0, 0.0, 1.0))


func get_component_default(type: AvailableComponents, _component_name: String):
	return _component_default_defaults(type)


func get_node_description() -> String:
	return title


func get_trigger(index: int) -> Variant:
	if index >= len(connect_triggers):
		return null
	return connect_triggers.get(index)


func get_action(index: int) -> Variant:
	if index >= len(connect_actions):
		return null
	return connect_actions.get(index)


func update_slots():
	if trigger_remove_queue.any(func(a): return a):
		for i in range(len(trigger_remove_queue) - 1, -1, -1):
			if not trigger_remove_queue[i]:
				continue
			connect_triggers.remove_at(i)
	if action_remove_queue.any(func(a): return a):
		for i in range(len(action_remove_queue) - 1, -1, -1):
			if not action_remove_queue[i]:
				continue
			connect_actions.remove_at(i)
	var port_amount := len(components) - 3
	var port_needed_amount := maxi(len(connect_triggers), len(connect_actions))
	#var ports_to_update := mini(port_amount, port_needed_amount)
	for i in port_amount:
		var slot_index = i + 3 # Skips "LinkRepeats", "LinkState", "LogicType"
		var link_slot: LinkSlotComponent = get_child(slot_index) as LinkSlotComponent
		var value: Array = link_slot.variable_value as Array
		var cur : Variant = get_trigger(i)
		if value[0] != cur:
			if value[0] != null and (not (value[0] as StringName).is_empty()):
				graph.disconnect_node(value[0], 0, name, i)
			if cur != null:
				graph.connect_node(cur, 0, name, i, true)
		cur = get_action(i)
		if value[1] != cur:
			if value[1] != null and (not (value[1] as StringName).is_empty()):
				graph.disconnect_node(name, i + 1, value[1], 0)
			if cur != null:
				graph.connect_node(name, i + 1, cur, 0, true)
		link_slot.set_value([get_trigger(i), cur])
	# We need an extra port in UI so that user can add new connections
	if port_amount < port_needed_amount + 1:
		var new_slots: int = port_needed_amount - port_amount + 1
		for i in new_slots - 1:
			add_new_component(AvailableComponents.LinkSlot, "Slot%s" % [component_count - 3])
			set_slot(get_child_count() - 1, true, 0, Color(1.0, 1.0, 1.0), true, 1, Color(1.0, 1.0, 0.0))
			var slot_value: Array[StringName] = [get_trigger(port_amount + i), get_action(port_amount + i)]
			if slot_value[0] != null:
				graph.connect_node(slot_value[0], 0, name, get_input_port_count() - 1, true)
			if slot_value[1] != null:
				graph.connect_node(name, get_output_port_count() - 1, slot_value[1], 0, true)
			components[len(components) - 1].set_value(slot_value)
		# Add en empty slot
		add_new_component(AvailableComponents.LinkSlot, "Slot%s" % [component_count - 3])
		set_slot(get_child_count() - 1, true, 0, Color(1.0, 1.0, 1.0), true, 1, Color(1.0, 1.0, 0.0))
	# if we have extra slots, disconnect all from them, then remove them
	elif port_amount > port_needed_amount + 1:
		var ports_to_remove := port_amount - port_needed_amount - 1
		for i in ports_to_remove:
			var link_slot = components[len(components) - 1]
			var trigger: Variant = (link_slot.variable_value as Array)[0]
			var action: Variant = (link_slot.variable_value as Array)[1]
			if trigger != null and (not (trigger as StringName).is_empty()):
				graph.disconnect_node(trigger, 0, name, i)
			if action != null and (not (action as StringName).is_empty()):
				graph.disconnect_node(name, i, action, 0)
			remove_component(link_slot.variable_name)
	update_queued = false
	action_remove_queue.resize(len(connect_actions))
	action_remove_queue.fill(false)
	trigger_remove_queue.resize(len(connect_triggers))
	trigger_remove_queue.fill(false)


func process_connection(other_node: GlobalsGraphNodeBase, port: int):
	var node_name = other_node.name
	var is_output_port: bool = other_node is ActionNode
	if is_output_port:
		if connect_actions.find(node_name) != -1: # Don't allow linking the same node twice
			graph.disconnect_node(name, port, node_name, 0)
			return
		# Here we subtract 1 for the link state output port
		if port - 1 >= len(connect_actions):
			connect_actions.append(other_node.name)
			update_slots()
			update_queued = false
			return
		else:
			connect_actions[port - 1] = other_node.name
	else:
		if connect_triggers.find(node_name) != -1: # Don't allow linking the same node twice
			graph.disconnect_node(node_name, 0, name, port)
			return
		if port >= len(connect_triggers):
			connect_triggers.append(other_node.name)
			update_slots()
			update_queued = false
			return
		else:
			connect_actions[port] = other_node.name
	if not update_queued:
		update_slots.call_deferred()
		update_queued = true


func process_disconnect(other_node: GlobalsGraphNodeBase, port: int):
	var is_output_port: bool = other_node is ActionNode
	if is_output_port:
		#connect_actions.remove_at(port - 1)
		action_remove_queue[port - 1] = true
	else:
		#connect_triggers.remove_at(port)
		trigger_remove_queue[port] = true
	if not update_queued:
		update_slots.call_deferred()
		update_queued = true


func _on_child_exiting_tree(node: Node):
	node.tree_exited.connect(self.reset_size)
