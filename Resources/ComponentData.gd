class_name ComponentData extends Resource

@export var id: int
@export var descriptive_name: String
@export var variable_params: Dictionary[String, VarParameters]
@export var type_overrides: Dictionary[String, GlobalsGraphNodeBase.AvailableComponents]
@export var variable_aliases: Dictionary[String, String]
