class_name ComponentStorage extends Node

var mapping: Dictionary[int, ComponentData]
var folder_mapping: Dictionary[int, String]


func load_from_folder(folder: String):
	var folders: Array[String] = [folder]
	while not folders.is_empty():
		var cur_folder: String = folders.pop_back()
		for item in ResourceLoader.list_directory(cur_folder):
			if item.ends_with("/"):
				folders.append(cur_folder + item)
				continue
			if not item.ends_with("tres"):
				continue
			var new_data: ComponentData = ResourceLoader.load(cur_folder + item, "ComponentData") as ComponentData
			mapping.set(new_data.id, new_data)
			folder_mapping.set(new_data.id, cur_folder.trim_prefix(folder))
