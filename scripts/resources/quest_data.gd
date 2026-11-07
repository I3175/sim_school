class_name QuestData
extends Resource
@export var id: String = ""
@export var title_key: String = ""
@export var description_key: String = ""
@export var quest_type: String = "main"
@export var giver_id: String = ""
@export var turn_in_id: String = ""
@export var prerequisites: Dictionary = {}
@export var objectives: Array[Dictionary] = []
@export var sequential: bool = false
@export var time_limit_days: int = 0
@export var rewards: Dictionary = {}
@export var repeatable: bool = false
@export var cooldown_days: int = 1
