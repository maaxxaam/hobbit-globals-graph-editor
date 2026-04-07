class_name VarParameters extends Resource

@export var data: Dictionary[String, Variant]

static func from_dict(dict: Dictionary[String, Variant]) -> VarParameters:
	var result := VarParameters.new()
	result.data = dict
	return result
