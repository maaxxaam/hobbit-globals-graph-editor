class_name StringComponent extends EditComponent

const DEBOUNCE_DURATION = 0.2
@onready var debounce: Timer = $DebounceTimer
@onready var name_label: Label = $Label
@onready var textbox: LineEdit = $LineEdit
var debounced_value: String
var default_params: Dictionary[String, Variant] = {
	"max_length": 255,
	"placeholder": "Enter value..."
}


func _ready():
	variable_default = ""


func set_value(value: Variant):
	if value is not String:
		push_error("Expected String on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
		return
	variable_value = value
	textbox.text = value

func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, params: Dictionary = default_params):
	variable_display_name = display_name
	name_label.text = display_name
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count
	textbox.max_length = params.get("max_length", default_params["max_length"])
	textbox.placeholder_text = params.get("placeholder", default_params["placeholder"])
	set_value(value)


func _on_spin_box_value_changed(value):
	if debounce.is_stopped():
		debounce.start(DEBOUNCE_DURATION)
		set_value(str(value))
	else:
		debounced_value = str(value)


func _on_debounce_timer_timeout():
	set_value(debounced_value)
