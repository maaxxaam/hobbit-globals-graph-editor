class_name FloatComponent extends EditComponent

const DEBOUNCE_DURATION = 0.2
@onready var debounce: Timer = $DebounceTimer
@onready var name_label: Label = $Label
@onready var numberbox: SpinBox = $SpinBox
var debounced_value: float = 0.0
var default_params: Dictionary[String, Variant] = {
	"min_value": 0,
	"max_value": 10000,
	"step": 0.001,
	# "prefix": "",
	# "suffix": "",
	# "unbounded_down": false,
	"unbounded_up": true
}


func _ready():
	variable_default = 0.0


func set_value(value: Variant):
	if value is not float:
		push_error("Expected float on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
		return
	variable_value = value
	numberbox.set_value_no_signal(value)


func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: VarParameters = VarParameters.new()):
	if name_label == null:
		debounce = $DebounceTimer
		name_label = $Label
		numberbox = $SpinBox
	variable_display_name = display_name
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count
	name_label.text = display_name + " "

	numberbox.min_value = params.data.get("min_value", default_params["min_value"])
	numberbox.max_value = params.data.get("max_value", default_params["max_value"])
	numberbox.step = params.data.get("step", default_params["step"])
	numberbox.custom_arrow_step = params.data.get("step", default_params["step"])
	numberbox.allow_greater = params.data.get("unbounded_up", default_params["unbounded_up"])
	numberbox.allow_lesser = params.data.get("unbounded_down", false)
	numberbox.prefix = params.data.get("prefix", "")
	numberbox.suffix = params.data.get("suffix", "")
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
