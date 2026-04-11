class_name GlobalsPopup extends PopupMenu

@export var main_window: MainWindow
@export var graph: GlobalsGraph
var function_mapping: Dictionary[int, Callable]


func _ready():
	if get_parent().get_parent() is MainWindow:
		main_window = get_parent().get_parent()
	id_pressed.connect(_on_id_pressed)


func _on_id_pressed(id: int):
	var function: Callable = function_mapping.get(id)
	if function == null:
		return
	function.call()
