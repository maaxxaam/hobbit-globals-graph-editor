class_name GlobalsGraph extends GraphEdit


enum BufferModes {
	CUT,
	COPY
}

var link_scene: Resource
var action_scene: Resource
var trigger_scene: Resource
var popup: PopupRMB
var selected_nodes: Array[StringName]
var buffered_nodes
var buffer_mode: BufferModes
var history: UndoRedo
var popup_mapping: Dictionary[int, Callable] = {
	9: undo_action,
	10: redo_action
}


func _is_node_hover_valid(from, from_port, to, to_port):
	var from_node: GraphNode = get_node(NodePath(from))
	var to_node: GraphNode = get_node(NodePath(to))
	return (from != to) and is_valid_connection_type(from_node.get_output_port_type(from_port), to_node.get_input_port_type(to_port))


func _ready():
	link_scene = preload("res://link.tscn")
	action_scene = preload("res://action.tscn")
	trigger_scene = preload("res://trigger.tscn")
	popup = $"../RMB_Popup"
	history = UndoRedo.new()

	add_valid_connection_type(0, 0)
	add_valid_connection_type(1, 1)
	add_valid_right_disconnect_type(0)
	add_valid_right_disconnect_type(1)
	add_valid_connection_type(0, 1)

	await get_tree().process_frame
	popup.popup_menu.id_pressed.connect(_on_rmb_popup_item)


func _on_rmb_popup_item(id: int):
	if id in popup_mapping:
		print("Calling '%s'" % [popup_mapping[id].get_method()])
		popup_mapping[id].call()


func undo_action():
	print("Tried undo!")
	if history.has_undo():
		history.undo()


func redo_action():
	print("Tried redo!")
	if history.has_redo():
		history.redo()


func _on_connection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	var from_node: GraphNode = get_node(NodePath(from))
	var to_node: GraphNode = get_node(NodePath(to))
	var from_type: int = from_node.get_output_port_type(from_port)
	var to_type: int = to_node.get_input_port_type(from_port)
	if is_valid_connection_type(from_type, to_type):
		if from_type == to_type:
			connect_node(from, from_port, to, to_port, true)
		else:
			var pos: Vector2 = (from_node.position_offset + to_node.position_offset + from_node.get_output_port_position(from_port) + to_node.get_input_port_position(to_port)) / 2.0
			var node: GraphNode = link_scene.instantiate()
			add_child(node)
			node.set_owner(self)
			node.position_offset = pos
			connect_node(from, from_port, StringName(get_path_to(node)), 0, true)
			connect_node(StringName(get_path_to(node)), 0, to, to_port, true)


func _on_connection_drag_started(from, from_port, is_output):
	var from_node: GraphNode = get_node(NodePath(from))
	if is_output:
		print("%s %s" % [from_port, from_node.get_output_port_type(from_port)])
	else:
		print("%s %s" % [from_port, from_node.get_input_port_type(from_port)])


func _on_disconnection_request(from_node, from_port, to_node, to_port):
	print("disconnection request")
	disconnect_node(from_node, from_port, to_node, to_port)


func _on_delete_nodes_request(nodes):
	for node in nodes:
		var node_ref = get_node(NodePath(node))
		remove_connections_to_node(node_ref)
		_on_node_deselected(node_ref)
		node_ref.queue_free()


func remove_connections_to_node(node):
	for con in get_connection_list():
		if con.to_node == node.name or con.from_node == node.name:
			disconnect_node(con.from_node, con.from_port, con.to_node, con.to_port)


func _on_connection_from_empty(to, to_port, release_position):
	var node: GraphNode = link_scene.instantiate()
	add_child(node)
	node.set_owner(self)
	node.position_offset = scroll_offset + release_position
	connect_node(StringName(get_path_to(node)), 0, to, to_port, true)


func _on_connection_to_empty(from, from_port, release_position):
	var node: GraphNode = link_scene.instantiate()
	add_child(node)
	node.set_owner(self)
	node.position_offset = scroll_offset + release_position
	connect_node(from, from_port, StringName(get_path_to(node)), 0, true)


func _on_copy_nodes_request():
	# TODO: handle node copy
	pass # Replace with function body.


func _on_cut_nodes_request():
	# TODO: handle node cut
	pass # Replace with function body.


func _on_paste_nodes_request():
	# TODO: handle node paste for both copy and cut
	pass # Replace with function body.


func _on_duplicate_nodes_request():
	# TODO: handle node duplication
	pass # Replace with function body.


func _on_node_selected(node: Node):
	var node_name: StringName = node.name
	var index = selected_nodes.find(node_name)
	if index == -1:
		selected_nodes.append(node_name)


func _on_node_deselected(node):
	var node_name: StringName = node.name
	var index = selected_nodes.find(node_name)
	if index != -1:
		selected_nodes.remove_at(index)


func _on_popup_request(at_position):
	popup.show()
	popup.position = at_position
	popup.popup_menu.position = at_position

func ur_move_node(node: GraphNode, from: Vector2, to: Vector2):
	history.add_do_property(node, "position_offset", to)
	history.add_undo_property(node, "position_offset", from)

