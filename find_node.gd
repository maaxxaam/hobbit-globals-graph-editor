class_name FindNodePanel extends Control

signal perform_search(query: String, case_sensitive: bool)



func escape_regex(input: String) -> String:
	input = input.replace("\\", "\\\\")
	input = input.replace(".", "\\.")
	input = input.replace("^", "\\^")
	input = input.replace("$", "\\$")
	input = input.replace("*", "\\*")
	input = input.replace("+", "\\+")
	input = input.replace("?", "\\?")
	input = input.replace("(", "\\(")
	input = input.replace(")", "\\)")
	input = input.replace("[", "\\[")
	input = input.replace("]", "\\]")
	input = input.replace("{", "\\{")
	input = input.replace("}", "\\}")
	input = input.replace("|", "\\|")
	return input
