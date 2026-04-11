class_name ComponentPopup extends PopupMenu

var submenus: Dictionary[String, PopupMenu]


func populate(storage: ComponentStorage):
	for key in storage.folder_mapping:
		var submenu_key: String = storage.folder_mapping[key]
		if submenu_key.is_empty():
			self.add_item(storage.mapping[key].descriptive_name, key)
		else:
			submenus[submenu_key].add_item(storage.mapping[key].descriptive_name, key)
