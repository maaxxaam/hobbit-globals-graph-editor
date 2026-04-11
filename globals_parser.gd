extends Node


class ParsedEntry:
	var name: String
	var params: Array[ParsedValue]

	func _init(_name: String, _params: Array[ParsedValue]):
		name = _name
		params = _params

	func add_param(_name: String, type: String, value: Variant):
		params.append(ParsedValue.new(_name, type, value))

	func last_param() -> ParsedValue:
		return params[len(params) - 1] if len(params) > 0 else null

	func find_param_by_name(param_name: String) -> ParsedValue:
		var index: int = params.find_custom(func(item): return item.name == param_name)
		return null if index == -1 else params[index]

	static func from_json(_name: String, list: Dictionary) -> ParsedEntry:
		var parse_result := GlobalsParser.parse_var_names(_name, list)
		return ParsedEntry.new(_name, parse_result)

	func _to_string():
		return "'%s' - %s" % [name, params]


class ParsedValue:
	var name: String
	var type: String
	var value: Variant

	func _init(_name: String, _type: String, _value: Variant):
		name = _name
		type = _type
		value = _value

	func _to_string():
		return "%s: %s = %s" % [name, type, value]


var simple_type_mapping: Dictionary[String, int] = {
	"d": TYPE_INT,
	"f": TYPE_FLOAT,
	"s": TYPE_STRING,
	"g": TYPE_STRING, # GUIDs, stored in format HHHHHHHH_HHHHHHHH, where H is a hex digit [0-9A-F]
	"a": TYPE_ARRAY # Not found in actual data, inserted by us for convenience
}


func parse_text(_file: String) -> Dictionary[String, Array]:
	var data: Array[Dictionary] = []
	var file = FileAccess.open(_file, FileAccess.READ)
	var line_num: int = 0
	while file.get_position() < file.get_length():
		var line = file.get_line().strip_edges().trim_prefix("[").trim_suffix("]").strip_edges()
		line_num += 1
		if len(line) == 0:  # Wow, text file with comments!
			line = file.get_line().strip_edges().trim_prefix("[").trim_suffix("]").strip_edges()
			line_num += 1
			if file.get_position() >= file.get_length():  # the prev line might've been last
				break
		var row_count_sep: int = line.find(" : ")
		if row_count_sep == -1:  # no match
			var err_msg: String = "Parse error (line %s): expected string format '[ Name : 000 ]', got '[ %s ]'" % [line_num, line]
			push_error(err_msg)
			return {"Abort": []}
		var new_entry: Dictionary[String, Variant] = {
			"name": line.substr(0, row_count_sep),
			"row_count": line.substr(row_count_sep + 3).to_int(),
			"rows": []
		}
		line = file.get_line().strip_edges().trim_prefix("{").trim_suffix("}").strip_edges()
		line_num += 1
		var names: Array[String] = []
		var fres: int = -1
		while len(line) > 0:
			if line[0] == "'":
				fres = line.find("'", 1)
				names.append(line.substr(1, fres - 1))
				line = line.substr(fres + 2).lstrip(" \n\r\t")
			else:
				fres = line.find(" ")
				names.append(line.substr(0, fres))
				fres = len(line) if fres == -1 else fres
				line = line.substr(fres + 1).lstrip(" \n\r\t")
		for i in new_entry["row_count"]:
			var name_index: int = 0
			var string_offset: int = 1
			var new_row: Dictionary[String, Variant] = {}
			line = file.get_line().strip_edges()
			line_num += 1
			if line.begins_with("//"):  # Wow, text file with comments!
				line = file.get_line().strip_edges()
				line_num += 1
			while len(line) > 0:
				var cur_name: String = names[name_index]
				var value: Variant = []
				while cur_name[len(cur_name) - string_offset] != ":":
					var type_symbol: String = cur_name[len(cur_name) - string_offset]
					match type_symbol:
						"d":
							fres = line.find(" ")
							var next_value: String = line.substr(0, fres)
							fres = len(line) if fres == -1 else fres
							line = line.substr(fres + 1).lstrip(" \n\r\t")
							value.append(next_value.to_int())
						"f":
							fres = line.find(" ")
							var next_value: String = line.substr(0, fres)
							fres = len(line) if fres == -1 else fres
							line = line.substr(fres + 1).lstrip(" \n\r\t")
							value.append(next_value.to_float())
						"s":
							var next_value: String = line.substr(0, line.find('"', line.find('"') + 1))
							line = line.substr(len(next_value) + 1).lstrip(" \n\r\t")
							value.append(next_value.lstrip('"').rstrip('"'))
						"g":
							fres = line.find(" ")
							var next_value: String = line.substr(0, fres)
							fres = len(line) if fres == -1 else fres
							line = line.substr(fres + 1).lstrip(" \n\r\t")
							value.append(next_value)
						_:
							var err_msg: String = "Parse error (line %s): unknown variable type '%s' from attr '%s' on obj '%s'" % [line_num, type_symbol, cur_name, new_entry["name"]]
							push_error(err_msg)
							file.close()
							return {"Abort": []}
					string_offset += 1
				if len(value) == 1:
					value = value[0]
				new_row.set(cur_name, value)
				name_index += 1
				string_offset = 1
			new_entry["rows"].append(new_row)
		data.append(new_entry)
	file.close()
	return parse_data(data)


