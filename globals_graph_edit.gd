class_name GlobalsGraph extends GraphEdit


enum BufferModes {
	CUT,
	COPY
}

var link_scene: PackedScene
var action_scene: PackedScene
var trigger_scene: PackedScene
var popup: PopupRMB
var selected_nodes: Array[StringName]
var last_action_node: GlobalsGraphNodeBase
var buffered_nodes: Array[GlobalsGraphNodeBase]
var buffer_mode: BufferModes
var history: UndoRedo


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


func undo_action():
	if history.has_undo():
		history.undo()


func redo_action():
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
	pass


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


func link_spawn_at(pos: Vector2) -> LinkNode:
	var node: GlobalsGraphNodeBase = link_scene.instantiate()
	add_child(node)
	node.set_owner(self)
	node.position_offset = pos
	node.link_graph(self)
	node.from_empty(0)
	return node as LinkNode


func _on_connection_from_empty(to, to_port, release_position):
	var node: LinkNode = link_spawn_at(scroll_offset + release_position)
	connect_node(StringName(get_path_to(node)), 0, to, to_port, true)


func _on_connection_to_empty(from, from_port, release_position):
	var node: LinkNode = link_spawn_at(scroll_offset + release_position)
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
	# Start with a sorting prepass putting
	# Isolated subgraphs with a single link on the bottom
	var last_link_idx := len(parsed_data["Links"]) - 1
	var idx := 0
	while idx <= last_link_idx:
		var data = parsed_data["Links"][idx] as GlobalsParser.ParsedEntry
		var orphan: bool = true
		var items_t: Array = []
		var items_a: Array = []
		var pval = data.find_param_by_name("LinkTrigger")
		if pval != null:
			items_t = pval.value.duplicate()
		pval = data.find_param_by_name("LinkAction")
		if pval != null:
			items_a = pval.value.duplicate()
		if len(items_t) > 0 or len(items_a) > 0:
			for item: GlobalsParser.ParsedEntry in parsed_data["Links"]:
				if item.name == parsed_data["Links"][idx].name:
					continue
				var link_items_t: Array
				var link_items_a: Array
				pval = item.find_param_by_name("LinkTrigger")
				if pval != null:
					link_items_t = pval.value.duplicate()
				pval = item.find_param_by_name("LinkAction")
				if pval != null:
					link_items_a = pval.value.duplicate()
				for candidate in link_items_t:
					for tester in items_t:
						if candidate == tester:
							orphan = false
							break
					if orphan == false:
						break
				for candidate in link_items_a:
					for tester in items_a:
						if candidate == tester:
							orphan = false
							break
					if orphan == false:
						break
				if orphan == false:
					break
		if orphan:
			var temp = parsed_data["Links"].get(idx)
			parsed_data["Links"].set(idx, parsed_data["Links"].get(last_link_idx))
			parsed_data["Links"].set(last_link_idx, temp)
			last_link_idx -= 1
		else:
			idx += 1
	# Second sorting prepass putting
	# Remaining isolated subgraphs together
	idx = 0
	while idx < last_link_idx:
		print(last_link_idx)
		var data = parsed_data["Links"][idx] as GlobalsParser.ParsedEntry
		var ids: Array[int] = [idx]
		var items_t: Array = []
		var items_a: Array = []
		var pval = data.find_param_by_name("LinkTrigger")
		if pval != null:
			items_t = pval.value.duplicate()
		pval = data.find_param_by_name("LinkAction")
		if pval != null:
			items_a = pval.value.duplicate()
		prints(items_t, items_a)
		for i in last_link_idx + 1:
			var item = parsed_data["Links"][i]
			if item.name == parsed_data["Links"][idx].name:
				continue
			var skip := false
			var link_items_t: Array
			var link_items_a: Array
			pval = item.find_param_by_name("LinkTrigger")
			if pval != null:
				link_items_t = pval.value.duplicate()
			pval = item.find_param_by_name("LinkAction")
			if pval != null:
				link_items_a = pval.value.duplicate()
			for candidate in link_items_t:
				for tester in items_t:
					if candidate == tester:
						items_t.append_array(link_items_t)
						items_a.append_array(link_items_a)
						ids.append(i)
						skip = true
						break
				if skip:
					break
			if skip:
				continue
			for candidate in link_items_a:
				for tester in items_a:
					if candidate == tester:
						items_t.append_array(link_items_t)
						items_a.append_array(link_items_a)
						ids.append(i)
						skip = true
						break
				if skip:
					break
			if skip:
				continue
		ids.sort()
		ids.reverse()
		print(ids)
		for index in len(ids):
			var item := ids[index]
			var temp = parsed_data["Links"].get(item)
			parsed_data["Links"].set(item, parsed_data["Links"].get(last_link_idx))
			parsed_data["Links"].set(last_link_idx, temp)
			last_link_idx -= 1
		#idx += 1

	for item: GlobalsParser.ParsedEntry in parsed_data["Links"]:
		var new_node: GraphNode = node_from_parsed(item, Vector2(LINK_X, link_y))
		link_y += new_node.size.y + ITEM_SPACING
		var pval: GlobalsParser.ParsedValue = item.find_param_by_name("LinkTrigger")
		if pval == null:
			continue
		for index: int in pval.value:
			var new_trigger: GraphNode = find_trigger_by_index(index)
			if new_trigger == null:
				var trigger_data: GlobalsParser.ParsedEntry = parsed_data["Triggers"][index]
				new_trigger = node_from_parsed(trigger_data, Vector2(TRIGGER_X, trigger_y))
				trigger_y += new_trigger.size.y + ITEM_SPACING
			connect_node(new_trigger.name, 0, new_node.name, 0, true)
		pval = item.find_param_by_name("LinkAction")
		if pval == null:
			continue
		for index: int in pval.value:
			var new_action: GraphNode = find_action_by_index(index)
			if new_action == null:
				var action_data: GlobalsParser.ParsedEntry = parsed_data["Actions"][index]
				new_action = node_from_parsed(action_data, Vector2(ACTION_X, action_y))
				action_y += new_action.size.y + ITEM_SPACING
			connect_node(new_node.name, 0, new_action.name, 0, true)
		link_y = max(link_y, action_y, trigger_y)
		action_y = link_y
		trigger_y = link_y
	# Since components do not affect node's size until next frame,
	# reposition them next frame
	await get_tree().process_frame
	for item in get_tree().get_nodes_in_group("LinkNode"):
		pass


