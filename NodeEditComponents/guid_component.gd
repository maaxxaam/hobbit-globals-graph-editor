class_name GUIDComponent extends EditComponent

const DEBOUNCE_DURATION = 0.2
const ALLOWED_CHARS = '0123456789abcdefABCDEF'
@onready var debounce: Timer = $DebounceTimer
@onready var name_label: Label = $Label
@onready var text_part_1: LineEdit = $GUIDEdit/HBoxContainer/LineEdit
@onready var text_part_2: LineEdit = $GUIDEdit/HBoxContainer/LineEdit2
var debounced_value: String
var default_params: Dictionary
var caret_last := 0
var caret_now  := 0
var selection  := 0

func _ready():
	variable_default = "00000000_00000000"
	variable_value = variable_default


func set_value(value: Variant):
	if value is not String:
		push_error("Expected String on assignment to value '%s', got %s" % [variable_name, type_string(typeof(value))])
		return
	variable_value = value

func init_component(node: GlobalsGraphNodeBase, var_name: String, display_name: String, value: Variant, _params: Dictionary = default_params):
	variable_display_name = display_name
	name_label.text = display_name
	graph_node = node
	variable_name = var_name
	variable_order = graph_node.component_count
	#textbox.max_length = params.get("max_length", default_params["max_length"])
	#textbox.placeholder_text = params.get("placeholder", default_params["placeholder"])
	set_value(value)


func _on_spin_box_value_changed(value):
	if debounce.is_stopped():
		debounce.start(DEBOUNCE_DURATION)
		set_value(str(value))
	else:
		debounced_value = str(value)


func _on_debounce_timer_timeout():
	set_value(debounced_value)


func update_value():
	var new_value = "%s_%s" % [text_part_1.text, text_part_2.text]
	variable_value = new_value


func overwrite_value():
	text_part_1.text = (variable_value as String).substr(0, 8)
	text_part_2.text = (variable_value as String).substr(9, 8)


func _on_line_edit_text_changed(new_text: String):
	new_text = line_change(new_text)
	var part_value: String = (variable_value as String).substr(0, 8)
	for i in min(8, len(new_text)):
		if new_text[i] not in ALLOWED_CHARS:
			new_text[i] = part_value[i]
	var car_pos: int = text_part_1.caret_column
	if len(new_text) < 8:
		var text_to_insert: String = "".lpad(8 - len(new_text), '0')
		new_text = new_text.insert(car_pos, text_to_insert)
	text_part_1.text = new_text
	text_part_1.caret_column = car_pos
	update_value()


func line_change(text: String) -> String:
	return text.to_upper()


func _on_line_edit_text_change_rejected(rejected_substring: String):
	rejected_substring = line_change(rejected_substring)
	var car_pos := text_part_1.caret_column
	var spill := ""
	if len(rejected_substring) > (8 - car_pos):
		spill = rejected_substring.substr(8 - car_pos)
		rejected_substring = rejected_substring.substr(0, 8 - car_pos)
	var to_remove := rejected_substring.remove_chars(ALLOWED_CHARS)
	rejected_substring = rejected_substring.remove_chars(to_remove)
	var text := text_part_1.text
	for i in len(rejected_substring):
		text[car_pos + i] = rejected_substring[i]
	text_part_1.text = text
	text_part_1.caret_column = car_pos + len(rejected_substring)
	if car_pos + len(rejected_substring) == 8:
		grab_2()
		text_part_2.text_change_rejected.emit(spill)
	update_value()


func _on_line_edit_gui_input(event: InputEvent):
	caret_last = caret_now
	caret_now = text_part_1.caret_column
	prints(caret_now, caret_last)
	if event.is_action("ui_right"):
		var regular := text_part_1.caret_column == 8 and not text_part_1.has_selection()
		var select := text_part_1.caret_column == 8 and text_part_1.has_selection() and caret_last == text_part_1.caret_column
		if regular:
			grab_2()
		if select:
			grab_2()
			text_part_1.select.call_deferred(text_part_1.get_selection_from_column(), text_part_1.get_selection_to_column())
	common_gui_input(event)


func common_gui_input(event: InputEvent):
	if event.is_action("ui_down"):
		grab_2(8)
	if event.is_action("ui_up"):
		grab_1(0)
	if event.is_action("ui_home"):
		grab_1(0)
	if event.is_action("ui_end"):
		grab_2(8)
	if event.is_action("ui_copy"):
		DisplayServer.clipboard_set.call_deferred(text_part_1.get_selected_text() + text_part_2.get_selected_text())
	if event.is_action("ui_text_select_all"):
		text_part_1.select()
		text_part_2.select()


func grab_1(caret_pos: int = 7):
	text_part_1.grab_focus.call_deferred()
	text_part_1.edit.call_deferred()
	text_part_1.caret_column = caret_pos
	caret_now = caret_pos


func grab_2(caret_pos: int = 0):
	text_part_2.grab_focus.call_deferred()
	text_part_2.edit.call_deferred()
	text_part_2.caret_column = caret_pos
	caret_now = caret_pos + 8


func _on_line_edit_2_gui_input(event: InputEvent):
	caret_last = caret_now
	caret_now = text_part_2.caret_column + 8
	if event.is_action("ui_left"):
		if text_part_2.caret_column == 0 and caret_now == caret_last:
			grab_1()
			if event is InputEventKey:
				if (event as InputEventKey).shift_pressed:
					if text_part_1.has_selection():
						text_part_1.select.call_deferred(text_part_1.get_selection_from_column(), 7)
					else:
						text_part_1.select.call_deferred(7, 8)
				if text_part_2.has_selection():
					text_part_2.select.call_deferred(text_part_2.get_selection_from_column(), text_part_2.get_selection_to_column())
	common_gui_input(event)


func _on_line_edit_2_text_change_rejected(rejected_substring: String):
	rejected_substring = line_change(rejected_substring)
	var car_pos := text_part_2.caret_column
	if len(rejected_substring) > (8 - car_pos):
		rejected_substring = rejected_substring.substr(0, 8 - car_pos)
	var to_remove := rejected_substring.remove_chars(ALLOWED_CHARS)
	rejected_substring = rejected_substring.remove_chars(to_remove)
	var text := text_part_2.text
	for i in len(rejected_substring):
		text[car_pos + i] = rejected_substring[i]
	text_part_2.text = text
	text_part_2.caret_column = car_pos + len(rejected_substring)
	update_value()


func _on_line_edit_2_text_changed(new_text):
	new_text = line_change(new_text)
	var part_value: String = (variable_value as String).substr(9, 8)
	for i in min(8, len(new_text)):
		if new_text[i] not in ALLOWED_CHARS:
			new_text[i] = part_value[i]
	var car_pos: int = text_part_2.caret_column
	if len(new_text) < 8:
		var text_to_insert: String = "".lpad(8 - len(new_text), '0')
		new_text = new_text.insert(car_pos, text_to_insert)
	text_part_2.text = new_text
	text_part_2.caret_column = car_pos
	update_value()


func deselect_all():
	text_part_1.deselect()
	text_part_2.deselect()


func _on_line_edit_2_editing_toggled(toggled_on):
	if not toggled_on:
		deselect_all()


func _on_line_edit_editing_toggled(toggled_on):
	if not toggled_on:
		deselect_all()
