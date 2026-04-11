class_name FindNodePanel extends Control

@onready var query_box: LineEdit = $PanelContainer/HBoxContainer/LineEdit
@onready var case_flag: CheckBox = $PanelContainer/HBoxContainer/FlagsRow/CaseSensitive
@onready var regex_flag: CheckBox = $PanelContainer/HBoxContainer/FlagsRow/UseRegex
var last_query_result: GlobalsGraphNodeBase = null
var regex: RegEx
var graph: GlobalsGraph


func perform_search(query: String, case_sensitive: bool, use_regex: bool) -> GlobalsGraphNodeBase:
	if not case_sensitive:
		query = query.to_lower()
	if not use_regex:
		query = escape_regex(query)
	regex = RegEx.create_from_string(query)
	var nodes: Array = get_tree().get_nodes_in_group("GlobalsGraphNodeBase")
	var idx := nodes.find(last_query_result) + 1
	var shifted := nodes.slice(idx)
	shifted.append_array(nodes.slice(0, idx))
	var names: Array = shifted.map(func(item): return item.title + char(30) + item.get_node_description())
	for i in len(names):
		var from: String = names[i] as String
		if not case_sensitive:
			from = from.to_lower()
		if regex.search(from) != null:
			last_query_result = shifted[i]
			return shifted[i]
	return null


func escape_regex(input: String) -> String:
	input = input.replace("\\", "\\\\")
	input = input.replace(".", "\\.")
	input = input.replace("^", "\\^")
	input = input.replace("$", "\\$")
	input = input.replace("*", "\\*")
	input = input.replace("+", "\\+")
	input = input.replace("?", "\\?")
	input = input.replace("(", "\\(")
	input = input.replace(")", "\\)")
	input = input.replace("[", "\\[")
	input = input.replace("]", "\\]")
	input = input.replace("{", "\\{")
	input = input.replace("}", "\\}")
	input = input.replace("|", "\\|")
	return input


func _on_case_insensitive_pressed():
	last_query_result = null  # This changes the query


func _on_use_regex_pressed():
	last_query_result = null  # This changes the query


func _on_find_next_pressed():
	find()


func find():
	var result := perform_search(query_box.text, case_flag.button_pressed, regex_flag.button_pressed)
	if result != null:
		graph.scroll_to_element(result)


func _on_find_close_pressed():
	find()
	hide()
	last_query_result = null


func _on_close_pressed():
	hide()
	last_query_result = null


func _on_line_edit_text_submitted(_new_text):
	find()


func _on_line_edit_text_changed(_new_text):
	last_query_result = null  # This changes the query
