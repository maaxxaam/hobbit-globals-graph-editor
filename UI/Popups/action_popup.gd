extends ComponentPopup

signal new_action_requested(id: int)

func _ready():
	var counter: int = 0
	submenus = {
		"AI": $AI,
		"Cutscene": $Cutscene,
		"Environment": $Environment,
		"NPC": $NPC,
		"Quest": $Quest,
		"Triggers": $Triggers
	}
	for item in submenus:
		set_item_submenu_node(counter, submenus[item])
		counter += 1


func _on_submenu_id_pressed(id):
	new_action_requested.emit(id)


func _on_id_pressed(id):
	if id == 999:
		return
	new_action_requested.emit(id)