func find_trigger_by_index(index: int) -> GlobalsGraphNodeBase:
	var trigger_name = "Trigger%s" % [index]
	var arr: Array = get_tree().get_nodes_in_group("TriggerNode").filter(func(item): return item.title == trigger_name)
	return null if arr.is_empty() else arr.get(0)

func find_action_by_index(index: int) -> GlobalsGraphNodeBase:
	var action_name = "Action%s" % [index]
	var arr: Array = get_tree().get_nodes_in_group("ActionNode").filter(func(item): return item.title == action_name)
	return null if arr.is_empty() else arr.get(0)

func find_link_by_index(index: int) -> GlobalsGraphNodeBase:
	var link_name = "Link%s" % [index]
	var arr: Array = get_tree().get_nodes_in_group("LinkNode").filter(func(item): return item.title == link_name)
	return null if arr.is_empty() else arr.get(0)

func node_from_parsed(data: GlobalsParser.ParsedEntry, pos: Vector2) -> GlobalsGraphNodeBase:
	var name_mask: String = data.name.substr(0, 4)
	var node: GlobalsGraphNodeBase
	match name_mask:
		"Link":
			node = link_scene.instantiate()
		"Acti":
			node = action_scene.instantiate()
		"Trig":
			node = trigger_scene.instantiate()
		_:
			push_error("Don't know which node type is object '%s'" % [data.name])
			return null
	add_child(node)
	node.set_owner(self)
	node.position_offset = pos
	node.link_graph(self)
	node.from_parsed(data)
	return node


func get_node_class_index(type: StringName) -> int:
	var indices: Array = get_tree().get_nodes_in_group(type).map(func (node): return (node as GlobalsGraphNodeBase).node_class_index)
	indices.sort()
	var prev := -1
	for idx in indices:
		if idx - prev > 1:
			if idx == -1:
				continue
			return prev + 1
		prev = idx
	return prev + 1


func link_at_mouse():
	var pos: Vector2 = get_global_mouse_position()
	link_spawn_at(scroll_offset + pos)


func select_all():
	get_tree().set_group("LinkNode", "selected", true)
	get_tree().set_group("ActionNode", "selected", true)
	get_tree().set_group("TriggerNode", "selected", true)
