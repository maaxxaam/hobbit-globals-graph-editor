extends ComponentPopup

signal new_trigger_requested(id: int)

func _ready():
	var counter: int = 0
	submenus = {
		"AI": $AI,
		"Bilbo": $Bilbo,
		"Environment": $Environment,
		"NPC": $NPC,
		"Quest": $Quest
	}
	for item in submenus:
		set_item_submenu_node(counter, submenus[item])
		counter += 1


func _on_submenu_id_pressed(id):
	new_trigger_requested.emit(id)


func _on_id_pressed(id):
	if id == 999:
		return
	new_trigger_requested.emit(id)
