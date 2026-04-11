class_name MainWindow extends Control

@onready var Graph: GlobalsGraph = $GraphEdit
var can_focus_graph: bool:
	get = get_focus_graph, set = set_focus_graph
@onready var popup: PopupRMB = $RMB_Popup
@onready var find_node: FindNodePanel = $FindNode
@onready var error_box: ErrorBox = $ErrorBox
@onready var open_file_dialog: FileDialog = $OpenFile
@onready var save_file_dialog: FileDialog = $SaveFile
@onready var notif: AcceptDialog = $NotifyUser
@onready var menu_bar: MenuBar = $MenuBar


func get_focus_graph():
	return Graph.focus_mode != FocusMode.FOCUS_NONE


func set_focus_graph(value: Variant):
	if value == true:
		Graph.focus_mode = Control.FOCUS_ALL
		Graph.mouse_filter = Control.MOUSE_FILTER_STOP
		Graph.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
		Graph.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
		menu_bar.focus_mode = Control.FOCUS_ALL
		menu_bar.mouse_filter = Control.MOUSE_FILTER_STOP
		menu_bar.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
		menu_bar.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	elif value == false:
		Graph.focus_mode = Control.FOCUS_NONE
		Graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Graph.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		Graph.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		menu_bar.focus_mode = Control.FOCUS_NONE
		menu_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_bar.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		menu_bar.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED


func _ready():
	OS.low_processor_usage_mode = true
	await get_tree().physics_frame
	get_tree().root.size_changed.connect(match_size)
	get_tree().root.files_dropped.connect(_on_window_files_dropped)
	match_size()
	show()
	popup.graph = Graph
	find_node.graph = Graph
	popup.new_link_requested.connect(Graph.link_at_mouse)
	popup.select_all_requested.connect(Graph.select_all)
	popup.undo_requested.connect(Graph.undo_action)
	popup.redo_requested.connect(Graph.redo_action)
	popup.find_requested.connect(find_action)

	var testing: ComponentStorage = ComponentStorage.new()
	testing.load_from_folder("res://Resources/Triggers")


func find_action():
	if find_node.visible:
		find_node.find()
	else:
		find_node.show()
		can_focus_graph = false
		find_node.query_box.edit()


func _on_window_files_dropped(files: PackedStringArray):
	var file = files[0]
	load_file(file)


func load_file(file: String):
	var extension = file.get_extension().to_lower()
	var parsed_data: Dictionary[String, Array]
	match extension:
		"json":
			parsed_data = GlobalsParser.parse_json(file)
		"export":
			parsed_data = GlobalsParser.parse_export(file)
		"txt":
			parsed_data = GlobalsParser.parse_text(file)
		_:
			# TODO: print a proper user-faced message on supported data formats
			push_error("Supported formats are [json, txt, export], got %s" % [extension])
			parsed_data = { "Abort": [] }
	error_box.trigger_error()
	if parsed_data.has("Abort"):
		return
	# TODO: check if file is already opened and ask to save that one first
	Graph.clear_all()
	await get_tree().process_frame
	Graph.from_parsed_data(parsed_data)
	error_box.trigger_error()


func open_file():
	open_file_dialog.popup_centered_clamped()


func save_file_as():
	save_file_dialog.popup_centered_clamped()


func match_size():
	var window_size: Vector2i = get_tree().root.size
	Graph.set_size(window_size - Vector2i(0, 32))
	find_node.position = window_size / 2.0
	error_box.position = window_size / 2.0
	notif.position = window_size / 2.0


func _unhandled_input(event):
	if event.is_pressed():
		popup.popup_menu.activate_item_by_event(event)


func notify(message: String, title: String = "Important message"):
	notif.dialog_text = message
	notif.popup_centered_clamped()


func _on_open_file_visibility_changed():
	if open_file_dialog:
		can_focus_graph = not open_file_dialog.visible


func _on_save_file_visibility_changed():
	if save_file_dialog:
		can_focus_graph = not save_file_dialog.visible


func _on_error_box_visibility_changed():
	if error_box:
		can_focus_graph = not error_box.visible


func _on_find_node_visibility_changed():
	if find_node:
		can_focus_graph = not find_node.visible


func _on_notify_user_visibility_changed():
	if notif:
		can_focus_graph = not notif.visible


func _on_graph_edit_child_entered_tree(node):
	pass # Replace with function body.
