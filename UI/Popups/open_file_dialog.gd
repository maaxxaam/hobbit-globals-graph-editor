extends FileDialog

@export var graph: GlobalsGraph
@onready var main_window: MainWindow = $".."

func _on_file_selected(path):
	main_window.load_file(path)
	hide()
