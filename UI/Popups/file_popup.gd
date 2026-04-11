extends GlobalsPopup

func _ready():
	super._ready()
	function_mapping = {
		0: new_file,
		1: open_file,
		2: save_current_file,
		3: save_as,
		4: exit
	}


func new_file():
	main_window.notify("This operation is not implemented yet...", "Error")

func open_file():
	main_window.open_file()

func save_current_file():
	main_window.notify("Saving is not implemented yet...", "Error")

func save_as():
	main_window.notify("Saving is not implemented yet...", "Error")

func exit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
