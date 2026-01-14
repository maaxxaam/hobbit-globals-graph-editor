@abstract class_name EditComponent extends Control

var graph_node: GlobalsGraphNodeBase
var variable_order := 1
var variable_name := ""
var variable_value: Variant = []: set = set_value
var variable_default: Variant = []


@abstract func set_value(value: Variant)
@abstract func init_component(node: GlobalsGraphNodeBase, var_name: String, value: Variant, params: Dictionary[String, Variant])


func export() -> Dictionary[String, Variant]:
	return { graph_node.wrap_var_name(variable_name): variable_value }
pass