func parse_export(_file: String) -> Dictionary[String, Array]:
	var data: Array[Dictionary] = []
	var strings: Array[String] = []
	var file = FileAccess.open(_file, FileAccess.READ)
	file.seek(8);
	var string_amount: int = file.get_32();
	var strings_bytes: int = file.get_32();
	var strings_as_bytes: PackedByteArray = file.get_buffer(strings_bytes);
	while len(strings_as_bytes) > 0:
		strings.append(strings_as_bytes.slice(0, strings_as_bytes.find(0)).get_string_from_ascii())
		strings_as_bytes = strings_as_bytes.slice(strings_as_bytes.find(0) + 1)
	if len(strings) != string_amount:
		var err_msg: String = "Integrity check failed: expected %s strings, got %s" % [string_amount, len(strings)]
		push_error(err_msg)
		file.close()
		return {"Abort": []}
	var next_entry: int = file.get_position()
	while next_entry != 0:
		if next_entry != file.get_position():
			var err_msg: String = "Integrity error after parsing entry %s: expected to be at pos 0x%s but got to pos 0x%s" % [len(data), String.num_int64(next_entry, 16), String.num_int64(file.get_position(), 16)]
			push_error(err_msg)
			file.close()
			return {"Abort": []}
		var new_entry: Dictionary[String, Variant] = {
			"name": strings[file.get_32()],
			"rows": []
		}
		new_entry.set("row_count", file.get_32())
		next_entry = file.get_32()
		file.get_32() # Skip 4 bytes
		for i in new_entry["row_count"]:
			if file.eof_reached():
				var err_msg: String = "Parse error: expected to read %s more rows for entry '%s' but reached EOF" % [new_entry["row_count"] - i, new_entry["name"]]
				push_error(err_msg)
				file.close()
				return {"Abort": []}
			var row_bytes: int = file.get_32()
			var row_bytes_read: int = 0
			file.get_32()
			var row_data: Dictionary[String, Variant] = {}
			while not file.eof_reached() and row_bytes_read < row_bytes:
				var column_name: String = strings[file.get_32()]
				var column_size: int = file.get_32()
				var column_data: PackedByteArray = file.get_buffer(column_size)
				row_bytes_read += 8 + column_size
				var col_final_data: Variant = []
				var name_index = len(column_name) - 1
				while column_name[name_index] != ":":
					var type_symbol: String = column_name[name_index]
					match type_symbol:
						"d":
							col_final_data.append(column_data.slice(0, 4).decode_s32(0))
							column_data = column_data.slice(4)
						"f":
							col_final_data.append(column_data.slice(0, 4).decode_float(0))
							column_data = column_data.slice(4)
						"s":
							col_final_data.append(column_data.slice(0, column_data.find(0)).get_string_from_ascii())
							column_data = column_data.slice(column_data.find(0) + 1)
						"g":
							var final: String = ""
							var slice: Array = Array(column_data.slice(0, 4))
							slice.reverse()
							final += slice.reduce(func(accum: String, item: int): return accum + "%02X" % [item], "")
							column_data = column_data.slice(4)
							final += "_"
							slice = Array(column_data.slice(0, 4))
							slice.reverse()
							final += slice.reduce(func(accum: String, item: int): return accum + "%02X" % [item], "")
							column_data = column_data.slice(4)
							col_final_data.append(final)
						_:
							var err_msg: String = "Parse error: unknown variable type '%s' from attr '%s' on obj '%s'" % [type_symbol, column_name, new_entry["name"]]
							push_error(err_msg)
							file.close()
							return {"Abort": []}
					name_index -= 1
				if len(col_final_data) == 1:
					col_final_data = col_final_data[0]
				row_data.set(column_name, col_final_data)
			if row_bytes_read > row_bytes:
				var err_msg: String = "Parse error: expected to read %s bytes for a row of entry '%s' but read %s bytes instead" % [row_bytes, new_entry["name"], row_bytes_read]
				push_error(err_msg)
				file.close()
				return {"Abort": []}
			new_entry["rows"].append(row_data)
		data.append(new_entry)
		file.get_64()
	file.close()
	return parse_data(data)


