class_name PopupRMB extends Control

signal _do_not_use
signal select_all_requested
signal find_requested
signal remove_requested
signal copy_requested
signal cut_requested
signal paste_requested
signal undo_requested
signal redo_requested
signal new_link_requested
signal action_spawn_requested(id: int)
signal trigger_spawn_requested(id: int)

@onready var popup_menu: PopupMenu = $PopupMenu
@onready var action_submenu: PopupMenu = $PopupMenu/AddActionSubMenu
@onready var trigger_submenu: PopupMenu = $PopupMenu/AddTriggerSubMenu
var graph: GlobalsGraph
var signal_map: Dictionary[int, Signal] = {
	2: new_link_requested,
	9: undo_requested,
	10: redo_requested,
	12: find_requested,
	4: cut_requested,
	5: copy_requested,
	6: paste_requested,
	7: select_all_requested,
	8: remove_requested
}

func _ready():
	popup_menu.set_item_submenu_node(0, trigger_submenu)
	popup_menu.set_item_submenu_node(1, action_submenu)
	# New Link
	popup_setup_shortcut([KEY_L], 2)
	# Remove
	popup_setup_shortcut([KEY_DELETE], 12)
	# Undo/Redo
	popup_setup_shortcut([KEY_MASK_CMD_OR_CTRL, KEY_Z], 4)
	popup_setup_shortcut([KEY_MASK_CMD_OR_CTRL, KEY_R], 5)
	# Find
	popup_setup_shortcut([KEY_MASK_CMD_OR_CTRL, KEY_F], 7)
	# Cut/Copy/Paste/Select All
	popup_setup_shortcut([KEY_MASK_CMD_OR_CTRL, KEY_X], 8)
	popup_setup_shortcut([KEY_MASK_CMD_OR_CTRL, KEY_C], 9)
	popup_setup_shortcut([KEY_MASK_CMD_OR_CTRL, KEY_V], 10)
	popup_setup_shortcut([KEY_MASK_CMD_OR_CTRL, KEY_A], 11)

	visibility_changed.connect(setup_submenus)


func setup_submenus():
	action_submenu.populate(graph.action_storage)
	trigger_submenu.populate(graph.trigger_storage)
	visibility_changed.disconnect(setup_submenus)


func popup_setup_shortcut(keys: Array[int], item_index: int, popup: PopupMenu = popup_menu):
	var key_event: InputEventKey = InputEventKey.new()
	for key in keys:
		match key:
			KEY_MASK_CMD_OR_CTRL:
				key_event.ctrl_pressed = true
				key_event.command_or_control_autoremap = true # Swaps Ctrl for Command on Mac.
			KEY_MASK_ALT: key_event.alt_pressed = true
			KEY_MASK_SHIFT: key_event.shift_pressed = true
			KEY_MASK_META: key_event.meta_pressed = true
			_: key_event.keycode = (key_event.keycode | key) as Key
	var shortcut: Shortcut = Shortcut.new()
	shortcut.events = [key_event.duplicate_deep()]
	var accel_key: int = keys.reduce(func(accum: int, item: int): return accum | item)
	popup.set_item_accelerator(item_index, accel_key)
	popup.set_item_shortcut(item_index, shortcut, true)


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


func _on_popup_menu_index_pressed(index):
	var ident := popup_menu.get_item_id(index)
	(signal_map.get(ident, _do_not_use) as Signal).emit()
