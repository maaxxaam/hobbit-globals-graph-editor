class_name LinkComponent extends EditComponent

@onready var name_label: Label = $LinkLabel
@onready var value_label: Label = $LinkName
@onready var show_btn: Button = $ShowButton
var can_update: bool
var link_node: LinkNode


func _ready():
	variable_default = ""
	can_update = true
	link_node = null


func set_value(value: Variant):
	if value is not String:
		push_error("Expected String on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
		return
	variable_value = value
	if can_update:
		link_from_string()


func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: VarParameters = VarParameters.new()):
	variable_display_name = display_name
	name_label.text = display_name
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count

	can_update = false
	graph_node.graph.load_complete.connect(on_load_complete)

	set_value(value)

func on_load_complete():
	link_from_string()
	can_update = true


func generate_connections(node: LinkNode) -> Dictionary[String, Array]:
	var connections = node.graph.get_connection_list_from_node(node.name)
	var result: Dictionary[String, Array] = {
		"in": connections.filter(func(item): return item["to_node"] == node.name).map(func(item): return (node.graph.get_node(NodePath(item["from_node"])) as GlobalsGraphNodeBase).node_description.text),
		"out": connections.filter(func(item): return item["from_node"] == node.name).map(func(item): return (node.graph.get_node(NodePath(item["to_node"])) as GlobalsGraphNodeBase).node_description.text)
	}
	return result


func array_compare(arr1: Array, arr2: Array) -> bool:
	if len(arr1) > len(arr2):
		#print("diff len")
		return false
	if arr1.is_empty() and arr2.is_empty():
		#print("both empty")
		return true
	var arr2_checked: Array[bool]
	arr2_checked.resize(len(arr2))
	for i in len(arr1):
		var found: bool = false
		for j in len(arr2):
			if arr2_checked[j]:
				continue
			if arr2[j] == arr1[i]:
				found = true
				arr2_checked[j] = true
				break
		if not found:
			#prints(arr1, arr2)
			return false
	#prints("yay!", arr1, arr2)
	return true


func set_link(new_link_node: LinkNode):
	if link_node != null:
		graph_node.graph.disconnect_node(link_node.name, 0, graph_node.name, 1)
	link_node = new_link_node
	show_btn.disabled = link_node == null
	if link_node != null:
		graph_node.graph.connect_node(link_node.name, 0, graph_node.name, 1)
		value_label.text = "Link%s" % [link_node.node_class_index]
	else:
		value_label.text = "Not assigned"


func link_from_string():
	var val: String = variable_value
	if val.contains("LINKS: "):
		val = val.replace("ACTIONS: ", "TRIGGERS: ").replace("LINKS: ", "ACTIONS: ")
	var start_triggers = len("TRIGGERS: ")
	var end_triggers = val.find(" ACTIONS: ")
	var triggers: Array = val.substr(start_triggers, end_triggers - start_triggers).split("/ ", false)
	var start_actions = end_triggers + len(" ACTIONS: ")
	var actions: Array = val.substr(start_actions).split("/ ", false)
	var links: Array = get_tree().get_nodes_in_group("LinkNode")
	var link_connections: Array = links.map(generate_connections)
	#print(link_connections)
	var result_index: int = link_connections.find_custom(func(item: Dictionary) -> bool: return array_compare(triggers, item["in"]))
	var final_index: int = result_index
	while result_index != -1:
		if array_compare(actions, link_connections[result_index]["out"]):
			set_link(links[result_index] as LinkNode)
			return
		else:
			final_index = result_index
			result_index = link_connections.find_custom(func(item: Dictionary) -> bool: return array_compare(triggers, item["in"]), result_index + 1)
	if final_index == -1:
		#prints(triggers, actions)
		#print(link_connections.filter(func(item: Dictionary) -> bool: return array_compare(triggers, item["in"])))
		push_error("Could not link link \"%s\"" % [val])
		return
	set_link(links[final_index] as LinkNode)


func _on_show_button_pressed():
	if link_node != null:
		graph_node.graph.scroll_to_element(link_node)