func parse_json(_file: String) -> Dictionary[String, Array]:
	var json_result = JSON.parse_string(FileAccess.get_file_as_string(_file))
	if json_result == null:
		push_error("Not a JSON file!")
		return {"Abort": []}
	if typeof(json_result) != TYPE_ARRAY:
		var err_msg: String = "Expected an Array from JSON, got a different type %s" % [typeof(json_result)]
		push_error(err_msg)
		return {"Abort": []}
	var json_array: Array = json_result as Array
	return parse_data(json_array)

func parse_data(json_array: Array) -> Dictionary[String, Array]:
	var result: Dictionary[String, Array] = {
		"BeforeAI": [],
		"Triggers": [],
		"Actions": [],
		"Links": [],
		"AfterAI": []
	}
	var entry_index: int = 0
	while (entry_index < len(json_array)) and (json_array[entry_index].name != "AIManager"):
		result["BeforeAI"].append(json_array[entry_index])
		entry_index += 1
	if entry_index == len(json_array):
		push_error("Failed to parse JSON: 'AIManager' entry not found")
		return result
	var actions: int = -1
	var triggers: int = -1
	var links: int = -1
	for pvalue in json_array[entry_index].rows[0]:
		if pvalue == "TriggerCount:d":
			triggers = json_array[entry_index].rows[0][pvalue]
		if pvalue == "ActionCount:d":
			actions = json_array[entry_index].rows[0][pvalue]
		if pvalue == "LinkCount:d":
			links = json_array[entry_index].rows[0][pvalue]
	if actions == -1 or triggers == -1 or links == -1:
		push_error("Failed to parse JSON: action, trigger or link count is missing in AIManager: %s %s %s" % [triggers, actions, links])
		return result
	if entry_index + actions + triggers + links >= len(json_array):
		push_error("Failed to parse JSON: there are %s AIManager objects reported but only %s entries left. Parsing the file would cause going OOB" % [actions + triggers + links, len(json_array) - entry_index - 1])
		return result
	if triggers > 0 and json_array[entry_index + triggers].name != ("Trigger%s" % [triggers - 1]):
		push_error("Integrity check failed: expected element %s to be 'Trigger%s', got %s" % [triggers - 1, triggers - 1, json_array[entry_index + triggers].name])
		return result
	if actions > 0 and json_array[entry_index + triggers + actions].name != ("Action%s" % [actions - 1]):
		push_error("Integrity check failed: expected element %s to be 'Action%s', got %s" % [triggers + actions - 1, actions - 1, json_array[entry_index + triggers + actions].name])
		return result
	if links > 0 and json_array[entry_index + triggers + actions + links].name != ("Link%s" % [links - 1]):
		push_error("Integrity check failed: expected element %s to be 'Link%s', got %s" % [triggers + actions + links - 1, links - 1, json_array[entry_index + triggers + actions + links].name])
		return result
	result["Triggers"] = json_array.slice(entry_index + 1, entry_index + triggers + 1, 1, true).map(func(item): return ParsedEntry.from_json(item.name, item.rows[0]))
	result["Actions"] = json_array.slice(entry_index + triggers + 1, entry_index + triggers + actions + 1, 1, true).map(func(item): return ParsedEntry.from_json(item.name, item.rows[0]))
	result["Links"] = json_array.slice(entry_index + triggers + actions + 1, entry_index + triggers + actions + links + 1, 1, true).map(func(item): return ParsedEntry.from_json(item.name, item.rows[0]))
	return result

func get_int_from_string_end(from: String) -> int:
	var index_length: int = 1
	while from.substr(len(from) - index_length).is_valid_int():
		index_length += 1
	var index: int = -1
	index_length -= 1
	if index_length > 0:
		index = from.substr(len(from) - index_length).to_int()
	return index

