class_name FloatComponent extends EditComponent

const DEBOUNCE_DURATION = 0.2
@onready var debounce: Timer = $DebounceTimer
var debounced_value: float = 0.0
var numberbox: SpinBox
var default_params: Dictionary[String, Variant] = {
	"min_value": 0,
	"max_value": 10000,
	"step": 1,
	# "prefix": "",
	# "suffix": "",
	# "unbounded_down": false,
	"unbounded_up": true
}

func set_value(value: Variant):
	if value is not float:
		push_error("Expected float on assignment to value '%s', got %s" % [variable_name, typeof(value)])
		return
	variable_value = value
	numberbox.set_value_no_signal(value)


func init_component(node: GlobalsGraphNodeBase, var_name: String, value: Variant, params: Dictionary[String, Variant] = default_params):
	numberbox = $SpinBox
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count
	if params != null:
		numberbox.min_value = params.get("min_value", default_params["min_value"])
		numberbox.max_value = params.get("max_value", default_params["max_value"])
		numberbox.step = params.get("step", default_params["step"])
		numberbox.custom_arrow_step = params.get("step", default_params["step"])
		numberbox.allow_greater = params.get("unbounded_up", default_params["unbounded_up"])
		numberbox.allow_less = params.get("unbounded_down", false)
		numberbox.prefix = params.get("prefix", "")
		numberbox.suffix = params.get("suffix", "")
	set_value(value)


func _on_spin_box_value_changed(value):
	if debounce.is_stopped():
		debounce.start(DEBOUNCE_DURATION)
		set_value(value)
	else:
		if value is int or value is float or value is bool:
			debounced_value = float(value)


func _on_debounce_timer_timeout():
	set_value(debounced_value)
