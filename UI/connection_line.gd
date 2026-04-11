class_name ConnectionLine extends Line2D

var nodes: Array[StringName] = [&"", &""]
var coordinates: Array[Vector2] = []
var graph: GlobalsGraph

func _ready():
	draw.connect(set_coords)
	if is_inside_tree():
		_enter_tree()


func _enter_tree():
	add_to_group("ConnectionLine")

func _exit_tree():
	remove_from_group("ConnectionLine")


func link_graph(graph_: GlobalsGraph):
	graph = graph_


func modulate_connection(state: bool = true):
	if not state:
		modulate = Color("#FFFFFFFF")
		return
	else:
		var in_selection: bool = graph.selected_nodes.reduce(func(accum: bool, item: StringName): return accum or (item in nodes), false)
		var value: float = 1.0 if in_selection else 0.2
		modulate = Color(value, value, value, value)


func set_coords():
	if len(points) < 2:
		return # Not enough points to form a line
	coordinates = [points.get(0), points.get(len(points) - 1)]
	var connection_from: Dictionary = graph.get_closest_connection_at_point(coordinates[0] - graph.scroll_offset)
	var connection_to: Dictionary = graph.get_closest_connection_at_point(coordinates[1] - graph.scroll_offset)
	if connection_from.is_empty() or connection_to.is_empty():
		push_error("Could not find a suitable connection for Line2D: %s %s" % [connection_from.is_empty(), connection_to.is_empty()])
		return
	nodes[0] = connection_from.get("from_node", &"")
	nodes[1] = connection_to.get("to_node", &"")
	draw.disconnect(set_coords)