func parse_var_names(var_name: String, row: Dictionary) -> Array[ParsedValue]:
	var index: int = get_int_from_string_end(var_name)
	var index_length: int = len(String.num_int64(index))
	var result: Array[ParsedValue] = []
	for item: String in row.keys():
		var sep: int = item.find(":")
		if sep == -1:
			var err_msg := "Object '%s' has attr '%s' w/o type info. Skipping attribute..." % [var_name, item]
			push_error(err_msg)
			continue
		var type: String = item.substr(sep + 1)
		var name_indexed: String = item.substr(0, sep)
		var attr_name: String
		if name_indexed.begins_with(var_name):
			attr_name = name_indexed.substr(len(var_name))
		elif index_length > 0:
			var possible_index: String = name_indexed.substr(len(name_indexed) - index_length)
			var link_array_index: String = "Index%s-" % [index]
			if name_indexed.contains(link_array_index):
				attr_name = name_indexed.replace(link_array_index, "")
			elif not possible_index.is_valid_int():
				var err_msg := "Object '%s' has attr '%s' w/o matching index suffix. Skipping attribute..." % [var_name, name_indexed]
				push_error(err_msg)
				continue
			elif possible_index.to_int() != index:
				var err_msg := "Object '%s' has attr '%s' w/o matching index suffix. Skipping attribute..." % [var_name, name_indexed]
				push_error(err_msg)
				continue
			else:
				attr_name = name_indexed.substr(0, len(name_indexed) - index_length)
		else:
			attr_name = name_indexed  # there was no index, actually
		# Failsafe in case attribute name == variable name.
		# Example: TriggerXXX may have a TriggerXXX attribute. Fun!
		if len(attr_name) == 0:
			attr_name = var_name.replace(String.num_int64(index), "")
		var value: Variant = row[item]
		var val_type: int = typeof(value)
		# Let's check for arrays! Yay!
		var array_index: int = -1
		#if attr_name.ends_with("Count"):
		#	attr_name = attr_name.replace("Count", "")
		#	value = []
		#	value.resize(int(row[item]))
		var a_index_start: int = 0
		if attr_name.ends_with("Guid"):
			a_index_start += 4
		if attr_name[len(attr_name) - a_index_start - 1].is_valid_int():
			var a_index_length = 1
			while attr_name.substr(len(attr_name) - a_index_length - a_index_start, a_index_length).is_valid_int():
				a_index_length += 1
			a_index_length -= 1
			array_index = attr_name.substr(len(attr_name) - a_index_length - a_index_start, a_index_length).to_int()
			attr_name = attr_name.substr(0, len(attr_name) - a_index_length - a_index_start)
			type = "a" + simple_type_mapping.find_key(val_type)
			val_type = TYPE_ARRAY
		# Check for array types like fff or dddd
		if len(type) > 1 and val_type != TYPE_ARRAY:
			var err_msg := "Type mismatch for attr '%s' in object '%s': expected array from notation '%s', got type %s. Inserting anyway..." % [attr_name, var_name, type, val_type]
			push_error(err_msg)
		if len(type) == 1 and not simple_type_mapping.has(type):
			var err_msg := "Unknown type in attr '%s' of object '%s': '%s'. Inserting anyway..." % [attr_name, var_name, type]
			push_error(err_msg)
			result.append(ParsedValue.new(attr_name, type, value))
			continue
		if len(type) == 1 and simple_type_mapping[type] != val_type:
			# Handle edge case of INT being parsed as FLOAT
			if simple_type_mapping[type] == TYPE_INT and val_type == TYPE_FLOAT and ((value - int(value)) == 0):
				value = int(value)
			else:
				var err_msg := "Type mismatch for attr '%s' in object '%s': expected type %s, got type %s. Skipping attribute..." % [attr_name, var_name, simple_type_mapping[type], val_type]
				push_error(err_msg)
				continue
		if array_index == -1:
			result.append(ParsedValue.new(attr_name, type, value))
		else:
			var res_index: int = result.find_custom(func(res): return res.name == attr_name)
			if res_index != -1:
				if result[res_index].type == "a":
					result[res_index].type = result[res_index].type + type
				if array_index + 1 > len(result[res_index].value):
					(result[res_index].value as Array).resize(array_index + 1)
				result[res_index].value[array_index] = value
			else:
				if type.begins_with("a"):
					result.append(ParsedValue.new(attr_name, type, []))
					(result[len(result) - 1].value as Array).resize(array_index + 1)
					result[len(result) - 1].value[array_index] = value
				else:
					attr_name = attr_name + String.num_int64(array_index)
					result.append(ParsedValue.new(attr_name, type, value))
	for item in result:
		if item.type.begins_with("a"):
			if (item.value as Array).has(null):
				var err_msg := "Attr '%s' of object '%s' is an array %s with null entries!" % [item.name, var_name, item.value]
				push_warning(err_msg)
	return result
