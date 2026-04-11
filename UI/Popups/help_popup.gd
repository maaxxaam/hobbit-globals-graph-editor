extends GlobalsPopup


func _ready():
	super._ready()
	function_mapping = {
		0: main_window.notify.bind("Open file with [[File] > [Open]]\nor by dragging the file into editor.\nAt the moment, only viewing the files\nis fully supported.", "Mini-manual"),
		1: main_window.notify.bind("Made with Godot 4.6.2\nBy Maaxxaam\nWith help from Modera, boredom and king174rus\nFor Technical Hobbit community\nv0.1.0, April 2026", "About Globals Graph Editor")
	}