func clear_all():
	for child in get_children():
		if child is GraphNode:
			remove_connections_to_node(child)
			child.queue_free()

func from_parsed_data(parsed_data: Dictionary[String, Array]):
	const ITEM_SPACING = 16
	const ACTION_X = 1000.0
	const TRIGGER_X = 0.0
	const LINK_X = 500.0
	var link_y: float = 0.0
	var action_y: float = 0.0
	var trigger_y: float = 0.0
	for item: GlobalsParser.ParsedEntry in parsed_data["Links"]:
		var new_node: GraphNode = link_from_parsed(item, Vector2(LINK_X, link_y))
		link_y += new_node.size.y + ITEM_SPACING
		var pval: GlobalsParser.ParsedValue = item.find_param_by_name("LinkTrigger")
		if pval == null:
			continue
		for index: int in pval.value:
			var new_trigger: GraphNode = find_trigger_by_index(index)
			if new_trigger == null:
				var trigger_data: GlobalsParser.ParsedEntry = parsed_data["Triggers"][index]
				new_trigger = trigger_from_parsed(trigger_data, Vector2(TRIGGER_X, trigger_y))
				trigger_y += new_trigger.size.y + ITEM_SPACING
			connect_node(new_trigger.name, 0, new_node.name, 0, true)
		pval = item.find_param_by_name("LinkAction")
		if pval == null:
			continue
		for index: int in pval.value:
			var new_action: GraphNode = find_action_by_index(index)
			if new_action == null:
				var action_data: GlobalsParser.ParsedEntry = parsed_data["Actions"][index]
				new_action = action_from_parsed(action_data, Vector2(ACTION_X, action_y))
				action_y += new_action.size.y + ITEM_SPACING
			connect_node(new_node.name, 0, new_action.name, 0, true)
		link_y = max(link_y, action_y, trigger_y)
		action_y = link_y
		trigger_y = link_y

func find_trigger_by_index(index: int) -> GraphNode:
	var trigger_name = "Trigger%s" % [index]
	for child in get_children():
		if child is GraphNode and child.title == trigger_name:
			return child
	return null

func find_action_by_index(index: int) -> GraphNode:
	var action_name = "Action%s" % [index]
	for child in get_children():
		if child is GraphNode and child.title == action_name:
			return child
	return null

func find_link_by_index(index: int) -> GraphNode:
	var link_name = "Link%s" % [index]
	for child in get_children():
		if child is GraphNode and child.title == link_name:
			return child
	return null

func trigger_from_parsed(data: GlobalsParser.ParsedEntry, pos: Vector2) -> GraphNode:
	var node: TriggerNode = trigger_scene.instantiate()
	add_child(node)
	node.set_owner(self)
	node.position_offset = pos
	node.title = data.name
	var pval: GlobalsParser.ParsedValue = data.find_param_by_name("TriggerName")
	if pval == null:
		push_error("Didn't find param 'TriggerName' on Trigger")
		return node
	node.triggerName.text = pval.value
	pval = data.find_param_by_name("TriggerType")
	if pval == null:
		push_error("Didn't find param 'TriggerType' on Trigger")
		return node
	node.typeDescription.text = String.num_int64(pval.value)
	return node

func action_from_parsed(data: GlobalsParser.ParsedEntry, pos: Vector2) -> GraphNode:
	var node: ActionNode = action_scene.instantiate()
	add_child(node)
	node.set_owner(self)
	node.position_offset = pos
	node.title = data.name
	var pval: GlobalsParser.ParsedValue = data.find_param_by_name("ActionName")
	if pval == null:
		push_error("Didn't find param 'ActionName' on Action")
		return node
	node.actionName.text = pval.value
	pval = data.find_param_by_name("ExecuteDelay")
	if pval == null:
		push_error("Didn't find param 'ExecuteDelay' on Action")
		return node
	node.execDelay.value = pval.value
	pval = data.find_param_by_name("ExecuteImmediately")
	if pval == null:
		push_error("Didn't find param 'ExecuteImmediately' on Action")
		return node
	node.execImmediately.set_pressed_no_signal(pval.value == 1)
	pval = data.find_param_by_name("ActionType")
	if pval == null:
		push_error("Didn't find param 'ActionType' on Action")
		return node
	node.typeDescription.text = String.num_int64(pval.value)
	return node

func link_from_parsed(data: GlobalsParser.ParsedEntry, pos: Vector2) -> GraphNode:
	var node: LinkNode = link_scene.instantiate()
	add_child(node)
	node.set_owner(self)
	node.position_offset = pos
	node.title = data.name
	var pval: GlobalsParser.ParsedValue = data.find_param_by_name("LinkRepeats")
	if pval == null:
		push_error("Didn't find param 'LinkRepeats' on Link")
		return node
	node.linkRepeats.set_pressed_no_signal(pval.value == 1)
	pval = data.find_param_by_name("LogicType")
	if pval == null:
		push_error("Didn't find param 'LogicType' on Link")
		return node
	node.logicType.selected = pval.value
	pval = data.find_param_by_name("LinkState")
	if pval == null:
		push_error("Didn't find param 'LinkState' on Link")
		return node
	node.linkState.selected = pval.value
	return node
