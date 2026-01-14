class_name PopupRMB extends Control


@onready var popup_menu: PopupMenu = $PopupMenu
@onready var action_submenu: PopupMenu = $PopupMenu/AddActionSubMenu
@onready var trigger_submenu: PopupMenu = $PopupMenu/AddTriggerSubMenu
var graph: GlobalsGraph


func _ready():
	popup_menu.set_item_submenu_node(0, trigger_submenu)
	popup_menu.set_item_submenu_node(1, action_submenu)
	var key_event: InputEventKey = InputEventKey.new()
	# New Link
	key_event.keycode = KEY_L
	popup_setup_shortcut(key_event, 2)
	# Remove
	key_event.keycode = KEY_DELETE
	popup_setup_shortcut(key_event, 12)
	# Undo/Redo
	key_event.ctrl_pressed = true
	key_event.command_or_control_autoremap = true # Swaps Ctrl for Command on Mac.
	key_event.keycode = KEY_Z
	popup_setup_shortcut(key_event, 4)
	key_event.keycode = KEY_R
	popup_setup_shortcut(key_event, 5)
	# Find
	key_event.keycode = KEY_F
	popup_setup_shortcut(key_event, 7)
	# Cut/Copy/Paste/Select All
	key_event.keycode = KEY_X
	popup_setup_shortcut(key_event, 8)
	key_event.keycode = KEY_C
	popup_setup_shortcut(key_event, 9)
	key_event.keycode = KEY_V
	popup_setup_shortcut(key_event, 10)
	key_event.keycode = KEY_A
	popup_setup_shortcut(key_event, 11)


func popup_setup_shortcut(key_event: InputEventKey, item_index: int):
	var shortcut: Shortcut = Shortcut.new()
	shortcut.events = [key_event.duplicate_deep()]
	var accel_key: int = key_event.keycode
	accel_key = accel_key | (int(key_event.ctrl_pressed) * KEY_MASK_CMD_OR_CTRL)
	accel_key = accel_key | (int(key_event.alt_pressed) * KEY_MASK_ALT)
	accel_key = accel_key | (int(key_event.shift_pressed) * KEY_MASK_SHIFT)
	popup_menu.set_item_accelerator(item_index, accel_key)
	popup_menu.set_item_shortcut(item_index, shortcut, true)


func _on_visibility_changed():
	if popup_menu == null:
		return
	if visible:
		popup_menu.show()
		check_menu_visibility()
	else:
		popup_menu.hide()


func _on_popup_menu_popup_hide():
	hide()


func check_menu_visibility():
	if graph == null:
		popup_menu.set_item_disabled(4, true)
		popup_menu.set_item_disabled(5, true)
		popup_menu.set_item_disabled(8, true)
		popup_menu.set_item_disabled(9, true)
		popup_menu.set_item_disabled(12, true)
	else:
		popup_menu.set_item_disabled(4, not graph.history.has_undo())
		popup_menu.set_item_disabled(5, not graph.history.has_redo())
		popup_menu.set_item_disabled(8,  len(graph.selected_nodes) == 0)
		popup_menu.set_item_disabled(9,  len(graph.selected_nodes) == 0)
		popup_menu.set_item_disabled(12, len(graph.selected_nodes) == 0)
