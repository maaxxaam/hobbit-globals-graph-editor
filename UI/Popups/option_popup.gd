extends GlobalsPopup


func _ready():
	super._ready()
	function_mapping = {
		0: main_window.notify.bind("No settings yet...", "Error"),
		1: main_window.notify.bind("No GUID menu yet, \ncome back later...", "Error"),
		2: main_window.notify.bind("Rebinding things is planned, \ncome back later...", "Error")
	}
