class_name LinkSlotComponent extends EditComponent

@onready var trigger_label: Label = $TriggerName
@onready var trigger_btn: Button = $GoToTrigger
@onready var action_label: Label = $ActionName
@onready var action_btn: Button = $GoToAction


func _ready():
	variable_default = [null, null]
	variable_value = [null, null]


func set_value(value: Variant):
	if value is not Array:
		push_error("Expected Array on assignment to link slot, got %s" % [type_string(typeof(value))])
		return
	if len(value) < 2:
		push_error("Expected Array with len() of >=2 for link slot, got %s" % [len(value)])
		return
	variable_value = value
	if value[0] == null or value[0].is_empty():
		trigger_label.text = ""
	else:
		trigger_label.text = get_slot_text(value[0])
	trigger_btn.disabled = (value[0] == null) or ((value[0] as String).is_empty())
	if value[1] == null or value[1].is_empty():
		action_label.text = ""
	else:
		action_label.text = get_slot_text(value[1])
	action_btn.disabled = (value[1] == null) or ((value[1] as String).is_empty())


func get_slot_text(node_name: StringName) -> String:
	var node: GlobalsGraphNodeBase = graph_node.graph.get_node(NodePath(node_name))
	if node == null:
		return ""
	return "[%s] %s" % [node.node_class_index, node.type_description.text if node.node_description.text.is_empty() else node.node_description.text]


func init_component(node: GlobalsGraphNodeBase, _var_name: String, _display_name: String, _value: Variant = [null, null], _params: VarParameters = VarParameters.new()):
	graph_node = node
	variable_order = graph_node.component_count
	set_value([null, null])


func _on_go_to_trigger_pressed():
	graph_node.graph.scroll_to_element_name(variable_value[0])


func _on_go_to_action_pressed():
	graph_node.graph.scroll_to_element_name(variable_value[1])
