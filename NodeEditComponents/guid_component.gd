class_name GUIDComponent extends EditComponent

const DEBOUNCE_DURATION = 0.2
const ALLOWED_CHARS = '0123456789abcdefABCDEF_'
@onready var debounce: Timer = $DebounceTimer
@onready var name_label: Label = $Label
@onready var text: LineEdit = $GUIDEdit/HBoxContainer/LineEdit
var debounced_value: String
var default_params: Dictionary
var caret_now  := 0

func _ready():
	variable_default = "00000000_00000000"
	variable_value = variable_default


func ready_init():
	debounce = $DebounceTimer
	name_label = $Label
	text = $GUIDEdit/HBoxContainer/LineEdit


func set_value(value: Variant):
	if value is not String:
		push_error("Expected String on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
		return
	variable_value = value
	text.text = variable_value
	text.caret_column = caret_now

func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, _params: VarParameters = VarParameters.new()):
	if text == null:
		ready_init()
	variable_display_name = display_name
	name_label.text = display_name
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count
	set_value(value)


func _on_debounce_timer_timeout():
	set_value(debounced_value)


func update_value():
	variable_value = text.text


func _on_line_edit_text_changed(new_text: String):
	new_text = line_change(new_text)
	caret_now = text.caret_column
	var to_remove := new_text.remove_chars(ALLOWED_CHARS)
	new_text = new_text.remove_chars(to_remove).substr(0, 17 - caret_now)
	if len(new_text) < 17:
		if len(new_text) == 16:
			new_text = new_text.substr(0, 8) + '_' + new_text.substr(8)
		else:
			new_text = new_text + (variable_default as String).substr(len(new_text))
	if len(new_text) > 17:
		new_text = new_text.substr(0, 17)
	for i in 17:
		if new_text[i] == '_':  # always double-assigns the underscore, but should be fine otherwise
			new_text[i] = variable_value[i]
	text.text = new_text
	text.caret_column = caret_now
	update_value()


func line_change(txt: String) -> String:
	return txt.to_upper()


func _on_line_edit_text_change_rejected(rejected_substring: String):
	print(rejected_substring)
	rejected_substring = line_change(rejected_substring)
	caret_now = text.caret_column
	var to_remove := rejected_substring.remove_chars(ALLOWED_CHARS)
	rejected_substring = rejected_substring.remove_chars(to_remove).substr(0, 17 - caret_now)
	for i in len(rejected_substring):
		if caret_now + i != 8 and rejected_substring[i] == '_':
			rejected_substring[i] = variable_value[caret_now + i]
		elif caret_now + i == 8 and rejected_substring[i] != '_':
			rejected_substring[i] = '_'
	text.text = text.text.substr(0, caret_now) + rejected_substring + text.text.substr(caret_now + len(rejected_substring))
	text.caret_column = caret_now + len(rejected_substring)
	caret_now += len(rejected_substring)
	update_value()
