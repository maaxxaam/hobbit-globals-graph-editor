class_name MainWindow extends Node2D

@onready var Graph: GlobalsGraph = $Control/GraphEdit
@onready var popup: PopupRMB = $Control/RMB_Popup
@onready var find_node: FindNodePanel = $Control/FindNode
@onready var error_box: ErrorBox = $Control/ErrorBox


func _ready():
	await get_tree().physics_frame
	get_tree().root.size_changed.connect(match_size)
	get_tree().root.files_dropped.connect(_on_window_files_dropped)
	match_size()
	show()
	popup.graph = Graph


func _on_window_files_dropped(files: PackedStringArray):
	var file = files[0]
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
			return # TODO: print a message on supported data formats
	if parsed_data.has("Errors"):
		var full_text: String = (parsed_data["Errors"] as Array[String]).reduce(func(accum: String, item: String): return accum + "\n" + item, "")
		error_box.trigger_error()
		if parsed_data.has("Abort"):
			return
	# TODO: check if file is already opened and ask to save that one first
	Graph.clear_all()
	await get_tree().process_frame
	Graph.from_parsed_data(parsed_data)


func match_size():
	var window_size: Vector2i = get_tree().root.size
	Graph.set_size(window_size - Vector2i(0, 32))
	find_node.position = window_size / 2
	error_box.position = window_size / 2


func _unhandled_input(event):
	if event.is_pressed():
		popup.popup_menu.activate_item_by_event(event)
