@abstract class_name EditComponent extends Container

var graph_node: GlobalsGraphNodeBase
var variable_order := 1
var variable_name := ""
var variable_display_name := ""
var variable_value: Variant = []: set = set_value
var variable_default: Variant = []

# Set value stored by the component and display the updated value
@abstract func set_value(value: Variant)
# Perform the neccessary setup
@abstract func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: VarParameters)

# Export the key-value pairs contained within the component in format suitable for writing
func export() -> Dictionary[String, Variant]:
	return { graph_node.wrap_var_name(variable_name): variable_value }
pass
