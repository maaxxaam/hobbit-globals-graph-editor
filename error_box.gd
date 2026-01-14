class_name ErrorBox extends Control


class ErrorBoxLogger extends Logger:
	var history: Array[String] = []
	const function_mapping = {
		"a": "b"
	}
	const err_type_mapping: Dictionary[Logger.ErrorType, String] = {
		Logger.ERROR_TYPE_ERROR: "Error",
		Logger.ERROR_TYPE_SCRIPT: "Script error",
		Logger.ERROR_TYPE_SHADER: "Shader error",
		Logger.ERROR_TYPE_WARNING: "Warning"
	}

	func has_pending_errors():
		return len(history) > 0

	func pop_errors() -> Array[String]:
		var result := history.duplicate()
		history.clear()
		return result

	func _log_message(_message, _error):
		pass  # Don't care about print() like messages

	func _log_error(function, _file, _line, _code, rationale, _editor_notify, error_type, _script_backtraces):
		if function_mapping.has(function):
			function = function_mapping.get(function)
		history.append("%s %s: %s" % [err_type_mapping.get(error_type), function, rationale])


@onready var text_box: TextEdit = $PanelContainer/HBoxContainer/ScrollContainer/TextEdit
var logger: ErrorBoxLogger


func _ready():
	logger = ErrorBoxLogger.new()
	OS.add_logger(logger)


func trigger_error():
	if not logger.has_pending_errors():
		return
	show()
	text_box.editable = true
	text_box.text = logger.pop_errors().reduce(func(agg, item): return agg + "\n" + item, "").strip_edges()
	text_box.editable = false


func _on_close_pressed():
	hide()
